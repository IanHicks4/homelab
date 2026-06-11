# Service Inventory

## Status Model

This inventory is based on repository evidence only. It distinguishes between:

- Configured in repo: defined in Docker Compose, Caddy, monitoring, logging, backup scripts, or inventory files.
- Confirmed running in production: not confirmed by this document unless supported by runtime evidence such as `docker ps`, which was not inspected for this inventory.

Public exposure is marked as confirmed only when supported by `inventory/domains.md` or other explicit repository evidence. A Caddy route alone is treated as configured routing, not proof of public exposure.

## Overview

The repository documents a Docker-based homelab centered on the `server` host. Existing inventory identifies this host as a Dell OptiPlex with LAN IP `192.168.1.100` and Tailscale IP `100.77.136.106`.

The repo shows these main architectural pieces:

- Docker Compose stacks under `compose/`
- Caddy configured as the reverse proxy on ports `80` and `443`
- A shared external Docker network named `proxy` for proxied services
- Several admin services bound directly to `100.77.136.106`, identified in inventory as the server Tailscale IP
- `/mnt/media` as shared media storage
- `/mnt/backupshare` as the documented SMB backup destination
- Prometheus, cAdvisor, node-exporter, Grafana, Loki, and Alloy configured for monitoring and logging

## Service And Stack Table

| Stack | Main services | Purpose | Repo-configured access | Confirmed public exposure | Persistent data | Backup relevance |
|---|---|---|---|---|---|---|
| `arr` | Sonarr, Radarr, Prowlarr, Seerr, FlareSolverr, Bazarr, Recyclarr | Media automation and requests | Tailscale-bound admin ports; Seerr Caddy route | Seerr confirmed by `inventory/domains.md` | Config dirs, `/mnt/media` | Backup script and restore runbook exist |
| `authelia` | Authelia, Redis | Forward authentication | Proxy network; `auth.kai.coach` Caddy route | Internal/private; public DNS removed | Config, secrets mount, Redis data | Backup script and restore runbook exist |
| `caddy` | Caddy | Reverse proxy / TLS | `80:80`, `443:443` | Configured edge ports; running/exposure needs verification | Caddy data/config | Backup script and restore runbook exist |
| `ddns` | Porkbun DDNS | Dynamic DNS updates | Internal/background | Not applicable | Credential/config files | Backup script and restore runbook exist |
| `homepage-stack` | Homepage, Glances, Uptime Kuma | Dashboard, host metrics, uptime checks | Tailscale-bound Homepage; Caddy routes for Homepage and Uptime Kuma | Internal/private via Pi-hole DNS | Homepage config, Uptime Kuma data | Backup script and restore runbook exist |
| `immich` | Immich server, ML, Redis, Postgres | Photo library | Caddy route; no active host port | Confirmed by `inventory/domains.md` | Upload library, database, model cache | Backup script and restore runbook exist |
| `it-tools` | IT Tools | Utility tools | `100.77.136.106:8085`; Caddy route | Internal/private via Pi-hole DNS | No volume shown | Low, based on repo config |
| `jellyfin` | Jellyfin | Media streaming | Host network; Caddy route | Confirmed by `inventory/domains.md` | Config, `/mnt/media` | Backup script and restore runbook exist |
| `logging` | Loki, Grafana, Alloy | Log collection and dashboards | Localhost ports; Grafana Caddy route | Grafana internal/private via Pi-hole DNS | Loki data, Grafana data | Backup script and restore runbook exist |
| `monitoring` | Prometheus, node-exporter, cAdvisor | Metrics collection | Localhost ports; proxy network for Prometheus | No public route found | Prometheus data | Backup script and restore runbook exist |
| `n8n` | n8n | Workflow automation and webhooks | `n8n.kai.coach` internal route; address-form webhook route | Internal/private via Pi-hole DNS | `/srv/docker/n8n` | Backup script and restore runbook exist |
| `speedtest-tracker` | Speedtest Tracker | Network speed history | `100.77.136.106:8082`; proxy network | Needs verification | `./config` | Backup script and restore runbook exist |
| `vaultwarden` | Vaultwarden | Password manager | `vault.kai.coach` Caddy route | Internal/private via Pi-hole DNS | `./data` | Backup script and restore runbook exist |
| `vpn` | Gluetun, qBittorrent | VPN-bound torrent client | `100.77.136.106:8080` | No | VPN config, qBittorrent config, `/mnt/media` | Backup script and restore runbook exist |
| `wedding-address-form` | nginx static site | Address form frontend | `address.kai.coach` route | Public address form; webhook proxies internally to n8n | Static `./html`; n8n handles webhook | Needs verification |

## Stack Details

### `arr`

Status:

- Configured in repo: yes.
- Confirmed running in production: needs verification.

Main services:

- `sonarr`
- `radarr`
- `prowlarr`
- `seerr`
- `flaresolverr`
- `bazarr`
- `recyclarr`

Purpose:

- Media automation, indexer management, subtitle management, media requests, and profile synchronization.

Ports and routes:

- Sonarr: `100.77.136.106:8989:8989`
- Radarr: `100.77.136.106:7878:7878`
- Prowlarr: `100.77.136.106:9696:9696`
- Bazarr: `100.77.136.106:6767:6767`
- Seerr: Caddy route `seerr.kai.coach`

Access classification:

- Sonarr, Radarr, Prowlarr, and Bazarr are configured for Tailscale/private access based on the server Tailscale IP binding.
- Seerr public exposure is confirmed by `inventory/domains.md`.

Persistent volumes/bind mounts:

- `./sonarr:/config`
- `./radarr:/config`
- `./prowlarr:/config`
- `./seerr:/app/config`
- `./bazarr:/config`
- `./recyclarr:/config`
- `/mnt/media:/media`

Backup relevance:

- Persistent application configs and shared media paths are present.
- Verified backup script: `scripts/backups/backup-arr.sh`.
- Verified restore runbook: `runbooks/restore-arr.md`.
- The backup script archives `/srv/docker/arr` to `/mnt/backupshare/arr/archive` after stopping Arr stack containers for a clean backup.
- Arr configs may contain API keys or service credentials and must not be committed to Git.

Monitoring/logging relevance:

- Alloy is configured to discover Docker containers and forward Docker logs to Loki.

Security notes:

- Admin services are configured on the server Tailscale IP.
- Seerr is confirmed as public-facing by inventory.
- Any credentials used by these tools need verification outside this repo.

### `authelia`

Status:

- Configured in repo: yes.
- Confirmed running in production: yes; Authelia is running and used.

Main services:

- `authelia`
- `redis`

Purpose:

- Authentication and forward-auth provider for selected Caddy routes.

Ports and routes:

- No host ports are configured in compose.
- Caddy route `auth.kai.coach` proxies to `authelia:9091`.

Access classification:

- Intended for internal/private access.
- Caddy route `auth.kai.coach` remains valid for internal access.
- `auth.kai.coach` is handled by Pi-hole internal DNS and is not managed by the Porkbun DDNS container.
- The previous manual/static Porkbun DNS record for `auth.kai.coach` was removed; current public DNS no longer resolves.

Persistent volumes/bind mounts:

- `./config:/config`
- `./secrets:/secrets:ro`
- `./redis:/data`

Backup relevance:

- Config, mounted secret files, and Redis data are persistent.
- Verified backup script: `scripts/backups/backup-authelia.sh`.
- Verified restore runbook: `runbooks/restore-authelia.md`.
- The backup script archives `/srv/docker/authelia` to `/mnt/backupshare/authelia/archive` and requires root because Authelia secrets and Redis data may be permission-restricted.
- Authelia secrets, including `jwt_secret`, `session_secret`, and `storage_encryption_key`, must be restored exactly from backup.

Monitoring/logging relevance:

- Docker logs should be collected by Alloy if the container is running.

Security notes:

- Secret file paths are referenced for JWT, session, and storage encryption keys.
- The secrets mount is read-only.
- Do not treat example env files as proof of live secret values.
- `config/.env` and files under `secrets/` are sensitive and must not be committed to Git.
- Authelia should remain internal/private even if a Caddy route is configured.

### `caddy`

Status:

- Configured in repo: yes.
- Confirmed running in production: needs verification.

Main services:

- `caddy`

Purpose:

- Reverse proxy and TLS handling.

Ports and routes:

- `80:80`
- `443:443`

Access classification:

- Configured as the HTTP/HTTPS edge proxy.
- Public services behind Caddy are only considered confirmed public when supported by `inventory/domains.md`.

Persistent volumes/bind mounts:

- `./Caddyfile:/etc/caddy/Caddyfile`
- `./data:/data`
- `./config:/config`

Backup relevance:

- Caddy state and config are persistent.
- Verified backup script: `scripts/backups/backup-caddy.sh`.
- Verified restore runbook: `runbooks/restore-caddy.md`.
- The backup script archives `/srv/docker/caddy` to `/mnt/backupshare/caddy/archive` and requires root because Caddy data/config may be permission-restricted.

Monitoring/logging relevance:

- Docker logs should be collected by Alloy if the container is running.

Security notes:

- `home.kai.coach`, `status.kai.coach`, and `grafana.kai.coach` import the Authelia forward-auth snippet.
- `home.kai.coach`, `status.kai.coach`, and `grafana.kai.coach` remain configured in Caddy for internal/private access.
- Several Caddy routes use `tls internal`.
- Caddy route configuration does not by itself confirm public internet exposure.
- Caddy certificate state and reverse-proxy config are sensitive operational state and must not be committed to Git if copied from live data.

### `ddns`

Status:

- Configured in repo: yes.
- Confirmed running in production: needs verification.

Main services:

- `porkbun-ddns`

Purpose:

- Dynamic DNS updates for `kai.coach`.

Ports and routes:

- No host ports are configured.

Access classification:

- Internal/background service.

Persistent volumes/bind mounts:

- None shown.
- Operational files under `/srv/docker/ddns` are covered by `scripts/backups/backup-ddns.sh`.

Backup relevance:

- Verified backup script: `scripts/backups/backup-ddns.sh`.
- Verified restore runbook: `runbooks/restore-ddns.md`.
- The backup script archives `/srv/docker/ddns` to `/mnt/backupshare/ddns/archive` and requires root because DDNS `.env` credentials may be permission-restricted.
- DDNS API keys are sensitive and must not be committed to Git.

Monitoring/logging relevance:

- Docker logs should be collected by Alloy if the container is running.

Security notes:

- API key environment variable names are referenced.
- No real secret values are included in this document.
- Public Porkbun/DDNS records should remain limited to `jellyfin`, `seerr`, `immich`, and `address`.
- `compose/ddns/compose.yaml` should not be treated as the source of access for internal/private routes.
- `home.kai.coach`, `status.kai.coach`, and `grafana.kai.coach` are intentionally handled by Pi-hole internal DNS, resolve internally to `100.77.136.106`, are not managed by Porkbun DDNS, and should not publicly resolve.
- `vault.kai.coach`, `auth.kai.coach`, and `tools.kai.coach` are intentionally handled by Pi-hole internal DNS and are not managed by the Porkbun DDNS container.
- `n8n.kai.coach` is also intentionally handled by Pi-hole internal DNS on both the Pi 4 and Pi-hole LXC, points to `100.77.136.106`, and is not public-Porkbun-DNS-managed.
- The public Porkbun DNS record for `n8n.kai.coach` was removed; current public DNS no longer resolves.
- `auth.kai.coach` previously had a manual/static Porkbun DNS record and was externally reachable.
- The `auth.kai.coach` Porkbun DNS record was removed; current public DNS no longer resolves.
- `vault.kai.coach` and `tools.kai.coach` also do not publicly resolve based on the current DNS check.

### `homepage-stack`

Status:

- Configured in repo: yes.
- Confirmed running in production: needs verification.

Main services:

- `homepage`
- `glances`
- `uptime-kuma`

Purpose:

- Dashboard, host metrics, and uptime monitoring.

Ports and routes:

- Homepage: `100.77.136.106:3000:3000`
- Glances: `network_mode: host`
- Caddy route `home.kai.coach`
- Caddy route `status.kai.coach`

Access classification:

- Homepage has a Tailscale/private port binding.
- `home.kai.coach` and `status.kai.coach` remain configured in Caddy for internal/private access.
- `home.kai.coach` and `status.kai.coach` are resolved internally by Pi-hole to `100.77.136.106`.
- `home.kai.coach` and `status.kai.coach` are not managed by Porkbun DDNS and should not publicly resolve.

Persistent volumes/bind mounts:

- `./homepage-config:/app/config`
- `/var/run/docker.sock:/var/run/docker.sock:ro`
- `/mnt/media:/mnt/media:ro`
- `./uptime-kuma:/app/data`
- Glances read-only host mounts include Docker socket, OS release, proc, sys, and root filesystem.

Backup relevance:

- Homepage config and Uptime Kuma data are persistent.
- Verified backup script: `scripts/backups/backup-homepage-stack.sh`.
- Verified restore runbook: `runbooks/restore-homepage-stack.md`.
- The backup script archives `/srv/docker/homepage-stack` to `/mnt/backupshare/homepage-stack/archive` and requires root because Homepage env/config and Uptime Kuma data may be permission-restricted.
- `homepage-config/.env` and Uptime Kuma data are sensitive and must not be committed to Git.

Monitoring/logging relevance:

- Uptime Kuma is configured as a service in this stack, but specific monitors need verification.
- Glances is configured for host metrics.
- Docker logs should be collected by Alloy if containers are running.

Security notes:

- Runtime inspection and repo references confirm Docker socket mounts for Homepage and Glances in `compose/homepage-stack/compose.yaml`.
- Homepage read-only Docker socket access is intentionally retained for Docker/container dashboard widgets.
- Glances Docker socket and host-level read-only mounts are intentionally retained for host/process metrics consumed by Homepage widgets, including Opti CPU and top-process visibility.
- Homepage integration secrets and Uptime Kuma notification/monitor data are sensitive.
- Treat Docker socket access as high-trust even when mounted read-only; this is an accepted risk, not an immediate removal task.
- Homepage and Glances must remain internal/private and should not be publicly exposed.
- Caddy routes for Homepage and Uptime Kuma import Authelia forward auth.

### `immich`

Status:

- Configured in repo: yes.
- Confirmed running in production: needs verification.

Main services:

- `immich-server`
- `immich-machine-learning`
- `redis`
- `database`

Purpose:

- Photo and video library management.

Ports and routes:

- No active host port is configured.
- Commented Tailscale/private port: `100.77.136.106:2283:2283`
- Caddy route `immich.kai.coach`

Access classification:

- Public exposure is confirmed by `inventory/domains.md`.

Persistent volumes/bind mounts:

- `${UPLOAD_LOCATION}:/usr/src/app/upload`
- `./config.yml:${IMMICH_CONFIG_FILE}:ro`
- `/dev/dri:/dev/dri`
- `model-cache:/cache`
- `${DB_DATA_LOCATION}:/var/lib/postgresql/data`

Backup relevance:

- Verified backup script: `scripts/backups/backup-immich.sh`.
- Verified restore runbook: `runbooks/restore-immich.md`.
- The backup script references library, Postgres dump, and compose backup paths.
- Immich `.env`, media library contents, and database metadata are sensitive and must not be committed to Git.

Monitoring/logging relevance:

- Docker logs should be collected by Alloy if containers are running.
- Uptime Kuma coverage needs verification.

Security notes:

- Uses environment variables from `.env`; live values were not inspected.
- Personal media and database metadata are sensitive.

### `it-tools`

Status:

- Configured in repo: yes.
- Confirmed running in production: needs verification.

Main services:

- `it-tools`

Purpose:

- Browser-based utility tools.

Ports and routes:

- Compose exposes `100.77.136.106:8085:80`.
- Caddy route `tools.kai.coach` proxies to `it-tools:80`.

Access classification:

- Direct port is configured for Tailscale/private access.
- Caddy proxies `tools.kai.coach` to `it-tools:80`.
- Direct Tailscale/private access uses `100.77.136.106:8085`.
- `tools.kai.coach` is an internal/private route handled by Pi-hole internal DNS.
- `tools.kai.coach` is not managed by the Porkbun DDNS container and does not publicly resolve based on the current DNS check.

Persistent volumes/bind mounts:

- None shown.

Backup relevance:

- No persistent volume is shown.

Monitoring/logging relevance:

- Docker logs should be collected by Alloy if the container is running.

Security notes:

- Caddy route does not import the Authelia forward-auth snippet.

### `jellyfin`

Status:

- Configured in repo: yes.
- Confirmed running in production: needs verification.

Main services:

- `jellyfin`

Purpose:

- Media streaming.

Ports and routes:

- Uses `network_mode: host`.
- Caddy route `jellyfin.kai.coach` proxies to `host.docker.internal:8096`.

Access classification:

- Public exposure is confirmed by `inventory/domains.md`.

Persistent volumes/bind mounts:

- `./config:/config`
- `/mnt/media:/media`
- `/srv/docker/jellyfin/config/index.html:/usr/share/jellyfin/web/index.html`
- `/dev/dri:/dev/dri`

Backup relevance:

- Jellyfin config and media storage are persistent.
- Verified backup script: `scripts/backups/backup-jellyfin.sh`.
- Verified restore runbook: `runbooks/restore-jellyfin.md`.
- Verified media restore runbook: `runbooks/restore-media-drive.md`.
- The backup script archives `/srv/docker/jellyfin` to `/mnt/backupshare/jellyfin/archive` after stopping Jellyfin for a clean config backup.

Monitoring/logging relevance:

- Docker logs should be collected by Alloy if the container is running.

Security notes:

- Public-facing service per inventory.
- Uses hardware device `/dev/dri`.

### `logging`

Status:

- Configured in repo: yes.
- Confirmed running in production: needs verification.

Main services:

- `loki`
- `grafana`
- `alloy`

Purpose:

- Central log collection and dashboards.

Ports and routes:

- Loki: `127.0.0.1:3100:3100`
- Grafana: `127.0.0.1:3002:3000`
- Alloy: `127.0.0.1:12345:12345`
- Caddy route `grafana.kai.coach`

Access classification:

- Direct ports are localhost-bound.
- Grafana Caddy route remains configured for internal/private access.
- `grafana.kai.coach` uses internal TLS and Authelia forward auth.
- `grafana.kai.coach` is resolved internally by Pi-hole to `100.77.136.106`.
- `grafana.kai.coach` is not managed by Porkbun DDNS and should not publicly resolve.

Persistent volumes/bind mounts:

- `./loki/config.yml:/etc/loki/config.yml:ro`
- `./loki/data:/loki`
- `./grafana/data:/var/lib/grafana`
- `./alloy/config.alloy:/etc/alloy/config.alloy:ro`
- `/var/run/docker.sock:/var/run/docker.sock:ro`
- `/var/log/journal:/var/log/journal:ro`
- `/etc/machine-id:/etc/machine-id:ro`

Backup relevance:

- Loki and Grafana data are persistent.
- Verified backup script: `scripts/backups/backup-logging.sh`.
- Verified restore runbook: `runbooks/restore-logging.md`.
- The backup script archives `/srv/docker/logging` to `/mnt/backupshare/logging/archive` and requires root because Grafana/Loki data and logging `.env` may be permission-restricted.
- Grafana admin settings, logging `.env`, Loki data, and Alloy config may contain sensitive state and must not be committed to Git.

Monitoring/logging relevance:

- Alloy is configured to discover Docker containers and forward Docker logs to Loki.
- Loki retention is configured for `168h`.

Security notes:

- Grafana admin password is referenced through environment configuration; no value is included here.
- Runtime inspection and repo references confirm Alloy Docker socket use in `compose/logging/compose.yaml`.
- Alloy read-only Docker socket access is intentionally retained for Docker log discovery and labeling.
- Treat Docker socket access as high-trust even when mounted read-only; this is an accepted risk, not an immediate removal task.
- Alloy and the logging admin surfaces must remain internal/private and should not be publicly exposed.

### `monitoring`

Status:

- Configured in repo: yes.
- Confirmed running in production: needs verification.

Main services:

- `prometheus`
- `node-exporter`
- `cadvisor`

Purpose:

- Metrics collection for the host, containers, and a Pi-hole LXC target.

Ports and routes:

- Prometheus: `127.0.0.1:9090:9090`
- cAdvisor: `127.0.0.1:8081:8080`
- node-exporter uses host networking.

Access classification:

- Localhost-bound for direct access.
- No Caddy route was found in the inspected Caddyfile.

Persistent volumes/bind mounts:

- `./prometheus.yml:/etc/prometheus/prometheus.yml:ro`
- `./data:/prometheus`
- node-exporter: `/:/host:ro,rslave`
- cAdvisor: host Docker/system paths read-only

Backup relevance:

- Prometheus data is persistent.
- Verified backup script: `scripts/backups/backup-monitoring.sh`.
- Verified restore runbook: `runbooks/restore-monitoring.md`.
- The backup script archives `/srv/docker/monitoring` to `/mnt/backupshare/monitoring/archive` and requires root because Prometheus data may be permission-restricted.

Monitoring/logging relevance:

- Prometheus scrapes `host.docker.internal:9100`, `cadvisor:8080`, and `192.168.1.53:9100`.

Security notes:

- Metrics services mount host paths read-only.
- Prometheus and cAdvisor ports are localhost-bound.

### `n8n`

Status:

- Configured in repo: yes.
- Confirmed running in production: needs verification.

Main services:

- `n8n`

Purpose:

- Workflow automation and webhook handling.

Ports and routes:

- No active host port is configured.
- Commented Tailscale/private port: `100.77.136.106:5678:5678`
- Caddy route `n8n.kai.coach` proxies to `n8n:5678`.
- Caddy route `address.kai.coach` sends `/api/wedding-address` to the n8n webhook path `/webhook/wedding-address`.

Access classification:

- n8n UI/admin access through `n8n.kai.coach` is internal/private only and should not be publicly reachable.
- `n8n.kai.coach` is resolved internally by Pi-hole on both the Pi 4 and Pi-hole LXC.
- Internal DNS points `n8n.kai.coach` to `100.77.136.106`.
- The public Porkbun DNS record for `n8n.kai.coach` was removed; current public DNS no longer resolves.
- The n8n container is not directly host-published.
- `address.kai.coach` remains public and points to the WAN IP.
- `address.kai.coach/api/wedding-address` remains the public address-form webhook path and proxies internally to `n8n:5678`.

Persistent volumes/bind mounts:

- `/srv/docker/n8n:/home/node/.n8n`

Backup relevance:

- n8n persistent data may include workflows and credentials.
- Verified backup script: `scripts/backups/backup-n8n.sh`.
- Verified restore runbook: `runbooks/restore-n8n.md`.
- The backup script archives `/srv/docker/n8n` to `/mnt/backupshare/n8n/archive` after stopping the `n8n` container for a clean SQLite backup.

Monitoring/logging relevance:

- Docker logs should be collected by Alloy if the container is running.

Security notes:

- Treat n8n persistent data as sensitive.
- n8n workflows and credentials are sensitive and must not be committed to Git.
- Caddy route `n8n.kai.coach` does not import the Authelia forward-auth snippet.
- n8n UI/admin access should remain internal/private.
- Public access should be limited to the address-form webhook path through `address.kai.coach/api/wedding-address`.

### `speedtest-tracker`

Status:

- Configured in repo: yes.
- Confirmed running in production: needs verification.

Main services:

- `speedtest-tracker`

Purpose:

- Network speed test tracking.

Ports and routes:

- `100.77.136.106:8082:80`

Access classification:

- Configured for Tailscale/private access by direct port binding.
- Attached to the `proxy` network, but no Caddy route was found.

Persistent volumes/bind mounts:

- `./config:/config`

Backup relevance:

- Config/history data is persistent.
- Verified backup script: `scripts/backups/backup-speedtest-tracker.sh`.
- Verified restore runbook: `runbooks/restore-speedtest-tracker.md`.
- The backup script archives `/srv/docker/speedtest-tracker` to `/mnt/backupshare/speedtest-tracker/archive` and requires root because config, database, and secrets may be permission-restricted.
- Speedtest Tracker `.env`, config, and database files are sensitive and must not be committed to Git.

Monitoring/logging relevance:

- Docker logs should be collected by Alloy if the container is running.

Security notes:

- Uses an env file; live values were not inspected.

### `vaultwarden`

Status:

- Configured in repo: yes.
- Confirmed running in production: needs verification.

Main services:

- `vaultwarden`

Purpose:

- Password manager.

Ports and routes:

- No host port is configured.
- Caddy route `vault.kai.coach` proxies to `vaultwarden:80`.

Access classification:

- Existing inventory classifies `vault.kai.coach` as restricted/internal.
- This document does not classify Vaultwarden as public-facing.
- `vault.kai.coach` is an internal/private route handled by Pi-hole internal DNS.
- Caddy route `vault.kai.coach` remains valid for internal access.
- `vault.kai.coach` is not managed by the Porkbun DDNS container and does not publicly resolve based on the current DNS check.

Persistent volumes/bind mounts:

- `./data:/data`

Backup relevance:

- Verified backup script: `scripts/backups/backup-vault.sh`.
- Verified restore runbook: `runbooks/restore-vaultwarden.md`.
- The backup script archives Vaultwarden data and syncs the live data directory under `/mnt/backupshare/vaultwarden`.
- Vaultwarden data and environment-derived admin configuration are sensitive and must not be committed to Git.

Monitoring/logging relevance:

- Docker logs should be collected by Alloy if the container is running.
- Uptime Kuma coverage needs verification.

Security notes:

- Contains password vault data.
- Signups are disabled in compose.
- Admin token is referenced through environment configuration; no value is included here.
- A public DNS record, if added or found later, would not by itself mean Vaultwarden should be publicly accessible.

### `vpn`

Status:

- Configured in repo: yes.
- Confirmed running in production: needs verification.

Main services:

- `gluetun`
- `qbittorrent`

Purpose:

- VPN container and qBittorrent client routed through the VPN network namespace.

Ports and routes:

- `100.77.136.106:8080:8080`

Access classification:

- Configured for Tailscale/private access.

Persistent volumes/bind mounts:

- `./gluetun:/gluetun`
- `./qbittorrent:/config`
- `/mnt/media:/media`
- `/dev/net/tun:/dev/net/tun`

Backup relevance:

- VPN and qBittorrent config are persistent.
- `/mnt/media` is shared media storage.
- Verified backup script: `scripts/backups/backup-vpn.sh`.
- Verified restore runbook: `runbooks/restore-vpn.md`.
- The backup script archives `/srv/docker/vpn` to `/mnt/backupshare/vpn/archive` and requires root because VPN/qBittorrent config and secrets may be permission-restricted.
- VPN/WireGuard secrets, qBittorrent config, and related `.env` values are sensitive and must not be committed to Git.

Monitoring/logging relevance:

- Docker logs should be collected by Alloy if containers are running.

Security notes:

- WireGuard private key is referenced through environment configuration; no value is included here.
- Gluetun has `NET_ADMIN` capability and `/dev/net/tun` access.

### `wedding-address-form`

Status:

- Configured in repo: yes.
- Confirmed running in production: needs verification.

Main services:

- `wedding-address-form`

Purpose:

- Static nginx frontend for address collection.

Ports and routes:

- No active host port is configured.
- Commented host port: `8090:80`
- Caddy route `address.kai.coach` proxies normal requests to `wedding-address-form:80`.
- Caddy route `address.kai.coach/api/wedding-address` rewrites to `/webhook/wedding-address` and proxies to `n8n:5678`.

Access classification:

- `address.kai.coach` remains public and points to the WAN IP.
- `address.kai.coach/api/wedding-address` proxies internally to `n8n:5678`.
- Public address-form access is separate from n8n UI/admin access, which should not be publicly reachable.

Persistent volumes/bind mounts:

- `./html:/usr/share/nginx/html:ro`

Backup relevance:

- Static frontend content is mounted read-only.
- Any submitted data or workflow state appears related to n8n and needs verification.

Monitoring/logging relevance:

- Docker logs should be collected by Alloy if the container is running.

Security notes:

- `address.kai.coach` is intentionally public.
- The webhook path exposes selected n8n workflow execution through `address.kai.coach/api/wedding-address`, while n8n UI/admin access remains internal/private.

## Confirmed Public-Facing Services

Confirmed by `inventory/domains.md` or current DNS/access decision:

| Service | Domain | Evidence |
|---|---|---|
| Jellyfin | `jellyfin.kai.coach` | Listed under public domains and configured in Caddy |
| Seerr | `seerr.kai.coach` | Listed under public domains and configured in Caddy |
| Immich | `immich.kai.coach` | Listed under public domains and configured in Caddy |
| Wedding address form | `address.kai.coach` | Remains public and points to the WAN IP; webhook path proxies internally to n8n |

## Configured Routes With Exposure Notes

These routes are configured in the repo and have internal/private or route-specific exposure notes:

| Service | Domain / route | Reason verification is needed |
|---|---|---|
| Authelia | `auth.kai.coach` | Internal/private via Pi-hole DNS after public Porkbun DNS cleanup; not Porkbun-DDNS-managed |
| Homepage | `home.kai.coach` | Internal/private via Pi-hole DNS; points to `100.77.136.106`; not Porkbun-DDNS-managed |
| Uptime Kuma | `status.kai.coach` | Internal/private via Pi-hole DNS; points to `100.77.136.106`; not Porkbun-DDNS-managed |
| Grafana | `grafana.kai.coach` | Internal/private via Pi-hole DNS; points to `100.77.136.106`; uses internal TLS and Authelia forward auth; not Porkbun-DDNS-managed |
| n8n UI | `n8n.kai.coach` | Internal/private via Pi-hole DNS on Pi 4 and Pi-hole LXC; points to `100.77.136.106`; public Porkbun DNS removed |
| Address-form webhook | `address.kai.coach/api/wedding-address` | Public webhook path on `address.kai.coach`; proxies internally to `n8n:5678` |
| Wedding address form | `address.kai.coach` | Public address form; points to WAN IP |
| IT Tools | `tools.kai.coach` | Internal/private via Pi-hole DNS; Caddy route remains valid for internal access; not Porkbun-DDNS-managed |
| Vaultwarden | `vault.kai.coach` | Internal/private via Pi-hole DNS; Caddy route remains valid for internal access; not Porkbun-DDNS-managed |

## Tailscale / Private-Bound Services

The following services are configured to bind to `100.77.136.106`, which inventory identifies as the server Tailscale IP:

| Service | Port |
|---|---|
| Sonarr | `8989` |
| Radarr | `7878` |
| Prowlarr | `9696` |
| Bazarr | `6767` |
| qBittorrent via Gluetun | `8080` |
| Homepage | `3000` |
| IT Tools | `8085` |
| Speedtest Tracker | `8082` |

## Services With Sensitive Data

| Service/stack | Sensitive data type |
|---|---|
| Vaultwarden | Password vault data and admin-token environment reference |
| Immich | Personal photos/videos and database metadata |
| Authelia | Authentication config, mounted secret files, Redis data |
| n8n | Workflow data and likely credential storage |
| DDNS | DNS provider API credential references |
| VPN/Gluetun | WireGuard private-key environment reference |
| qBittorrent | Download client config and media paths |
| Homepage | Integration configuration and read-only Docker socket access |
| Grafana | Admin credential environment reference and dashboard data |
| Caddy | TLS/certificate state and reverse-proxy config |
| Monitoring | Prometheus data and host/container metric history |
| Speedtest Tracker | App config/history and env-file usage |
| Arr stack | Service configs and possible API tokens in persistent config |
| Jellyfin | Media library config and user/server metadata |

## Existing Backup And Restore Evidence

Backup scripts are under `scripts/backups/`. Restore runbooks are under `runbooks/`.

Some backup scripts require root because they archive sensitive or permission-restricted data. Sensitive files such as `.env` files, Authelia secrets, VPN/WireGuard secrets, Homepage integration secrets, n8n credentials/workflows, Vaultwarden data, Caddy certificate state, and DDNS API keys must not be committed to Git.

The repository proves script and runbook presence. It does not prove scheduling. If backups are scheduled operationally, verify with crontab or the relevant scheduler on the host.

Verified backup scripts:

| Service | File |
|---|---|
| Arr stack | `scripts/backups/backup-arr.sh` |
| Authelia | `scripts/backups/backup-authelia.sh` |
| Caddy | `scripts/backups/backup-caddy.sh` |
| DDNS | `scripts/backups/backup-ddns.sh` |
| Homepage/Uptime Kuma/Glances | `scripts/backups/backup-homepage-stack.sh` |
| Immich | `scripts/backups/backup-immich.sh` |
| Jellyfin | `scripts/backups/backup-jellyfin.sh` |
| Logging/Grafana/Loki/Alloy | `scripts/backups/backup-logging.sh` |
| Monitoring/Prometheus | `scripts/backups/backup-monitoring.sh` |
| n8n | `scripts/backups/backup-n8n.sh` |
| Speedtest Tracker | `scripts/backups/backup-speedtest-tracker.sh` |
| Vaultwarden | `scripts/backups/backup-vault.sh` |
| VPN/qBittorrent/Gluetun | `scripts/backups/backup-vpn.sh` |

Verified restore runbooks:

| Area | File |
|---|---|
| Arr stack | `runbooks/restore-arr.md` |
| Authelia | `runbooks/restore-authelia.md` |
| Caddy | `runbooks/restore-caddy.md` |
| DDNS | `runbooks/restore-ddns.md` |
| Homepage/Uptime Kuma/Glances | `runbooks/restore-homepage-stack.md` |
| Immich | `runbooks/restore-immich.md` |
| Jellyfin | `runbooks/restore-jellyfin.md` |
| Logging/Grafana/Loki/Alloy | `runbooks/restore-logging.md` |
| Media drive | `runbooks/restore-media-drive.md` |
| Monitoring/Prometheus | `runbooks/restore-monitoring.md` |
| n8n | `runbooks/restore-n8n.md` |
| Speedtest Tracker | `runbooks/restore-speedtest-tracker.md` |
| Vaultwarden | `runbooks/restore-vaultwarden.md` |
| VPN/qBittorrent/Gluetun | `runbooks/restore-vpn.md` |

Other operational runbooks present:

| Area | File |
|---|---|
| Docker updates | `runbooks/docker-updates.md` |
| OptiPlex rebuild | `runbooks/rebuild-optiplex.md` |
| Troubleshooting | `runbooks/troubleshooting.md` |

Backup coverage summary:

| Service/stack | Backup script path | Restore runbook path | Backup scope | Sensitivity notes | Status |
|---|---|---|---|---|---|
| Immich | `scripts/backups/backup-immich.sh` | `runbooks/restore-immich.md` | Postgres dump, media library sync, compose backup paths | `.env`, personal media, and database metadata are sensitive | complete |
| Vaultwarden | `scripts/backups/backup-vault.sh` | `runbooks/restore-vaultwarden.md` | Vaultwarden data archive and data sync | Vault data and admin-token-derived configuration are sensitive | complete |
| n8n | `scripts/backups/backup-n8n.sh` | `runbooks/restore-n8n.md` | `/srv/docker/n8n` archive after stopping n8n | Workflows, credentials, and runtime state are sensitive | complete |
| Authelia | `scripts/backups/backup-authelia.sh` | `runbooks/restore-authelia.md` | `/srv/docker/authelia` archive including config, secrets, and Redis data | `jwt_secret`, `session_secret`, and `storage_encryption_key` must be restored exactly | complete |
| Homepage/Uptime Kuma/Glances | `scripts/backups/backup-homepage-stack.sh` | `runbooks/restore-homepage-stack.md` | `/srv/docker/homepage-stack` archive including Homepage config and Uptime Kuma data | `homepage-config/.env`, integration secrets, notification data, and monitor data are sensitive | complete |
| Caddy | `scripts/backups/backup-caddy.sh` | `runbooks/restore-caddy.md` | `/srv/docker/caddy` archive after Caddy config validation | TLS/certificate state and reverse-proxy config are sensitive | complete |
| Media drive | Not in `scripts/backups/` | `runbooks/restore-media-drive.md` | Shared media storage restore documentation | Media contents may be private | partial |
| Logging/Grafana/Loki/Alloy | `scripts/backups/backup-logging.sh` | `runbooks/restore-logging.md` | `/srv/docker/logging` archive including Grafana and Loki data | Grafana admin settings, `.env`, Loki data, and Alloy config may be sensitive | complete |
| Arr stack | `scripts/backups/backup-arr.sh` | `runbooks/restore-arr.md` | `/srv/docker/arr` archive excluding logs/cache/internal app backups | API keys and service credentials may exist in app configs | complete |
| VPN/qBittorrent/Gluetun | `scripts/backups/backup-vpn.sh` | `runbooks/restore-vpn.md` | `/srv/docker/vpn` archive excluding logs/lockfiles/history | VPN/WireGuard secrets and qBittorrent config are sensitive | complete |
| Jellyfin | `scripts/backups/backup-jellyfin.sh` | `runbooks/restore-jellyfin.md` | `/srv/docker/jellyfin` config archive excluding cache/log/transcodes | User/server metadata and config are sensitive; media drive restore is separate | complete |
| Speedtest Tracker | `scripts/backups/backup-speedtest-tracker.sh` | `runbooks/restore-speedtest-tracker.md` | `/srv/docker/speedtest-tracker` archive excluding logs | `.env`, app config, and database/history may be sensitive | complete |
| Monitoring/Prometheus | `scripts/backups/backup-monitoring.sh` | `runbooks/restore-monitoring.md` | `/srv/docker/monitoring` archive excluding Prometheus lock/active query files | Prometheus history and host metadata may be sensitive | complete |
| DDNS | `scripts/backups/backup-ddns.sh` | `runbooks/restore-ddns.md` | `/srv/docker/ddns` archive excluding logs | Porkbun API credentials are sensitive | complete |

## Services Needing Backup / Restore Documentation

| Area | Reason |
|---|---|
| Pi-hole export/restore | Internal DNS is an access dependency, but no Pi-hole export/restore documentation was found. |
| Proxmox host/VM/LXC backup strategy | Broader host and VM/LXC backup strategy is outside the Docker stack scripts and needs documentation. |
| Full OptiPlex host rebuild validation | Rebuild runbook exists, but periodic end-to-end validation status needs documentation. |
| Offsite backup strategy | `/mnt/backupshare` is documented as the backup target; offsite copy strategy needs documentation. |
| Periodic restore testing | Restore test cadence and evidence need documentation. |
| Wedding address form state | Needs verification whether all state is static or handled by n8n. |

## Retired Services

| Service | Reason | Retirement note |
|---|---|---|
| OnlyOffice | Unused service; Compose file exposed `8082:80` on all interfaces if started | Archived under `/srv/docker/_retired` and removed from active repo inventory |
| Gamebuilds | Retired service; formerly Filebrowser for game builds | Removed from active service inventory |

## Monitoring And Logging Notes

Configured in repo:

- Prometheus scrape interval is `15s`.
- Prometheus scrapes `host.docker.internal:9100`, `cadvisor:8080`, and `192.168.1.53:9100`.
- cAdvisor is configured for container metrics.
- node-exporter is configured with host networking and a read-only host root mount.
- Alloy is configured to discover Docker containers through the Docker socket.
- Alloy is configured to forward Docker logs to Loki.
- Alloy includes journal relabeling configuration.
- Loki retention is configured as `168h`.
- Grafana is configured behind Caddy as internal/private `grafana.kai.coach` with internal TLS, Authelia forward auth, and Pi-hole DNS resolving to `100.77.136.106`.

Needs verification:

- Which services are actively monitored in Uptime Kuma.
- Whether alerting is configured.
- Whether all expected running containers are visible to Alloy.
- Whether the configured monitoring/logging stack is currently running.

## Docker Socket Mount Risk

Runtime inspection confirmed Docker socket mounts in Homepage, Glances, and Alloy. Repo references also confirm Docker socket use in `compose/homepage-stack/compose.yaml` and `compose/logging/compose.yaml`.

Docker socket access is high-trust even when mounted read-only. These mounts are accepted risks for current functionality, not immediate removal tasks.

| Service | Purpose | Risk decision |
|---|---|---|
| Homepage | Docker/container dashboard widgets | Accepted risk; intentionally retained |
| Glances | Host/process metrics consumed by Homepage widgets, including Opti CPU and top-process visibility | Accepted risk; intentionally retained |
| Alloy | Docker log discovery and labeling | Accepted risk; intentionally retained |

All Docker-socket-backed services must remain internal/private and should not be publicly exposed.

## Security Review Items

| Item | Reason |
|---|---|
| n8n UI exposure | `n8n.kai.coach` is internal/private only; UI/admin access should not be publicly reachable |
| Address-form webhook exposure | `address.kai.coach` remains public and `/api/wedding-address` proxies internally to `n8n:5678` |
| Caddy routes without Authelia import | Review intended auth model for `vault.kai.coach`, `tools.kai.coach`, and `address.kai.coach` |
| Internal DNS routes | `auth.kai.coach`, `vault.kai.coach`, `tools.kai.coach`, `n8n.kai.coach`, `home.kai.coach`, `status.kai.coach`, and `grafana.kai.coach` are intentionally internal/private through Pi-hole DNS; Caddy routes remain valid for internal access |
| Non-DDNS Caddy routes | `vault.kai.coach`, `auth.kai.coach`, `tools.kai.coach`, `n8n.kai.coach`, `home.kai.coach`, `status.kai.coach`, and `grafana.kai.coach` are configured in Caddy but are not managed by the Porkbun DDNS container |
| Docker socket mounts | Homepage, Glances, and Alloy use read-only Docker socket mounts as accepted high-trust risks for dashboard widgets, host/process metrics, and Docker log discovery |
| Host mounts | Glances, node-exporter, cAdvisor, and Alloy mount host paths and should remain internal/private |
| VPN stack privileges | Gluetun uses `NET_ADMIN` and `/dev/net/tun` |

## Open Questions / Human Verification Needed

- Which configured stacks are currently running in production?
- Which trusted client networks should use Pi-hole internal DNS for `n8n.kai.coach`?
- Which trusted client networks should use Pi-hole internal DNS for `auth.kai.coach`, `vault.kai.coach`, and `tools.kai.coach`?
- Which trusted client networks should use Pi-hole internal DNS for `home.kai.coach`, `status.kai.coach`, and `grafana.kai.coach`?
- Should Vaultwarden rely only on its own authentication, or should there be additional proxy-layer authentication?
- Where are live `.env` files backed up, if at all?
- Does Uptime Kuma monitor all public and critical private services?
- Are backup scripts scheduled operationally? Verify with crontab or the active host scheduler because scheduling is not proven by the repo.
- Which missing restore runbooks should be created first for stacks that now have backup scripts?
- Should `inventory/services.md` link to this inventory to reduce documentation drift?
