# Restore Logging Stack

## Purpose And Scope

Restore the logging stack after a rebuild, failed update, Grafana data loss, Loki data loss, or Alloy configuration loss.

This runbook is based on:

- `scripts/backups/backup-logging.sh`
- `compose/logging/compose.yaml`

Covered services:

- `loki`
- `grafana`
- `alloy`

## Backup Archive Contains

Backup archives are stored under:

```bash
/mnt/backupshare/logging/archive/
```

Expected archive name:

```bash
logging-YYYY-MM-DD.tar.gz
```

The backup script archives:

```bash
/srv/docker/logging
```

Expected important paths include:

```bash
/srv/docker/logging/loki/config.yml
/srv/docker/logging/loki/data
/srv/docker/logging/grafana/data
/srv/docker/logging/alloy/config.alloy
```

Grafana data, dashboards, and data sources are more important to restore than historical Loki logs.

## Backup Archive Does Not Contain

- Files matching `*.log`.
- Host journal data mounted from `/var/log/journal`.
- Host machine identity mounted from `/etc/machine-id`.
- Docker socket state from `/var/run/docker.sock`.
- Images, containers, Docker networks, or the external `proxy` network.

## Prerequisites

Verify the backup share and archive:

```bash
mountpoint /mnt/backupshare
ls -lh /mnt/backupshare/logging/archive
```

Verify the compose file exists:

```bash
ls -lh compose/logging/compose.yaml
```

Verify the current stack path if present:

```bash
ls -la /srv/docker/logging
```

## Restore Assumptions

- The Docker host has the required images or can pull them.
- The external `proxy` network exists.
- The selected archive is trusted and from the intended restore date.
- Restore commands may require an account with permission to write `/srv/docker/logging` and manage containers.
- Grafana remains internal/private at `grafana.kai.coach`.

## Restore Procedure

Select an archive:

```bash
ls -lh /mnt/backupshare/logging/archive/logging-*.tar.gz
```

Stop containers in backup-script order:

```bash
docker stop alloy
docker stop grafana
docker stop loki
```

Preserve the current directory:

```bash
mv /srv/docker/logging /srv/docker/logging.restore-old-$(date +%F-%H%M%S)
mkdir -p /srv/docker/logging
```

Extract the selected archive:

```bash
tar -xzf /mnt/backupshare/logging/archive/logging-YYYY-MM-DD.tar.gz -C /srv/docker/logging
```

Validate expected files:

```bash
test -f /srv/docker/logging/loki/config.yml
test -d /srv/docker/logging/loki/data
test -d /srv/docker/logging/grafana/data
test -f /srv/docker/logging/alloy/config.alloy
```

Start containers in backup-script order:

```bash
docker start loki
docker start grafana
docker start alloy
```

If containers were recreated instead of stopped, start from compose:

```bash
cd compose/logging
docker compose up -d
```

Keep `/srv/docker/logging.restore-old-*` until the restore is confirmed.

## Ownership And Permissions Notes

- Grafana runs as user `472:472` in compose, so restored `grafana/data` permissions must allow Grafana to read and write.
- Alloy runs as root in compose to read Docker and journal sources.
- Loki must be able to read `loki/config.yml` and write `loki/data`.
- If permission errors appear in logs, inspect ownership before changing it.

## Validation Steps

Verify containers:

```bash
docker ps --filter name=loki
docker ps --filter name=grafana
docker ps --filter name=alloy
docker logs loki --tail 100
docker logs grafana --tail 100
docker logs alloy --tail 100
```

Validate Grafana access from a trusted internal client:

```bash
curl -I https://grafana.kai.coach
```

Validate local service ports:

```bash
curl -I http://127.0.0.1:3002
curl -I http://127.0.0.1:3100/ready
curl -I http://127.0.0.1:12345
```

Expected:

- Grafana loads internally.
- Dashboards and data sources are present.
- Loki is ready or becomes ready after startup.
- Alloy logs show Docker discovery and log forwarding without repeated errors.
- New container logs appear in Loki/Grafana after a few minutes.

## Rollback Steps

Stop the restored stack:

```bash
docker stop alloy
docker stop grafana
docker stop loki
```

Move the failed restore aside:

```bash
mv /srv/docker/logging /srv/docker/logging.failed-restore-$(date +%F-%H%M%S)
```

Restore the previous directory:

```bash
mv /srv/docker/logging.restore-old-YYYY-MM-DD-HHMMSS /srv/docker/logging
```

Start containers:

```bash
docker start loki
docker start grafana
docker start alloy
```

Keep the failed restore directory for analysis.

## Security And Sensitivity Notes

- `logging/.env`, Grafana admin settings, Grafana data, Loki data, and Alloy config may contain sensitive operational data.
- Do not commit restored data, `.env` files, or generated runtime state to Git.
- Alloy has read-only Docker socket access and journal access. Treat this as high-trust even when mounted read-only.
- Logging admin surfaces must remain internal/private.

## Known Limitations

- Historical Loki logs may be incomplete if excluded, rotated, or outside the archive.
- Host journal files, Docker socket state, and host identity are live host resources, not restored from this archive.
- Restore run success depends on the external `proxy` network and local DNS being correct.
- Backup scheduling is not proven by this runbook; verify operational scheduling separately.
