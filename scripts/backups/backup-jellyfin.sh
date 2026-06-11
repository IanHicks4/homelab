#!/bin/bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
    echo "ERROR: This backup must be run as root so all Jellyfin config/data can be read."
    echo "Run with: sudo /srv/docker/jellyfin/backup-jellyfin.sh"
    exit 1
fi

DATE=$(date +%F)
LOCAL_JELLYFIN="/srv/docker/jellyfin"
REMOTE_ROOT="/mnt/backupshare/jellyfin"
CONTAINER_NAME="jellyfin"

restart_jellyfin() {
    echo "Ensuring Jellyfin container is running..."
    docker start "$CONTAINER_NAME" >/dev/null 2>&1 || true
}

trap restart_jellyfin EXIT

if ! mountpoint -q /mnt/backupshare; then
    echo "ERROR: /mnt/backupshare is not mounted. Aborting backup."
    exit 1
fi

mkdir -p "$REMOTE_ROOT/archive"

echo "Stopping Jellyfin for a clean backup..."
docker stop "$CONTAINER_NAME"

echo "Creating Jellyfin config archive..."
tar -czf "$REMOTE_ROOT/archive/jellyfin-$DATE.tar.gz" \
    --exclude='./backup-jellyfin.sh' \
    --exclude='./config/cache' \
    --exclude='./config/log' \
    --exclude='./config/transcodes' \
    --exclude='*.log' \
    -C "$LOCAL_JELLYFIN" .

echo "Cleaning old Jellyfin archives..."
find "$REMOTE_ROOT/archive" -type f -name 'jellyfin-*.tar.gz' -mtime +30 -delete

echo "Jellyfin backup complete."
