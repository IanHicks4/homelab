# Restore Jellyfin

## Purpose And Scope

Restore Jellyfin application configuration, users, metadata, app state, and compose context after a rebuild, failed update, or damaged config directory.

This runbook is based on:

- `scripts/backups/backup-jellyfin.sh`
- `compose/jellyfin/compose.yaml`

Covered container:

- `jellyfin`

## Backup Archive Contains

Backup archives are stored under:

```bash
/mnt/backupshare/jellyfin/archive/
```

Expected archive name:

```bash
jellyfin-YYYY-MM-DD.tar.gz
```

The backup script archives:

```bash
/srv/docker/jellyfin
```

Expected restored data includes Jellyfin config, users, metadata/app state, custom `index.html`, and compose context present under `/srv/docker/jellyfin`.

## Backup Archive Does Not Contain

- `/mnt/media` media files.
- `./config/cache`.
- `./config/log`.
- `./config/transcodes`.
- Files matching `*.log`.
- Docker images or host GPU device state.

## Prerequisites

Verify the backup share and archive:

```bash
mountpoint /mnt/backupshare
ls -lh /mnt/backupshare/jellyfin/archive
```

Verify `/mnt/media` is mounted:

```bash
mountpoint /mnt/media
ls -la /mnt/media
```

Verify the compose file exists:

```bash
ls -lh compose/jellyfin/compose.yaml
```

## Restore Assumptions

- `/mnt/media` is restored separately and already mounted.
- Hardware acceleration device `/dev/dri` exists if used.
- Jellyfin uses host networking.
- The selected archive is from the intended restore date.
- Restore commands may require an account with permission to write `/srv/docker/jellyfin` and manage containers.

## Restore Procedure

Select an archive:

```bash
ls -lh /mnt/backupshare/jellyfin/archive/jellyfin-*.tar.gz
```

Stop Jellyfin:

```bash
docker stop jellyfin
```

Move the current directory aside:

```bash
mv /srv/docker/jellyfin /srv/docker/jellyfin.restore-old-$(date +%F-%H%M%S)
mkdir -p /srv/docker/jellyfin
```

Extract the selected archive:

```bash
tar -xzf /mnt/backupshare/jellyfin/archive/jellyfin-YYYY-MM-DD.tar.gz -C /srv/docker/jellyfin
```

Validate expected files:

```bash
test -d /srv/docker/jellyfin/config
test -f /srv/docker/jellyfin/config/index.html
```

Start Jellyfin:

```bash
docker start jellyfin
```

If the container was recreated instead of stopped, start from compose:

```bash
cd compose/jellyfin
docker compose up -d
```

Keep `/srv/docker/jellyfin.restore-old-*` until restore is confirmed.

## Ownership And Permissions Notes

- The Jellyfin container uses `PUID=1000` and `PGID=1000`.
- Restored config should be readable and writable by UID/GID `1000`.
- `/mnt/media` is mounted into the container and must be readable.
- `/dev/dri` must be present for hardware acceleration.

## Validation Steps

Verify the container and logs:

```bash
docker ps --filter name=jellyfin
docker logs jellyfin --tail 100
```

Validate local and public access:

```bash
curl -I http://127.0.0.1:8096
curl -I https://jellyfin.kai.coach
```

In Jellyfin, verify:

- Login works.
- Users are present.
- Libraries are present.
- Media paths under `/mnt/media` work.
- Metadata and watched state are present as expected.
- Custom web file behavior is present if expected.

## Rollback Steps

Stop Jellyfin:

```bash
docker stop jellyfin
```

Move failed restore aside:

```bash
mv /srv/docker/jellyfin /srv/docker/jellyfin.failed-restore-$(date +%F-%H%M%S)
```

Restore previous directory:

```bash
mv /srv/docker/jellyfin.restore-old-YYYY-MM-DD-HHMMSS /srv/docker/jellyfin
```

Start Jellyfin:

```bash
docker start jellyfin
```

## Security And Sensitivity Notes

- Jellyfin config contains user/server metadata and may include tokens or private library details.
- Do not commit restored config, metadata, or custom runtime files to Git.
- Jellyfin is intentionally public, but admin access and server config remain sensitive.

## Known Limitations

- `/mnt/media` is not included and must be restored separately.
- Cache, logs, and transcodes are intentionally excluded.
- Hardware acceleration depends on host device availability.
- Backup scheduling is not proven by this runbook; verify separately.
