#!/bin/bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
    echo "ERROR: This backup must be run as root so DDNS .env credentials can be read."
    echo "Run with: sudo /srv/docker/ddns/backup-ddns.sh"
    exit 1
fi

DATE=$(date +%F)
LOCAL_DDNS="/srv/docker/ddns"
REMOTE_ROOT="/mnt/backupshare/ddns"
CONTAINER_NAME="porkbun-ddns"

restart_ddns() {
    echo "Ensuring DDNS container is running..."
    docker start "$CONTAINER_NAME" >/dev/null 2>&1 || true
}

trap restart_ddns EXIT

if ! mountpoint -q /mnt/backupshare; then
    echo "ERROR: /mnt/backupshare is not mounted. Aborting backup."
    exit 1
fi

mkdir -p "$REMOTE_ROOT/archive"

echo "Stopping DDNS for a clean backup..."
docker stop "$CONTAINER_NAME"

echo "Creating DDNS archive..."
tar -czf "$REMOTE_ROOT/archive/ddns-$DATE.tar.gz" \
    --exclude='./backup-ddns.sh' \
    --exclude='*.log' \
    -C "$LOCAL_DDNS" .

echo "Cleaning old DDNS archives..."
find "$REMOTE_ROOT/archive" -type f -name 'ddns-*.tar.gz' -mtime +30 -delete

echo "DDNS backup complete."
