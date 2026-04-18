#!/usr/bin/env bash
# =============================================================================
# backup.sh — Dump MySQL + archive storage, then push to remote server
#
# Usage:
#   ./scripts/backup.sh [remote_user@remote_host] [remote_path]
#
# Examples:
#   ./scripts/backup.sh                                  # dump only (no push)
#   ./scripts/backup.sh root@isell.dev-ark.com           # push to default path
#   ./scripts/backup.sh root@isell.dev-ark.com /opt/app  # push to custom path
# =============================================================================
set -euo pipefail

# ── Config ────────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BACKUP_DIR="$PROJECT_ROOT/backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_NAME="foodapp_backup_$TIMESTAMP"
BACKUP_PATH="$BACKUP_DIR/$BACKUP_NAME"

REMOTE_TARGET="${1:-}"                        # e.g. root@isell.dev-ark.com
REMOTE_PATH="${2:-/opt/foodapp}"              # destination path on remote

# Load .env for DB credentials
if [ -f "$PROJECT_ROOT/.env" ]; then
  # shellcheck disable=SC2046
  export $(grep -v '^#' "$PROJECT_ROOT/.env" | grep -v '^$' | xargs)
fi

DB_HOST="${DB_HOST:-127.0.0.1}"
DB_PORT="${DB_PORT:-3350}"
DB_DATABASE="${DB_DATABASE:-foodapp_central}"
DB_USERNAME="${DB_USERNAME:-foodapp}"
DB_PASSWORD="${DB_PASSWORD:-secret}"
DB_ROOT_PASSWORD="${DB_ROOT_PASSWORD:-root}"

MYSQL_CONTAINER="foodapp-mysql"

# ── Helpers ───────────────────────────────────────────────────────────────────
log()  { echo "[$(date '+%H:%M:%S')] $*"; }
die()  { echo "ERROR: $*" >&2; exit 1; }

# ── Preflight ─────────────────────────────────────────────────────────────────
mkdir -p "$BACKUP_PATH"
log "Backup directory: $BACKUP_PATH"

# Verify MySQL container is running
docker inspect "$MYSQL_CONTAINER" --format '{{.State.Status}}' 2>/dev/null | grep -q running \
  || die "Container $MYSQL_CONTAINER is not running"

# ── 1. Dump MySQL (central + all tenant databases) ────────────────────────────
log "Dumping MySQL databases..."

# Get all databases (central + tenant_*)
ALL_DBS=$(docker exec "$MYSQL_CONTAINER" \
  mysql -uroot -p"$DB_ROOT_PASSWORD" -e "SHOW DATABASES;" 2>/dev/null \
  | grep -E "^(${DB_DATABASE}|tenant_)" || true)

if [ -z "$ALL_DBS" ]; then
  die "No databases found. Check DB_ROOT_PASSWORD in .env"
fi

for DB in $ALL_DBS; do
  log "  → Dumping $DB ..."
  docker exec "$MYSQL_CONTAINER" \
    mysqldump -uroot -p"$DB_ROOT_PASSWORD" \
      --single-transaction \
      --routines \
      --triggers \
      --add-drop-database \
      --databases "$DB" \
    > "$BACKUP_PATH/${DB}.sql" 2>/dev/null
done

log "MySQL dump complete."

# ── 2. Archive storage/app (uploaded files) ───────────────────────────────────
log "Archiving storage/app ..."
if [ -d "$PROJECT_ROOT/storage/app" ]; then
  tar -czf "$BACKUP_PATH/storage_app.tar.gz" \
    -C "$PROJECT_ROOT/storage" app
  log "storage/app archived."
else
  log "  (skipped — storage/app not found)"
fi

# ── 3. Archive storage/minio (MinIO objects) ──────────────────────────────────
log "Archiving storage/minio ..."
if [ -d "$PROJECT_ROOT/storage/minio" ] && [ "$(ls -A "$PROJECT_ROOT/storage/minio" 2>/dev/null)" ]; then
  tar -czf "$BACKUP_PATH/storage_minio.tar.gz" \
    -C "$PROJECT_ROOT/storage" minio
  log "storage/minio archived."
else
  log "  (skipped — storage/minio empty or not found)"
fi

# ── 4. Bundle everything into a single tarball ────────────────────────────────
log "Creating final archive: ${BACKUP_NAME}.tar.gz ..."
tar -czf "$BACKUP_DIR/${BACKUP_NAME}.tar.gz" \
  -C "$BACKUP_DIR" "$BACKUP_NAME"
rm -rf "$BACKUP_PATH"
log "Archive ready: $BACKUP_DIR/${BACKUP_NAME}.tar.gz"

# ── 5. Push to remote (optional) ─────────────────────────────────────────────
if [ -n "$REMOTE_TARGET" ]; then
  log "Pushing to $REMOTE_TARGET:$REMOTE_PATH ..."
  ssh "$REMOTE_TARGET" "mkdir -p $REMOTE_PATH/backups"
  rsync -avz --progress \
    "$BACKUP_DIR/${BACKUP_NAME}.tar.gz" \
    "$REMOTE_TARGET:$REMOTE_PATH/backups/"
  log "Upload complete."

  # Copy restore script to remote
  rsync -avz "$SCRIPT_DIR/restore.sh" "$REMOTE_TARGET:$REMOTE_PATH/scripts/"
  ssh "$REMOTE_TARGET" "chmod +x $REMOTE_PATH/scripts/restore.sh"
  log "restore.sh copied to remote."

  log ""
  log "To restore on the remote server, run:"
  log "  ssh $REMOTE_TARGET"
  log "  cd $REMOTE_PATH && ./scripts/restore.sh backups/${BACKUP_NAME}.tar.gz"
else
  log ""
  log "No remote target specified — backup saved locally only."
  log "To push manually:  rsync -avz $BACKUP_DIR/${BACKUP_NAME}.tar.gz user@host:/opt/foodapp/backups/"
fi

log "Done."
