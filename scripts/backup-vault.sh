#!/bin/bash
set -euo pipefail

DATE=$(date +%F)

LOCAL_VAULT="/srv/docker/vaultwarden/data"
REMOTE_ROOT="/mnt/backupshare/vaultwarden"

mkdir -p "$REMOTE_ROOT/archive"
mkdir -p "$REMOTE_ROOT/data"

echo "Shutting down vaultwarden container to get clean snapshot"
docker stop vaultwarden

echo "Creating compressed archive..."
tar -czf "$REMOTE_ROOT/archive/vaultwarden-$DATE.tar.gz" \
    -C "$LOCAL_VAULT" .

echo "Syncing live data directory..."
rsync -avh --delete "$LOCAL_VAULT/" "$REMOTE_ROOT/data/"

echo "Starting Vaultwarden container..."
docker start vaultwarden

echo "Cleaning old archives..."
find "$REMOTE_ROOT/archive" -type f -mtime +30 -delete

echo "Vaultwarden backup complete."
