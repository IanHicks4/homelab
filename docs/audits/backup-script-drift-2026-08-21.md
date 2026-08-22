# Immich and Vaultwarden Backup Script Drift Audit

Audit date: 2026-08-21 (America/New_York)

## 1. Executive summary

Both live/repo script pairs differ. The differences are small in line count but materially affect failure safety:

- The Immich repo script checks that `/mnt/backupshare` is a mountpoint before creating remote directories or copying data. The live script lacks this guard.
- The Vaultwarden repo script installs an `EXIT` trap that attempts to ensure the container is running even if archive, synchronization, or retention steps fail. The live script restarts the container only on the normal success path.

The live scripts are the strongest evidence of currently deployed production behavior because they reside in the production service trees. Current-dated backup filenames show that backups are being produced, but filename-only inspection cannot identify which script path was invoked. The repo scripts are newer and contain clear safety improvements, so they appear to be the intended desired-state candidates. Reconciliation should update the repo-to-production deployment process through review; this audit does not recommend or apply direct live changes.

Risk is **high for failure handling** despite no observed failure: an unavailable backup share could cause Immich data to be written into the local mountpoint directory, and an error after Vaultwarden is stopped could leave it stopped. No secrets were printed, no archive or database dump was opened, and no Docker command was executed.

## 2. Commands run

All inspection commands were read-only. The only writes were creation of this report directory and report file. No command used `sudo`.

```text
sha256sum <four specified scripts>
stat -c <selected file metadata> <four specified scripts>
rg -l -i <secret/private-key/credential/sensitive-URL patterns> <four specified scripts>
diff -u <Immich repo script> <Immich live script>
diff -u <Vaultwarden repo script> <Vaultwarden live script>
bash -n <four specified scripts>
find /mnt/backupshare/immich -maxdepth 2 -printf <entry type and relative name only>
find /mnt/backupshare/vaultwarden -maxdepth 2 -printf <entry type and relative name only>
nl -ba <four specified scripts>
mkdir -p /home/server/homelab-audits/backup-script-drift
```

The first combined hash/stat attempt succeeded, but its secret-scan portion did not execute due to shell quoting. The corrected secret scan was then run successfully before either diff. It returned no matches. No script body is reproduced in this report.

## 3. Files compared

| Service/role | Path | SHA-256 | Size | Modified | Mode/owner |
|---|---|---|---:|---|---|
| Immich live | `/srv/docker/immich/scripts/backup-immich.sh` | `2d2577048fe192bb73c4ac983afffe26fda89971c52250da9b80c537ae449b50` | 911 bytes | 2026-04-05 19:02:14 -0400 | `0755`, `root:root` |
| Immich repo | `/home/server/homelab/scripts/backups/backup-immich.sh` | `f0ee6c5bf174779506f883bee733655cdb8e154eff501910c0a1365205fd7d45` | 1036 bytes | 2026-06-11 14:23:04 -0400 | `0775`, `server:server` |
| Vaultwarden live | `/srv/docker/vaultwarden/scripts/backup-vault.sh` | `fab0e76b995b332e707b2be2da073edb2cd7be80523b8bb1f8cc3812e2358f94` | 697 bytes | 2026-04-05 23:58:25 -0400 | `0755`, `root:root` |
| Vaultwarden repo | `/home/server/homelab/scripts/backups/backup-vault.sh` | `2f3d1b5ea96a97d7273370609825eeda1cb1e2515d823a92bb183e43f0661d3a` | 841 bytes | 2026-06-11 14:23:04 -0400 | `0775`, `server:server` |

All four scripts pass `bash -n` syntax validation.

Ownership and mode differ by location. Live production files are root-owned and executable; repo copies are user-owned and group-writable. This is **documentation-only**: each location's local ownership model is authoritative, and permissions should not be synchronized solely for visual parity. It matters for provenance and change control, but it does not alter the shell logic compared below.

## 4. Immich backup drift

There is one code difference: the repo script checks `mountpoint -q /mnt/backupshare` and exits with an error if the share is not mounted; the live script proceeds directly to directory creation.

- Why it matters: without the check, `mkdir -p` can create directories on the underlying local filesystem when the network share is absent. Subsequent `rsync` operations may look successful while consuming local disk and failing to produce an off-host backup.
- Authority: **live is authoritative for deployed production behavior**, while **repo is the more authoritative desired-state safety implementation** because it is newer and explicitly prevents a known mountpoint failure mode.
- Classification: **production-reviewed**. The safety intent is strong, but reconciliation affects production backup execution and should be reviewed and deployed through the normal controlled process rather than copied automatically.

Everything else is identical: strict shell mode, date naming, paths, directory creation, PostgreSQL dump pipeline, library/dump/Compose synchronization, 14-day local dump cleanup, and progress output.

## 5. Vaultwarden backup drift

The repo script defines a container-name variable, defines a restart helper, and registers it as an `EXIT` trap. The helper attempts `docker start`, suppresses its output, and tolerates restart failure. The live script uses the literal container name, has no trap, and performs one explicit visible `docker start` after archive and synchronization complete.

- Why it matters: under `set -euo pipefail`, a failed `tar` or `rsync` exits the live script before its explicit start command, potentially leaving Vaultwarden stopped. The repo trap attempts a restart on every exit path.
- Authority: **live is authoritative for deployed production behavior**, while **repo is the more authoritative desired-state safety implementation** because it is newer and adds failure-path recovery.
- Classification: **production-reviewed**. Container lifecycle behavior must be tested and deployed through review; no direct production change is appropriate from this audit.

The shutdown log line also differs slightly in capitalization, punctuation, and use of the variable versus literal name. This is **documentation-only**: repo is more maintainable because the name is centralized, but the current value is identical and runtime behavior is unchanged on the normal path.

## 6. Safety differences

### Immich mount guard

- Difference: present only in repo.
- Why it matters: prevents false-success backups to the local directory beneath an absent mount.
- Authority: repo is more authoritative for intended safe behavior; live is authoritative for what is deployed.
- Classification: **production-reviewed**.

### Vaultwarden exit recovery

- Difference: repo always invokes a best-effort restart handler on shell exit; live starts only after successful archive and sync steps.
- Why it matters: repo reduces the chance of an extended outage after an intermediate backup failure.
- Authority: repo is more authoritative for intended safe behavior; live is authoritative for what is deployed.
- Classification: **production-reviewed**.

### Shared safeguards

All scripts use `set -euo pipefail`, so unhandled command failures, unset variables, and pipeline errors terminate execution. This is aligned, not drift. Neither service uses staging filenames plus atomic rename, explicit free-space checks, checksum verification, post-backup validation, locking to prevent overlapping runs, or structured error notification. Those are shared design observations, not differences, and any additions are **production-reviewed**.

## 7. Mountpoint/share handling

Immich repo explicitly verifies `/mnt/backupshare`; Immich live does not. This is the principal share-handling drift and is **production-reviewed**, with repo more authoritative for safety and live more authoritative operationally.

Neither Vaultwarden script verifies the share mountpoint before creating `archive` and `data` directories. There is no drift for Vaultwarden, but the shared omission has the same local-disk/false-backup risk. Adding a check would be **production-reviewed**, not an automatic reconciliation item.

Filename-only inspection found the expected Immich `compose`, `library`, and `postgres` directory structure and Vaultwarden `archive` and `data` structure. It also found dated backup filenames through 2026-08-21 for both services. This confirms artifacts exist, but not their completeness, integrity, storage medium, or producer script. No archive, SQL dump, database, key, configuration, or other backup content was opened.

## 8. Stop/start behavior

Immich does not stop or start application containers. It runs `pg_dumpall` inside the PostgreSQL container while services remain live. There is no stop/start drift.

Both Vaultwarden scripts stop the `vaultwarden` container before archiving and synchronizing its data. The difference is restart handling:

- Live explicitly starts it only after `tar` and `rsync` succeed.
- Repo registers a best-effort `EXIT` trap before the stop, so it attempts a start after success or failure.
- Why it matters: live can leave the service stopped after an intermediate error; repo reduces that outage risk. The repo helper's `|| true` also means restart failure does not change the final script status or produce normal command output, which may hide a failed recovery attempt.
- Authority: repo is more authoritative for failure recovery, but live is the deployed behavior.
- Classification: **production-reviewed**.

No Docker lifecycle command was run during this audit.

## 9. Database backup behavior

Immich behavior is identical in both scripts: run `pg_dumpall` as the PostgreSQL user inside `immich-postgres`, gzip the stream, and write a date-named local SQL gzip file before synchronization to the backup share.

Why it matters: the pipeline is protected by `pipefail`, so a dump or compression failure returns failure. However, output redirection can create or truncate the date-named file before the pipeline succeeds, leaving a partial artifact after failure. This is shared behavior, not drift. Live is operationally authoritative; neither version is safer here. Any atomic staging/validation enhancement is **production-reviewed**.

Vaultwarden behavior is identical in backup content scope: the service is stopped, then the entire data directory is archived and mirrored. The scripts do not invoke SQLite's online backup mechanism; stopping the service is their consistency strategy. No database file or archive was opened. Any change to this strategy is **production-reviewed**.

## 10. Retention behavior

Immich scripts identically delete local PostgreSQL dump files older than 14 days. They do not delete remote PostgreSQL dumps, which is consistent with the filename-only observation of many older remote files. Live is operationally authoritative, but there is no drift. Retention-policy changes are **production-reviewed** because they delete backup artifacts.

Vaultwarden scripts identically delete archive files older than 30 days under the remote archive directory. The mirrored `data` directory is maintained with `rsync --delete` rather than versioned retention. Live is operationally authoritative, but there is no drift. Any retention change is **production-reviewed** and must not be automated from this audit.

## 11. Logging/output behavior

Immich logging is identical except that the repo emits an explicit error when the share is not mounted. That difference matters because it gives operators a clear failure reason. Repo is more authoritative for intended diagnostics; classification: **repo reconciliation** for documentation/source tracking, with production deployment still requiring review.

Vaultwarden repo emits an “ensuring running” message from the exit handler but suppresses `docker start` output and ignores its failure. Live emits a normal “starting” message and allows an explicit start failure to terminate the script. This changes observability and exit semantics:

- Repo improves recovery coverage but can obscure restart failure.
- Live exposes start failure but only reaches it on the success path.
- Authority: neither is unambiguously superior; repo is the newer intended version, while live is deployed.
- Classification: **production-reviewed**.

Both scripts otherwise use simple human-readable progress messages and command output; neither uses timestamps, structured logs, explicit logging destinations, or notification hooks.

## 12. Which script appears authoritative for each service

### Immich

- **Operational authority:** live `/srv/docker/immich/scripts/backup-immich.sh`, based on its production location. Filename-only artifact history is compatible with it running but does not prove invocation origin.
- **Desired-state authority:** repo `/home/server/homelab/scripts/backups/backup-immich.sh`, because it is newer and adds a deliberate mountpoint safety check without otherwise changing behavior.
- Reconciliation classification: **production-reviewed**.

### Vaultwarden

- **Operational authority:** live `/srv/docker/vaultwarden/scripts/backup-vault.sh`, based on its production location. Current archive filenames do not prove which path invoked the backup logic.
- **Desired-state authority:** repo `/home/server/homelab/scripts/backups/backup-vault.sh`, because it is newer and adds deliberate failure-path restart handling.
- Reconciliation classification: **production-reviewed**.

No scheduler, unit, cron configuration, process command line, or logs were inspected, so this audit cannot conclusively identify the invoked script path. That limitation is **documentation-only** and should be resolved by documenting the backup entrypoints.

## 13. Recommended repo reconciliation plan

1. Document the actual scheduler/entrypoint for each backup and the intended repo-to-production deployment flow. Classification: **documentation-only**.
2. Treat the repo safety changes as candidates for the reviewed source of truth, not as authorization to edit live files. Classification: **repo reconciliation**.
3. For Immich, test the mountpoint guard for mounted, unmounted, and transiently unavailable share scenarios. Confirm the exact required mount target. Classification: **production-reviewed**.
4. For Vaultwarden, test failures at stop, archive, sync, retention, and restart stages. Decide whether restart failure must be visible and must cause a nonzero final status; the current repo trap suppresses and ignores that failure. Classification: **production-reviewed**.
5. Consider a consistent share preflight for Vaultwarden and operational alerting for both services. Classification: **production-reviewed**.
6. Validate backup integrity and restoration through a separately authorized process. Do not use this audit to open archives/dumps or perform restoration. Classification: **production-reviewed**.

## 14. Items not safe to change automatically

- Either live script or any file under `/srv/docker`.
- Either tracked script under `/home/server/homelab` without the normal repository review workflow.
- Vaultwarden stop/start/trap behavior or ignored restart errors.
- Mountpoint paths, mount validation rules, or backup destinations.
- Database dump, archive, synchronization, deletion, or retention logic.
- `rsync --delete` behavior.
- Backup ownership, permissions, archive contents, database files, private keys, or configuration contents.
- Scheduler, timer, cron, notification, container, or service configuration.

These are **production-reviewed** because mistakes can cause service downtime, misleading backup success, data deletion, loss of recovery points, or disclosure of sensitive backup material. Live remains authoritative for current deployment; desired changes must follow review and controlled deployment.

## 15. No changes applied

No changes were made to the four scripts, `/srv/docker`, `/home/server/homelab`, backup-share contents, containers, services, schedules, archives, databases, dumps, or configuration. No Docker command, lifecycle action, `sudo`, archive read, database read, or backup-content read was performed. The only created artifact is this report under `/home/server/homelab-audits/backup-script-drift/`.
