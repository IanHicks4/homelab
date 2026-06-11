#!/bin/bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
    echo "ERROR: This backup must be run as root so VPN/qBittorrent config and secrets can be read."
    echo "Run with: sudo /srv/docker/vpn/backup-vpn.sh"
    exit 1
fi

DATE=$(date +%F)
LOCAL_VPN="/srv/docker/vpn"
REMOTE_ROOT="/mnt/backupshare/vpn"

STOP_ORDER=(
    "qbittorrent"
    "gluetun"
)

START_ORDER=(
    "gluetun"
    "qbittorrent"
)

restart_vpn() {
    echo "Ensuring VPN stack containers are running..."
    for container in "${START_ORDER[@]}"; do
        docker start "$container" >/dev/null 2>&1 || true
    done
}

trap restart_vpn EXIT

if ! mountpoint -q /mnt/backupshare; then
    echo "ERROR: /mnt/backupshare is not mounted. Aborting backup."
    exit 1
fi

mkdir -p "$REMOTE_ROOT/archive"

echo "Stopping VPN stack containers for a clean backup..."
for container in "${STOP_ORDER[@]}"; do
    docker stop "$container"
done

echo "Creating VPN stack archive..."
tar -czf "$REMOTE_ROOT/archive/vpn-$DATE.tar.gz" \
    --exclude='./backup-vpn.sh' \
    --exclude='*.log' \
    --exclude='*/lockfile' \
    --exclude='*/.ash_history' \
    -C "$LOCAL_VPN" .

echo "Cleaning old VPN archives..."
find "$REMOTE_ROOT/archive" -type f -name 'vpn-*.tar.gz' -mtime +30 -delete

echo "VPN stack backup complete."
