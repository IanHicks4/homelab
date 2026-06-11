#!/bin/bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
    echo "ERROR: This backup must be run as root so all Arr stack config/data can be read."
    echo "Run with: sudo /srv/docker/arr/backup-arr.sh"
    exit 1
fi

DATE=$(date +%F)
LOCAL_ARR="/srv/docker/arr"
REMOTE_ROOT="/mnt/backupshare/arr"

STOP_ORDER=(
    "recyclarr"
    "flaresolverr"
    "bazarr"
    "seerr"
    "prowlarr"
    "radarr"
    "sonarr"
)

START_ORDER=(
    "sonarr"
    "radarr"
    "prowlarr"
    "seerr"
    "bazarr"
    "flaresolverr"
    "recyclarr"
)

restart_arr() {
    echo "Ensuring Arr stack containers are running..."
    for container in "${START_ORDER[@]}"; do
        docker start "$container" >/dev/null 2>&1 || true
    done
}

trap restart_arr EXIT

if ! mountpoint -q /mnt/backupshare; then
    echo "ERROR: /mnt/backupshare is not mounted. Aborting backup."
    exit 1
fi

mkdir -p "$REMOTE_ROOT/archive"

echo "Stopping Arr stack containers for a clean backup..."
for container in "${STOP_ORDER[@]}"; do
    docker stop "$container"
done

echo "Creating Arr stack archive..."
tar -czf "$REMOTE_ROOT/archive/arr-$DATE.tar.gz" \
    --exclude='./backup-arr.sh' \
    --exclude='*/log/*' \
    --exclude='*/logs/*' \
    --exclude='*/cache/*' \
    --exclude='*/Backups/*' \
    --exclude='*/backup/*' \
    -C "$LOCAL_ARR" .

echo "Cleaning old Arr archives..."
find "$REMOTE_ROOT/archive" -type f -name 'arr-*.tar.gz' -mtime +30 -delete

echo "Arr stack backup complete."
