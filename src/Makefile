.PHONY: help setup setup-dev setup-preview clean test test-local test-ssl test-ssl-dry-run up down logs ps shell-nginx shell-app shell-certbot shell-ofelia

# 変数定義（環境変数でオーバーライド可能）
APP_NAME ?= Laravel Application
COMPOSE_FILE_DEV ?= docker-compose.yml
COMPOSE_FILE_PREVIEW ?= docker-compose.preview.yml
DOMAIN ?= example.com
EMAIL ?= admin@example.com
NGINX_TIMEOUT ?= 30

# デフォルトターゲット
.DEFAULT_GOAL := help

## ヘルプ表示
help:
	@echo "$(APP_NAME) - Makefile"
	@echo ""
	@echo "使用方法: make [ターゲット]"
	@echo ""
	@echo "セットアップ:"
	@echo "  setup          - 開発環境をセットアップ（setup.sh を実行）"
	@echo "  setup-dev      - 開発環境をセットアップ"
	@echo "  setup-preview  - プレビュー環境をセットアップ"
	@echo "  clean          - 環境をクリーンアップ（コンテナ・ボリューム・.envを削除）"
	@echo ""
	@echo "Docker Compose 操作:"
	@echo "  up             - プレビュー環境のコンテナを起動"
	@echo "  down           - プレビュー環境のコンテナを停止・削除"
	@echo "  ps             - コンテナの状態を確認"
	@echo "  logs           - コンテナのログを確認（-f オプションでフォロー）"
	@echo ""
	@echo "テスト:"
	@echo "  test           - すべてのローカルテストを実行"
	@echo "  test-local     - ローカル環境で実行可能なテスト（構文チェック等）"
	@echo "  test-ssl       - SSL証明書発行のテスト（dry-run + staging）"
	@echo "  test-ssl-dry-run - SSL証明書発行のdry-runテスト"
	@echo ""
	@echo "シェルアクセス:"
	@echo "  shell-nginx    - nginxコンテナのシェルにアクセス"
	@echo "  shell-app      - appコンテナのシェルにアクセス"
	@echo "  shell-certbot  - certbotコンテナのシェルにアクセス"
	@echo "  shell-ofelia   - ofeliaコンテナのシェルにアクセス"
	@echo ""
	@echo "SSL証明書操作（VPS上で実行）:"
	@echo "  ssl-issue      - SSL証明書を発行（本番環境）"
	@echo "  ssl-renew      - SSL証明書を更新"
	@echo "  ssl-check      - SSL証明書の状態を確認"
	@echo ""
	@echo "環境変数（オーバーライド可能）:"
	@echo "  DOMAIN         - ドメイン名（デフォルト: example.com）"
	@echo "  EMAIL          - Let's Encrypt用メールアドレス（デフォルト: admin@example.com）"
	@echo "  NGINX_TIMEOUT  - nginx起動待機タイムアウト秒数（デフォルト: 30）"
	@echo ""
	@echo "例: DOMAIN=myapp.com EMAIL=me@myapp.com make ssl-issue"

## セットアップ
setup:
	@./setup.sh

setup-dev:
	@./setup.sh

setup-preview:
	@./setup.sh -p

clean:
	@./setup.sh -c -p

## Docker Compose 操作
up:
	@echo "🚀 プレビュー環境のコンテナを起動中..."
	@docker compose -f $(COMPOSE_FILE_PREVIEW) up -d

down:
	@echo "🛑 プレビュー環境のコンテナを停止中..."
	@docker compose -f $(COMPOSE_FILE_PREVIEW) down

ps:
	@docker compose -f $(COMPOSE_FILE_PREVIEW) ps

logs:
	@docker compose -f $(COMPOSE_FILE_PREVIEW) logs -f

## テスト
test: test-local
	@echo "✅ すべてのローカルテストが完了しました"

test-local: test-compose test-script test-nginx
	@echo "✅ ローカル環境でのテストが完了しました"

test-compose:
	@echo "🔍 Docker Compose 構文チェック中..."
	@docker compose -f $(COMPOSE_FILE_PREVIEW) config > /dev/null
	@echo "✅ Docker Compose 構文チェック: OK"

test-script:
	@echo "🔍 シェルスクリプト構文チェック中..."
	@sh -n scripts/certbot-renew.sh
	@echo "✅ シェルスクリプト構文チェック: OK"
	@echo "🔍 シェルスクリプト実行権限確認中..."
	@test -x scripts/certbot-renew.sh || (echo "❌ シェルスクリプトに実行権限がありません" && exit 1)
	@echo "✅ シェルスクリプト実行権限: OK"

test-nginx:
	@echo "🔍 nginx設定構文チェック中..."
	@docker compose -f $(COMPOSE_FILE_PREVIEW) up -d nginx
	@echo "⏳ nginxコンテナの起動を待機中..."
	@timeout=$(NGINX_TIMEOUT); \
	while [ $$timeout -gt 0 ]; do \
		if docker compose -f $(COMPOSE_FILE_PREVIEW) exec -T nginx nginx -t > /dev/null 2>&1; then \
			break; \
		fi; \
		sleep 1; \
		timeout=$$((timeout - 1)); \
	done; \
	if [ $$timeout -eq 0 ]; then \
		echo "❌ nginxコンテナの起動がタイムアウトしました（$(NGINX_TIMEOUT)秒）"; \
		exit 1; \
	fi
	@docker compose -f $(COMPOSE_FILE_PREVIEW) exec -T nginx nginx -t
	@echo "✅ nginx設定構文チェック: OK"

test-ssl: test-ssl-dry-run
	@echo "✅ SSL証明書発行テストが完了しました"

test-ssl-dry-run:
	@echo "🔍 SSL証明書発行のdry-runテスト中..."
	@echo "   ドメイン: $(DOMAIN)"
	@echo "   メール: $(EMAIL)"
	@echo "   モード: --staging --dry-run"
	@docker compose -f $(COMPOSE_FILE_PREVIEW) up -d nginx
	@echo "⏳ nginxコンテナの起動を待機中..."
	@timeout=$(NGINX_TIMEOUT); \
	while [ $$timeout -gt 0 ]; do \
		if docker compose -f $(COMPOSE_FILE_PREVIEW) exec -T nginx nginx -t > /dev/null 2>&1; then \
			break; \
		fi; \
		sleep 1; \
		timeout=$$((timeout - 1)); \
	done; \
	if [ $$timeout -eq 0 ]; then \
		echo "❌ nginxコンテナの起動がタイムアウトしました（$(NGINX_TIMEOUT)秒）"; \
		exit 1; \
	fi
	@docker compose -f $(COMPOSE_FILE_PREVIEW) run --rm certbot certbot certonly \
		--webroot \
		--webroot-path=/var/www/public \
		--email $(EMAIL) \
		--agree-tos \
		--no-eff-email \
		-d $(DOMAIN) \
		--staging \
		--dry-run
	@echo "✅ SSL証明書発行のdry-runテスト: OK"

## シェルアクセス
shell-nginx:
	@docker compose -f $(COMPOSE_FILE_PREVIEW) exec nginx sh

shell-app:
	@docker compose -f $(COMPOSE_FILE_PREVIEW) exec app sh

shell-certbot:
	@docker compose -f $(COMPOSE_FILE_PREVIEW) run --rm certbot sh

shell-ofelia:
	@docker compose -f $(COMPOSE_FILE_PREVIEW) exec ofelia sh

## SSL証明書操作（VPS上で実行）
ssl-issue:
	@echo "🔐 SSL証明書を発行中..."
	@echo "   ドメイン: $(DOMAIN)"
	@echo "   メール: $(EMAIL)"
	@docker compose -f $(COMPOSE_FILE_PREVIEW) run --rm certbot certbot certonly \
		--webroot \
		--webroot-path=/var/www/public \
		--email $(EMAIL) \
		--agree-tos \
		--no-eff-email \
		-d $(DOMAIN)
	@echo "✅ SSL証明書の発行が完了しました"

ssl-renew:
	@echo "🔄 SSL証明書を更新中..."
	@docker compose -f $(COMPOSE_FILE_PREVIEW) run --rm certbot certbot renew
	@docker compose -f $(COMPOSE_FILE_PREVIEW) exec nginx nginx -s reload
	@echo "✅ SSL証明書の更新が完了しました"

ssl-check:
	@echo "🔍 SSL証明書の状態を確認中..."
	@docker compose -f $(COMPOSE_FILE_PREVIEW) run --rm certbot ls -la /etc/letsencrypt/live/$(DOMAIN)/ || echo "❌ 証明書が発行されていません"

