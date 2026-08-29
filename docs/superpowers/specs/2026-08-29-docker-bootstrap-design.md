# Docker 初回起動の再現性改善 設計

## 対象

- GitHub Issue: [#70 Docker初回起動を再現可能にし、環境設定の二重管理を解消する](https://github.com/beekle-team/laravel-react-docker-template/issues/70)
- 対象環境: ローカル開発用 Docker Compose

## 背景

現在のリポジトリには、クリーンチェックアウトからアプリを起動する利用者向け手順がない。ルートと `src/` の両方に `.env.example` があり、前者は PostgreSQL・Redis・Mailpit、後者は SQLite・database queue・log mailer を既定としているため、どちらを Laravel の設定として使うかで実際の構成が変わる。

また、Dockerfile は Composer と npm の依存を導入せず、Compose は `./src` を `/var/www` へ bind mount する。クリーンチェックアウトで `docker compose up -d` だけを実行しても、Laravel の `vendor`、フロントエンド依存、APP_KEY、migration、Vite が準備されず、アプリを利用できない。現在の CI は各準備を個別に実行するため、この利用者経路の退行を検出しない。

## 目標

- Git と Docker を用意したクリーンチェックアウトから、1つのセットアップコマンドで開発環境を起動できる。
- Laravel と Docker Compose が同じ環境設定を参照する。
- セットアップを安全に再実行できる。
- アプリ、Vite HMR、PostgreSQL、Redis、Mailpit の接続を開発環境の標準構成として揃える。
- CI でクリーンチェックアウトからの起動と HTTP 疎通を検証する。

## 非目標

- 本番用 Docker イメージまたはデプロイ方式の設計
- Node.js のメジャーバージョン更新
- Queue worker や scheduler の常駐サービス追加
- Windows の Command Prompt / PowerShell だけで完結する専用スクリプト

## 検討した方式

### 1. `src/.env` を正本にし、Compose wrapper を使う（採用）

`src/.env.example` を唯一の設定テンプレートとする。`scripts/compose.sh` が `docker compose --env-file src/.env` を必ず付け、Compose の変数展開と Laravel が同じ `src/.env` を参照する。

Laravel 標準の配置を維持でき、APP_KEY も `php artisan key:generate` で通常どおり保存できる。raw の `docker compose` ではなく wrapper を入口にする制約は、README と失敗メッセージで明示する。

### 2. ルート `.env` を `/var/www/.env` へマウントする（不採用）

Compose が自動読込するルート `.env` を Laravel にも直接マウントすれば正本を1つにできる。しかし Laravel、Composer script、CI が前提とする `src/.env` / `src/.env.example` から外れ、ファイルマウントの存在を全コマンドで意識する必要がある。

### 3. 依存を開発用 Docker イメージへ含める（不採用）

依存をイメージへ含めること自体はセキュリティ上の問題ではない。lockfile 固定、multi-stage build、秘密情報を build layer に残さないこと、不要な開発依存を本番 runtime に含めないことを守れば、実行物を不変化できる利点がある。

今回は `./src:/var/www` の bind mount がイメージ内の `/var/www/vendor` と `/var/www/node_modules` を隠すこと、lockfile 更新のたびに開発用イメージの再ビルドが必要になることから採用しない。依存はセットアップ時に Docker named volume へ導入する。

## 設計

### 環境設定

- `src/.env.example` を開発用設定テンプレートの正本にする。
- PostgreSQL、Redis、Mailpit、`APP_URL=http://localhost:8080` を Docker 開発環境の既定値にする。
- Compose 公開ポートも同じファイルで定義できるようにする。
- ルート `.env.example` は削除し、重複する設定テンプレートを残さない。
- `.env` は引き続き Git 管理外とし、セットアップは既存の `src/.env` を上書きしない。

### コマンド境界

`scripts/compose.sh` を Docker Compose の共通入口にする。

- リポジトリルートを自動解決する。
- `src/.env` がない場合は、先に `scripts/setup.sh` を実行するよう案内して失敗する。
- `docker compose --env-file src/.env "$@"` へ引数をそのまま渡す。

`scripts/setup.sh` は以下を順番に行う。

1. Docker と Docker Compose が利用可能か確認する。
2. `src/.env` がなければ `src/.env.example` から作る。
3. app イメージをビルドする。
4. `--no-deps` を付けた一時 app コンテナで、`composer-vendor` と `node-modules` named volume へ `composer install` と `npm ci` を実行する。
5. `--no-deps` を付けた一時 app コンテナで、APP_KEY が空の場合だけ生成する。
6. PostgreSQL、Redis、Mailpit を起動して health check を待つ。
7. migration を実行する。
8. app、nginx、Vite を起動する。

途中で失敗した場合は非0で終了し、失敗したコマンドを隠さない。再実行時は既存の APP_KEY、環境設定、PostgreSQL volume を保持する。

### Compose サービス

- app は PHP-FPM に専念する。
- Vite は app と同じイメージと bind mount を使う専用サービスとして起動する。
- app と Vite は `composer-vendor:/var/www/vendor` と `node-modules:/var/www/node_modules` を共有する。
- named volume により Docker Desktop の bind mount 上で依存の大量ファイルを更新せず、依存を image layer にも含めない。
- Vite の公開ポートは app から Vite サービスへ移す。
- Vite サービスは `npm run dev -- --host 0.0.0.0` を実行する。
- nginx は app に依存し、既存どおり `http://localhost:8080` を公開する。
- PostgreSQL、Redis、Mailpit の設定値は `--env-file src/.env` を通じて解決する。

### README

ルート `README.md` をテンプレート固有の入口として追加し、次を記載する。

- 必要なツールは Git と Docker であること
- `scripts/setup.sh` による初回セットアップ
- 通常の起動、停止、ログ、コンテナ内コマンド
- アプリ、Vite、Mailpit の URL
- `src/.env` によるポート・接続設定の変更
- 日常的な品質ゲート
- `down` と `down -v` の違い、および volume 削除が破壊的操作であること

`src/README.md` は二重の入口を作らないため削除する。

## セキュリティ境界

- `.env`、Composer/npm の認証情報、秘密鍵を Dockerfile の build context や image layer に追加しない。
- Composer/npm の依存は named volume に保存し、Docker image layer へ含めない。
- setup のログへ APP_KEY や環境変数の値を表示しない。
- Dockerfile の既存 `.dockerignore` により `.env`、`vendor`、`node_modules` を除外し続ける。
- 永続 volume の削除は setup や通常の停止処理に含めない。
- 今後本番イメージを作る場合は、開発用 Compose と分離し、multi-stage build と runtime dependency の最小化を別設計で扱う。

## テスト

### スクリプト回帰テスト

Docker を実際に起動しない shell test で、次を検証する。

- `scripts/compose.sh` が `--env-file src/.env` を付ける。
- `src/.env` がない場合の案内と終了コード。
- setup が既存 `.env` と APP_KEY を上書きしない。
- root `.env.example` が再追加されていない。

外部コマンドは PATH 上の fake executable で記録し、分岐を決定論的に検証する。

### Docker スモークテスト

GitHub Actions の専用 job で次を行う。

1. クリーンチェックアウトから `scripts/setup.sh` を実行する。
2. `http://localhost:8080` が HTTP 200 を返すまで上限時間つきで待つ。
3. app コンテナ内で migration 状態と PostgreSQL 接続を確認する。
4. Vite のポートへ疎通できることを確認する。
5. 成否にかかわらず Compose resources を停止する。CI の一時 volume は削除する。

## 移行

既存利用者の `src/.env` は変更しない。ルート `.env` を使っていた場合は、必要な値を `src/.env` へ移してルート `.env` を削除し、以後 `scripts/compose.sh` を使う。README に移行メモを記載する。

## 完了条件

- クリーンチェックアウトから `scripts/setup.sh` が成功する。
- セットアップ後、アプリが HTTP 200 を返し、Vite HMR と Mailpit を利用できる。
- Laravel と Compose が `src/.env` の PostgreSQL、Redis、Mailpit 設定を共有する。
- setup の再実行で APP_KEY と永続データが保持される。
- setup が依存を Docker named volume へ導入し、ホストの `vendor` と `node_modules` を必須にしない。
- shell test、既存 CI、Docker スモークテストが成功する。
