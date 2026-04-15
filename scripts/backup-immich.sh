#!/bin/bash
set -euo pipefail

DATE=$(date +%F)

LOCAL_LIBRARY="/mnt/media/photos/immich/library"
LOCAL_POSTGRES_BACKUP="/srv/docker/immich/backups/postgres"
LOCAL_COMPOSE="/srv/docker/immich/compose"
REMOTE_ROOT="/mnt/backupshare/immich"

mkdir -p "$LOCAL_POSTGRES_BACKUP"
mkdir -p "$REMOTE_ROOT/postgres"
mkdir -p "$REMOTE_ROOT/library"
mkdir -p "$REMOTE_ROOT/compose"

echo "Creating postgres dump..."
docker exec immich-postgres pg_dumpall -U postgres | gzip > "$LOCAL_POSTGRES_BACKUP/immich-$DATE.sql.gz"

echo "Syncing library..."
rsync -avh --delete "$LOCAL_LIBRARY/" "$REMOTE_ROOT/library/"

echo "Syncing postgres dumps..."
rsync -avh "$LOCAL_POSTGRES_BACKUP/" "$REMOTE_ROOT/postgres/"

echo "Syncing compose files..."
rsync -avh --delete "$LOCAL_COMPOSE/" "$REMOTE_ROOT/compose/"

echo "Cleaning old postgres dumps..."
find "$LOCAL_POSTGRES_BACKUP" -type f -mtime +14 -delete

echo "Backup complete."
