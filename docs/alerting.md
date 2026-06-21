# Homelab Alerting

## Purpose

This document describes the current homelab alerting architecture, alert rules, validation workflow, and known limitations.

## Architecture

- Grafana-managed alerts provide infrastructure and backup-freshness alerting.
- Discord is the notification destination.
- Grafana uses a custom Discord notification template.
- Alert rules use labels such as `severity=critical` and `severity=warning` for routing and message context.
- Uptime Kuma separately checks service availability. It is not the source of the infrastructure and backup-freshness rules documented here.
- Prometheus uses a global `15s` scrape interval and scrapes:
  - node-exporter at `host.docker.internal:9100`
  - cAdvisor at `cadvisor:8080`
  - the Pi-hole LXC node-exporter at `192.168.1.53:9100`
- Backup freshness metrics are exposed through the node-exporter textfile collector as `homelab_backup_*` metrics.

Grafana, Prometheus, and their administrative interfaces should remain internal/private.

## Backup Freshness Model

The backup share is hosted on the user's desktop and is not always mounted. Alerting should therefore focus on the age of the last successful backup rather than firing immediately when `/mnt/backupshare` is absent.

The textfile collector file is expected at:

```text
/var/lib/node_exporter/textfile_collector/backup_status.prom
```

The key freshness series is:

```promql
homelab_backup_age_seconds
```

Additional `homelab_backup_*` series and their labels may be present. Inspect the current metric output before changing alert selectors. The label schema and exact stale thresholds are not provisioned in this repository and need verification in the Grafana UI.

## Alert Rules

### Critical Backups Stale

**Purpose:** Detect stale backups for services classified as critical.

**PromQL/query shape:**

```promql
homelab_backup_age_seconds{<critical-backup-selector>} > <critical-threshold-seconds>
```

The exact label selector and threshold seconds need verification in the Grafana UI.

**Threshold:** Configured critical-backup maximum age. Needs verification in Grafana UI.

**Evaluation timing:** Needs verification in Grafana UI.

**No Data handling:** Needs verification in Grafana UI. Confirm that missing metrics are handled intentionally and are not silently masking a failed collector.

**Severity label:** `severity=critical`

**When it fires:**

1. Query `homelab_backup_age_seconds` in Prometheus and identify the stale backup series.
2. Inspect `/var/lib/node_exporter/textfile_collector/backup_status.prom` for the affected backup.
3. Confirm the relevant backup script last completed successfully.
4. Confirm the backup destination was available when that backup was expected to run.
5. Inspect the selected archive under `/mnt/backupshare/<stack>/archive/` when the share is mounted.
6. Verify operational scheduling with crontab or the active scheduler; scheduling is not documented as code in this repository.

### Standard Backups Stale

**Purpose:** Detect stale backups for services classified as standard/non-critical.

**PromQL/query shape:**

```promql
homelab_backup_age_seconds{<standard-backup-selector>} > <standard-threshold-seconds>
```

The exact label selector and threshold seconds need verification in the Grafana UI.

**Threshold:** Configured standard-backup maximum age. Needs verification in Grafana UI.

**Evaluation timing:** Needs verification in Grafana UI.

**No Data handling:** Needs verification in Grafana UI.

**Severity label:** `severity=warning`

**When it fires:**

1. Identify the stale series in Prometheus.
2. Check the textfile collector output and metric timestamp/age.
3. Check the corresponding backup archive when `/mnt/backupshare` is mounted.
4. Review backup-script output or operational scheduler logs.
5. Do not treat an intentionally unmounted desktop backup share as an immediate failure; determine whether the backup age exceeded its allowed window.

### Prometheus Target Down

**Purpose:** Detect when Prometheus cannot scrape node-exporter, cAdvisor, or the Pi-hole LXC target.

**PromQL/query shape:**

```promql
up
```

**Grafana condition:** Reduce using **Last**, then apply a threshold of **is below 1**.

The raw `up` metric is used because `up == 0` may return no series while every target is healthy. Using `up` with Grafana's **Reduce Last** and **Threshold is below 1** condition preserves healthy series and avoids treating the normal healthy state as No Data.

The Grafana query may further filter or group by `job` and `instance`; verify the exact selector in the Grafana UI.

**Threshold:** One or more expected targets report `up = 0`.

**Evaluation timing:** Needs verification in Grafana UI.

**No Data handling:** Needs verification in Grafana UI.

**Severity label:** `severity=critical`

**When it fires:**

1. Open Prometheus **Status > Targets** and identify the failed job/instance.
2. Check the target's last error and last scrape time.
3. Confirm network reachability from Prometheus to the target.
4. For the node job, check `host.docker.internal:9100`.
5. For cAdvisor, check `cadvisor:8080` on the monitoring network.
6. For Pi-hole LXC, check `192.168.1.53:9100` and the LXC/network path.

### OptiPlex Root Disk Above 85%

**Purpose:** Warn when the OptiPlex root filesystem exceeds 85% usage.

**PromQL/query shape:**

```promql
100 * (1 - (
  node_filesystem_avail_bytes{mountpoint="/",fstype!~"tmpfs|overlay"}
  /
  node_filesystem_size_bytes{mountpoint="/",fstype!~"tmpfs|overlay"}
)) > 85
```

The exact instance/device filters need verification in the Grafana UI so the rule targets the OptiPlex node rather than the Pi-hole LXC.

**Threshold:** Root filesystem usage above `85%`.

**Evaluation timing:** Needs verification in Grafana UI.

**No Data handling:** Needs verification in Grafana UI.

**Severity label:** `severity=warning`

**When it fires:**

1. Confirm the alert instance is the OptiPlex node.
2. Check root filesystem usage and inode usage.
3. Identify large Docker data, logs, caches, archives, or temporary files.
4. Confirm `/mnt/media` and `/mnt/backupshare` have not failed to mount in a way that redirected writes onto the root filesystem.
5. Avoid deleting data until ownership and retention requirements are understood.

### Backup Share Above 85%

**Purpose:** Warn when the mounted backup share exceeds 85% usage without alerting merely because the desktop-hosted share is intentionally unmounted.

**PromQL/query shape:**

```promql
100 * (1 - (
  node_filesystem_avail_bytes{mountpoint="/mnt/backupshare"}
  /
  node_filesystem_size_bytes{mountpoint="/mnt/backupshare"}
)) > 85
```

The exact instance/device filters need verification in the Grafana UI.

**Threshold:** Backup share usage above `85%` while mounted and emitting filesystem metrics.

**Evaluation timing:** Needs verification in Grafana UI.

**No Data handling:** `OK`. The desktop-hosted share may be intentionally unmounted.

**Severity label:** `severity=warning`

**When it fires:**

1. Confirm `/mnt/backupshare` is currently mounted.
2. Check filesystem capacity and identify which stack archive directories consume the most space.
3. Confirm backup retention cleanup is running as intended.
4. Check for unexpected duplicate archives or failed partial backups.
5. Do not delete the newest known-good backup without confirming another valid restore point exists.

## Manual Metric Verification

### Inspect The Textfile Collector

Run on the OptiPlex host:

```bash
cat /var/lib/node_exporter/textfile_collector/backup_status.prom
```

Expected:

- Valid Prometheus text exposition format.
- One or more `homelab_backup_*` metrics.
- No secret values in labels or metric content.

### Query node-exporter Directly

```bash
curl -s http://127.0.0.1:9100/metrics | grep '^homelab_backup_'
```

If node-exporter is checked from another trusted host, use the OptiPlex's private address instead of `127.0.0.1`. Do not expose node-exporter publicly.

### Query Prometheus

Use the Prometheus expression browser:

```promql
homelab_backup_age_seconds
```

Or query the local Prometheus HTTP API:

```bash
curl -sG http://127.0.0.1:9090/api/v1/query \
  --data-urlencode 'query=homelab_backup_age_seconds'
```

If the metric exists in node-exporter but not Prometheus, check the node target's scrape status and the textfile collector configuration.

## Verify Prometheus Targets

Open the internal Prometheus targets page:

```text
http://127.0.0.1:9090/targets
```

Or query the API:

```bash
curl -s http://127.0.0.1:9090/api/v1/targets
```

Expected jobs from repository configuration:

| Job | Target |
|---|---|
| `node` | `host.docker.internal:9100` |
| `cadvisor` | `cadvisor:8080` |
| `pihole-lxc` | `192.168.1.53:9100` |

Review each target's health, last scrape time, and last error.

## Discord Notifications

Grafana sends alerts to Discord through a contact point and custom notification template. Webhook URLs and credentials are intentionally not documented here.

### Test The Contact Point

1. Open the internal Grafana UI.
2. Go to **Alerting > Contact points**.
3. Select the Discord contact point.
4. Use Grafana's **Test** function.
5. Confirm a test message arrives in the intended Discord channel.
6. Confirm the custom template renders alert name, state, severity, and useful labels/annotations as expected.

If the test fails, check Grafana's error message and contact-point configuration without copying the webhook URL into tickets or Git.

## Temporarily Silence An Alert

Use a Grafana silence/mute timing rather than deleting or weakening the alert rule.

1. Open **Alerting > Silences** in Grafana. Depending on the Grafana version, this may appear under **Alerting > Alert rules** or **Alerting > Notification policies**.
2. Create a silence that matches the narrowest useful labels, such as the alert name, instance, job, or service.
3. Set an explicit start time, end time, owner, and reason.
4. Confirm unrelated critical alerts are not matched.
5. Remove or allow the silence to expire after maintenance.

If Grafana uses mute timings instead of silences for the current rule path, create a temporary mute timing and attach it through the relevant notification policy. Needs verification in the Grafana UI.

## Responsibilities And Separation

- Grafana-managed alerts: infrastructure health, disk capacity, Prometheus target status, and backup freshness.
- Uptime Kuma: service availability checks.
- Prometheus: metric collection and query source.
- node-exporter textfile collector: backup freshness metric publication.
- Discord: notification delivery only; it is not the source of alert state.

## Known Limitations

- Grafana alert rules, contact points, notification policies, and custom templates are configured through the Grafana UI unless later provisioned as code.
- Exact backup alert label selectors, stale thresholds, evaluation intervals, pending durations, and most No Data/error settings are not present in this repository and need verification in the Grafana UI.
- A deliberately unmounted backup share produces no filesystem data; the backup-share-fullness rule therefore uses **No Data = OK**.
- **No Data = OK** for share fullness must not replace stale-backup alerting. Backup age remains the primary signal that expected backups are not occurring.
- Discord delivery depends on external service availability and valid contact-point configuration.

## Future Improvements

- Provision Grafana alert rules, contact points, notification policies, and templates as code.
- If immediate provisioning is not practical, export and securely retain Grafana alerting resources for recovery and review.
- Document exact backup metric labels and stale thresholds in version-controlled, non-secret configuration.
- Add periodic alert tests for Discord delivery, target-down detection, disk thresholds, and stale-backup detection.
