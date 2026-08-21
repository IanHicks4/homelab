# Homelab Repository Health Review

Review date: 2026-08-21  
Scope: repository evidence only; no live-system inspection or changes

## 1. Executive summary

The repository is healthier than a typical informal homelab repository. Services are generally separated into one Compose directory per stack, sensitive values are represented by environment variables or secret-file references, most stateful Docker stacks have both a backup script and a restore runbook, and the Codex/change-control documents set sensible boundaries between repository work and production. The internal/Tailscale-first design is visible in Tailscale-bound ports, localhost-bound monitoring ports, container-only databases, internal Caddy TLS routes, and a short intentional list of public services.

The main risk is not missing documentation; it is conflicting or partially stale documentation. Two Caddyfiles differ, the short inventory files lag the comprehensive service inventory, and `docs/service-inventory.md` contains a stale statement that the now-present Vikunja Compose stack is absent. Caddy and Homepage reference Calibre/Shelfmark, but those services have no Compose, inventory, backup, or restore representation. The wedding form declares an `html/` bind mount whose content is not tracked. These discrepancies weaken the repository as a recovery source.

Backup breadth is good, but reliability is uneven. Most current scripts stop stateful services, verify the backup share, retain archives, and use an exit trap to restart containers. The Vaultwarden script lacks the mountpoint guard used by most peers, two older top-level backup scripts duplicate newer scripts, archives generally have no integrity manifest, and there is no repository evidence of scheduling or restore tests. Several standardized restore runbooks use relative `cd compose/<stack>` fallback commands that are unlikely to work from the documented recovery location. The older Immich, Caddy, and Vaultwarden runbooks also contain stale names, ports, exposure assumptions, or less-safe restore patterns.

Security choices are mostly pragmatic and consistent with the stated priorities. Docker socket and broad host mounts are real high-trust risks, but they are documented and attached to internal monitoring/dashboard functions. Gluetun's `NET_ADMIN` and TUN access are expected for its purpose. The more immediate security work is to keep these services private, make ignored runtime paths more explicit, avoid emitting possible values from repository helper scripts, and resolve the intent of the public address-form webhook and unexplained `mc` DDNS entry. The known historical WireGuard credential is history-only and mitigated by rotation; current `HEAD` uses a placeholder. The Immich background URL is also placeholder-backed in current `HEAD`.

The recommended strategy is incremental: repair documentation and recovery-command correctness now; establish tested backup/restore evidence, a canonical exposure matrix, and controlled image-update policy next; consider socket isolation and more configuration-as-code only later. Avoid a broad platform migration, blanket CIS remediation, blanket proxy authentication, or unattended container updating.

## 2. Files and areas inspected

The review covered the complete tracked repository tree at the level appropriate to each artifact:

- Root: `.gitignore`, `README.md`, `CHANGELOG.md`, working-tree state, recent history, and visible local/remote branch metadata.
- `compose/`: all stack Compose files for Arr/Recyclarr, Authelia, Caddy, DDNS, Homepage/Glances/Uptime Kuma, Immich, IT Tools, Jellyfin, logging, monitoring, n8n, Speedtest Tracker, Vaultwarden, Vikunja, VPN/qBittorrent, and the wedding form; all example environment schemas and Recyclarr configuration/state mappings.
- `configs/`: both Caddyfile copies, all Homepage YAML/CSS/JS configuration, Immich configuration, Alloy, Loki, and Prometheus configuration.
- `docs/`: alerting, service inventory, media-profile review and decisions, P360 notes, Codex workflow, change control, PR review checklist, and secret-history review.
- `inventory/`: hardware, IP, storage, port, domain, and service summaries; the point-in-time Sonarr/Radarr export set was assessed for purpose, structure, scale, and repository impact rather than re-litigating every media-profile record already analyzed in the dedicated reviews.
- `runbooks/`: every update, rebuild, troubleshooting, media-drive, and stack restore runbook; command paths, preservation/rollback patterns, validation assumptions, and matching backup names were compared.
- `scripts/`: every backup script plus repository drift and secret-check helpers.

No Docker command, `sudo`, SSH, service API, live host path, or `/srv/docker` access was used.

## 3. Repository structure assessment

### What is working well

- The `compose/`, `configs/`, `docs/`, `inventory/`, `runbooks/`, and `scripts/` split is understandable.
- Compose stacks are consistently grouped by stack name, and the shared external `proxy` network pattern is easy to recognize.
- Restore material is discoverable by the `restore-<stack>.md` naming convention; current backup scripts are similarly grouped under `scripts/backups/`.
- Dedicated documents exist for security-sensitive workflow, change control, PR review, alerting, service inventory, and media-profile decisions.
- Retired OnlyOffice and Gamebuilds services are excluded from active Compose content and are explicitly listed as retired in `docs/service-inventory.md`.

### Structural weaknesses

- `README.md` advertises `diagrams/` and `backups/` directories that do not exist, while it does not point readers to `scripts/backups/` or the authoritative `docs/service-inventory.md`.
- `compose/caddy/Caddyfile` is the file mounted by `compose/caddy/compose.yaml`, but `configs/caddy/Caddyfile` has two additional internal routes. `scripts/check_repo_drift.sh` compares the latter to the live Caddyfile. The repository therefore has two plausible sources of truth.
- `scripts/backup-immich.sh` and `scripts/backup-vault.sh` duplicate scripts under `scripts/backups/`; the older copies omit safeguards present in at least some newer scripts. `runbooks/docker-updates.md` still invokes the top-level copies.
- The empty `CHANGELOG.md`, empty Homepage `custom.js`, sample `kubernetes.yaml`, and two short P360 day notes add navigation noise unless their intended role is documented.
- Generated Recyclarr state and large point-in-time media exports are mixed with hand-maintained configuration. They are useful audit evidence but need a retention/refresh convention.

Roadmap items N1, N4, N8, and L3 address these findings.

## 4. Service inventory and documentation assessment

`docs/service-inventory.md` is the strongest inventory artifact. It uses a useful evidence model, distinguishes a configured route from proven public exposure, records sensitive-state and backup implications, and documents accepted Docker-socket risk. Its backup/runbook tables accurately enumerate the files currently present.

It is not fully consistent with current repository content:

- The Vikunja detail section says no Vikunja Compose stack is present even though `compose/vikunja/compose.yaml` now exists.
- Several statements say runtime inspection confirmed services, DNS, mounts, or Docker socket use. Those may record prior human/runtime observations, but the document's own status model says it is repository-based. The evidence date and source should be explicit so these facts do not look perpetually current.
- Calibre Web Automated and Shelfmark appear in `configs/caddy/Caddyfile`; Calibre also appears in Homepage. Neither appears in the service tables, Compose tree, backup coverage, or restore coverage.
- `inventory/services.md` omits Authelia, IT Tools, logging, monitoring, n8n, Speedtest Tracker, Vikunja, wedding form, and the newer Caddy-referenced book services.
- `inventory/domains.md` omits the documented public wedding form and most internal routes. `inventory/ports.md` lists several application ports without interface classification and includes ports that are no longer published by Compose.
- DDNS includes an `mc` name, but no Minecraft service, host, route, backup, or ownership record exists in the current tree.
- `compose/wedding-address-form/compose.yaml` expects `./html`, but no tracked content exists. Repository-only recovery would produce an incomplete stack.
- The media-profile documents are careful and decision-oriented. Their JSON inputs are explicitly point-in-time exports, which is good; the repo does not prove when they should next be refreshed.
- `docs/p360-day0.md` and `docs/p360-day1.md` duplicate facts now also in `inventory/hardware.md`; Day 0 still poses Proxmox as a question while Day 1 and inventory state it is installed.

Roadmap items N2, N8, O5, O6, and L3 address these findings.

## 5. Backup and restore assessment

### Coverage visible in the repository

| Service or stack | Backup script | Restore runbook | Assessment |
|---|---|---|---|
| Arr/Recyclarr | `scripts/backups/backup-arr.sh` | `runbooks/restore-arr.md` | Covered; shared media is separate |
| Authelia/Redis | `scripts/backups/backup-authelia.sh` | `runbooks/restore-authelia.md` | Covered, including sensitive files |
| Caddy | `scripts/backups/backup-caddy.sh` | `runbooks/restore-caddy.md` | Covered; canonical Caddyfile ambiguity remains |
| Porkbun DDNS | `scripts/backups/backup-ddns.sh` | `runbooks/restore-ddns.md` | Covered |
| Homepage/Glances/Uptime Kuma | `scripts/backups/backup-homepage-stack.sh` | `runbooks/restore-homepage-stack.md` | Covered |
| Immich | `scripts/backups/backup-immich.sh` | `runbooks/restore-immich.md` | Covered in principle; runbook/script mismatch needs correction |
| Jellyfin | `scripts/backups/backup-jellyfin.sh` | `runbooks/restore-jellyfin.md` | Config covered; media separate |
| Loki/Grafana/Alloy | `scripts/backups/backup-logging.sh` | `runbooks/restore-logging.md` | Covered |
| Prometheus/node-exporter/cAdvisor | `scripts/backups/backup-monitoring.sh` | `runbooks/restore-monitoring.md` | Covered |
| n8n | `scripts/backups/backup-n8n.sh` | `runbooks/restore-n8n.md` | Covered |
| Speedtest Tracker | `scripts/backups/backup-speedtest-tracker.sh` | `runbooks/restore-speedtest-tracker.md` | Covered |
| Vaultwarden | `scripts/backups/backup-vault.sh` | `runbooks/restore-vaultwarden.md` | Covered; backup mount guard and runbook safety need work |
| Vikunja/Postgres | `scripts/backups/backup-vikunja.sh` | `runbooks/restore-vikunja.md` | Strongest pattern: logical dump, private umask, temporary output, rollback |
| VPN/qBittorrent/Gluetun | `scripts/backups/backup-vpn.sh` | `runbooks/restore-vpn.md` | Covered; media separate |
| Media drive | No script | `runbooks/restore-media-drive.md` | Restore/mount guidance only; source backup method not evidenced |
| IT Tools | None | None | Reasonably stateless from Compose evidence |
| Wedding form | None | None | Gap because tracked static content is absent |
| Calibre/Shelfmark | None found | None found | Status and state location unknown |
| Pi-hole/Unbound | None found | None found | Infrastructure recovery gap |

### Script maturity

Most scripts use `set -euo pipefail`, fixed paths, a backup-share mount check, a deliberate stop/start order, a restart trap, and time-based retention. Those are good homelab-appropriate controls.

Important inconsistencies remain:

- `scripts/backups/backup-vault.sh` does not verify that `/mnt/backupshare` is mounted. Creating the destination directory on an unmounted path could silently place backup data on the root filesystem. The older top-level Vaultwarden script has the same problem and lacks the restart trap.
- The top-level Immich script lacks the mount guard present in `scripts/backups/backup-immich.sh`.
- Only the Vikunja script uses `umask 077` and temporary files followed by atomic rename. Other archives can be visible while incomplete and may inherit broader permissions.
- Date-only filenames overwrite or collide when a backup runs more than once per day.
- Retention is inconsistent: most archives use 30 days; Immich local database dumps use 14 days, while its remote Postgres sync does not mirror deletions. Intended remote retention is unclear.
- No script produces checksums/manifests or a success marker consumed by the documented freshness metrics.
- All evidenced backups converge on one desktop-hosted SMB target. This is useful second-host protection, but no offsite or offline copy is evidenced.

### Restore maturity

The newer restore runbooks generally preserve the current directory, extract into a new directory, validate expected files, retain rollback data, and describe sensitivity. That is practical and non-destructive.

The most important correctness issues are:

- Twelve restore runbooks use `cd compose/<stack>` as the recreate fallback. In the documented `/srv/docker/<stack>` recovery context, that relative path is not established and is likely to fail. Vikunja correctly uses an absolute stack path.
- `runbooks/restore-immich.md` uses a database container name that does not match current Compose, generic dump filenames that do not match the backup script, localhost tests even though the host port is commented out, and no preserve/rollback sequence comparable to newer runbooks.
- `runbooks/restore-caddy.md` treats several internal routes as public tests, expects direct localhost ports that current Compose does not publish, and does not include newer routes.
- `runbooks/restore-vaultwarden.md` uses a relative archive filename, tests a localhost port not published by current Compose, and lacks the preserve/rollback structure of newer runbooks.
- `runbooks/rebuild-optiplex.md` and `runbooks/docker-updates.md` omit many current stacks. The update runbook invokes duplicate legacy scripts, uses a convenience installer pipeline for Docker, and presents volume pruning close to the normal update path despite its warning.
- No restore-test cadence, completed drill record, archive integrity check, recovery-time objective, or recovery-point objective is stored in the repo.

Roadmap items N3, N4, O1, O2, and O6 address these findings.

## 6. Security and exposure assessment

### Secret and repository safety

Current `HEAD` contains placeholders rather than the known sensitive Homepage background URL and WireGuard value. The historical WireGuard credential documented in `docs/secret-history-review.md` is history-only and has been rotated by the human owner. `.gitignore` excludes `.env` files, common database/log/runtime names, Recyclarr secrets, and Vikunja state/artifacts; example files are intentionally allowed.

The ignore policy is not comprehensive for running Compose directly from this checkout. Examples include Arr application directories, Authelia `secrets/` and Redis/config directories, Homepage Uptime Kuma data, Caddy runtime `config/`, and VPN application directories. Generic backup archives and SQL dumps are not broadly ignored. Explicit stack-scoped rules would reduce the chance of staging runtime state or credentials.

The Homepage environment example also lacks variables now referenced for the background image and Calibre widget credentials. An incomplete schema encourages ad hoc local fixes and makes recovery less deterministic.

### Exposure model evidenced by the repo

| Class | Repository evidence |
|---|---|
| Public/intended edge | Caddy on host ports 80/443; inventory identifies Jellyfin, Seerr, Immich, and wedding address form as public; DDNS also names `mc` without corresponding service evidence |
| Internal DNS/internal TLS | Vaultwarden, Homepage, Uptime Kuma, Grafana, n8n UI, Authelia, IT Tools, Vikunja, and the two book routes are configured as internal routes, though the short domain inventory is incomplete |
| Tailscale-bound direct ports | Sonarr, Radarr, Prowlarr, Bazarr, qBittorrent, Homepage, IT Tools, Speedtest Tracker, and Glances |
| Localhost-only | Prometheus, cAdvisor, Loki, Grafana direct port, and Alloy HTTP endpoint |
| Container-only | Immich Postgres/Redis/ML, Authelia Redis, Vikunja Postgres, Seerr, FlareSolverr, Recyclarr, Uptime Kuma, and most proxied backends |
| Host network | Jellyfin, Glances, and node-exporter; this broadens host coupling and makes documentation of listener behavior important |

The model is sensible, but it is spread among Compose, two Caddyfiles, DDNS, Homepage, and inventories. DNS-based privacy is an operational assertion, not a firewall boundary proven by this repository. Internal routes without Authelia are not automatically defects: Vaultwarden and Vikunja have application authentication, and proxy authentication can break native clients. The intended control for each route should be recorded rather than applying a blanket auth layer.

### High-trust mounts and capabilities

- Homepage and Alloy mount the Docker socket read-only; Glances mounts it read-only while also running as root with host PID/network access and broad read-only host filesystem mounts.
- node-exporter and cAdvisor use host namespaces or broad host mounts for their monitoring purpose.
- Gluetun requires `NET_ADMIN` and `/dev/net/tun`; qBittorrent correctly shares Gluetun's network namespace.
- Jellyfin uses host networking, GPU access, the full media mount, and an absolute host-side web UI override.
- Immich is the only stack with explicit `no-new-privileges`; applying the setting everywhere without testing could break expected behavior and is not justified by repo evidence.

These are expected tradeoffs for the selected functionality, not reasons for immediate removal. Their risk depends primarily on keeping the administrative surfaces private, controlling image updates, and limiting who can edit their configuration.

### Other security/reliability observations

- Most images use `latest` or another floating tag. That simplifies maintenance but makes rollback and rebuild outcomes less predictable.
- The public wedding endpoint forwards a selected path into n8n. Repository evidence does not show rate limiting, request validation, authentication, or abuse controls at the proxy or workflow layer.
- `scripts/check_secrets.sh` prints matching source lines and staged diff lines. If it finds a real value, the helper itself can expose it in terminal logs or copied output. It also does not inspect history.
- `scripts/check_repo_drift.sh` prints full diffs of selected live configuration and has an incomplete stack map. On a production host, full diffs can disclose sensitive URLs or values even when `.env` files are excluded.

Roadmap items N5, N6, N7, O4, O5, L1, and A1-A3 address these findings.

## 7. Monitoring and alerting assessment

The repository has a reasonable small-lab observability split: Prometheus collects node/container metrics, Grafana handles infrastructure and backup-freshness alerting, Loki retains seven days of logs, Alloy discovers Docker logs, and Uptime Kuma is intended for service availability. Ports are mostly localhost/internal, which fits the exposure priorities.

Documentation quality is good where state is known. `docs/alerting.md` explains why backup age is more useful than immediate share-mount failure, warns about No Data behavior, distinguishes Grafana from Uptime Kuma, and provides response steps. It correctly labels UI-managed thresholds, selectors, evaluation timing, notification policies, and contact points as needing verification.

Operational evidence is incomplete:

- The repository contains no implementation that writes the documented `homelab_backup_*` textfile metrics and no scheduler definitions proving backups or metric updates run.
- Grafana alert rules, contact points, templates, and notification policy are not provisioned or exported here.
- Uptime Kuma monitor coverage is not documented, so critical public/internal services and certificate checks cannot be confirmed.
- Compose healthchecks exist only in the Immich stack. Restart policies cover process exit, but not hung or dependency-unready applications. Vikunja and Authelia databases/caches have no health-gated dependency evidence.
- Alloy has Docker log collection wired to Loki. It defines journal relabeling, but no journal source component is visible in `config.alloy`; journal collection therefore appears incomplete or intentionally unused.
- No Docker log-driver rotation policy or disk-growth policy is evidenced. Loki's seven-day retention does not itself limit Docker's local log files.

Roadmap items O3, O4, and O7 address these findings.

## 8. Codex workflow/change-control assessment

`docs/codex-workflow.md`, `docs/change-control.md`, and `docs/pr-review-checklist.md` form a strong lightweight control set. They clearly assign production authority to the human, distinguish docs/repo/lab/production/security change classes, require rollback and validation proportional to risk, insist on branch-based review, separate repository state from runtime claims, and discourage secrets or runtime artifacts in Git.

The current tree supports that model: `main` is the shared merge point, the active review branch starts at the same commit, and history shows small `codex/*` and `reconcile/*` branches merged through focused PRs. However, all visible topic branches are already merged into `main`; keeping them indefinitely makes branch discovery noisy and weakens the “short-lived branch” convention.

Recommended workflow refinements are narrow:

- Make masked output the default for secret and drift checks; never rely on a helper that prints the suspected value.
- Add a check that the task branch is based on current `main` before review. The existing checklist says this, but the known Homepage remediation demonstrated why it matters.
- Treat `git fetch`, branch creation, commits, and PR operations as actions requiring task authorization; the startup checklist should not override stricter task constraints or offline work.
- Define which Caddyfile and inventory document are canonical, then make review checklists compare derived summaries against them.
- Record the source and date of human/runtime observations in inventory so old production facts do not appear continuously verified.
- Expand drift coverage only through a reviewed, masked design; do not make the script copy from or overwrite production.

Roadmap items N1, N2, N7, and N9 address these findings.

## 9. Stale or cleanup candidates

These are candidates for human review, not deletion instructions:

- All visible local and remote topic branches are reported as merged into `main`, including older `codex/*`, `reconcile/*`, `docs/service-inventory`, and `origin/ian/update-recent-changes` refs. Branch retention policy is not documented.
- `scripts/backup-immich.sh` and `scripts/backup-vault.sh` duplicate the versions under `scripts/backups/`.
- `compose/caddy/Caddyfile` and `configs/caddy/Caddyfile` overlap but differ.
- `inventory/services.md`, `inventory/domains.md`, and `inventory/ports.md` lag `docs/service-inventory.md` and current configuration.
- `docs/p360-day0.md` and `docs/p360-day1.md` duplicate `inventory/hardware.md` and contain a resolved question.
- `CHANGELOG.md` and `configs/homepage/custom.js` are empty; Homepage Kubernetes/provider/Proxmox files look like optional scaffolding.
- `README.md` references absent `diagrams/` and `backups/` directories.
- Recyclarr state mappings are generated artifacts; media-profile exports are large point-in-time audit artifacts. Both need an explicit keep/refresh/retire policy.
- OnlyOffice and Gamebuilds are correctly absent from active config and retained only as retirement notes; no further cleanup is evidenced in the current tree.

Roadmap items N1, N2, N4, N8, N9, and L3 cover these candidates.

## 10. Prioritized recommendations

Validation class meanings: **documentation-only** changes repository documentation only; **lab-tested** changes behavior and should be exercised away from production; **production-reviewed** requires an approved production plan and post-change validation. No row authorizes an automatic fix.

### Now / low-risk cleanup

| ID | Evidence or repo path | Why it matters | Risk/impact | Suggested next action | Validation class | Human approval |
|---|---|---|---|---|---|---|
| N1 | `compose/caddy/Caddyfile`, `configs/caddy/Caddyfile`, `compose/caddy/compose.yaml`, `scripts/check_repo_drift.sh` | Two differing proxy sources make recovery and exposure review ambiguous. | High operational risk: a restore may omit routes or promote unintended ones. | Human selects the canonical file; document the decision and differences. Any later config reconciliation must be separately reviewed. | Documentation-only now; production-reviewed for later config change | Yes |
| N2 | `docs/service-inventory.md`, `inventory/services.md`, `inventory/domains.md`, `inventory/ports.md` | Inventories disagree and Vikunja contains a stale “Compose absent” statement. | Medium: responders may use wrong routes, ports, or backup assumptions. | Declare one canonical inventory, timestamp human/runtime facts, and reconcile summaries against current repo evidence. | Documentation-only | Yes, for operational facts |
| N3 | `runbooks/restore-*.md`, especially Immich/Caddy/Vaultwarden and relative `cd compose/<stack>` commands | Recovery commands must work under pressure and match current names, paths, and exposure. | High: restore failure, unnecessary downtime, or incorrect exposure testing. | Perform a docs-only command/path audit against current Compose; add archive preflight, preservation, rollback, and explicit working directories. Do not execute restores. | Documentation-only, followed by lab-tested drills | Yes |
| N4 | Top-level backup scripts, `scripts/backups/`, `runbooks/docker-updates.md` | Operators can invoke older, less-safe duplicates. | High for Vaultwarden/Immich: missed mount checks or failed restart can affect data/availability. | Mark one script set canonical, update documentation references, and propose retirement of duplicates without deleting them in the documentation task. | Documentation-only; later production-reviewed | Yes |
| N5 | Homepage `.env.example`, `configs/homepage/settings.yaml`, `configs/homepage/services.yaml` | Referenced background and Calibre variables are missing from the example schema. | Medium: incomplete recovery or accidental inline values. | Add names-only blank placeholders in a separately scoped review; never add values. | Documentation-only/repo-only | Yes |
| N6 | `.gitignore`; runtime paths implied by Compose | Several stack-local runtime/secret directories and generic archives are not explicitly ignored. | High confidentiality risk if Compose is run from the checkout; low runtime risk. | Draft explicit stack-scoped ignores and archive/dump patterns, then validate with synthetic filenames and confirm no intended tracked file would become hidden. | Lab-tested repository check | Yes |
| N7 | `scripts/check_secrets.sh`, `scripts/check_repo_drift.sh`, `docs/secret-history-review.md` | Helpers print full matching lines/diffs and can disclose the thing they detect. | High confidentiality impact in logs/chat; drift map is also incomplete. | Design masked, filename/rule-only default output and a deliberate opt-in local diff mode. Review without accessing production. | Lab-tested | Yes |
| N8 | `README.md`, `CHANGELOG.md`, P360 notes, absent advertised directories | Entry-point navigation is stale and minor files are ambiguous. | Low: onboarding and recovery friction. | Refresh the repository map, identify the canonical P360 record, and decide whether empty/scaffold files are intentional. Do not delete in the docs task. | Documentation-only | No for factual link fixes; yes for retirement/deletion decisions |
| N9 | Visible merged topic branches; workflow docs | Numerous already-merged refs conflict with the short-lived branch convention. | Low: navigation noise and accidental work from stale refs. | Document branch retention, list merged candidates, and let the human remove refs separately after confirming remote policy. | Documentation-only | Yes |

### Next / operational maturity

| ID | Evidence or repo path | Why it matters | Risk/impact | Suggested next action | Validation class | Human approval |
|---|---|---|---|---|---|---|
| O1 | `scripts/backups/*.sh`; Vikunja as the strongest pattern | Consistent mount guards, private permissions, temporary outputs, timestamps, and success markers make backups trustworthy. | High data-protection impact; changing scripts can cause downtime or false success. | Define a common backup contract, then lab-test one stack before proposing incremental adoption. Include the Vaultwarden mount check first. | Lab-tested, then production-reviewed | Yes |
| O2 | Backup scripts, all restore runbooks, `docs/alerting.md`, single SMB target | File existence is not proof of recoverability; RPO/RTO and second-copy expectations are undefined. | High data-loss/recovery risk. | Human classifies critical data, selects RPO/RTO, encryption and offsite/offline policy, and schedules documented restore drills with non-secret evidence. | Documentation-only planning, then lab-tested and production-reviewed | Yes |
| O3 | `docs/alerting.md`, Prometheus config, absent metric writer/scheduler/Uptime matrix | Alert intent cannot be reconstructed or audited from Git. | Medium-high: silent stale backups or missing service coverage. | Document exact non-secret metric labels/thresholds, the metric producer and scheduler ownership, and a Uptime Kuma service matrix; export UI-managed rules if practical. | Documentation-only, then lab-tested | Yes |
| O4 | Nearly all Compose files use floating tags; only Immich has healthchecks | Floating rebuilds and process-only restart detection reduce predictability. | Medium; broad pinning/healthchecks can also create maintenance burden or false failures. | Define a controlled update cadence and rollback record; pilot version pinning and meaningful healthchecks on critical stateful dependencies rather than changing every service. | Lab-tested, then production-reviewed | Yes |
| O5 | Caddy, DDNS, domain inventory, public address webhook, unexplained `mc`, internal routes without uniform proxy auth | Exposure intent is distributed and some routes lack ownership evidence. | High if an admin UI or webhook is unintentionally public. | Produce one route/access matrix and obtain human decisions for `address`, `mc`, books/shelf, n8n UI, and application-vs-proxy authentication. No DNS/Caddy edits in this task. | Documentation-only; any change production-reviewed | Yes |
| O6 | Missing Pi-hole/Unbound, Proxmox, wedding content, Calibre/Shelfmark, and media-source backup evidence | These dependencies can block whole-lab recovery despite strong Docker-stack coverage. | Medium-high depending on actual state. | Confirm which are active/stateful, then create recovery-scope documents in priority order; add scripts only through later tested tasks. | Documentation-only discovery, then lab-tested | Yes |
| O7 | `compose/logging/alloy/config.alloy` | Journal relabel rules exist without a visible journal source pipeline. | Low-medium: operators may assume host journal coverage that is absent. | Decide whether Docker-only logging is intentional; document that choice or lab-test a complete journal source pipeline. | Documentation-only or lab-tested | Yes |

### Later / optional hardening

| ID | Evidence or repo path | Why it matters | Risk/impact | Suggested next action | Validation class | Human approval |
|---|---|---|---|---|---|---|
| L1 | Homepage, Glances, Alloy Docker socket mounts; host mounts and root users | A compromised high-trust monitoring container could affect or deeply inspect the host. | High consequence but currently reduced by internal-only access. | Reassess socket proxies, reduced privileges, or narrower metrics sources only after documenting required features and testing compatibility. | Lab-tested, then production-reviewed | Yes |
| L2 | UI-managed Grafana alerting and Uptime Kuma state | Reproducible non-secret alert definitions improve disaster recovery. | Medium benefit; full provisioning may add complexity. | Export or provision only the stable, high-value alert rules and templates; keep notification credentials outside Git. | Lab-tested | Yes |
| L3 | `inventory/media-profiles/*.json`, `compose/arr/recyclarr/state/`, media review docs | Point-in-time/generated evidence can become stale and create review noise or privacy exposure. | Low-medium repository bloat and stale-decision risk. | Add capture date, source, sanitization statement, refresh trigger, and retention rule; do not delete existing evidence automatically. | Documentation-only | Yes |

### Avoid / probably not worth it

| ID | Evidence or repo path | Why it matters | Risk/impact | Suggested next action | Validation class | Human approval |
|---|---|---|---|---|---|---|
| A1 | Small single-host design and documented accepted risks | Blanket CIS/Docker Bench remediation would ignore service purpose and homelab constraints. | High complexity and outage risk for uncertain benefit. | Keep contextual reviews focused on actual exposure, secrets, mounts, and recovery. | Documentation-only decision | Yes if reconsidered |
| A2 | Internal DNS/Tailscale model; native-client services | Blanket Authelia insertion can break clients and duplicates application authentication. | Medium availability/usability risk. | Decide auth per route in O5; do not apply a universal proxy-auth rule. | Production-reviewed if reconsidered | Yes |
| A3 | Floating image tags and stability priority | Unattended image updates can combine multiple changes with weak rollback evidence. | High availability risk. | Prefer scheduled, reviewed stack-by-stack updates with backups and rollback; do not add an auto-updater by default. | Production-reviewed if reconsidered | Yes |
| A4 | Current Compose scale and low-power/simple-operation priorities | Kubernetes/HA/service-mesh migration would add control-plane cost without repo evidence of a matching need. | High complexity, power, and maintenance cost. | Keep Compose unless concrete availability or scale evidence changes the decision. | Architecture decision | Yes if reconsidered |

## 11. Items needing human decision

- Which Caddyfile is authoritative, and are the Calibre/Shelfmark routes active? (N1)
- Should `docs/service-inventory.md` replace the short service/domain/port lists, or should those remain maintained summaries? (N2)
- Is the wedding form still required, where is its static content, and what abuse/data-retention controls exist for its public webhook? (O5/O6)
- What service or host owns the `mc` DDNS name, and is public DNS still intentional? (O5)
- Which internal routes rely on application authentication, Authelia, Tailscale identity, LAN trust, or a combination? (O5)
- Which data is critical, what data loss/downtime is acceptable, and is an encrypted offsite/offline copy warranted? (O2)
- Are the old top-level backup scripts retained for compatibility, or may they be retired after references are updated? (N4)
- Should journal logs be collected by Alloy, or is Docker-only logging the intended low-noise scope? (O7)
- Which generated exports/state mappings must remain in Git, and for how long? (L3)
- What merged-branch retention period is preferred locally and on the remote? (N9)

## 12. Suggested follow-up Codex tasks

Each task should remain a separate branch/PR and must not apply production changes:

1. **Caddy source-of-truth review (N1):** document file ownership, enumerate route differences, and stop before editing configuration.
2. **Inventory reconciliation (N2):** update docs from repository evidence, marking every operational fact with source/date or `needs verification`.
3. **Restore command audit (N3):** correct only runbook paths/names/ports and add non-destructive preflight/rollback structure; do not execute commands.
4. **Backup script design review (N4/O1):** propose a common contract and a migration sequence without modifying scripts.
5. **Ignore-policy test plan (N6):** use synthetic paths to prove proposed patterns hide runtime artifacts but not intended configuration.
6. **Masked secret/drift helper design (N7):** specify safe output behavior and tests using dummy values only.
7. **Exposure matrix (O5):** map every hostname and direct port to public, internal DNS, Tailscale, localhost, or container-only, with human-decision flags.
8. **Recovery objectives and drill template (O2/O6):** define tiers, RPO/RTO prompts, test evidence, and offsite decision points.
9. **Monitoring evidence reconciliation (O3/O7):** compare documented alerts, metric ownership, Uptime Kuma responsibilities, and Alloy pipelines using repository evidence only.
10. **Image/healthcheck policy memo (O4):** identify a small pilot set and rollback criteria; do not edit Compose.

## 13. Things not to change automatically

- Public DNS, DDNS subdomains, Caddy routes, TLS mode, firewall rules, bind addresses, or Tailscale policy.
- Authelia placement or application authentication for Vaultwarden, n8n, Vikunja, IT Tools, book services, or public applications.
- Docker socket mounts, host networking, host PID mode, GPU/TUN devices, capabilities, UID/GID settings, or host bind mounts.
- Image tags, dependency versions, healthchecks, restart policies, or resource limits.
- Backup retention, archive contents, encryption, schedules, stop/start order, or destination paths.
- Restore commands, production data, `.env` files, secret files, databases, archives, or generated runtime directories.
- The known historical credential record or Git history. The WireGuard key is rotated; history rewrite is not recommended by the existing review.
- Merged branches, generated media exports, Recyclarr state, retired-service notes, empty/scaffold files, or duplicate scripts/configs without human confirmation.
- Docker volumes/images or any data via prune, delete, reset, cleanup, or automated remediation.

## 14. Evidence gaps

The following cannot be concluded from the repository and must not be treated as current production fact:

- Which Compose stacks and containers are currently running, healthy, or restarting.
- Actual host listeners, firewall/NAT rules, Docker network membership, and reachability from LAN, Tailscale, and internet clients.
- Current public and internal DNS answers, including whether `mc`, address form, book services, and private routes resolve as intended.
- Active image versions behind floating tags and whether update rollback is practiced.
- Backup scheduling, last-success times, archive readability, backup destination permissions/encryption, available restore points, and actual retention.
- Whether the backup freshness metric producer exists and how it derives success.
- Results and dates of restore drills, full-host rebuild tests, database integrity checks, or recovery-time measurements.
- Uptime Kuma monitors, Grafana alert rules/contact points/templates, notification delivery, silence behavior, and No Data settings.
- Docker daemon log rotation and host disk-growth controls.
- Pi-hole/Unbound configuration, export/restore state, and redundancy behavior.
- Proxmox VM/LXC backup configuration and the recoverability of the codex-lab environment.
- Wedding form static content, submitted-data handling, n8n workflow validation, rate limiting, and abuse controls.
- Calibre/Shelfmark Compose location, persistence, authentication, backup, restore, and active status.
- Minecraft or other owner/project service configuration associated with the DDNS name.
- Whether old human/runtime statements in `docs/service-inventory.md` remain accurate.
- The intended retention of merged branches, media exports, and generated Recyclarr mappings.
