#!/bin/bash
set -euo pipefail

DATE=$(date +%F)
LOCAL_N8N="/srv/docker/n8n"
REMOTE_ROOT="/mnt/backupshare/n8n"
CONTAINER_NAME="n8n"

restart_n8n() {
    echo "Ensuring n8n container is running..."
    docker start "$CONTAINER_NAME" >/dev/null 2>&1 || true
}

trap restart_n8n EXIT

if ! mountpoint -q /mnt/backupshare; then
    echo "ERROR: /mnt/backupshare is not mounted. Aborting backup."
    exit 1
fi

mkdir -p "$REMOTE_ROOT/archive"

echo "Stopping n8n for a clean SQLite backup..."
docker stop "$CONTAINER_NAME"

echo "Creating n8n archive..."
tar -czf "$REMOTE_ROOT/archive/n8n-$DATE.tar.gz" \
    --exclude='*.log' \
    --exclude='crash.journal' \
    -C "$LOCAL_N8N" .

echo "Cleaning old n8n archives..."
find "$REMOTE_ROOT/archive" -type f -name 'n8n-*.tar.gz' -mtime +30 -delete

echo "n8n backup complete."
