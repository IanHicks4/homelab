# Restore Vikunja

## Purpose And Scope

Restore the internal/private Vikunja task-management service after a host rebuild, failed update, database loss, or damaged application files.

This runbook covers:

- App container: `vikunja`
- Database container: `vikunja-db`
- Restore target: `/srv/docker/vikunja`
- Backup script: `scripts/backups/backup-vikunja.sh`

Vikunja is used for brain dumping, task breakdown, homelab/project organization, and possible future n8n/Ollama-assisted task extraction. Registration should remain disabled, and `vikunja.kai.coach` should remain internal/private.

## What Is Backed Up

PostgreSQL logical dumps are stored under:

```bash
/mnt/backupshare/vikunja/postgres/
```

Expected dump name:

```bash
vikunja-YYYY-MM-DD.sql.gz
```

App-state archives are stored under:

```bash
/mnt/backupshare/vikunja/archive/
```

Expected archive name:

```bash
vikunja-YYYY-MM-DD.tar.gz
```

The app-state archive contains:

- `compose.yaml`
- `.env`
- `files/`, including Vikunja files and attachments

## What Is Not Backed Up

- The raw live `/srv/docker/vikunja/db` directory is excluded. The PostgreSQL logical dump is the primary database restore method.
- Docker images, containers, networks, and host packages.
- Internal DNS and the Caddy route.
- External integrations or credentials not represented in the Vikunja database, `.env`, or files archive.
- Any external n8n/Ollama state.

## Prerequisites

- A Docker/Compose host with permission to manage containers and write under `/srv/docker`.
- `/mnt/backupshare` mounted.
- A selected PostgreSQL dump and matching app-state archive.
- Internal DNS and the Caddy route restored separately if required.
- Enough free space for the restored database, files, and rollback directory.

Verify the backup share and list candidates:

```bash
mountpoint /mnt/backupshare
ls -lh /mnt/backupshare/vikunja/postgres/
ls -lh /mnt/backupshare/vikunja/archive/
```

Select matching backup dates unless there is a documented reason to combine dates:

```bash
ls -lh /mnt/backupshare/vikunja/postgres/vikunja-YYYY-MM-DD.sql.gz
ls -lh /mnt/backupshare/vikunja/archive/vikunja-YYYY-MM-DD.tar.gz
```

## Restore Assumptions

- The restore target is `/srv/docker/vikunja`.
- The restored Compose file creates containers named `vikunja` and `vikunja-db`.
- The database service key is expected to be `vikunja-db`; verify it with `docker compose config --services` after extracting the archive.
- PostgreSQL credentials and database settings are restored from the archived `.env`.
- The database starts with a new `/srv/docker/vikunja/db` directory; raw database files are not restored.
- The internal Caddy route is `vikunja.kai.coach`, uses `tls internal`, and proxies to `vikunja:3456`.

Do not display or paste `.env` contents during the restore.

## Restore Procedure

### 1. Stop The Existing Stack

If the existing stack directory and Compose file are present:

```bash
cd /srv/docker/vikunja
docker compose down
```

If Compose cannot be used, stop the known containers without deleting production data:

```bash
docker stop vikunja vikunja-db
```

### 2. Preserve The Existing Directory

Record one timestamp and use it consistently:

```bash
RESTORE_TS=$(date +%F-%H%M%S)
mv /srv/docker/vikunja "/srv/docker/vikunja.restore-old-$RESTORE_TS"
mkdir -p /srv/docker/vikunja
```

Do not delete the preserved directory until the restore has been validated.

### 3. Extract The App-State Archive

```bash
tar -xzf /mnt/backupshare/vikunja/archive/vikunja-YYYY-MM-DD.tar.gz \
    -C /srv/docker/vikunja
```

Verify required paths without printing `.env`:

```bash
test -f /srv/docker/vikunja/compose.yaml
test -f /srv/docker/vikunja/.env
test -d /srv/docker/vikunja/files
test ! -e /srv/docker/vikunja/db
```

Inspect the service names:

```bash
cd /srv/docker/vikunja
docker compose config --services
```

The following commands assume the database service key is `vikunja-db`. If the Compose service key differs, substitute the verified database service key while retaining the `vikunja-db` container name.

### 4. Start PostgreSQL Only

```bash
cd /srv/docker/vikunja
docker compose up -d vikunja-db
```

Do not start the Vikunja app until the database restore is complete.

### 5. Wait For PostgreSQL Readiness

```bash
until docker exec vikunja-db sh -c 'pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB"'; do
    sleep 2
done
```

This reads credentials inside the container and does not print their values.

### 6. Restore The PostgreSQL Dump

Restore the compressed `pg_dumpall` output through the PostgreSQL container:

```bash
set -o pipefail
gunzip -c /mnt/backupshare/vikunja/postgres/vikunja-YYYY-MM-DD.sql.gz \
    | docker exec -i vikunja-db sh -c 'psql -U "$POSTGRES_USER" -d postgres'
```

Review the restore output for failures. A `pg_dumpall` restore into a newly initialized PostgreSQL container may report that the bootstrap role or database already exists; do not dismiss other errors. If the restore stops early or reports schema/data failures, leave the preserved old directory intact and investigate before starting Vikunja.

Verify PostgreSQL remains ready:

```bash
docker exec vikunja-db sh -c 'pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB"'
```

### 7. Start Vikunja

```bash
cd /srv/docker/vikunja
docker compose up -d
```

## Validation

Verify both containers:

```bash
docker ps --filter name=vikunja
docker logs vikunja-db --tail 100
docker logs vikunja --tail 100
```

Expected:

- `vikunja-db` is running and ready.
- `vikunja` is running without repeated database or migration errors.
- Neither container is in a restart loop.

From a trusted internal client, verify the internal route:

```bash
curl -I https://vikunja.kai.coach
```

Confirm:

- The internal CA/TLS behavior is expected for `tls internal`.
- The login page loads only through the intended private/internal path.
- Existing login works.
- Registration remains disabled.
- Expected tasks, projects, and attachments are visible.
- A representative attachment can be opened.

Do not expose the route publicly as part of recovery.

## Rollback

If validation fails, stop the restored stack:

```bash
cd /srv/docker/vikunja
docker compose down
```

Move the failed restore aside:

```bash
mv /srv/docker/vikunja /srv/docker/vikunja.failed-restore-$(date +%F-%H%M%S)
```

Move the preserved directory back:

```bash
mv /srv/docker/vikunja.restore-old-YYYY-MM-DD-HHMMSS /srv/docker/vikunja
```

Start the previous stack:

```bash
cd /srv/docker/vikunja
docker compose up -d
```

Re-run the container, route, login, task/project, and attachment validation checks. Keep the failed restore directory until the failure is understood.

## Security And Sensitivity Notes

- Backups contain task/project data, `.env`, a full database dump, and files/attachments.
- Treat both backup sets as sensitive.
- Do not print or copy secret values into tickets, shell history, or documentation.
- Do not commit archives, SQL dumps, `.env`, raw database data, or extracted backup directories.
- Keep `vikunja.kai.coach` internal/private; do not add public DNS or public exposure during restore.
- Registration should remain disabled after restore.

## Known Limitations And Verification Items

- Backup scheduling is not proven by repository evidence and needs verification on the host.
- The checked-in Caddyfile did not contain the provided Vikunja route at review time; the route is a human-provided runtime fact and must be restored/verified separately.
- External integrations not stored in the database, `.env`, or files archive require separate recovery.
