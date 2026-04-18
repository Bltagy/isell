#!/usr/bin/env bash
# =============================================================================
# health_check.sh — Full stack health check for FoodApp SaaS
# Usage: bash scripts/health_check.sh
# =============================================================================

set -euo pipefail

# ── Config ────────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# Load .env from project root
if [[ -f "$ROOT_DIR/.env" ]]; then
  export $(grep -v '^#' "$ROOT_DIR/.env" | grep -v '^$' | xargs)
fi

HOST="${HOST_IP:-localhost}"
API_URL="https://${HOST}/api/v1/settings/app-config"
WS_PORT="${REVERB_PORT_FORWARD:-18060}"
WS_INTERNAL_PORT="${REVERB_SERVER_PORT:-8060}"

# ── Colors ────────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

PASS=0
FAIL=0
WARN=0

# ── Helpers ───────────────────────────────────────────────────────────────────
ok()   { echo -e "  ${GREEN}✔${RESET}  $1"; ((PASS++)); }
fail() { echo -e "  ${RED}✘${RESET}  $1"; ((FAIL++)); }
warn() { echo -e "  ${YELLOW}⚠${RESET}  $1"; ((WARN++)); }
info() { echo -e "  ${CYAN}→${RESET}  $1"; }
section() { echo -e "\n${BOLD}${CYAN}▶ $1${RESET}"; }

# ── Start ─────────────────────────────────────────────────────────────────────
echo -e "\n${BOLD}╔══════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}║       FoodApp SaaS — Health Check        ║${RESET}"
echo -e "${BOLD}╚══════════════════════════════════════════╝${RESET}"
echo -e "  Host: ${CYAN}${HOST}${RESET}"
echo -e "  Time: $(date '+%Y-%m-%d %H:%M:%S')"

cd "$ROOT_DIR"

# ── 1. Docker containers ──────────────────────────────────────────────────────
section "Docker Containers"

CONTAINERS=(
  "foodapp-nginx"
  "foodapp-app"
  "foodapp-horizon"
  "foodapp-reverb"
  "foodapp-mysql"
  "foodapp-redis"
  "foodapp-meilisearch"
  "foodapp-minio"
)

for name in "${CONTAINERS[@]}"; do
  status=$(docker inspect --format='{{.State.Status}}' "$name" 2>/dev/null || echo "missing")
  health=$(docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' "$name" 2>/dev/null || echo "missing")

  if [[ "$status" == "running" ]]; then
    if [[ "$health" == "unhealthy" ]]; then
      fail "$name — running but UNHEALTHY"
    elif [[ "$health" == "healthy" || "$health" == "none" ]]; then
      ok "$name — $status"
    else
      warn "$name — $status (health: $health)"
    fi
  elif [[ "$status" == "missing" ]]; then
    fail "$name — not found"
  else
    fail "$name — $status"
  fi
done

# ── 2. API endpoint ───────────────────────────────────────────────────────────
section "API Endpoint"

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$API_URL" 2>/dev/null || echo "000")
if [[ "$HTTP_CODE" == "200" ]]; then
  ok "GET $API_URL → $HTTP_CODE"
else
  fail "GET $API_URL → $HTTP_CODE (expected 200)"
fi

# ── 3. Laravel internals ──────────────────────────────────────────────────────
section "Laravel Internals"

# Migrations
MIGRATE_OUT=$(docker compose exec -T laravel-app php artisan migrate:status 2>&1 || true)
PENDING=$(echo "$MIGRATE_OUT" | grep -c "Pending" || true)
if [[ "$PENDING" -eq 0 ]]; then
  ok "Migrations — all ran"
else
  warn "Migrations — $PENDING pending migration(s)"
fi

# Config cache
CONFIG_OUT=$(docker compose exec -T laravel-app php artisan config:show app.env 2>&1 || true)
if echo "$CONFIG_OUT" | grep -q "local\|production\|staging"; then
  ok "Laravel config — readable"
else
  warn "Laravel config — could not verify (run: php artisan config:cache)"
fi

# Storage link
STORAGE_LINK=$(docker compose exec -T laravel-app test -L /var/www/html/public/storage && echo "ok" || echo "missing")
if [[ "$STORAGE_LINK" == "ok" ]]; then
  ok "Storage symlink — exists"
else
  fail "Storage symlink — missing (run: php artisan storage:link)"
fi

# ── 4. Horizon (Queue) ────────────────────────────────────────────────────────
section "Horizon / Queue"

HORIZON_OUT=$(docker compose exec -T laravel-app php artisan horizon:status 2>&1 || true)
if echo "$HORIZON_OUT" | grep -qi "running"; then
  ok "Horizon — running"
elif echo "$HORIZON_OUT" | grep -qi "paused"; then
  warn "Horizon — paused"
else
  fail "Horizon — not running (output: $HORIZON_OUT)"
fi

# ── 5. Redis ──────────────────────────────────────────────────────────────────
section "Redis"

REDIS_PING=$(docker compose exec -T redis redis-cli ping 2>/dev/null || echo "FAIL")
if [[ "$REDIS_PING" == "PONG" ]]; then
  ok "Redis — PONG"
else
  fail "Redis — no response"
fi

# ── 6. MySQL ──────────────────────────────────────────────────────────────────
section "MySQL"

DB_NAME="${DB_DATABASE:-foodapp_central}"
DB_USER="${DB_USERNAME:-foodapp}"
DB_PASS="${DB_PASSWORD:-secret}"

MYSQL_OUT=$(docker compose exec -T mysql8 mysqladmin ping -u"$DB_USER" -p"$DB_PASS" --silent 2>/dev/null || echo "FAIL")
if echo "$MYSQL_OUT" | grep -qi "alive\|mysqld is alive"; then
  ok "MySQL — alive"
elif [[ -z "$MYSQL_OUT" ]]; then
  # mysqladmin ping returns empty on success with --silent
  ok "MySQL — alive"
else
  fail "MySQL — not responding"
fi

# ── 7. Reverb WebSocket ───────────────────────────────────────────────────────
section "Reverb WebSocket"

WS_CHECK=$(curl -s -o /dev/null -w "%{http_code}" \
  --max-time 5 \
  -H "Upgrade: websocket" \
  -H "Connection: Upgrade" \
  "http://${HOST}:${WS_PORT}/app/${REVERB_APP_KEY:-local}" 2>/dev/null || echo "000")

if [[ "$WS_CHECK" == "101" || "$WS_CHECK" == "200" || "$WS_CHECK" == "400" ]]; then
  ok "Reverb port ${WS_PORT} — reachable (HTTP $WS_CHECK)"
else
  fail "Reverb port ${WS_PORT} — not reachable (HTTP $WS_CHECK)"
  info "Check firewall: ufw allow ${WS_PORT}"
fi

# ── 8. MinIO / Storage ────────────────────────────────────────────────────────
section "MinIO Storage"

MINIO_PORT="${MINIO_PORT_FORWARD:-19000}"
MINIO_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" \
  --max-time 5 \
  "http://localhost:${MINIO_PORT}/minio/health/live" 2>/dev/null || echo "000")

if [[ "$MINIO_HEALTH" == "200" ]]; then
  ok "MinIO — healthy"
else
  fail "MinIO — not healthy (HTTP $MINIO_HEALTH)"
fi

# ── 9. Meilisearch ────────────────────────────────────────────────────────────
section "Meilisearch"

MEILI_PORT="${MEILISEARCH_PORT_FORWARD:-17700}"
MEILI_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" \
  --max-time 5 \
  "http://localhost:${MEILI_PORT}/health" 2>/dev/null || echo "000")

if [[ "$MEILI_HEALTH" == "200" ]]; then
  ok "Meilisearch — healthy"
else
  warn "Meilisearch — not healthy (HTTP $MEILI_HEALTH)"
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo -e "\n${BOLD}╔══════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}║                 Summary                  ║${RESET}"
echo -e "${BOLD}╚══════════════════════════════════════════╝${RESET}"
echo -e "  ${GREEN}Passed : $PASS${RESET}"
echo -e "  ${YELLOW}Warnings: $WARN${RESET}"
echo -e "  ${RED}Failed : $FAIL${RESET}"

if [[ "$FAIL" -eq 0 && "$WARN" -eq 0 ]]; then
  echo -e "\n  ${GREEN}${BOLD}✔ All systems operational${RESET}\n"
  exit 0
elif [[ "$FAIL" -eq 0 ]]; then
  echo -e "\n  ${YELLOW}${BOLD}⚠ System running with warnings${RESET}\n"
  exit 0
else
  echo -e "\n  ${RED}${BOLD}✘ Some checks failed — review above${RESET}\n"
  exit 1
fi
