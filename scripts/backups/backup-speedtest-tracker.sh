#!/bin/bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
    echo "ERROR: This backup must be run as root so Speedtest Tracker config/database/secrets can be read."
    echo "Run with: sudo /srv/docker/speedtest-tracker/backup-speedtest-tracker.sh"
    exit 1
fi

DATE=$(date +%F)
LOCAL_SPEEDTEST="/srv/docker/speedtest-tracker"
REMOTE_ROOT="/mnt/backupshare/speedtest-tracker"
CONTAINER_NAME="speedtest-tracker"

restart_speedtest() {
    echo "Ensuring Speedtest Tracker container is running..."
    docker start "$CONTAINER_NAME" >/dev/null 2>&1 || true
}

trap restart_speedtest EXIT

if ! mountpoint -q /mnt/backupshare; then
    echo "ERROR: /mnt/backupshare is not mounted. Aborting backup."
    exit 1
fi

mkdir -p "$REMOTE_ROOT/archive"

echo "Stopping Speedtest Tracker for a clean backup..."
docker stop "$CONTAINER_NAME"

echo "Creating Speedtest Tracker archive..."
tar -czf "$REMOTE_ROOT/archive/speedtest-tracker-$DATE.tar.gz" \
    --exclude='./backup-speedtest-tracker.sh' \
    --exclude='*.log' \
    --exclude='./config/log/*' \
    -C "$LOCAL_SPEEDTEST" .

echo "Cleaning old Speedtest Tracker archives..."
find "$REMOTE_ROOT/archive" -type f -name 'speedtest-tracker-*.tar.gz' -mtime +30 -delete

echo "Speedtest Tracker backup complete."
