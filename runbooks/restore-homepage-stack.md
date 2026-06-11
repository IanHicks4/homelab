# Restore Homepage Stack

## Goal

Restore the Homepage stack after a rebuild, failed update, damaged Homepage configuration, lost Uptime Kuma data, or broken Glances integration.

This runbook is based on:

- `scripts/backups/backup-homepage-stack.sh`
- `compose/homepage-stack/compose.yaml`

## Important Warnings

- The stack should remain internal/private.
- `home.kai.coach` and `status.kai.coach` are intended for internal/private access through Pi-hole DNS and Caddy.
- Do not paste secret values, API keys, service tokens, integration credentials, or notification credentials into this runbook or tickets.
- `homepage-config/.env` is sensitive and must not be committed to Git.
- Uptime Kuma data may include monitor history, notification configuration, private URLs, credentials, or tokens.
- Homepage and Glances intentionally use read-only Docker socket mounts. Treat Docker socket access as high-trust even when mounted read-only.

## Prerequisites

Verify the backup share is mounted:

```bash
mountpoint /mnt/backupshare
```

Verify Homepage stack backups exist:

```bash
ls -lh /mnt/backupshare/homepage-stack/archive
```

Expected archive name:

```bash
homepage-stack-YYYY-MM-DD.tar.gz
```

Verify the compose file exists in the repo:

```bash
ls -lh compose/homepage-stack/compose.yaml
```

Verify the current persistent path if it exists:

```bash
ls -la /srv/docker/homepage-stack
```

The backup script is designed to run with enough filesystem permission to read Homepage env/config and Uptime Kuma data. Restore work also needs permission to write `/srv/docker/homepage-stack`.

## Paths And Layout

Persistent data root:

```bash
/srv/docker/homepage-stack
```

Expected restored paths:

```bash
/srv/docker/homepage-stack/homepage-config
/srv/docker/homepage-stack/homepage-config/.env
/srv/docker/homepage-stack/uptime-kuma
```

Containers:

```bash
homepage
glances
uptime-kuma
```

Access model:

- Homepage direct port is bound to `100.77.136.106:3000`.
- `home.kai.coach` remains internal/private.
- `status.kai.coach` remains internal/private.
- Glances uses host networking and is consumed by Homepage widgets.

## Restore Steps

Stop stack containers before restoring:

```bash
docker stop homepage
docker stop uptime-kuma
docker stop glances
```

Create a rollback archive of the current data if it exists:

```bash
mkdir -p /srv/docker/_restore-rollback/homepage-stack
tar -czf /srv/docker/_restore-rollback/homepage-stack/homepage-stack-pre-restore-$(date +%F-%H%M%S).tar.gz -C /srv/docker/homepage-stack .
```

Move the current data aside:

```bash
mv /srv/docker/homepage-stack /srv/docker/homepage-stack.restore-old-$(date +%F-%H%M%S)
mkdir -p /srv/docker/homepage-stack
```

Restore the selected backup archive:

```bash
tar -xzf /mnt/backupshare/homepage-stack/archive/homepage-stack-YYYY-MM-DD.tar.gz -C /srv/docker/homepage-stack
```

Verify restored files and directories:

```bash
ls -la /srv/docker/homepage-stack
ls -la /srv/docker/homepage-stack/homepage-config
ls -la /srv/docker/homepage-stack/uptime-kuma
```

Verify the sensitive Homepage environment file exists without printing it:

```bash
test -f /srv/docker/homepage-stack/homepage-config/.env
```

Do not commit `homepage-config/.env` to Git.

Start the stack from the compose directory:

```bash
cd compose/homepage-stack
docker compose up -d
```

## Validation Steps

Verify all expected containers are running:

```bash
docker ps --filter name=homepage
docker ps --filter name=uptime-kuma
docker ps --filter name=glances
```

Check container health and status:

```bash
docker inspect --format '{{.Name}} {{.State.Status}} {{if .State.Health}}{{.State.Health.Status}}{{else}}no-healthcheck{{end}}' homepage
docker inspect --format '{{.Name}} {{.State.Status}} {{if .State.Health}}{{.State.Health.Status}}{{else}}no-healthcheck{{end}}' uptime-kuma
docker inspect --format '{{.Name}} {{.State.Status}} {{if .State.Health}}{{.State.Health.Status}}{{else}}no-healthcheck{{end}}' glances
```

Expected:

- `homepage` status is `running`.
- `uptime-kuma` status is `running`.
- `glances` status is `running`.
- If a healthcheck is present, it reports `healthy`.
- If no healthcheck is defined, the command reports `no-healthcheck`; then use logs and functional tests.

Check logs without exposing secrets:

```bash
docker logs homepage --tail 100
docker logs uptime-kuma --tail 100
docker logs glances --tail 100
```

Expected:

- Homepage starts without config parsing errors.
- Uptime Kuma starts without database or permission errors.
- Glances starts its web service and host metrics collection.
- No missing `homepage-config/.env` errors.

Validate internal/private routes from a trusted internal client:

```bash
curl -I https://home.kai.coach
curl -I https://status.kai.coach
```

Expected:

- Both routes resolve through internal DNS.
- Public DNS should not resolve `home.kai.coach` or `status.kai.coach`.
- Caddy routes remain valid for internal access.

Validate Homepage:

- Homepage loads at `home.kai.coach`.
- Docker/container widgets render as expected.
- Glances widgets show Opti CPU and top-process visibility.
- No widgets expose sensitive tokens or credentials.

Validate Uptime Kuma:

- Uptime Kuma loads at `status.kai.coach`.
- Existing monitors are present.
- Monitor history is present for the restored backup date.
- Notification integrations are present but do not expose secret values in documentation or tickets.
- Expected public and internal monitors report reasonable status after a few checks.

Validate Glances:

- Glances container is running with host networking.
- Homepage Glances widgets receive host/process metrics.
- Docker socket and host mounts are present only for the intended internal/private use case.

## Rollback Steps

If the stack fails after restore, stop all three containers:

```bash
docker stop homepage
docker stop uptime-kuma
docker stop glances
```

Move the failed restore aside:

```bash
mv /srv/docker/homepage-stack /srv/docker/homepage-stack.failed-restore-$(date +%F-%H%M%S)
mkdir -p /srv/docker/homepage-stack
```

Restore the pre-restore rollback archive:

```bash
tar -xzf /srv/docker/_restore-rollback/homepage-stack/homepage-stack-pre-restore-YYYY-MM-DD-HHMMSS.tar.gz -C /srv/docker/homepage-stack
```

Start the stack again:

```bash
cd compose/homepage-stack
docker compose up -d
```

Validate all containers again:

```bash
docker ps --filter name=homepage
docker ps --filter name=uptime-kuma
docker ps --filter name=glances
docker logs homepage --tail 100
docker logs uptime-kuma --tail 100
docker logs glances --tail 100
```

If rollback also fails, keep the failed restore and rollback data directories intact for analysis. Do not delete Homepage config or Uptime Kuma data until the cause is understood.

## Common Issues

### Missing `homepage-config/.env`

Symptoms:

- Homepage starts with missing integration data.
- Docker or service widgets fail.
- Logs mention missing environment variables.

Check:

```bash
test -f /srv/docker/homepage-stack/homepage-config/.env
```

Fix:

- Restore `homepage-config/.env` from backup or the approved secret store.
- Do not commit `homepage-config/.env` to Git.
- Do not paste the file contents into tickets or chat.

### Uptime Kuma Data Missing Or Reset

Symptoms:

- Uptime Kuma opens as a fresh install.
- Monitors are missing.
- Notification integrations are missing.
- Monitor history is gone.

Check:

```bash
ls -la /srv/docker/homepage-stack/uptime-kuma
```

Fix:

- Confirm the selected archive date is the intended restore point.
- Restore the `uptime-kuma` directory from the correct backup archive.
- Keep the failed restore directory until monitor data is confirmed.

### Homepage Widgets Fail

Symptoms:

- Homepage loads but Docker/container widgets are blank.
- Glances widgets are blank.
- CPU or top-process widgets do not render.

Check:

```bash
docker logs homepage --tail 100
docker logs glances --tail 100
docker ps --filter name=glances
```

Notes:

- Homepage Docker/container widgets depend on the read-only Docker socket mount.
- Homepage Glances widgets depend on the Glances container and host/process mounts.
- These mounts are accepted high-trust risks and should remain internal/private.

### Internal Route Is Publicly Reachable

This is not the intended access model.

Expected:

- `home.kai.coach` is internal/private.
- `status.kai.coach` is internal/private.
- Public DNS should not resolve these hostnames.

If public access is observed, treat it as an exposure issue and review DNS and Caddy routing before continuing normal operation.

### Sensitive Config Accidentally Staged

Check Git status before committing:

```bash
git status --short
```

Expected:

- No `homepage-config/.env` file is staged or committed.
- No Uptime Kuma database or runtime data is staged or committed.

If sensitive files appear in Git status, stop and remove them from the index before committing. Do not paste their contents anywhere.
