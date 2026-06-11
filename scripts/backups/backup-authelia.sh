#!/bin/bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
    echo "ERROR: This backup must be run as root so Authelia secrets and Redis data can be read."
    echo "Run with: sudo /srv/docker/authelia/backup-authelia.sh"
    exit 1
fi

DATE=$(date +%F)
LOCAL_AUTHELIA="/srv/docker/authelia"
REMOTE_ROOT="/mnt/backupshare/authelia"
AUTHELIA_CONTAINER="authelia"
REDIS_CONTAINER="authelia-redis"

restart_authelia() {
    echo "Ensuring Authelia Redis container is running..."
    docker start "$REDIS_CONTAINER" >/dev/null 2>&1 || true

    echo "Ensuring Authelia container is running..."
    docker start "$AUTHELIA_CONTAINER" >/dev/null 2>&1 || true
}

trap restart_authelia EXIT

if ! mountpoint -q /mnt/backupshare; then
    echo "ERROR: /mnt/backupshare is not mounted. Aborting backup."
    exit 1
fi

mkdir -p "$REMOTE_ROOT/archive"

echo "Stopping Authelia for a clean backup..."
docker stop "$AUTHELIA_CONTAINER"

echo "Stopping Authelia Redis for a clean backup..."
docker stop "$REDIS_CONTAINER"

echo "Creating Authelia archive..."
tar -czf "$REMOTE_ROOT/archive/authelia-$DATE.tar.gz" \
    --exclude='./backup-authelia.sh' \
    -C "$LOCAL_AUTHELIA" .

echo "Cleaning old Authelia archives..."
find "$REMOTE_ROOT/archive" -type f -name 'authelia-*.tar.gz' -mtime +30 -delete

echo "Authelia backup complete."
