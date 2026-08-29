#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEST_ROOT"' EXIT

cd "$PROJECT_ROOT"
docker compose --env-file src/.env.example config --format json > "$TEST_ROOT/compose.json"

python3 - "$TEST_ROOT/compose.json" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as compose_file:
    config = json.load(compose_file)

services = config["services"]
vite = services["vite"]
app = services["app"]

expected_command = ["npm", "run", "dev", "--", "--host", "0.0.0.0"]
if vite.get("command") != expected_command:
    raise SystemExit(f"unexpected Vite command: {vite.get('command')!r}")

vite_targets = {port["target"] for port in vite.get("ports", [])}
if 5173 not in vite_targets:
    raise SystemExit("Vite does not publish container port 5173")

app_targets = {port["target"] for port in app.get("ports", [])}
if 5173 in app_targets:
    raise SystemExit("app still publishes the Vite port")

expected_mounts = {
    ("composer-vendor", "/var/www/vendor"),
    ("node-modules", "/var/www/node_modules"),
}

for service_name, service in (("app", app), ("vite", vite)):
    mounts = {
        (volume.get("source"), volume["target"])
        for volume in service.get("volumes", [])
        if volume["type"] == "volume"
    }
    if not expected_mounts.issubset(mounts):
        raise SystemExit(f"{service_name} dependency mounts are incomplete: {mounts!r}")
PY

printf 'PASS: Compose gives Vite its own port and shares dependency volumes.\n'
