#!/bin/bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
    echo "ERROR: This backup must be run as root so all Paperless documents, application data, and environment configuration can be read."
    echo "Run with: sudo /srv/docker/paperless/backup-paperless.sh"
    exit 1
fi

umask 077

DATE=$(date +%F)
LOCAL_PAPERLESS="/srv/docker/paperless"
REMOTE_ROOT="/mnt/backupshare/paperless"
ARCHIVE_DIR="$REMOTE_ROOT/archive"
POSTGRES_DIR="$REMOTE_ROOT/postgres"
REDIS_DIR="$REMOTE_ROOT/redis"

ARCHIVE_FILE="$ARCHIVE_DIR/paperless-$DATE.tar.gz"
POSTGRES_FILE="$POSTGRES_DIR/paperless-postgres-$DATE.sql.gz"
REDIS_FILE="$REDIS_DIR/paperless-redis-$DATE.tar.gz"

ARCHIVE_TMP="$ARCHIVE_FILE.tmp.$$"
POSTGRES_TMP="$POSTGRES_FILE.tmp.$$"
REDIS_TMP="$REDIS_FILE.tmp.$$"

COMPOSE=(
    docker compose
    --project-directory "$LOCAL_PAPERLESS"
    -f "$LOCAL_PAPERLESS/compose.yaml"
)

APP_STOPPED=false
BROKER_STOPPED=false

service_is_running() {
    "${COMPOSE[@]}" ps --status running --services | grep -Fxq "$1"
}

cleanup() {
    local status=$?
    local restart_failed=false

    trap - EXIT
    rm -f "$ARCHIVE_TMP" "$POSTGRES_TMP" "$REDIS_TMP"

    if [[ "$BROKER_STOPPED" == true ]]; then
        echo "Ensuring Paperless broker is running..."
        if ! "${COMPOSE[@]}" start broker; then
            echo "ERROR: Failed to restart the Paperless broker." >&2
            restart_failed=true
        fi
    fi

    if [[ "$APP_STOPPED" == true ]]; then
        echo "Ensuring Paperless application is running..."
        if ! "${COMPOSE[@]}" start paperless-ngx; then
            echo "ERROR: Failed to restart the Paperless application." >&2
            restart_failed=true
        fi
    fi

    if [[ "$restart_failed" == true && "$status" -eq 0 ]]; then
        status=1
    fi

    exit "$status"
}

trap cleanup EXIT

if ! mountpoint -q /mnt/backupshare; then
    echo "ERROR: /mnt/backupshare is not mounted. Aborting backup."
    exit 1
fi

for path in compose.yaml .env data media export consume postgres valkey; do
    if [[ ! -e "$LOCAL_PAPERLESS/$path" ]]; then
        echo "ERROR: Required Paperless path is missing: $LOCAL_PAPERLESS/$path"
        exit 1
    fi
done

mkdir -p "$ARCHIVE_DIR" "$POSTGRES_DIR" "$REDIS_DIR"

if service_is_running paperless-ngx; then
    echo "Stopping Paperless application for an application-consistent backup..."
    APP_STOPPED=true
    "${COMPOSE[@]}" stop paperless-ngx
fi

echo "Creating Paperless PostgreSQL logical dump..."
"${COMPOSE[@]}" exec -T db sh -c 'pg_dump -U "$POSTGRES_USER" "$POSTGRES_DB"' \
    | gzip > "$POSTGRES_TMP"
test -s "$POSTGRES_TMP"
gzip -t "$POSTGRES_TMP"

if service_is_running broker; then
    echo "Stopping Paperless broker for a consistent Valkey archive..."
    BROKER_STOPPED=true
    "${COMPOSE[@]}" stop broker
fi

echo "Creating Paperless app-state archive..."
tar -czf "$ARCHIVE_TMP" \
    --exclude='./backup-paperless.sh' \
    --exclude='./postgres' \
    --exclude='./valkey' \
    -C "$LOCAL_PAPERLESS" \
    ./compose.yaml ./.env ./data ./media ./export ./consume
test -s "$ARCHIVE_TMP"
gzip -t "$ARCHIVE_TMP"

echo "Creating Paperless Valkey persistence archive..."
tar -czf "$REDIS_TMP" \
    -C "$LOCAL_PAPERLESS" \
    ./valkey
test -s "$REDIS_TMP"
gzip -t "$REDIS_TMP"

mv "$POSTGRES_TMP" "$POSTGRES_FILE"
mv "$ARCHIVE_TMP" "$ARCHIVE_FILE"
mv "$REDIS_TMP" "$REDIS_FILE"

echo "Cleaning Paperless backups older than 30 days..."
find "$POSTGRES_DIR" -type f -name 'paperless-postgres-*.sql.gz' -mtime +30 -delete
find "$ARCHIVE_DIR" -type f -name 'paperless-*.tar.gz' -mtime +30 -delete
find "$REDIS_DIR" -type f -name 'paperless-redis-*.tar.gz' -mtime +30 -delete

echo "Paperless backup complete."
