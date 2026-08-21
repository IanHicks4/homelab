# Books Stack Review

Audit date: 2026-08-21  
Host: `server`  
Live stack: `/srv/docker/books`  
Scope: Read-only evidence gathering for later repository reconciliation

## 1. Executive summary

`/srv/docker/books` is an active two-service Docker Compose stack containing `calibre-web-automated` and `shelfmark`. Both containers were running and healthy at inspection time, use `restart: unless-stopped`, join the project-local `books_default` network and the external `proxy` network, and publish direct ports on `100.77.136.106` in addition to being routed through Caddy.

The Compose definition can be reconciled into the homelab repository, but the live configuration directories cannot. They contain databases, application secrets, user data, and generated state. No `/srv/docker/books/.env` file exists. The Compose-declared environment names are operational settings rather than secret references, but values were intentionally not recorded.

No books-related backup directory was found under `/mnt/backupshare` at the inspected depth, and no books-specific stack, backup script, or restore runbook was found in the repo. Before this stack is treated as recoverable, its config databases, book library, ingest workflow, and application-generated secrets need a reviewed backup/restore design.

## 2. Commands run

All commands were read-only, with structured output restricted to approved metadata. Environment values and sensitive file contents were never printed.

- `find /srv/docker/books -mindepth 1 -maxdepth 3 -printf ...` — filenames and directory structure only.
- `test -f /srv/docker/books/.env` — existence check only.
- `stat -c ...` — ownership and mode for the stack, Compose file, config directories, and media paths.
- `find /mnt/backupshare ... -iname '*book*'` and a case-insensitive books-name filter — directory names only.
- `docker compose -f /srv/docker/books/compose.yaml config --format json | jq ...` — services, images, ports, volume mappings, network names, restart policy, and environment variable names; values omitted.
- `docker inspect calibre-web-automated shelfmark | jq ...` — selected runtime metadata; environment values omitted.
- `docker ps --filter ... --format ...` — names, images, status, ports, and Compose project.
- `awk` against `/srv/docker/caddy/Caddyfile` — only the two books route blocks, with query-string redaction enforced.
- `find /home/server/homelab -maxdepth 4 -iname '*book*'` — repo path names only.

## 3. Live files and directories found

Stack definition:

- `/srv/docker/books/compose.yaml` — root-owned, mode `0644`.
- `/srv/docker/books/.env` — not present.

Persistent directories:

- `/srv/docker/books/calibre-web-automated/config`
- `/srv/docker/books/calibre-web-automated/config/.cache`
- `/srv/docker/books/calibre-web-automated/config/.config`
- `/srv/docker/books/calibre-web-automated/config/.cwa_conversion_tmp`
- `/srv/docker/books/calibre-web-automated/config/.cwa_migrations`
- `/srv/docker/books/calibre-web-automated/config/log_archive`
- `/srv/docker/books/calibre-web-automated/config/processed_books`
- `/srv/docker/books/calibre-web-automated/config/thumbnails`
- `/srv/docker/books/shelfmark/config`
- `/srv/docker/books/shelfmark/config/covers`
- `/srv/docker/books/shelfmark/config/plugins`

Sensitive or stateful filenames were observed but not opened. They include database files, a key file, a client-secrets file, user-profile/settings files, a Flask secret, generated status/queue files, and logs. Their presence confirms that these config trees are runtime state rather than repo-ready configuration.

Both service config directories are owned by `server:server` and mode `0775`. No file contents were inspected.

## 4. Compose services and images

| Service/container | Image | Runtime status | Restart policy |
|---|---|---|---|
| `calibre-web-automated` | `crocodilestick/calibre-web-automated:latest` | Running, healthy | `unless-stopped` |
| `shelfmark` | `ghcr.io/calibrain/shelfmark:latest` | Running, healthy | `unless-stopped` |

Both containers carry the Compose project label `books`. Both images use the floating `latest` tag, so a future rebuild may not reproduce the currently running image IDs. Image pinning should be evaluated during repo reconciliation, but no image pull or runtime change should be bundled into the initial source-of-truth capture.

## 5. Ports and exposure

| Service | Published endpoint | Container target |
|---|---|---|
| `calibre-web-automated` | `100.77.136.106:8083/tcp` | `8083/tcp` |
| `shelfmark` | `100.77.136.106:8084/tcp` | `8084/tcp` |

The host IP is specific rather than `0.0.0.0`, limiting direct reachability to the network associated with `100.77.136.106`. However, clients on that network can potentially reach the applications directly and bypass Caddy routing or any policy applied there. Firewall, DNS, and network membership were not evaluated, so this is an exposure observation rather than a conclusion about public access.

Both services also join the external `proxy` network, enabling Caddy to reach them by container name.

## 6. Volumes and persistent paths

All observed mounts are writable bind mounts.

### `calibre-web-automated`

- `/srv/docker/books/calibre-web-automated/config` → `/config`
- `/mnt/media/books/ingest` → `/cwa-book-ingest`
- `/mnt/media/books/library` → `/calibre-library`

### `shelfmark`

- `/srv/docker/books/shelfmark/config` → `/config`
- `/mnt/media/books/ingest` → `/books`
- `/mnt/media` → `/media`

The shared ingest path couples the services operationally. Shelfmark also receives writable access to all of `/mnt/media`, which is broader than the books subtree. That scope should be documented and reviewed during reconciliation; it must not be narrowed automatically because doing so could break existing behavior.

The media paths are owned by `server:server`. `/mnt/media/books` and `/mnt/media/books/library` are mode `0775`; `/mnt/media/books/ingest` is mode `0755`.

## 7. Env/secrets handling without values

No `/srv/docker/books/.env` file exists. Values were not copied from Compose or container metadata.

Compose-declared environment variable names:

- `calibre-web-automated`: `NETWORK_SHARE_MODE`, `PGID`, `PUID`, `TZ`
- `shelfmark`: `PGID`, `PUID`, `SEARCH_MODE`, `SESSION_COOKIE_SECURE`, `TZ`

Runtime metadata also contains image-provided environment names such as language, path, build/version, Python, and application-runtime settings. These image defaults do not all belong in a reconstructed Compose file; the repo should preserve only settings deliberately declared by the live Compose definition.

Application-generated secret-bearing files exist under the bind-mounted config directories. These must remain runtime data and must not be converted into Compose environment literals or committed as example values.

## 8. Caddy route relationship

The live Caddyfile contains two internal-TLS routes:

- `books.kai.coach` reverse-proxies to `calibre-web-automated:8083`.
- `shelf.kai.coach` reverse-proxies to `shelfmark:8084`.

These upstream names work because Caddy and both book services share the external `proxy` network. The routes use `tls internal`; clients need to trust the relevant internal CA. No authentication directive was present inside these two route blocks. The direct host-port bindings provide a second access path independent of these hostnames.

The repo already tracks both route names in `/home/server/homelab/configs/caddy/Caddyfile`, based on the preceding source-of-truth review. The future books-stack task should reference that canonical Caddy configuration rather than create another Caddy fragment or duplicate route definition.

## 9. Backup/restore implications

No books-related directory was found under `/mnt/backupshare` within the allowed directory-name inspection, and no live books backup script was found in `/srv/docker/books`.

A complete restore design must distinguish at least four state classes:

1. Calibre Web Automated configuration and its databases under `/srv/docker/books/calibre-web-automated/config`.
2. Shelfmark configuration, users database, covers, plugins, and application secret under `/srv/docker/books/shelfmark/config`.
3. The canonical book library under `/mnt/media/books/library`.
4. The shared ingest workflow under `/mnt/media/books/ingest`, including whether in-flight files require backup.

Copying live database files while applications are writing may not produce consistent backups. The correct application-aware snapshot or shutdown procedure needs product-specific review before a script is authored. Secret files should be backed up securely but never copied into Git or audit reports. Restore testing should verify permissions, database consistency, the internal-TLS routes, and the shared ingest/library mappings.

## 10. What should be added to the repo

Recommended repo reconciliation scope:

- `compose/books/compose.yaml`, sanitized and structurally equivalent to the live definition: two services, current images, container names if intentionally required, restart policies, bind-mount paths, direct bindings, project-local network, and external `proxy` network.
- Documentation of the declared environment variable names and how non-secret values should be supplied. If values are intentionally host-specific, use documented placeholders or an `.env.example` without live secrets.
- `runbooks/restore-books.md` covering prerequisites, expected paths and permissions, network requirements, restore ordering, validation, and rollback.
- A reviewed `scripts/backups/backup-books.sh` only after the data-consistency and retention design is agreed.
- Updates to service, port, storage, and domain inventories so the stack, direct ports, media paths, and both Caddy routes are discoverable.
- Ignore rules and explicit operator warnings that prevent live config directories, databases, keys, settings, user data, logs, covers, thumbnails, caches, and library content from entering Git.

The first repo capture should avoid unrelated production changes such as image upgrades, mount narrowing, port removal, or container renaming. Those are separate reviewed tasks.

## 11. What must not be committed

- The contents of either live `/config` tree.
- Database files and associated journal/WAL/shared-memory files.
- Key files, Flask/session secrets, OAuth or client-secret files, credentials, tokens, cookies, or generated application secrets.
- User profiles, user databases, application settings containing identities or credentials, or private plugin configuration.
- `/mnt/media/books/library`, `/mnt/media/books/ingest`, or any other media payload.
- Logs, caches, thumbnails, covers, conversion working files, migration state, retry queues, ingest status, or generated artifacts.
- Any future `.env` containing real values; only a deliberately sanitized `.env.example` is appropriate.
- Running-container image IDs as a substitute for an intentional image-version policy.

## 12. Recommended next Codex-lab task

Use a repo-only, review-first task with this scope:

> Reconcile the audited live books stack into `~/homelab` without changing production. Create a sanitized `compose/books/compose.yaml`, update the relevant service/port/storage/domain inventories, and draft `runbooks/restore-books.md`. Preserve the live service topology and paths. Do not copy runtime config, databases, media, credentials, keys, user data, or secret values. Treat backup-script design and any image pinning, port removal, mount narrowing, or live deployment as separate follow-up changes requiring human review.

Before merging, compare the sanitized Compose semantics against `/srv/docker/books/compose.yaml` using a value-redacted review and run repository secret checks. Do not deploy as part of that task.

## 13. No changes applied

No files under `/srv/docker` or `/home/server/homelab` were modified. No containers, images, networks, volumes, Caddy configuration, firewall rules, DNS records, backups, or schedules were changed. No `.env`, database, secret, key, user-data, media, or backup contents were printed or opened.

The only created file is this audit report: `/home/server/homelab-audits/books-stack-review/books-stack-review.md`.
