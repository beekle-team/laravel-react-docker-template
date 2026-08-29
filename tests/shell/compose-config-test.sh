#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEST_ROOT"' EXIT

cd "$PROJECT_ROOT"
docker compose --env-file src/.env.example config --format json > "$TEST_ROOT/compose.json"
cp src/.env.example "$TEST_ROOT/custom.env"
printf '\nDB_HOST_PORT=15432\nREDIS_HOST_PORT=16379\n' >> "$TEST_ROOT/custom.env"
DOCKER_UID=4321 docker compose --env-file "$TEST_ROOT/custom.env" config --format json > "$TEST_ROOT/custom-compose.json"

python3 - "$TEST_ROOT/compose.json" "$TEST_ROOT/custom-compose.json" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as compose_file:
    config = json.load(compose_file)

with open(sys.argv[2], encoding="utf-8") as compose_file:
    custom_config = json.load(compose_file)

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

custom_services = custom_config["services"]
if custom_services["app"]["build"]["args"]["uid"] != "4321":
    raise SystemExit("DOCKER_UID does not control the non-root image user")

postgres_ports = custom_services["postgres"].get("ports", [])
if not any(port["published"] == "15432" and port["target"] == 5432 for port in postgres_ports):
    raise SystemExit(f"PostgreSQL host and container ports are not separated: {postgres_ports!r}")

redis_ports = custom_services["redis"].get("ports", [])
if not any(port["published"] == "16379" and port["target"] == 6379 for port in redis_ports):
    raise SystemExit(f"Redis host and container ports are not separated: {redis_ports!r}")

environment = custom_services["app"].get("environment", {})
if environment:
    raise SystemExit(f"app unexpectedly received Compose-level environment overrides: {environment!r}")
PY

printf 'PASS: Compose isolates host ports and maps non-root dependency ownership.\n'
