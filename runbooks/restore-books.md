# Restore Books Stack

## Purpose And Scope

This planning-level runbook describes the intended recovery shape for the active `books` Compose project on `server`. The stack contains Calibre Web Automated and Shelfmark.

No books backup design or tested restore procedure exists yet. Do not treat this document as authorization to restore production data. The commands below are preservation-oriented placeholders for a future reviewed procedure.

## What The Stack Contains

- `calibre-web-automated` for managing and serving the Calibre library.
- `shelfmark` for searching and viewing books.
- A project-local Docker network named `books_default`.
- The external Docker network named `proxy` for the existing internal Caddy routes.
- Direct Tailscale-bound ports `100.77.136.106:8083` and `100.77.136.106:8084`.

Required paths:

- `/srv/docker/books`
- `/srv/docker/books/calibre-web-automated/config`
- `/srv/docker/books/shelfmark/config`
- `/mnt/media/books/library`
- `/mnt/media/books/ingest`

Persistent data classes:

- Calibre Web Automated configuration and databases.
- Shelfmark configuration, users, covers, plugins, and generated secrets.
- The canonical book library under `/mnt/media/books/library`.
- The shared ingest workflow under `/mnt/media/books/ingest`.

Shelfmark currently has writable access to `/mnt/media` at `/media`. This broad mount is preserved from the audit. Whether it can be narrowed is a separate, later review and must not be changed during recovery without testing.

## What Is Recoverable From The Repository

The repository contains:

- The audited Compose topology in `compose/books/compose.yaml`.
- A non-secret environment schema in `compose/books/.env.example`.
- Existing Caddy routes for `books.kai.coach` and `shelf.kai.coach` in the tracked Caddy source; both use internal TLS.
- Inventory of the services, routes, ports, and media paths.

The repository can recreate service definitions and directory layout. It cannot recreate application state or media payloads.

The audit found no live `/srv/docker/books/.env`. The repo example exists only because declared values were not captured; it is a verification schema for a future repo-defined deployment, not a copy of live configuration.

## What Is Not Yet Recoverable

Until a reviewed backup design exists, the following are not proven recoverable:

- Calibre Web Automated databases, settings, and generated application state.
- Shelfmark users, databases, covers, plugins, secrets, and settings.
- Book library contents.
- In-flight ingest contents and workflow state.
- Exact ownership and permissions required by restored application data.

No books backup script exists. No books backup was found by the audit, and no restore has been tested.

## Important Warnings

- Do not commit either runtime `/config` tree or any part of the media library/ingest payload.
- Do not commit databases, settings containing identities or credentials, generated secrets, keys, covers, plugins, logs, caches, thumbnails, conversion files, or queues.
- Do not infer application data from `.env.example`; it contains examples, not audited live values.
- Do not start the stack until `/mnt/media` and the required books paths are confirmed mounted. An absent media mount can redirect writes to the host root filesystem.
- Do not narrow Shelfmark's `/mnt/media` mount, remove direct Tailscale ports, change Caddy, or change image tags as part of a restore.

## Restore Assumptions

- The human owner has approved a specific restore point from a future protected backup.
- The backup format and application-consistency method have been documented and tested before use.
- `/mnt/media` is mounted and contains the intended books library and ingest paths.
- The external `proxy` network exists.
- Non-secret environment settings have been verified against approved operational evidence. `SEARCH_MODE` must not remain `REPLACE_ME`.
- Secret-bearing application files will come only from the approved protected backup, never Git.
- Current production directories will be preserved until validation is complete.

## Placeholder Restore Procedure

### 1. Preflight

Confirm the required mounts and paths without printing sensitive contents:

```bash
mountpoint /mnt/media
test -d /mnt/media/books/library
test -d /mnt/media/books/ingest
test -f ~/homelab/compose/books/compose.yaml
```

Confirm that the selected future backup has passed its documented integrity and application-consistency checks. Those checks are not defined yet; stop here until the backup design supplies them.

### 2. Stop And Preserve Existing State

After human approval and once a tested backup exists, stop the existing books stack using the approved operational procedure. Preserve the current stack directory with a timestamp instead of overwriting it:

```bash
RESTORE_TS=$(date +%F-%H%M%S)
if [ -d /srv/docker/books ]; then
  mv /srv/docker/books "/srv/docker/books.restore-old-$RESTORE_TS"
fi
mkdir -p /srv/docker/books
```

Keep the preserved directory until application data, routes, and ingest behavior are validated.

### 3. Restore Repository-Managed Files

Copy the reviewed Compose definition into the new stack directory:

```bash
cp ~/homelab/compose/books/compose.yaml /srv/docker/books/compose.yaml
```

Create a local `/srv/docker/books/.env` only from verified non-secret operational settings. Do not copy `REPLACE_ME`, and do not add application-generated secrets to this file.

### 4. Restore Protected Application State

Placeholder only: restore each config tree from the future approved backup into its matching path:

- Calibre Web Automated state to `/srv/docker/books/calibre-web-automated/config`.
- Shelfmark state to `/srv/docker/books/shelfmark/config`.

Restore the book library and any approved ingest content according to the future media-backup design. Do not guess archive names, extraction commands, database steps, ownership, or permissions before that design is tested.

### 5. Start In Dependency-Aware Order

The audited stack has no declared inter-service dependency. Once files, mounts, settings, networks, ownership, and permissions have passed the future preflight, start the Compose project using the approved operational procedure.

## Validation Checklist

- [ ] Both `calibre-web-automated` and `shelfmark` containers are running and healthy.
- [ ] `books.kai.coach` is reachable from an intended internal client and uses the expected internal TLS trust path.
- [ ] `shelf.kai.coach` is reachable from an intended internal client and uses the expected internal TLS trust path.
- [ ] Direct Tailscale endpoints on ports `8083` and `8084` are reachable if the human still intends them.
- [ ] The existing public internet does not become an assumed or newly enabled access path.
- [ ] Calibre Web Automated sees the expected library.
- [ ] The shared ingest workflow accepts and processes a non-sensitive test item as intended.
- [ ] Shelfmark can search for and view a non-sensitive test book.
- [ ] Existing users and settings are present without printing sensitive values.
- [ ] Container logs show no database, permission, mount, or internal-proxy errors.

## Rollback Placeholder

If validation fails, stop the restored stack, preserve the failed restore with a new timestamp, and move the previously preserved directory back into place. Do not delete either copy until the failure is understood.

Any rollback involving database or media changes must follow the future application-consistent backup design. Moving directories alone may not reverse writes made to `/mnt/media/books/library` or `/mnt/media/books/ingest`.

## Backup Gap

Backup design is pending. A future design must define:

- Application-consistent capture of both config/database trees.
- Whether applications must be stopped and in what order.
- Coverage and retention for the canonical library and in-flight ingest content.
- Secure handling of Shelfmark secrets and all user/application databases.
- Archive integrity checks, ownership/permission restoration, scheduling, retention, and backup-freshness reporting.
- A lab-tested restore procedure and recorded result before this runbook is considered operational.

Do not create or deploy a backup script until those decisions have human approval.

## Security And Sensitivity Notes

- Treat the book library, user data, application databases, generated secrets, and both config directories as sensitive.
- Keep runtime state, media, credentials, keys, tokens, cookies, plugins, covers, logs, and caches out of Git.
- The direct ports are bound to the audited Tailscale address; do not broaden them during recovery.
- The Caddy routes use internal TLS and must not be described as public based on route presence alone.
- Shelfmark's broad writable `/mnt/media` mount is intentional current state but deserves a separate least-scope review after recovery is proven.
- Floating image tags are preserved from the audit; version policy is a separate reviewed task.
