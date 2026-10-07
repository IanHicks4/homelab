# Restore Paperless-ngx

## Purpose And Scope

Restore the internal/private Paperless-ngx document-management service after a host rebuild, failed update, database loss, or damaged application files.

Paperless is highly sensitive. It may contain scanned documents, uploaded files, OCR text, document metadata, tags, correspondents, and identity, financial, legal, personal, or project records. Treat every archive, dump, log, and restored directory as private data.

This runbook covers the repository-defined services:

- `paperless-ngx`: application and OCR/document management
- `db`: PostgreSQL
- `broker`: persistent Valkey broker
- Restore target: `/srv/docker/paperless`
- Backup script: `scripts/backups/backup-paperless.sh`

This runbook is **not restore-tested**. Do not claim recovery readiness until a restore has been completed in an authorized non-production environment.

## What Is Backed Up

The backup script creates three private, date-matched artifacts.

Application state:

```text
/mnt/backupshare/paperless/archive/paperless-YYYY-MM-DD.tar.gz
```

Contains:

- `compose.yaml`
- Production `.env`
- `data/`
- `media/`
- `export/`
- `consume/`

PostgreSQL logical dump:

```text
/mnt/backupshare/paperless/postgres/paperless-postgres-YYYY-MM-DD.sql.gz
```

Valkey persistence:

```text
/mnt/backupshare/paperless/redis/paperless-redis-YYYY-MM-DD.tar.gz
```

The application is stopped before the PostgreSQL dump and file archive. The broker is stopped before archiving `valkey/`. Temporary files are validated and renamed to their final names only after successful creation.

## What Is Not Backed Up

- Raw live `postgres/` files; the logical PostgreSQL dump is the database restore source.
- The backup script itself.
- Docker images, containers, networks, and host packages.
- Caddy configuration and internal DNS.
- Files outside `/srv/docker/paperless`.
- Backup scheduling and the node-exporter backup-freshness metric producer.

## Prerequisites

- A Docker Compose host with permission to manage containers and write under `/srv/docker`.
- `/mnt/backupshare` mounted.
- Matching application, PostgreSQL, and Valkey artifacts from the same date.
- Enough free space for the restored service and a complete rollback copy.
- The external Docker network named `proxy`, if the restored Compose definition still requires it.
- Internal DNS and any Caddy route restored separately if required.

Verify the share and select one date without displaying archive contents:

```bash
mountpoint /mnt/backupshare
ls -lh /mnt/backupshare/paperless/archive/
ls -lh /mnt/backupshare/paperless/postgres/
ls -lh /mnt/backupshare/paperless/redis/
```

Check all three selected artifacts:

```bash
gzip -t /mnt/backupshare/paperless/archive/paperless-YYYY-MM-DD.tar.gz
tar -tzf /mnt/backupshare/paperless/archive/paperless-YYYY-MM-DD.tar.gz >/dev/null
gzip -t /mnt/backupshare/paperless/postgres/paperless-postgres-YYYY-MM-DD.sql.gz
gzip -t /mnt/backupshare/paperless/redis/paperless-redis-YYYY-MM-DD.tar.gz
tar -tzf /mnt/backupshare/paperless/redis/paperless-redis-YYYY-MM-DD.tar.gz >/dev/null
```

Stop if any integrity check fails. Do not print `.env`, SQL, OCR, or document content.

## Restore Assumptions

- The restore target is `/srv/docker/paperless`.
- The selected artifacts use the same `YYYY-MM-DD` date.
- The restored Compose service keys remain `paperless-ngx`, `db`, and `broker`.
- PostgreSQL credentials are supplied by the restored `.env` and read inside the database container.
- PostgreSQL initializes a new `/srv/docker/paperless/postgres` directory before the logical dump is loaded.
- The archive preserves the application files needed by Paperless; the Valkey archive separately restores `valkey/`.
- Compose publishes no direct host port. `PAPERLESS_URL` is configured as `https://paperless.kai.coach`, but no matching checked-in Caddy route was found.

## Restore Procedure

### 1. Stop The Existing Stack

If the existing Compose file is usable:

```bash
cd /srv/docker/paperless
docker compose down
```

Do not use `docker compose down -v` and do not delete local data.

### 2. Preserve The Existing Directory

Record one timestamp and move the complete service tree aside:

```bash
RESTORE_TS=$(date +%F-%H%M%S)
mv /srv/docker/paperless "/srv/docker/paperless.restore-old-$RESTORE_TS"
mkdir -p /srv/docker/paperless
```

Do not delete the preserved directory until the restore and a subsequent backup have been validated.

### 3. Restore Application Files And Valkey State

Extract both archives into the new service root:

```bash
tar -xzf /mnt/backupshare/paperless/archive/paperless-YYYY-MM-DD.tar.gz \
    -C /srv/docker/paperless
tar -xzf /mnt/backupshare/paperless/redis/paperless-redis-YYYY-MM-DD.tar.gz \
    -C /srv/docker/paperless
```

Verify required paths without reading `.env`:

```bash
test -f /srv/docker/paperless/compose.yaml
test -f /srv/docker/paperless/.env
test -d /srv/docker/paperless/data
test -d /srv/docker/paperless/media
test -d /srv/docker/paperless/export
test -d /srv/docker/paperless/consume
test -d /srv/docker/paperless/valkey
test ! -e /srv/docker/paperless/postgres
```

Create an empty database bind-mount directory:

```bash
mkdir -p /srv/docker/paperless/postgres
```

Run extraction and directory creation as the administrative account used by the deployment. Tar should preserve archived numeric ownership and modes. The Compose definition maps Paperless application files to UID/GID `1000`, but do not recursively apply that ownership to `postgres/` or `valkey/`; those images may require different ownership. Resolve permission errors from the deployed image requirements rather than guessing broad ownership changes.

### 4. Validate Compose Without Printing Secrets

List only service names:

```bash
cd /srv/docker/paperless
docker compose config --services
```

Expected service keys:

```text
broker
db
paperless-ngx
```

Do not print the fully rendered Compose configuration because it may contain interpolated secret values.

### 5. Initialize PostgreSQL

Start only the database service:

```bash
cd /srv/docker/paperless
docker compose up -d db
```

Wait for the configured database to accept connections:

```bash
until docker compose exec -T db sh -c 'pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB"'; do
    sleep 2
done
```

### 6. Restore PostgreSQL

Load the logical dump into the newly initialized configured database:

```bash
set -o pipefail
gunzip -c /mnt/backupshare/paperless/postgres/paperless-postgres-YYYY-MM-DD.sql.gz \
    | docker compose exec -T db sh -c 'psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" "$POSTGRES_DB"'
```

Stop if `psql` reports an error. Confirm PostgreSQL is still ready:

```bash
docker compose exec -T db sh -c 'pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB"'
```

### 7. Start Broker And Paperless

Start the remaining services from `/srv/docker/paperless`:

```bash
docker compose up -d broker
docker compose up -d paperless-ngx
```

## Validation Checklist

- All selected archive and gzip integrity checks pass.
- `db`, `broker`, and `paperless-ngx` are running and not restarting repeatedly.
- PostgreSQL readiness succeeds and logs show no database restore or migration failure.
- The Paperless web UI is reachable through the intended internal/private path.
- An existing user can log in.
- Existing documents, metadata, tags, and correspondents are visible.
- A representative document opens successfully.
- OCR text and search return expected results for a known document.
- The consume workflow successfully imports a non-sensitive test document.
- `https://paperless.kai.coach` works through Caddy/internal routing if that route is configured operationally.
- No direct host port or unintended public exposure was introduced.
- A new backup is not scheduled or claimed healthy until the restored service is accepted.

## Rollback

Stop the failed restored stack:

```bash
cd /srv/docker/paperless
docker compose down
```

Move it aside and restore the directory preserved earlier, substituting the recorded timestamp:

```bash
mv /srv/docker/paperless "/srv/docker/paperless.failed-restore-$(date +%F-%H%M%S)"
mv /srv/docker/paperless.restore-old-YYYY-MM-DD-HHMMSS /srv/docker/paperless
```

Start the preserved stack with its original Compose procedure. Retain the failed restore for investigation until its sensitive contents can be securely removed through an explicitly approved cleanup.

## Security Notes

- Archives, dumps, `.env`, OCR text, metadata, logs, and rollback copies are sensitive.
- Use private permissions and protected storage/transport for every recovery artifact.
- Never print environment values, SQL, OCR text, or document contents during validation.
- Do not copy production records into Git, tickets, chat, or an untrusted test environment.
- Keep Paperless internal/private; recovery does not authorize public DNS or exposure.
- Verify the operational Caddy route and authentication model separately before enabling access.

## Restore-Test Status

This procedure is based on the checked-in Compose mounts and the artifacts created by `scripts/backups/backup-paperless.sh`. It has **not** been restore-tested. Record the date, selected artifacts, validation results, and any required corrections after the first authorized non-production restore test.
