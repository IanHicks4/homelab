#!/bin/bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
    echo "ERROR: This backup must be run as root so Vikunja files and environment configuration can be read."
    echo "Run with: sudo /srv/docker/vikunja/backup-vikunja.sh"
    exit 1
fi

umask 077

DATE=$(date +%F)
LOCAL_VIKUNJA="/srv/docker/vikunja"
REMOTE_ROOT="/mnt/backupshare/vikunja"
POSTGRES_DIR="$REMOTE_ROOT/postgres"
ARCHIVE_DIR="$REMOTE_ROOT/archive"
POSTGRES_CONTAINER="vikunja-db"

DUMP_FILE="$POSTGRES_DIR/vikunja-$DATE.sql.gz"
ARCHIVE_FILE="$ARCHIVE_DIR/vikunja-$DATE.tar.gz"
DUMP_TMP="$DUMP_FILE.tmp.$$"
ARCHIVE_TMP="$ARCHIVE_FILE.tmp.$$"

cleanup() {
    rm -f "$DUMP_TMP" "$ARCHIVE_TMP"
}

trap cleanup EXIT

if ! mountpoint -q /mnt/backupshare; then
    echo "ERROR: /mnt/backupshare is not mounted. Aborting backup."
    exit 1
fi

for path in compose.yaml .env files; do
    if [[ ! -e "$LOCAL_VIKUNJA/$path" ]]; then
        echo "ERROR: Required Vikunja path is missing: $LOCAL_VIKUNJA/$path"
        exit 1
    fi
done

mkdir -p "$POSTGRES_DIR" "$ARCHIVE_DIR"

echo "Creating Vikunja PostgreSQL logical dump..."
docker exec "$POSTGRES_CONTAINER" sh -c 'pg_dumpall -U "$POSTGRES_USER"' \
    | gzip > "$DUMP_TMP"
mv "$DUMP_TMP" "$DUMP_FILE"

echo "Creating Vikunja app-state archive..."
tar -czf "$ARCHIVE_TMP" \
    --exclude='./db' \
    --exclude='./backup-vikunja.sh' \
    -C "$LOCAL_VIKUNJA" \
    ./compose.yaml ./.env ./files
mv "$ARCHIVE_TMP" "$ARCHIVE_FILE"

echo "Cleaning Vikunja backups older than 30 days..."
find "$POSTGRES_DIR" -type f -name 'vikunja-*.sql.gz' -mtime +30 -delete
find "$ARCHIVE_DIR" -type f -name 'vikunja-*.tar.gz' -mtime +30 -delete

echo "Vikunja backup complete."
