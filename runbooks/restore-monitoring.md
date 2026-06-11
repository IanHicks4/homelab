# Restore Monitoring Stack

## Purpose And Scope

Restore the monitoring stack after a rebuild, failed update, Prometheus data loss, or damaged monitoring configuration.

This runbook is based on:

- `scripts/backups/backup-monitoring.sh`
- `compose/monitoring/compose.yaml`

Covered containers:

- `prometheus`
- `node-exporter`
- `cadvisor`

## Backup Archive Contains

Backup archives are stored under:

```bash
/mnt/backupshare/monitoring/archive/
```

Expected archive name:

```bash
monitoring-YYYY-MM-DD.tar.gz
```

The backup script archives:

```bash
/srv/docker/monitoring
```

Expected paths include:

```bash
/srv/docker/monitoring/prometheus.yml
/srv/docker/monitoring/data
```

Prometheus history is useful, but the configuration is usually more critical than historical time-series data.

## Backup Archive Does Not Contain

- Prometheus `./data/lock`.
- Prometheus `./data/queries.active`.
- Host filesystem mounts used by node-exporter and cAdvisor.
- Docker images, containers, or networks.
- Metrics from targets outside retained Prometheus data.

## Prerequisites

Verify the backup share and archive:

```bash
mountpoint /mnt/backupshare
ls -lh /mnt/backupshare/monitoring/archive
```

Verify the compose file exists:

```bash
ls -lh compose/monitoring/compose.yaml
```

## Restore Assumptions

- Host filesystem mounts are provided by the current host and are not restored from backup.
- The selected archive is from the intended restore date.
- The external `proxy` network exists if compose expects it.
- Restore commands may require an account with permission to write `/srv/docker/monitoring` and manage containers.

## Restore Procedure

Select an archive:

```bash
ls -lh /mnt/backupshare/monitoring/archive/monitoring-*.tar.gz
```

Stop containers in backup-script order:

```bash
docker stop cadvisor
docker stop node-exporter
docker stop prometheus
```

Move current directory aside:

```bash
mv /srv/docker/monitoring /srv/docker/monitoring.restore-old-$(date +%F-%H%M%S)
mkdir -p /srv/docker/monitoring
```

Extract the selected archive:

```bash
tar -xzf /mnt/backupshare/monitoring/archive/monitoring-YYYY-MM-DD.tar.gz -C /srv/docker/monitoring
```

Validate expected files:

```bash
test -f /srv/docker/monitoring/prometheus.yml
test -d /srv/docker/monitoring/data
```

Start containers in backup-script order:

```bash
docker start prometheus
docker start node-exporter
docker start cadvisor
```

If containers were recreated instead of stopped, start from compose:

```bash
cd compose/monitoring
docker compose up -d
```

Keep `/srv/docker/monitoring.restore-old-*` until restore is confirmed.

## Ownership And Permissions Notes

- Prometheus must be able to read `prometheus.yml` and write `data`.
- node-exporter and cAdvisor depend on host mounts defined in compose.
- If Prometheus refuses to start, inspect logs before changing ownership.

## Validation Steps

Verify containers and logs:

```bash
docker ps --filter name=prometheus
docker ps --filter name=node-exporter
docker ps --filter name=cadvisor
docker logs prometheus --tail 100
docker logs node-exporter --tail 100
docker logs cadvisor --tail 100
```

Validate local endpoints:

```bash
curl -I http://127.0.0.1:9090
curl -I http://127.0.0.1:8081
```

Validate Prometheus targets:

```bash
curl -s http://127.0.0.1:9090/api/v1/targets
```

Expected:

- Prometheus starts without TSDB corruption errors.
- Prometheus targets show expected scrape health.
- node-exporter and cAdvisor are running.
- Historical graphs may be present depending on retained data.

## Rollback Steps

Stop containers:

```bash
docker stop cadvisor
docker stop node-exporter
docker stop prometheus
```

Move failed restore aside:

```bash
mv /srv/docker/monitoring /srv/docker/monitoring.failed-restore-$(date +%F-%H%M%S)
```

Restore previous directory:

```bash
mv /srv/docker/monitoring.restore-old-YYYY-MM-DD-HHMMSS /srv/docker/monitoring
```

Start containers:

```bash
docker start prometheus
docker start node-exporter
docker start cadvisor
```

## Security And Sensitivity Notes

- Prometheus data may reveal hostnames, internal IPs, service names, and operational patterns.
- Do not commit restored Prometheus data or host-derived runtime state to Git.
- Monitoring services should remain localhost/private as configured.

## Known Limitations

- Host filesystem mounts are not backed up.
- Excluded Prometheus lock and active query files are regenerated.
- Historical data may be less important than restoring working scrape configuration.
- Backup scheduling is not proven by this runbook; verify separately.
