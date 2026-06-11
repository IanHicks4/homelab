# Restore Authelia

## Goal

Restore Authelia after a rebuild, failed update, configuration loss, Redis data loss, or damaged persistent data.

This runbook is based on:

- `scripts/backups/backup-authelia.sh`
- `compose/authelia/compose.yaml`

## Important Warnings

- Authelia protects internal services and should remain internal/private.
- Do not paste secret values, passwords, tokens, session material, encryption keys, or identity-provider secrets into this runbook or tickets.
- `config/.env` is sensitive and must not be committed to Git.
- The files `secrets/jwt_secret`, `secrets/session_secret`, and `secrets/storage_encryption_key` must be restored exactly from backup. Changing them can invalidate sessions, reset-token signing, or encrypted storage data.
- The secrets directory is mounted read-only into the Authelia container at `/secrets`.
- Redis data may contain live session state. Restoring an older Redis snapshot can invalidate active sessions.

## Prerequisites

Verify the backup share is mounted:

```bash
mountpoint /mnt/backupshare
```

Verify Authelia backups exist:

```bash
ls -lh /mnt/backupshare/authelia/archive
```

Expected archive name:

```bash
authelia-YYYY-MM-DD.tar.gz
```

Verify the compose file exists in the repo:

```bash
ls -lh compose/authelia/compose.yaml
```

Verify the current persistent path if it exists:

```bash
ls -la /srv/docker/authelia
```

The backup script is designed to run with enough filesystem permission to read Authelia secrets and Redis data. Restore work also needs permission to write `/srv/docker/authelia`.

## Paths And Layout

Persistent data root:

```bash
/srv/docker/authelia
```

Expected restored subdirectories:

```bash
/srv/docker/authelia/config
/srv/docker/authelia/secrets
/srv/docker/authelia/redis
```

Important secret files:

```bash
/srv/docker/authelia/secrets/jwt_secret
/srv/docker/authelia/secrets/session_secret
/srv/docker/authelia/secrets/storage_encryption_key
```

Sensitive environment file:

```bash
/srv/docker/authelia/config/.env
```

Containers:

```bash
authelia
authelia-redis
```

## Restore Steps

Stop Authelia before restoring:

```bash
docker stop authelia
docker stop authelia-redis
```

Create a rollback archive of the current data if it exists:

```bash
mkdir -p /srv/docker/_restore-rollback/authelia
tar -czf /srv/docker/_restore-rollback/authelia/authelia-pre-restore-$(date +%F-%H%M%S).tar.gz -C /srv/docker/authelia .
```

Move the current data aside:

```bash
mv /srv/docker/authelia /srv/docker/authelia.restore-old-$(date +%F-%H%M%S)
mkdir -p /srv/docker/authelia
```

Restore the selected backup archive:

```bash
tar -xzf /mnt/backupshare/authelia/archive/authelia-YYYY-MM-DD.tar.gz -C /srv/docker/authelia
```

Verify required files and directories were restored:

```bash
ls -la /srv/docker/authelia
ls -la /srv/docker/authelia/config
ls -la /srv/docker/authelia/secrets
ls -la /srv/docker/authelia/redis
```

Verify the required secret files exist without printing their contents:

```bash
test -s /srv/docker/authelia/secrets/jwt_secret
test -s /srv/docker/authelia/secrets/session_secret
test -s /srv/docker/authelia/secrets/storage_encryption_key
```

Verify `config/.env` exists if the live configuration expects it:

```bash
test -f /srv/docker/authelia/config/.env
```

Do not commit `config/.env` or any file from `secrets/` to Git.

Start Authelia and Redis from the compose directory:

```bash
cd compose/authelia
docker compose up -d
```

## Validation Steps

Verify both containers are running:

```bash
docker ps --filter name=authelia
docker ps --filter name=authelia-redis
```

Check container health and status:

```bash
docker inspect --format '{{.Name}} {{.State.Status}} {{if .State.Health}}{{.State.Health.Status}}{{else}}no-healthcheck{{end}}' authelia
docker inspect --format '{{.Name}} {{.State.Status}} {{if .State.Health}}{{.State.Health.Status}}{{else}}no-healthcheck{{end}}' authelia-redis
```

Expected:

- `authelia` status is `running`.
- `authelia-redis` status is `running`.
- If a healthcheck is present, it reports `healthy`.
- If no healthcheck is defined, the command reports `no-healthcheck`; then use logs and functional tests.

Check logs without exposing secrets:

```bash
docker logs authelia --tail 100
docker logs authelia-redis --tail 100
```

Expected:

- Authelia starts without configuration parsing errors.
- Authelia can connect to Redis.
- No missing secret-file errors.
- No storage encryption key errors.
- Redis starts without persistence or permission errors.

Validate the internal/private route from a trusted internal client:

```bash
curl -I https://auth.kai.coach
```

Expected:

- `auth.kai.coach` resolves only through internal DNS.
- Public DNS should not resolve `auth.kai.coach`.
- The route remains internal/private.

Validate dependent protected routes from a trusted internal client:

- `home.kai.coach`
- `status.kai.coach`
- `grafana.kai.coach`

Expected:

- Protected routes still redirect to or consult Authelia as intended.
- Login works for expected users.
- Existing sessions may be invalidated if Redis was restored from an older snapshot, but new login should work.

## Rollback Steps

If Authelia fails after restore, stop both containers:

```bash
docker stop authelia
docker stop authelia-redis
```

Move the failed restore aside:

```bash
mv /srv/docker/authelia /srv/docker/authelia.failed-restore-$(date +%F-%H%M%S)
mkdir -p /srv/docker/authelia
```

Restore the pre-restore rollback archive:

```bash
tar -xzf /srv/docker/_restore-rollback/authelia/authelia-pre-restore-YYYY-MM-DD-HHMMSS.tar.gz -C /srv/docker/authelia
```

Start the stack again:

```bash
cd compose/authelia
docker compose up -d
```

Validate both containers again:

```bash
docker ps --filter name=authelia
docker ps --filter name=authelia-redis
docker logs authelia --tail 100
docker logs authelia-redis --tail 100
```

If rollback also fails, keep the failed restore and rollback data directories intact for analysis. Do not delete restored config, Redis data, or secret files until the cause is understood.

## Common Issues

### Missing Secret Files

Symptoms:

- Authelia exits during startup.
- Logs mention missing `jwt_secret`, `session_secret`, or `storage_encryption_key`.

Check:

```bash
test -s /srv/docker/authelia/secrets/jwt_secret
test -s /srv/docker/authelia/secrets/session_secret
test -s /srv/docker/authelia/secrets/storage_encryption_key
```

Fix:

- Restore the missing files exactly from backup.
- Do not regenerate these files during restore unless intentionally rebuilding Authelia state.
- Do not print the file contents in shell history, logs, tickets, or chat.

### Storage Encryption Errors

Symptoms:

- Authelia starts but cannot read existing storage data.
- Logs mention storage encryption or decryption failures.

Likely cause:

- `secrets/storage_encryption_key` does not match the key used by the restored data.

Fix:

- Restore the exact `secrets/storage_encryption_key` from the same backup set as the Authelia config and data.

### Login Or Session Problems

Symptoms:

- Users are forced to log in again.
- Existing sessions disappear.
- Redis logs show missing or replaced data.

Notes:

- Redis data is restored from `/srv/docker/authelia/redis`.
- Restoring an older Redis snapshot can invalidate active sessions.
- New login should still work if Authelia config, Redis, and secret files are correct.

### Sensitive Config Accidentally Staged

Check Git status before committing:

```bash
git status --short
```

Expected:

- No `compose/authelia/config/.env`, `/srv/docker/authelia/config/.env`, or `secrets/` files are staged or committed.

If sensitive files appear in Git status, stop and remove them from the index before committing. Do not paste their contents anywhere.
