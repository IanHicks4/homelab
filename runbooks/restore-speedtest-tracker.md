# Restore Speedtest Tracker

## Purpose And Scope

Restore Speedtest Tracker after a rebuild, failed update, lost database, or damaged configuration.

This runbook is based on:

- `scripts/backups/backup-speedtest-tracker.sh`
- `compose/speedtest-tracker/compose.yaml`

Covered container:

- `speedtest-tracker`

## Backup Archive Contains

Backup archives are stored under:

```bash
/mnt/backupshare/speedtest-tracker/archive/
```

Expected archive name:

```bash
speedtest-tracker-YYYY-MM-DD.tar.gz
```

The backup script archives:

```bash
/srv/docker/speedtest-tracker
```

Expected important paths include:

```bash
/srv/docker/speedtest-tracker/.env
/srv/docker/speedtest-tracker/config
```

## Backup Archive Does Not Contain

- Files matching `*.log`.
- `./config/log/*`.
- Docker images, containers, or networks.
- External speed test provider state.

## Prerequisites

Verify the backup share and archive:

```bash
mountpoint /mnt/backupshare
ls -lh /mnt/backupshare/speedtest-tracker/archive
```

Verify the compose file exists:

```bash
ls -lh compose/speedtest-tracker/compose.yaml
```

## Restore Assumptions

- The service remains private/Tailscale-bound at `100.77.136.106:8082`.
- The selected archive is from the intended restore date.
- The external `proxy` network exists if the compose stack expects it.
- Restore commands may require an account with permission to write `/srv/docker/speedtest-tracker` and manage containers.

## Restore Procedure

Select an archive:

```bash
ls -lh /mnt/backupshare/speedtest-tracker/archive/speedtest-tracker-*.tar.gz
```

Stop Speedtest Tracker:

```bash
docker stop speedtest-tracker
```

Move current directory aside:

```bash
mv /srv/docker/speedtest-tracker /srv/docker/speedtest-tracker.restore-old-$(date +%F-%H%M%S)
mkdir -p /srv/docker/speedtest-tracker
```

Extract the selected archive:

```bash
tar -xzf /mnt/backupshare/speedtest-tracker/archive/speedtest-tracker-YYYY-MM-DD.tar.gz -C /srv/docker/speedtest-tracker
```

Validate expected files:

```bash
test -f /srv/docker/speedtest-tracker/.env
test -d /srv/docker/speedtest-tracker/config
```

Start Speedtest Tracker:

```bash
docker start speedtest-tracker
```

If the container was recreated instead of stopped, start from compose:

```bash
cd compose/speedtest-tracker
docker compose up -d
```

Keep `/srv/docker/speedtest-tracker.restore-old-*` until restore is confirmed.

## Ownership And Permissions Notes

- The image stores app data under `/config`.
- Restored `config` must be writable by the container.
- If database or permission errors occur, inspect logs before changing ownership.

## Validation Steps

Verify container and logs:

```bash
docker ps --filter name=speedtest-tracker
docker logs speedtest-tracker --tail 100
```

Validate private/Tailscale access:

```bash
curl -I http://100.77.136.106:8082
```

In the UI, verify:

- Historical results are present.
- The database loads without migration or corruption errors.
- Scheduled tests/settings are present. Needs verification.
- Authentication/settings behave as expected.

## Rollback Steps

Stop Speedtest Tracker:

```bash
docker stop speedtest-tracker
```

Move failed restore aside:

```bash
mv /srv/docker/speedtest-tracker /srv/docker/speedtest-tracker.failed-restore-$(date +%F-%H%M%S)
```

Restore previous directory:

```bash
mv /srv/docker/speedtest-tracker.restore-old-YYYY-MM-DD-HHMMSS /srv/docker/speedtest-tracker
```

Start Speedtest Tracker:

```bash
docker start speedtest-tracker
```

## Security And Sensitivity Notes

- `.env`, `database.sqlite`, certificate files, key files, config, and history may be sensitive.
- Do not commit restored `.env`, database, cert, key, or config files to Git.
- The service should remain private/Tailscale-bound.

## Known Limitations

- Logs are excluded from the backup.
- Provider-side or network conditions are not restored.
- Exact database filename may vary by application version; `database.sqlite` presence needs verification from restored data.
- Backup scheduling is not proven by this runbook; verify separately.
