# Laravel React Docker Template

Laravel 13、Inertia 3、React 19、PostgreSQL、Redis、MailpitをDockerで起動する開発用テンプレートです。ホストにPHPやNode.jsをインストールせず、GitとDockerだけで開始できます。

## 必要なもの

- Git
- Docker DesktopまたはDocker Engine + Docker Compose v2

## 初回セットアップ

リポジトリルートで次を実行します。

```bash
scripts/setup.sh
```

このコマンドは、未作成の場合だけ`src/.env`を生成し、Dockerイメージのビルド、Composer/npm依存の導入、APP_KEY生成、migration、主要な開発サービスの起動を順に行います。再実行しても既存の`src/.env`、APP_KEY、PostgreSQLデータは削除しません。

依存は`composer-vendor`と`node-modules`というDocker named volumeに保存します。Dockerイメージには依存、`.env`、認証情報を含めません。

## URL

| 用途 | 既定URL |
| --- | --- |
| アプリ | http://localhost:8080 |
| Vite | http://localhost:5173 |
| Mailpit | http://localhost:8025 |

## 日常的な操作

Composeは必ず`scripts/compose.sh`経由で実行します。このwrapperが、ComposeとLaravelの両方に`src/.env`を使わせます。

```bash
# 起動・状態確認・停止
scripts/compose.sh up -d
scripts/compose.sh ps
scripts/compose.sh down

# ログ
scripts/compose.sh logs -f app nginx vite

# Artisan、Composer、npm
scripts/compose.sh exec app php artisan migrate
scripts/compose.sh up -d --wait postgres-test
scripts/compose.sh exec app composer test
scripts/compose.sh exec app npm run test:unit
```

## 環境設定とポート

設定の正本は`src/.env`です。初期値は`src/.env.example`にあります。

| 変数 | 既定値 | 用途 |
| --- | --- | --- |
| `APP_PORT` | `8080` | nginx |
| `VITE_PORT` | `5173` | Vite / HMR |
| `DB_HOST_PORT` | `5432` | PostgreSQLのホスト公開ポート |
| `DB_TEST_PORT` | `5433` | テスト用PostgreSQL |
| `REDIS_HOST_PORT` | `6379` | Redisのホスト公開ポート |
| `MAILPIT_SMTP_PORT` | `1025` | Mailpit SMTP |
| `MAILPIT_UI_PORT` | `8025` | Mailpit UI |

ポートが競合する場合は、`src/.env`で該当変数のコメントを外して変更し、サービスを再起動してください。
Laravelがコンテナ間通信に使う`DB_PORT=5432`と`REDIS_PORT=6379`は変更せず、ホスト側だけを`DB_HOST_PORT`と`REDIS_HOST_PORT`で変更します。

## 品質ゲート

```bash
bash scripts/check-php-version-consistency.sh
scripts/compose.sh exec app composer lint
scripts/compose.sh up -d --wait postgres-test
scripts/compose.sh exec app composer test
scripts/compose.sh exec app npm run lint:js
scripts/compose.sh exec app npm run types
scripts/compose.sh exec app npm run lint:react-compiler
scripts/compose.sh exec app npm run lint:architecture
scripts/compose.sh exec app npm run test:unit
```

## ホストIDEで依存ソースを参照する場合

通常の起動には不要です。ホスト側のIDEが`vendor`や`node_modules`を直接必要とし、ホストにPHP/Node.jsがある場合だけ次を実行できます。

```bash
cd src
composer install
npm ci
```

コンテナ実行時はnamed volume側の依存が使われます。

## 既存環境からの移行

以前のルート`.env`を使っている場合は、必要な値を`src/.env`へ移してルート`.env`を削除してください。以後はrawの`docker compose`ではなく`scripts/compose.sh`を使用します。

## データを削除して初期化する

通常の停止は`scripts/compose.sh down`です。次のコマンドはPostgreSQLデータとComposer/npm依存のnamed volumeを削除する破壊的操作です。

```bash
scripts/compose.sh down -v --remove-orphans
```

実行後は`scripts/setup.sh`で再作成できます。`src/.env`は削除されません。
