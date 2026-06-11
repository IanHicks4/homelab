#!/bin/bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
    echo "ERROR: This backup must be run as root so Caddy data/config can be read."
    echo "Run with: sudo /srv/docker/caddy/backup-caddy.sh"
    exit 1
fi

DATE=$(date +%F)
LOCAL_CADDY="/srv/docker/caddy"
REMOTE_ROOT="/mnt/backupshare/caddy"
CONTAINER_NAME="caddy"

restart_caddy() {
    echo "Ensuring Caddy container is running..."
    docker start "$CONTAINER_NAME" >/dev/null 2>&1 || true
}

trap restart_caddy EXIT

if ! mountpoint -q /mnt/backupshare; then
    echo "ERROR: /mnt/backupshare is not mounted. Aborting backup."
    exit 1
fi

mkdir -p "$REMOTE_ROOT/archive"

echo "Validating Caddy config before backup..."
docker exec "$CONTAINER_NAME" caddy validate --config /etc/caddy/Caddyfile

echo "Stopping Caddy for a clean backup..."
docker stop "$CONTAINER_NAME"

echo "Creating Caddy archive..."
tar -czf "$REMOTE_ROOT/archive/caddy-$DATE.tar.gz" \
    --exclude='./backup-caddy.sh' \
    --exclude='*.log' \
    -C "$LOCAL_CADDY" .

echo "Cleaning old Caddy archives..."
find "$REMOTE_ROOT/archive" -type f -name 'caddy-*.tar.gz' -mtime +30 -delete

echo "Caddy backup complete."
