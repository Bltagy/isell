#!/usr/bin/env bash
# =============================================================================
# restore.sh — Restore MySQL + storage from a backup archive on the remote server
#
# Usage (run on the remote server inside the project directory):
#   ./scripts/restore.sh <backup_file.tar.gz>
#
# Example:
#   ./scripts/restore.sh backups/foodapp_backup_20260418_120000.tar.gz
# =============================================================================
set -euo pipefail

# ── Config ────────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BACKUP_FILE="${1:-}"
MYSQL_CONTAINER="foodapp-mysql"

# ── Helpers ───────────────────────────────────────────────────────────────────
log()  { echo "[$(date '+%H:%M:%S')] $*"; }
die()  { echo "ERROR: $*" >&2; exit 1; }

confirm() {
  read -r -p "$1 [y/N] " response
  [[ "$response" =~ ^[Yy]$ ]] || die "Aborted."
}

# ── Preflight ─────────────────────────────────────────────────────────────────
[ -n "$BACKUP_FILE" ]      || die "Usage: $0 <backup_file.tar.gz>"
[ -f "$BACKUP_FILE" ]      || die "Backup file not found: $BACKUP_FILE"

# Load .env
if [ -f "$PROJECT_ROOT/.env" ]; then
  # shellcheck disable=SC2046
  export $(grep -v '^#' "$PROJECT_ROOT/.env" | grep -v '^$' | xargs)
fi

DB_ROOT_PASSWORD="${DB_ROOT_PASSWORD:-root}"

log "Backup file : $BACKUP_FILE"
log "Project root: $PROJECT_ROOT"
log ""
confirm "This will OVERWRITE the current database and storage. Continue?"

# ── 1. Extract archive ────────────────────────────────────────────────────────
EXTRACT_DIR=$(mktemp -d)
trap 'rm -rf "$EXTRACT_DIR"' EXIT

log "Extracting archive..."
tar -xzf "$BACKUP_FILE" -C "$EXTRACT_DIR"

# Find the inner backup folder (foodapp_backup_TIMESTAMP)
BACKUP_CONTENT=$(find "$EXTRACT_DIR" -mindepth 1 -maxdepth 1 -type d | head -1)
[ -n "$BACKUP_CONTENT" ] || die "Archive appears empty or malformed."
log "Extracted to: $BACKUP_CONTENT"

# ── 2. Ensure containers are up ───────────────────────────────────────────────
log "Ensuring containers are running..."
cd "$PROJECT_ROOT"
docker compose up -d mysql8 2>/dev/null || true

log "Waiting for MySQL to be healthy..."
for i in $(seq 1 30); do
  if docker exec "$MYSQL_CONTAINER" mysqladmin ping -uroot -p"$DB_ROOT_PASSWORD" --silent 2>/dev/null; then
    break
  fi
  [ "$i" -lt 30 ] || die "MySQL did not become healthy in time."
  sleep 2
done
log "MySQL is ready."

# ── 3. Restore MySQL databases ────────────────────────────────────────────────
SQL_FILES=$(find "$BACKUP_CONTENT" -name "*.sql" 2>/dev/null || true)

if [ -z "$SQL_FILES" ]; then
  log "  (no SQL files found — skipping DB restore)"
else
  for SQL_FILE in $SQL_FILES; do
    DB_NAME=$(basename "$SQL_FILE" .sql)
    log "  → Restoring $DB_NAME ..."
    docker exec -i "$MYSQL_CONTAINER" \
      mysql -uroot -p"$DB_ROOT_PASSWORD" \
      < "$SQL_FILE" 2>/dev/null
    log "    $DB_NAME restored."
  done
  log "MySQL restore complete."
fi

# ── 4. Restore storage/app ────────────────────────────────────────────────────
if [ -f "$BACKUP_CONTENT/storage_app.tar.gz" ]; then
  log "Restoring storage/app ..."
  rm -rf "$PROJECT_ROOT/storage/app"
  tar -xzf "$BACKUP_CONTENT/storage_app.tar.gz" \
    -C "$PROJECT_ROOT/storage"
  log "storage/app restored."
else
  log "  (storage_app.tar.gz not found — skipping)"
fi

# ── 5. Restore storage/minio ──────────────────────────────────────────────────
if [ -f "$BACKUP_CONTENT/storage_minio.tar.gz" ]; then
  log "Restoring storage/minio ..."
  rm -rf "$PROJECT_ROOT/storage/minio"
  tar -xzf "$BACKUP_CONTENT/storage_minio.tar.gz" \
    -C "$PROJECT_ROOT/storage"
  log "storage/minio restored."
else
  log "  (storage_minio.tar.gz not found — skipping)"
fi

# ── 6. Run migrations (safe — skips already-run ones) ────────────────────────
log "Running migrations..."
docker compose exec -T laravel-app php artisan migrate --force 2>/dev/null || true
docker compose exec -T laravel-app php artisan tenants:migrate --force 2>/dev/null || true

# ── 7. Clear caches ───────────────────────────────────────────────────────────
log "Clearing application caches..."
docker compose exec -T laravel-app php artisan optimize:clear 2>/dev/null || true

log ""
log "Restore complete. Your app is ready."
