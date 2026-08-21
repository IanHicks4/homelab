# Monitoring Compose Drift Audit

Audit date: 2026-08-21 (America/New_York)

## 1. Executive summary

The live and tracked monitoring Compose files are not byte-identical, but the service inventory and nearly all declared settings are aligned. One direct textual drift exists: the live `node-exporter` service enables the textfile collector with `--collector.textfile.directory=/host/var/lib/node_exporter/textfile_collector`, while the repo file does not.

There is also an important deployment-context difference: identical relative Prometheus bind paths resolve under each Compose file's own directory. The live file resolves them to `/srv/docker/monitoring`, while validation of the repo file in place resolves them under `/home/server/homelab/compose/monitoring`. This is not a textual difference, but it is a semantic difference when each file is run from its current location.

All three authorized containers are running. Their Compose metadata names `/srv/docker/monitoring/compose.yaml` and `/srv/docker/monitoring` as the source file and working directory. Runtime metadata matches the live file, including the node-exporter textfile collector argument and live Prometheus mount sources. The live file is therefore more authoritative for current production behavior; the tracked repo should be reconciled only after confirming that the textfile collector is intentional and establishing a safe path strategy for deployment.

Overall risk is **moderate configuration-management risk, low immediate availability risk**. No failing container was observed: `prometheus` and `node-exporter` were running, and `cadvisor` was running and healthy. However, redeployment from the repo file could omit textfile metrics and could bind Prometheus to unintended repo-local configuration/data paths.

No credentials, tokens, API keys, secrets, or sensitive URLs were found or included. No production changes were applied.

## 2. Commands run

All successful commands were read-only except creation of this report directory and report file. No command used `sudo`.

```text
sha256sum /srv/docker/monitoring/compose.yaml /home/server/homelab/compose/monitoring/compose.yaml
stat -c <selected file metadata> <both compose files>
rg -n -i <secret-looking fields and query-string URL patterns> <both compose files>
diff -u /home/server/homelab/compose/monitoring/compose.yaml /srv/docker/monitoring/compose.yaml
docker compose -f /srv/docker/monitoring/compose.yaml config --services
docker compose -f /home/server/homelab/compose/monitoring/compose.yaml config --services
docker compose -f <each compose file> config --format json | jq <non-secret service fields only>
docker ps --filter <exact authorized monitoring container names> --format <selected metadata>
docker inspect prometheus node-exporter cadvisor --format <selected metadata only>
docker inspect node-exporter --format <selected mount metadata only>
mkdir -p /home/server/homelab-audits/monitoring-compose-drift
```

One initial read-only inspection attempt failed before execution because the sandbox could not initialize loopback isolation (`RTM_NEWADDR: Operation not permitted`). It was rerun outside that sandbox with approval. One selected-metadata `docker inspect` attempt also failed because this Docker template implementation lacks the `dict` function; it returned no inspect data and was replaced with an explicit selected-field format.

No Compose lifecycle, container lifecycle, image pull, database, or backup-content commands were run.

## 3. Files compared

| Role | Path | SHA-256 | Size | Modified | Ownership/mode |
|---|---|---|---:|---|---|
| Live production | `/srv/docker/monitoring/compose.yaml` | `5ccfd0e1a0aa8a312c82af2a772536adb5d6cb2450eaf99a71ee28725e6ed953` | 1006 bytes | 2026-06-15 22:35:56 -0400 | `root:root`, `0644` |
| Tracked repo | `/home/server/homelab/compose/monitoring/compose.yaml` | `cf1f93a2038ae8443f6fa81efe19cdf866aa4056290819ccb41f96f5b5d68527` | 918 bytes | 2026-06-11 14:23:04 -0400 | `server:server`, `0664` |

Both files validated to the same service set: `cadvisor`, `node-exporter`, and `prometheus`.

File ownership, mode, size, and modification time are contextual filesystem metadata rather than Compose configuration. For the live file, production ownership is authoritative; for the repo file, repository ownership is authoritative. They should not be made identical merely for parity. Classification: **documentation-only**. Why it matters: it helps establish provenance but does not change the rendered Compose model.

## 4. Service-level differences

### node-exporter command

- Live: `--path.rootfs=/host` plus `--collector.textfile.directory=/host/var/lib/node_exporter/textfile_collector`.
- Repo: `--path.rootfs=/host` only.
- Authority: **live appears more authoritative** for current production behavior because the running container has both arguments and labels the live file as its Compose source.
- Why it matters: a deployment from the repo definition could stop node-exporter from ingesting metrics written to the textfile collector directory, causing silent loss of custom metrics and related alerts/dashboards.
- Classification: **repo reconciliation**. Confirm the collector is intentional, then represent it in the tracked definition; do not change production as part of reconciliation.

No other service-level textual differences were found.

## 5. Image/tag differences

No differences were found. Both files declare:

- `prom/prometheus:latest`
- `prom/node-exporter:latest`
- `gcr.io/cadvisor/cadvisor:latest`

Runtime reports the same image references. Neither file is more authoritative for a difference because there is no drift. The use of mutable `latest` tags is a shared risk, not a drift finding. Classification: **production-reviewed**. Why it matters: future pulls or recreations can select different image content without a Compose-file change; any pinning decision should be reviewed and tested, not applied automatically.

## 6. Port/bind differences

No differences were found between the files:

- Prometheus publishes container port `9090` as `127.0.0.1:9090`.
- cAdvisor publishes container port `8080` as `127.0.0.1:8081`.
- node-exporter uses host networking and has no separate published-port mapping.

Runtime matches these declarations. The live file is operationally authoritative because it is the deployed source, but no reconciliation is needed. Loopback-only publication limits direct external exposure and should be preserved.

## 7. Volume/bind-mount differences

The raw Compose files use the same mount expressions, but normalized resolution differs for Prometheus because relative source paths are anchored to the Compose project directory:

- Live resolves `./prometheus.yml` to `/srv/docker/monitoring/prometheus.yml` and `./data` to `/srv/docker/monitoring/data`.
- Repo-in-place validation resolves them to `/home/server/homelab/compose/monitoring/prometheus.yml` and `/home/server/homelab/compose/monitoring/data`.
- Runtime uses the live `/srv/docker/monitoring` sources.
- Authority: **live appears more authoritative** for current production mount targets, as confirmed by runtime metadata.
- Why it matters: directly deploying the repo file from its repository path could use a different Prometheus configuration and a different writable data directory. That could change scrape behavior or present an empty/alternate time-series store.
- Classification: **production-reviewed**. The repo may be a source artifact intended for deployment/copying rather than direct execution; the intended deployment workflow must be established before changing path semantics.

Other mounts match semantically:

- node-exporter binds `/` to `/host` read-only with `rslave` propagation; runtime confirms this mount.
- cAdvisor binds `/`, `/var/run`, `/sys`, and `/var/lib/docker` read-only to their declared targets; runtime confirms them.

## 8. Network differences

No differences were found. Both definitions put Prometheus on the project default network and external `proxy` network, cAdvisor on the default network, and node-exporter in host network/PID context as declared. Runtime matches: Prometheus is attached to `monitoring_default` and `proxy`, cAdvisor to `monitoring_default`, and node-exporter to `host` networking.

The live file is operationally authoritative, but no reconciliation is required. Host networking remains security-sensitive and should be retained or changed only through production review.

## 9. Restart policy differences

No differences were found. All three services declare `unless-stopped`, and runtime reports `unless-stopped`. The live file is operationally authoritative, but no reconciliation is required.

## 10. User/security/capability differences

No differences were found between rendered file settings. Neither file explicitly adds capabilities, drops capabilities, sets privileged mode, enables read-only root filesystems, or adds security options. Runtime shows:

- Prometheus runs as image user `nobody`, is not privileged, and has no explicit capability/security-option additions.
- node-exporter runs as image user `nobody`, is not privileged, uses host PID and host network modes, and Docker reports `label=disable` as a runtime security option.
- cAdvisor has no explicit image user in runtime metadata, is not privileged, and has no explicit capability/security-option additions.

The `label=disable` runtime value for node-exporter is consistent with host-level access behavior and is not evidence of file drift in the compared normalized fields. Live/runtime is authoritative for observed enforcement. Classification: **production-reviewed**. Why it matters: host PID/network access and broad host bind mounts materially increase visibility into the host; security hardening changes could disrupt monitoring and must not be automated from this audit.

## 11. Runtime metadata comparison

| Container | State/health | Runtime image reference | Key runtime match | Compose source label |
|---|---|---|---|---|
| `prometheus` | running / no healthcheck status | `prom/prometheus:latest` | Loopback port `9090`; live `/srv/docker/monitoring` config/data mounts; default + proxy networks; `unless-stopped` | `/srv/docker/monitoring/compose.yaml` |
| `node-exporter` | running / no healthcheck status | `prom/node-exporter:latest` | Both live command arguments; host network; host PID; `/` to `/host` read-only with `rslave`; `unless-stopped` | `/srv/docker/monitoring/compose.yaml` |
| `cadvisor` | running / healthy | `gcr.io/cadvisor/cadvisor:latest` | Loopback `8081` to container `8080`; four read-only host binds; default network; `unless-stopped` | `/srv/docker/monitoring/compose.yaml` |

Container creation metadata showed Prometheus and cAdvisor created on 2026-04-26 and node-exporter created on 2026-06-15 (local-date interpretation from Docker output). This timing is consistent with node-exporter having been recreated after the live file change, but that causal relationship is an inference, not proof.

## 12. Which version appears to match running containers

The **live production file** matches the running containers.

Evidence:

1. Every authorized container's `com.docker.compose.project.config_files` label points to `/srv/docker/monitoring/compose.yaml`.
2. Every authorized container's Compose working-directory label points to `/srv/docker/monitoring`.
3. The running node-exporter includes the textfile collector argument present only in the live file.
4. The running Prometheus mounts resolve to `/srv/docker/monitoring`, matching the live deployment context.
5. Images, ports, networks, restart policies, and remaining mounts align with the live rendered configuration.

For the two drift areas, live is more authoritative for observed production state. This does not automatically establish that every live-only behavior is the desired long-term source of truth; that intent should be confirmed before repo reconciliation.

## 13. Risk assessment

### Drift risk: moderate

- **Custom metric loss:** redeploying node-exporter from the repo definition could omit the textfile collector. Classification: **repo reconciliation**; live is more authoritative because runtime matches it.
- **Wrong Prometheus inputs/storage:** running the repo file directly from its current location could bind repo-local configuration and data paths instead of production paths. Classification: **production-reviewed**; live/runtime is more authoritative for production targets.
- **Non-reproducible image updates:** all services use mutable `latest` tags. Classification: **production-reviewed**; this is shared configuration rather than drift.

### Immediate operational risk: low based on inspected metadata

All scoped containers were running, and cAdvisor reported healthy. This audit did not query metrics endpoints, inspect logs, or validate Prometheus targets, so it does not establish end-to-end monitoring health.

## 14. Recommended repo reconciliation plan

1. Confirm with the monitoring owner that node-exporter textfile metrics are intentional and identify the producer(s) expected to write under `/var/lib/node_exporter/textfile_collector`. Classification: **documentation-only** until intent is confirmed.
2. Add the confirmed textfile collector argument to the tracked repo Compose file through normal review. Classification: **repo reconciliation**. The live setting is the current behavioral authority.
3. Document whether the repo Compose file is intended to be copied/rendered into `/srv/docker/monitoring` or run directly from the repo checkout. Classification: **documentation-only**.
4. Choose and review a deployment-safe mount strategy that preserves the production Prometheus config and data locations. Classification: **production-reviewed**. Do not infer the correct path model solely from this diff.
5. Separately evaluate pinning immutable image versions or digests and define an update process. Classification: **production-reviewed**.
6. After an approved repo-only change, re-run `docker compose ... config` against the intended deployment context and compare selected fields. Do not recreate production containers merely to verify repository reconciliation.

## 15. Items not safe to change automatically

- The live `/srv/docker/monitoring/compose.yaml` file or any live configuration.
- Any running container, image, network, or volume.
- Prometheus bind source paths or its writable data directory.
- The node-exporter textfile collector until its metric producers and operational intent are confirmed.
- Host networking, host PID mode, security labeling, capabilities, users, or broad host mounts.
- Mutable image tags or digest pinning without compatibility testing and an approved update process.
- File ownership or permissions merely to make live and repo metadata look identical.

These items are **production-reviewed** because changing them could affect availability, metric continuity, host visibility, or security. The live/runtime state is authoritative for what production currently uses; desired-state authority requires owner review.

## 16. No changes applied

No changes were made to either Compose file, `/srv/docker`, `/home/server/homelab`, any container, image, network, volume, database, or backup. No container was restarted, recreated, pulled, stopped, started, or updated. The only created artifact is this audit report under `/home/server/homelab-audits/monitoring-compose-drift/`.
