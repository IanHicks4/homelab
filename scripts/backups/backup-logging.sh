#!/bin/bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
    echo "ERROR: This backup must be run as root so Grafana/Loki data and logging .env can be read."
    echo "Run with: sudo /srv/docker/logging/backup-logging.sh"
    exit 1
fi

DATE=$(date +%F)
LOCAL_LOGGING="/srv/docker/logging"
REMOTE_ROOT="/mnt/backupshare/logging"

STOP_ORDER=(
    "alloy"
    "grafana"
    "loki"
)

START_ORDER=(
    "loki"
    "grafana"
    "alloy"
)

restart_logging() {
    echo "Ensuring logging stack containers are running..."
    for container in "${START_ORDER[@]}"; do
        docker start "$container" >/dev/null 2>&1 || true
    done
}

trap restart_logging EXIT

if ! mountpoint -q /mnt/backupshare; then
    echo "ERROR: /mnt/backupshare is not mounted. Aborting backup."
    exit 1
fi

mkdir -p "$REMOTE_ROOT/archive"

echo "Stopping logging stack containers for a clean backup..."
for container in "${STOP_ORDER[@]}"; do
    docker stop "$container"
done

echo "Creating logging stack archive..."
tar -czf "$REMOTE_ROOT/archive/logging-$DATE.tar.gz" \
    --exclude='./backup-logging.sh' \
    --exclude='*.log' \
    -C "$LOCAL_LOGGING" .

echo "Cleaning old logging archives..."
find "$REMOTE_ROOT/archive" -type f -name 'logging-*.tar.gz' -mtime +30 -delete

echo "Logging stack backup complete."
