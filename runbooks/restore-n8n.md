# Restore n8n

## Goal

Restore n8n after a rebuild, failed update, SQLite corruption, workflow loss, or damaged persistent data.

This runbook is based on:

- `scripts/backups/backup-n8n.sh`
- `compose/n8n/compose.yaml`

## Important Warnings

- n8n persistent data can contain workflows, execution history, credentials metadata, and encrypted credential payloads.
- Do not paste secrets, credential values, encryption keys, API tokens, or webhook credentials into this runbook or tickets.
- n8n credentials may not decrypt if the restored data is paired with a different encryption key or incompatible runtime configuration. Restore any required secret material only from the approved secret store or secure backup location.
- The n8n UI/admin route `n8n.kai.coach` should remain internal/private and should not be publicly reachable.
- The public address form may call selected n8n workflows through `address.kai.coach/api/wedding-address`, which proxies internally to `n8n:5678`.
- The n8n container is not directly host-published in compose. Access should go through Caddy/internal DNS, not a direct public host port.

## Paths And Backup Format

Persistent data:

```bash
/srv/docker/n8n
```

Compose stack:

```bash
compose/n8n/compose.yaml
```

Backup location used by `backup-n8n.sh`:

```bash
/mnt/backupshare/n8n/archive
```

Expected archive name:

```bash
n8n-YYYY-MM-DD.tar.gz
```

The backup script stops the `n8n` container, archives `/srv/docker/n8n`, excludes log files and `crash.journal`, then starts the container again.

## Pre-Restore Checks

Verify the backup share is mounted:

```bash
mountpoint /mnt/backupshare
ls -lh /mnt/backupshare/n8n/archive
```

Select the archive to restore:

```bash
ls -lh /mnt/backupshare/n8n/archive/n8n-*.tar.gz
```

Verify the stack files are available in the repo:

```bash
ls -lh compose/n8n/compose.yaml
```

Verify the current persistent data path:

```bash
ls -la /srv/docker/n8n
```

If `/srv/docker/n8n` exists, preserve it before overwriting anything.

## Restore Steps

Stop n8n if it is running:

```bash
docker stop n8n
```

Create a local rollback copy of the current data:

```bash
mkdir -p /srv/docker/_restore-rollback/n8n
tar -czf /srv/docker/_restore-rollback/n8n/n8n-pre-restore-$(date +%F-%H%M%S).tar.gz -C /srv/docker/n8n .
```

Move the damaged or current data aside:

```bash
mv /srv/docker/n8n /srv/docker/n8n.restore-old-$(date +%F-%H%M%S)
mkdir -p /srv/docker/n8n
```

Restore the selected backup archive:

```bash
tar -xzf /mnt/backupshare/n8n/archive/n8n-YYYY-MM-DD.tar.gz -C /srv/docker/n8n
```

Verify restored data exists:

```bash
ls -la /srv/docker/n8n
```

Expected contents commonly include n8n user data, SQLite database files, config files, and runtime directories. Exact contents may vary by n8n version.

Start n8n from the compose directory:

```bash
cd compose/n8n
docker compose up -d
```

## Validation Steps

Verify the container is running:

```bash
docker ps --filter name=n8n
docker logs n8n --tail 100
```

Expected:

- `n8n` container is running.
- No SQLite corruption errors.
- No missing encryption/configuration errors.
- No repeated restart loop.

Verify the container is not directly host-published:

```bash
docker port n8n
```

Expected:

- No active public host port is listed.

Validate internal route behavior from a trusted internal client:

```bash
curl -I https://n8n.kai.coach
```

Expected:

- n8n responds through the internal/private route.
- UI/admin access is not reachable from public DNS.

Validate the public address-form webhook path separately:

```bash
curl -I https://address.kai.coach/api/wedding-address
```

Expected:

- The public address domain responds.
- The webhook path routes through Caddy to `n8n:5678`.
- The n8n UI/admin route remains separate from the public webhook route.

Log in from a trusted internal network and verify:

- Existing workflows are present.
- Expected workflows are active or inactive as intended.
- Credential-backed nodes do not show decryption errors.
- Recent executions and workflow history are reasonable for the restored backup date.
- Webhook workflows required by `address.kai.coach/api/wedding-address` are present and enabled if they should be live.

## Rollback Steps

If n8n fails after restore, stop it:

```bash
docker stop n8n
```

Move the failed restore aside:

```bash
mv /srv/docker/n8n /srv/docker/n8n.failed-restore-$(date +%F-%H%M%S)
mkdir -p /srv/docker/n8n
```

Restore the pre-restore rollback archive:

```bash
tar -xzf /srv/docker/_restore-rollback/n8n/n8n-pre-restore-YYYY-MM-DD-HHMMSS.tar.gz -C /srv/docker/n8n
```

Start n8n again:

```bash
cd compose/n8n
docker compose up -d
```

Validate:

```bash
docker ps --filter name=n8n
docker logs n8n --tail 100
```

If rollback also fails, keep both failed and rollback data directories intact for analysis. Do not delete restored data until the cause is understood.

## Common Issues

### Credentials Fail To Decrypt

Symptoms:

- Workflows exist but credential-backed nodes fail.
- Logs mention credential or encryption errors.
- Webhook workflows start but fail when calling external services.

Likely causes:

- Missing or changed n8n encryption key.
- Runtime configuration differs from the original install.
- Backup archive does not match the intended restore point.

Fix:

- Restore required secret material only from the approved secret store or secure backup location.
- Do not write secret values into this runbook.
- Restart n8n after restoring required runtime secret material.

### Workflow Data Missing

Symptoms:

- Login works but workflows are absent.
- Expected webhook workflow is missing.
- Execution history is older than expected.

Check:

```bash
ls -lh /mnt/backupshare/n8n/archive
ls -la /srv/docker/n8n
```

Confirm the selected archive date is the intended restore point.

### Webhook Path Fails But UI Works

Symptoms:

- Internal n8n UI loads.
- `address.kai.coach/api/wedding-address` fails.

Check:

- The expected webhook workflow exists.
- The workflow is active if it should receive live submissions.
- Caddy route for `address.kai.coach/api/wedding-address` still proxies internally to `n8n:5678`.
- Public `address.kai.coach` DNS still points to the WAN IP.

### UI Is Publicly Reachable

This is not the intended access model.

Expected:

- `n8n.kai.coach` is internal/private only.
- Public Porkbun DNS for `n8n.kai.coach` should not resolve.
- Internal Pi-hole DNS should resolve `n8n.kai.coach` to `100.77.136.106`.

If public access is observed, treat it as an exposure issue and review DNS and Caddy routing before continuing normal operation.
