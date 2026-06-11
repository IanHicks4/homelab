#!/bin/bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
    echo "ERROR: This backup must be run as root so Homepage env/config and Uptime Kuma data can be read."
    echo "Run with: sudo /srv/docker/homepage-stack/backup-homepage-stack.sh"
    exit 1
fi

DATE=$(date +%F)
LOCAL_STACK="/srv/docker/homepage-stack"
REMOTE_ROOT="/mnt/backupshare/homepage-stack"

CONTAINERS=(
    "homepage"
    "uptime-kuma"
    "glances"
)

restart_stack() {
    echo "Ensuring homepage-stack containers are running..."
    for container in "${CONTAINERS[@]}"; do
        docker start "$container" >/dev/null 2>&1 || true
    done
}

trap restart_stack EXIT

if ! mountpoint -q /mnt/backupshare; then
    echo "ERROR: /mnt/backupshare is not mounted. Aborting backup."
    exit 1
fi

mkdir -p "$REMOTE_ROOT/archive"

echo "Stopping homepage-stack containers for a clean backup..."
for container in "${CONTAINERS[@]}"; do
    docker stop "$container"
done

echo "Creating homepage-stack archive..."
tar -czf "$REMOTE_ROOT/archive/homepage-stack-$DATE.tar.gz" \
    --exclude='./backup-homepage-stack.sh' \
    --exclude='*.log' \
    -C "$LOCAL_STACK" .

echo "Cleaning old homepage-stack archives..."
find "$REMOTE_ROOT/archive" -type f -name 'homepage-stack-*.tar.gz' -mtime +30 -delete

echo "Homepage-stack backup complete."
