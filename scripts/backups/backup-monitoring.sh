#!/bin/bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
    echo "ERROR: This backup must be run as root so Prometheus data can be read."
    echo "Run with: sudo /srv/docker/monitoring/backup-monitoring.sh"
    exit 1
fi

DATE=$(date +%F)
LOCAL_MONITORING="/srv/docker/monitoring"
REMOTE_ROOT="/mnt/backupshare/monitoring"

STOP_ORDER=(
    "cadvisor"
    "node-exporter"
    "prometheus"
)

START_ORDER=(
    "prometheus"
    "node-exporter"
    "cadvisor"
)

restart_monitoring() {
    echo "Ensuring monitoring stack containers are running..."
    for container in "${START_ORDER[@]}"; do
        docker start "$container" >/dev/null 2>&1 || true
    done
}

trap restart_monitoring EXIT

if ! mountpoint -q /mnt/backupshare; then
    echo "ERROR: /mnt/backupshare is not mounted. Aborting backup."
    exit 1
fi

mkdir -p "$REMOTE_ROOT/archive"

echo "Stopping monitoring stack containers for a clean backup..."
for container in "${STOP_ORDER[@]}"; do
    docker stop "$container"
done

echo "Creating monitoring stack archive..."
tar -czf "$REMOTE_ROOT/archive/monitoring-$DATE.tar.gz" \
    --exclude='./backup-monitoring.sh' \
    --exclude='./data/lock' \
    --exclude='./data/queries.active' \
    -C "$LOCAL_MONITORING" .

echo "Cleaning old monitoring archives..."
find "$REMOTE_ROOT/archive" -type f -name 'monitoring-*.tar.gz' -mtime +30 -delete

echo "Monitoring stack backup complete."
