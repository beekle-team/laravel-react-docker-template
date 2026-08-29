# Docker Bootstrap Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Git と Docker だけを用意したクリーンチェックアウトから、1つの冪等なコマンドで Laravel・Vite・PostgreSQL・Redis・Mailpit を起動できるようにする。

**Architecture:** `src/.env.example` を唯一の設定テンプレートとし、すべての Compose 操作を `scripts/compose.sh` から `--env-file src/.env` 付きで実行する。`scripts/setup.sh` が Docker named volume へ依存を導入し、APP_KEY と DB を初期化した後、PHP-FPM・nginx・専用 Vite サービスを起動する。shell 回帰テストは fake Docker CLI で制御フローを検証し、GitHub Actions は実コンテナで HTTP・Vite・DB の疎通を検証する。

**Tech Stack:** Bash, Docker Compose, PHP 8.5 / Laravel 13, Node.js 20 / Vite 7, GitHub Actions

**Spec:** `docs/superpowers/specs/2026-08-29-docker-bootstrap-design.md`

## Global Constraints

- 対象はローカル開発用 Docker Compose とし、本番イメージやデプロイ方式は変更しない。
- Node.js のメジャーバージョンは 20 のままとする。
- `.env`、APP_KEY、Composer/npm 認証情報を image layer やログへ出さない。
- `vendor` と `node_modules` は Docker イメージへ焼き込まず、`composer-vendor` と `node-modules` named volume へ導入する。
- 既存の `src/.env`、APP_KEY、PostgreSQL volume は setup の再実行で上書き・削除しない。
- volume 削除は通常の停止フローへ含めない。
- shell test は Docker daemon を使わず、実機確認だけを専用 smoke test で行う。

---

### Task 1: 環境設定の正本と Compose wrapper

**Files:**
- Create: `scripts/compose.sh`
- Create: `tests/shell/compose-wrapper-test.sh`
- Modify: `src/.env.example`
- Delete: `.env.example`
- Modify: `.gitignore`

**Interfaces:**
- Consumes: Docker Compose CLI `docker compose`、`src/.env`。
- Produces: `scripts/compose.sh [arguments...]`。カレントディレクトリに依存せず、リポジトリルートで `docker compose --env-file src/.env [arguments...]` を実行する。

- [ ] **Step 1: Compose wrapper の失敗する回帰テストを書く**

`tests/shell/compose-wrapper-test.sh` に一時プロジェクトと fake `docker` を作り、次を検証する。

```bash
#!/usr/bin/env bash
set -euo pipefail

TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEST_ROOT"' EXIT
mkdir -p "$TEST_ROOT/project/scripts" "$TEST_ROOT/project/src" "$TEST_ROOT/bin"
cp scripts/compose.sh "$TEST_ROOT/project/scripts/compose.sh"
printf 'APP_NAME=Laravel\n' > "$TEST_ROOT/project/src/.env"

cat > "$TEST_ROOT/bin/docker" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$DOCKER_CALLS"
EOF
chmod +x "$TEST_ROOT/bin/docker"

DOCKER_CALLS="$TEST_ROOT/docker.calls" \
PATH="$TEST_ROOT/bin:$PATH" \
    "$TEST_ROOT/project/scripts/compose.sh" ps

grep -Fx 'compose --env-file src/.env ps' "$TEST_ROOT/docker.calls"

rm "$TEST_ROOT/project/src/.env"
if DOCKER_CALLS="$TEST_ROOT/docker.calls" PATH="$TEST_ROOT/bin:$PATH" \
    "$TEST_ROOT/project/scripts/compose.sh" ps >"$TEST_ROOT/output" 2>&1; then
    echo 'FAIL: missing src/.env was accepted' >&2
    exit 1
fi
grep -F 'scripts/setup.sh' "$TEST_ROOT/output"
```

- [ ] **Step 2: テストが wrapper 未作成で失敗することを確認する**

Run: `bash tests/shell/compose-wrapper-test.sh`

Expected: FAIL。`scripts/compose.sh` が存在しないため `cp` が失敗する。

- [ ] **Step 3: 最小の Compose wrapper を実装する**

`scripts/compose.sh` は次の境界を持つ。

```bash
#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
ENV_FILE="$PROJECT_ROOT/src/.env"

if [[ ! -f "$ENV_FILE" ]]; then
    printf 'src/.env がありません。先に scripts/setup.sh を実行してください。\n' >&2
    exit 1
fi

cd "$PROJECT_ROOT"
exec docker compose --env-file src/.env "$@"
```

実行権限を付ける。`src/.env.example` は現在のルート `.env.example` の Docker 向け値へ揃え、末尾へ `APP_PORT`、`VITE_PORT`、`DB_PORT`、`DB_TEST_PORT`、`REDIS_PORT`、`MAILPIT_SMTP_PORT`、`MAILPIT_UI_PORT` を追加する。ルート `.env.example` を削除し、`.gitignore` のルート `.env.example` 例外も削除する。`src/.env.example` は既存の `src/.gitignore` により追跡対象のままとする。

- [ ] **Step 4: wrapper と設定一元化を検証する**

Run: `bash tests/shell/compose-wrapper-test.sh`

Expected: PASS。

Run: `test ! -e .env.example && test -e src/.env.example`

Expected: exit 0。

Run: `docker compose --env-file src/.env.example config --quiet`

Expected: exit 0。

- [ ] **Step 5: Task 1 をコミットする**

```bash
git add .gitignore src/.env.example scripts/compose.sh tests/shell/compose-wrapper-test.sh
git add -u .env.example
git commit -m "feat: Docker環境設定の入口を一本化する"
```

---

### Task 2: 冪等な初回セットアップ

**Files:**
- Create: `scripts/setup.sh`
- Create: `tests/shell/setup-test.sh`
- Modify: `.github/workflows/hooks.yml`

**Interfaces:**
- Consumes: `scripts/compose.sh`、`src/.env.example`、Docker CLI。
- Produces: `scripts/setup.sh`。引数なしで実行し、既存設定を保ちながら依存導入・APP_KEY生成・migration・サービス起動を完了する。

- [ ] **Step 1: setup の失敗する回帰テストを書く**

`tests/shell/setup-test.sh` は一時プロジェクトへ `setup.sh`、`compose.sh`、`src/.env.example` をコピーし、fake Docker CLI の呼び出しを `DOCKER_CALLS` へ記録する。最低限、以下を検証する。

```bash
grep -F 'compose version' "$DOCKER_CALLS"
grep -F 'compose --env-file src/.env build app' "$DOCKER_CALLS"
grep -F 'compose --env-file src/.env run --rm --no-deps app composer install --no-interaction --prefer-dist' "$DOCKER_CALLS"
grep -F 'compose --env-file src/.env run --rm --no-deps app npm ci' "$DOCKER_CALLS"
grep -F 'compose --env-file src/.env run --rm --no-deps app php artisan key:generate --ansi' "$DOCKER_CALLS"
grep -F 'compose --env-file src/.env up -d --wait postgres redis mailpit' "$DOCKER_CALLS"
grep -F 'compose --env-file src/.env run --rm app php artisan migrate --force --ansi' "$DOCKER_CALLS"
grep -F 'compose --env-file src/.env up -d app nginx vite' "$DOCKER_CALLS"
```

2回目のケースでは、事前に `APP_KEY=base64:existing-key` とした `src/.env` を置く。実行後も同じ行が残り、`key:generate` が記録されないことを検証する。fake Docker は引数にかかわらず0を返し、値を出力しない。

- [ ] **Step 2: テストが setup 未作成で失敗することを確認する**

Run: `bash tests/shell/setup-test.sh`

Expected: FAIL。`scripts/setup.sh` が存在しないため `cp` が失敗する。

- [ ] **Step 3: setup を最小実装する**

`scripts/setup.sh` は `set -euo pipefail` を使い、プロジェクトルートを解決してから次を実行する。

```bash
command -v docker >/dev/null 2>&1 || {
    printf 'Docker が見つかりません。Docker をインストールして再実行してください。\n' >&2
    exit 1
}
docker compose version >/dev/null

if [[ ! -f "$ENV_FILE" ]]; then
    cp "$ENV_EXAMPLE" "$ENV_FILE"
fi

"$COMPOSE" build app
"$COMPOSE" run --rm --no-deps app composer install --no-interaction --prefer-dist
"$COMPOSE" run --rm --no-deps app npm ci

if ! grep -Eq '^APP_KEY=.+$' "$ENV_FILE"; then
    "$COMPOSE" run --rm --no-deps app php artisan key:generate --ansi
fi

"$COMPOSE" up -d --wait postgres redis mailpit
"$COMPOSE" run --rm app php artisan migrate --force --ansi
"$COMPOSE" up -d app nginx vite
```

完了時は秘密値を含めず、アプリと Mailpit の URL だけを表示する。実行権限を付ける。

- [ ] **Step 4: setup の回帰テストを通す**

Run: `bash tests/shell/setup-test.sh`

Expected: PASS。新規設定では key generation が1回、既存 APP_KEY ケースでは0回記録される。

- [ ] **Step 5: repository guard へ shell test を接続する**

`.github/workflows/hooks.yml` の既存 hook regression test の後へ追加する。

```yaml
      - name: Execute bootstrap script regression tests
        run: |
          for test_file in tests/shell/*-test.sh; do
            bash "$test_file"
          done
```

Run: `for test_file in tests/shell/*-test.sh; do bash "$test_file"; done`

Expected: 全ファイルが exit 0。

- [ ] **Step 6: Task 2 をコミットする**

```bash
git add scripts/setup.sh tests/shell/setup-test.sh .github/workflows/hooks.yml
git commit -m "feat: 冪等なDocker初期化コマンドを追加する"
```

---

### Task 3: 依存用 named volume と Vite 専用サービス

**Files:**
- Modify: `docker-compose.yml`
- Create: `tests/shell/compose-config-test.sh`

**Interfaces:**
- Consumes: Task 1 の `src/.env.example`、既存 `app-backend` image と `./src:/var/www` bind mount。
- Produces: Compose service `vite` と volumes `composer-vendor`、`node-modules`。app と Vite が依存volumeを共有し、Viteは `npm run dev -- --host 0.0.0.0` を実行して `${VITE_PORT:-5173}:5173` を公開する。

- [ ] **Step 1: Vite service の失敗する構成テストを書く**

`tests/shell/compose-config-test.sh` は Compose の正規化済み構成を一時ファイルへ保存し、次を検証する。

```bash
docker compose --env-file src/.env.example config > "$CONFIG_FILE"
docker compose --env-file src/.env.example config --services | grep -Fx 'vite'
grep -F 'npm run dev -- --host 0.0.0.0' "$CONFIG_FILE"
```

加えて `app` ではなく `vite` のサービスブロックに `5173` の published port があることを、正規化済み YAML からサービス単位で抽出して検証する。

```bash
service_block() {
    awk -v service="$1" '
        $0 == "  " service ":" { found = 1; next }
        found && $0 ~ /^  [[:alnum:]_-]+:$/ { exit }
        found { print }
    ' "$CONFIG_FILE"
}

service_block vite | grep -F 'target: 5173'
service_block app | grep -F 'source: composer-vendor'
service_block app | grep -F 'source: node-modules'
service_block vite | grep -F 'source: composer-vendor'
service_block vite | grep -F 'source: node-modules'
if service_block app | grep -F 'target: 5173'; then
    echo 'FAIL: app still publishes the Vite port' >&2
    exit 1
fi
```

- [ ] **Step 2: Vite service がなくテストが失敗することを確認する**

Run: `bash tests/shell/compose-config-test.sh`

Expected: FAIL。`config --services` に `vite` がない。

- [ ] **Step 3: Vite service を追加する**

`docker-compose.yml` の app から Vite port を外し、次のサービスを追加する。

```yaml
  vite:
    image: app-backend
    restart: unless-stopped
    working_dir: /var/www
    command: npm run dev -- --host 0.0.0.0
    volumes:
      - ./src:/var/www
      - composer-vendor:/var/www/vendor
      - node-modules:/var/www/node_modules
    ports:
      - "${VITE_PORT:-5173}:5173"
    networks:
      - app-network
    depends_on:
      - app

volumes:
  composer-vendor:
    driver: local
  node-modules:
    driver: local
```

app にも同じ2つの named volume mount を追加する。既存 `postgres-data` volume は維持する。

- [ ] **Step 4: Compose 構成テストを通す**

Run: `bash tests/shell/compose-config-test.sh`

Expected: PASS。

Run: `for test_file in tests/shell/*-test.sh; do bash "$test_file"; done`

Expected: 全ファイルが exit 0。

- [ ] **Step 5: Task 3 をコミットする**

```bash
git add docker-compose.yml tests/shell/compose-config-test.sh
git commit -m "feat: Viteを専用Composeサービスで起動する"
```

---

### Task 4: 利用者向け README と Docker スモーク CI

**Files:**
- Create: `README.md`
- Delete: `src/README.md`
- Modify: `.github/workflows/ci.yml`
- Modify: `AGENTS.md`

**Interfaces:**
- Consumes: `scripts/setup.sh`、`scripts/compose.sh`、Compose services `app`, `nginx`, `vite`, `postgres`, `redis`, `mailpit`。
- Produces: テンプレートの唯一の利用者向け入口 `README.md` と、GitHub Actions job `docker-smoke`。

- [ ] **Step 1: README を作成して Laravel 標準 README を削除する**

ルート `README.md` に以下を具体的なコマンド付きで記載する。

```bash
scripts/setup.sh
scripts/compose.sh up -d
scripts/compose.sh down
scripts/compose.sh logs -f app nginx vite
scripts/compose.sh exec app php artisan test
scripts/compose.sh exec app composer lint
scripts/compose.sh exec app npm run lint:architecture
```

URL、`src/.env` の責務、ポート変数、既存ルート `.env` からの移行、依存が named volume に入ること、`down -v` が PostgreSQL データと依存volumeを削除することも記載する。ホストIDEが依存ソースを必要とする場合だけ、ホスト側で Composer/npm を任意実行できることを補足する。`src/README.md` は削除する。

- [ ] **Step 2: AI向け品質ゲートをCompose wrapperへ揃える**

`AGENTS.md` の品質ゲートをrawの`docker compose`から`scripts/compose.sh`へ置き換える。

- [ ] **Step 3: Docker smoke job を追加する**

`.github/workflows/ci.yml` に `docker-smoke` job を追加する。

```yaml
  docker-smoke:
    runs-on: ubuntu-latest
    timeout-minutes: 30
    env:
      COMPOSE_PROJECT_NAME: laravel-template-smoke
    steps:
      - uses: actions/checkout@v7
        with:
          persist-credentials: false
      - name: Bootstrap Docker environment
        run: scripts/setup.sh
      - name: Verify HTTP and Vite
        run: |
          for attempt in {1..30}; do
            curl --fail --silent --show-error http://localhost:8080 >/dev/null && break
            if [ "$attempt" -eq 30 ]; then exit 1; fi
            sleep 2
          done
          curl --fail --silent --show-error http://localhost:5173/@vite/client >/dev/null
      - name: Verify database
        run: scripts/compose.sh exec -T app php artisan migrate:status
      - name: Show Docker logs
        if: failure()
        run: scripts/compose.sh logs --no-color
      - name: Stop Docker environment
        if: always()
        run: scripts/compose.sh down -v --remove-orphans
```

既存 e2e job は、Docker向けへ変わった `src/.env.example` の Redis / PostgreSQL 設定を引き継がないよう job-level `env` を追加する。

```yaml
    env:
      DB_CONNECTION: sqlite
      SESSION_DRIVER: file
      CACHE_STORE: array
      QUEUE_CONNECTION: sync
      MAIL_MAILER: array
```

- [ ] **Step 4: 静的検証と全 shell test を実行する**

Run: `docker compose --env-file src/.env.example config --quiet`

Expected: exit 0。

Run: `for test_file in tests/shell/*-test.sh; do bash "$test_file"; done`

Expected: 全ファイルが exit 0。

Run: `git diff --check`

Expected: exit 0。

- [ ] **Step 5: Task 4 をコミットする**

```bash
git add README.md AGENTS.md .github/workflows/ci.yml docs/superpowers/plans/2026-08-29-docker-bootstrap.md
git add -u src/README.md
git commit -m "docs: Docker初回起動とsmoke testを整備する"
```

---

### Task 5: 実コンテナでのクリーン起動検証

**Files:**
- Modify only if verification exposes a defect in Task 1-4 files.

**Interfaces:**
- Consumes: 完成した `scripts/setup.sh` と全 Compose services。
- Produces: Issue #70 の完了条件を満たす検証記録。

- [ ] **Step 1: shell regression と既存の軽量 guard を再実行する**

Run: `for test_file in tests/shell/*-test.sh; do bash "$test_file"; done`

Expected: 全ファイルが exit 0。

Run: `bash scripts/check-php-version-consistency.sh`

Expected: PASS。

- [ ] **Step 2: クリーンな一時 worktree で setup を実行する**

コミット済みHEADから一時 worktreeを作り、既存の `src/.env`、`vendor`、`node_modules`、volume に依存しないことを保証する。検証専用 project name と空きポートを使う。

```bash
git worktree add --detach /tmp/laravel-template-smoke HEAD
cd /tmp/laravel-template-smoke
COMPOSE_PROJECT_NAME=laravel-template-smoke \
APP_PORT=18080 VITE_PORT=15173 DB_PORT=15432 DB_TEST_PORT=15433 \
REDIS_PORT=16379 MAILPIT_SMTP_PORT=11025 MAILPIT_UI_PORT=18025 \
scripts/setup.sh
```

Expected: setup が exit 0。既存 workspace の生成物を参照しない。

- [ ] **Step 3: HTTP、Vite、DB、再実行安全性を検証する**

```bash
curl --fail --silent --show-error http://localhost:18080 >/dev/null
curl --fail --silent --show-error http://localhost:15173/@vite/client >/dev/null
scripts/compose.sh exec -T app php artisan migrate:status
```

`src/.env` の APP_KEY を値を表示せずハッシュ化して保持し、`scripts/setup.sh` を再実行した後のハッシュが同一であることを比較する。migration と HTTP 疎通も再確認する。

- [ ] **Step 4: 検証用 resource を必ず片付ける**

```bash
scripts/compose.sh down -v --remove-orphans
git worktree remove /tmp/laravel-template-smoke
```

Expected: 検証用 container、network、volume、worktree が残らない。これは検証専用 project の一時データだけを削除し、利用者の既存 volume には触れない。

- [ ] **Step 5: 品質ゲートを実行する**

Run: `scripts/compose.sh exec -T app composer lint`

Expected: Pint、PHPStan、Rector がすべて成功。

Run: `scripts/compose.sh exec -T app composer test`

Expected: Pest がすべて成功。

Run: `scripts/compose.sh exec -T app npm run lint:js && scripts/compose.sh exec -T app npm run types && scripts/compose.sh exec -T app npm run lint:react-compiler && scripts/compose.sh exec -T app npm run lint:architecture && scripts/compose.sh exec -T app npm run test:unit`

Expected: フロントエンド品質ゲートと Vitest がすべて成功。

- [ ] **Step 6: 検証修正があれば所有TaskのTDDサイクルへ戻す**

検証で修正が必要だった場合は、Task 1〜4のうち該当するTaskへ戻り、失敗を再現するtest、最小修正、対象testと全shell testの成功を1つのコミットにする。修正がなければ新しいコミットは作らない。
