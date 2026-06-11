# Restore Arr Stack

## Purpose And Scope

Restore the Arr media automation stack after a rebuild, failed update, or lost application configuration.

This runbook is based on:

- `scripts/backups/backup-arr.sh`
- `compose/arr/compose.yaml`

Covered containers:

- `sonarr`
- `radarr`
- `prowlarr`
- `seerr`
- `bazarr`
- `flaresolverr`
- `recyclarr`

## Backup Archive Contains

Backup archives are stored under:

```bash
/mnt/backupshare/arr/archive/
```

Expected archive name:

```bash
arr-YYYY-MM-DD.tar.gz
```

The backup script archives:

```bash
/srv/docker/arr
```

Expected application config paths include:

```bash
/srv/docker/arr/sonarr
/srv/docker/arr/radarr
/srv/docker/arr/prowlarr
/srv/docker/arr/seerr
/srv/docker/arr/bazarr
/srv/docker/arr/recyclarr
```

## Backup Archive Does Not Contain

- `/mnt/media` media files.
- Logs, caches, and internal app backup folders excluded by the backup script.
- Docker images, containers, or networks.
- External indexer accounts or provider-side state.

## Prerequisites

Verify the backup share and archive:

```bash
mountpoint /mnt/backupshare
ls -lh /mnt/backupshare/arr/archive
```

Verify `/mnt/media` is mounted before restoring:

```bash
mountpoint /mnt/media
ls -la /mnt/media
```

Verify the compose file exists:

```bash
ls -lh compose/arr/compose.yaml
```

## Restore Assumptions

- `/mnt/media` is already mounted and contains the expected media paths.
- The selected archive is from the intended restore date.
- The external `proxy` network exists for Seerr.
- Restore commands may require an account with permission to write `/srv/docker/arr` and manage containers.
- Admin apps remain Tailscale/private except Seerr, which is public per inventory.

## Restore Procedure

Select an archive:

```bash
ls -lh /mnt/backupshare/arr/archive/arr-*.tar.gz
```

Stop containers in backup-script order:

```bash
docker stop recyclarr
docker stop flaresolverr
docker stop bazarr
docker stop seerr
docker stop prowlarr
docker stop radarr
docker stop sonarr
```

Move the current directory aside:

```bash
mv /srv/docker/arr /srv/docker/arr.restore-old-$(date +%F-%H%M%S)
mkdir -p /srv/docker/arr
```

Extract the selected archive:

```bash
tar -xzf /mnt/backupshare/arr/archive/arr-YYYY-MM-DD.tar.gz -C /srv/docker/arr
```

Validate expected config directories:

```bash
test -d /srv/docker/arr/sonarr
test -d /srv/docker/arr/radarr
test -d /srv/docker/arr/prowlarr
test -d /srv/docker/arr/seerr
test -d /srv/docker/arr/bazarr
test -d /srv/docker/arr/recyclarr
```

Start containers in backup-script order:

```bash
docker start sonarr
docker start radarr
docker start prowlarr
docker start seerr
docker start bazarr
docker start flaresolverr
docker start recyclarr
```

If containers were recreated instead of stopped, start from compose:

```bash
cd compose/arr
docker compose up -d
```

Keep `/srv/docker/arr.restore-old-*` until restore is confirmed.

## Ownership And Permissions Notes

- Most Arr containers run with `PUID=1000` and `PGID=1000`.
- Recyclarr runs as `1000:1000`.
- Restored config directories should be readable and writable by that UID/GID.
- Do not change permissions blindly; inspect logs first if a service cannot write its database.

## Validation Steps

Verify containers and logs:

```bash
docker ps --filter name=sonarr
docker ps --filter name=radarr
docker ps --filter name=prowlarr
docker ps --filter name=bazarr
docker ps --filter name=seerr
docker logs sonarr --tail 100
docker logs radarr --tail 100
docker logs prowlarr --tail 100
docker logs bazarr --tail 100
docker logs seerr --tail 100
```

Validate private/Tailscale app access:

```bash
curl -I http://100.77.136.106:8989
curl -I http://100.77.136.106:7878
curl -I http://100.77.136.106:9696
curl -I http://100.77.136.106:6767
```

Validate Seerr:

```bash
curl -I https://seerr.kai.coach
```

In the UIs, verify:

- Sonarr and Radarr libraries appear.
- Root folders point to valid `/mnt/media` paths.
- Prowlarr indexers are present.
- Bazarr settings and paths are present.
- Seerr users/settings are present.
- Recyclarr config is present and logs are clean.

## Rollback Steps

Stop containers:

```bash
docker stop recyclarr
docker stop flaresolverr
docker stop bazarr
docker stop seerr
docker stop prowlarr
docker stop radarr
docker stop sonarr
```

Move failed restore aside:

```bash
mv /srv/docker/arr /srv/docker/arr.failed-restore-$(date +%F-%H%M%S)
```

Restore previous directory:

```bash
mv /srv/docker/arr.restore-old-YYYY-MM-DD-HHMMSS /srv/docker/arr
```

Start containers:

```bash
docker start sonarr
docker start radarr
docker start prowlarr
docker start seerr
docker start bazarr
docker start flaresolverr
docker start recyclarr
```

## Security And Sensitivity Notes

- Arr config may contain API keys, indexer credentials, webhook URLs, and service tokens.
- Do not commit restored config directories or app databases to Git.
- Keep Sonarr, Radarr, Prowlarr, and Bazarr on Tailscale/private access.
- Seerr remains intentionally public per inventory, but its admin/config data is sensitive.

## Known Limitations

- `/mnt/media` is not included and must be restored separately.
- Excluded cache/log/internal backup directories may not be present after restore.
- External indexer or provider account changes are not controlled by this backup.
- Backup scheduling is not proven by this runbook; verify separately.
