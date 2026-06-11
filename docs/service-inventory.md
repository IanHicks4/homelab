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
| `arr` | Sonarr, Radarr, Prowlarr, Seerr, FlareSolverr, Bazarr, Recyclarr | Media automation and requests | Tailscale-bound admin ports; Seerr Caddy route | Seerr confirmed by `inventory/domains.md` | Config dirs, `/mnt/media` | Needs backup docs |
| `authelia` | Authelia, Redis | Forward authentication | Proxy network; `auth.kai.coach` Caddy route | Internal/private; public DNS removed | Config, secrets mount, Redis data | Needs backup docs |
| `caddy` | Caddy | Reverse proxy / TLS | `80:80`, `443:443` | Configured edge ports; running/exposure needs verification | Caddy data/config | Restore runbook exists |
| `ddns` | Porkbun DDNS | Dynamic DNS updates | Internal/background | Not applicable | No volume shown | Needs operational restore notes |
| `gamebuilds` | Filebrowser | File access for game builds | `100.77.136.106:8088` | No | Database/settings, game-build files | Needs backup docs |
| `homepage-stack` | Homepage, Glances, Uptime Kuma | Dashboard, host metrics, uptime checks | Tailscale-bound Homepage; Caddy routes for Homepage and Uptime Kuma | No; inventory marks restricted/internal | Homepage config, Uptime Kuma data | Needs backup docs |
| `immich` | Immich server, ML, Redis, Postgres | Photo library | Caddy route; no active host port | Confirmed by `inventory/domains.md` | Upload library, database, model cache | Backup script and restore runbook exist |
| `it-tools` | IT Tools | Utility tools | `100.77.136.106:8085`; Caddy route | Internal/private via Pi-hole DNS | No volume shown | Low, based on repo config |
| `jellyfin` | Jellyfin | Media streaming | Host network; Caddy route | Confirmed by `inventory/domains.md` | Config, `/mnt/media` | Needs service-specific backup docs |
| `logging` | Loki, Grafana, Alloy | Log collection and dashboards | Localhost ports; Grafana Caddy route | Needs verification | Loki data, Grafana data | Needs backup docs |
| `monitoring` | Prometheus, node-exporter, cAdvisor | Metrics collection | Localhost ports; proxy network for Prometheus | No public route found | Prometheus data | Needs backup docs |
| `n8n` | n8n | Workflow automation and webhooks | `n8n.kai.coach` internal route; address-form webhook route | Internal/private via Pi-hole DNS | `/srv/docker/n8n` | Needs backup docs |
| `speedtest-tracker` | Speedtest Tracker | Network speed history | `100.77.136.106:8082`; proxy network | Needs verification | `./config` | Needs backup docs |
| `vaultwarden` | Vaultwarden | Password manager | `vault.kai.coach` Caddy route | Internal/private via Pi-hole DNS | `./data` | Backup script and restore runbook exist |
| `vpn` | Gluetun, qBittorrent | VPN-bound torrent client | `100.77.136.106:8080` | No | VPN config, qBittorrent config, `/mnt/media` | Needs backup docs |
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
- No stack-specific backup script or restore runbook was found.

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
- No Authelia restore runbook was found.

Monitoring/logging relevance:

- Docker logs should be collected by Alloy if the container is running.

Security notes:

- Secret file paths are referenced for JWT, session, and storage encryption keys.
- The secrets mount is read-only.
- Do not treat example env files as proof of live secret values.
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
- Verified restore runbook: `runbooks/restore-caddy.md`.

Monitoring/logging relevance:

- Docker logs should be collected by Alloy if the container is running.

Security notes:

- `home.kai.coach`, `status.kai.coach`, and `grafana.kai.coach` import the Authelia forward-auth snippet.
- Several Caddy routes use `tls internal`.
- Caddy route configuration does not by itself confirm public internet exposure.

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

Backup relevance:

- No persistent volume is shown.
- Operational restore notes may still be useful because DNS updates are an infrastructure dependency.

Monitoring/logging relevance:

- Docker logs should be collected by Alloy if the container is running.

Security notes:

- API key environment variable names are referenced.
- No real secret values are included in this document.
- `compose/ddns/compose.yaml` manages only these subdomains for public DNS updates: `jellyfin`, `seerr`, `immich`, `home`, `status`, `grafana`, and `address`.
- `vault.kai.coach`, `auth.kai.coach`, and `tools.kai.coach` are intentionally handled by Pi-hole internal DNS and are not managed by the Porkbun DDNS container.
- `n8n.kai.coach` is also intentionally handled by Pi-hole internal DNS on both the Pi 4 and Pi-hole LXC, points to `100.77.136.106`, and is not public-Porkbun-DNS-managed.
- The public Porkbun DNS record for `n8n.kai.coach` was removed; current public DNS no longer resolves.
- `auth.kai.coach` previously had a manual/static Porkbun DNS record and was externally reachable.
- The `auth.kai.coach` Porkbun DNS record was removed; current public DNS no longer resolves.
- `vault.kai.coach` and `tools.kai.coach` also do not publicly resolve based on the current DNS check.

### `gamebuilds`

Status:

- Configured in repo: yes.
- Confirmed running in production: needs verification.

Main services:

- `filebrowser`

Purpose:

- Filebrowser instance for game builds.

Ports and routes:

- `100.77.136.106:8088:80`

Access classification:

- Configured for Tailscale/private access.

Persistent volumes/bind mounts:

- `/mnt/media/game-builds:/srv`
- `/srv/docker/gamebuilds/database.db:/database.db`
- `/srv/docker/gamebuilds/settings.json:/settings.json`

Backup relevance:

- Database, settings, and served files are persistent.
- No restore runbook was found.

Monitoring/logging relevance:

- Docker logs should be collected by Alloy if the container is running.

Security notes:

- Provides file access to a media subdirectory.
- Authentication settings need verification from live configuration.

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
- Existing inventory classifies `home.kai.coach` and `status.kai.coach` as restricted/internal.
- These routes are not classified as public by this document.

Persistent volumes/bind mounts:

- `./homepage-config:/app/config`
- `/var/run/docker.sock:/var/run/docker.sock:ro`
- `/mnt/media:/mnt/media:ro`
- `./uptime-kuma:/app/data`
- Glances read-only host mounts include Docker socket, OS release, proc, sys, and root filesystem.

Backup relevance:

- Homepage config and Uptime Kuma data are persistent.
- No restore runbook was found.

Monitoring/logging relevance:

- Uptime Kuma is configured as a service in this stack, but specific monitors need verification.
- Glances is configured for host metrics.
- Docker logs should be collected by Alloy if containers are running.

Security notes:

- Homepage has read-only Docker socket access.
- Glances has host-level read-only mounts and host networking.
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
- Verified media restore runbook: `runbooks/restore-media-drive.md`.
- No Jellyfin-specific restore runbook was found.

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
- Grafana Caddy route uses internal TLS and Authelia forward auth.
- Public exposure needs verification.

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
- No restore runbook was found.

Monitoring/logging relevance:

- Alloy is configured to discover Docker containers and forward Docker logs to Loki.
- Loki retention is configured for `168h`.

Security notes:

- Grafana admin password is referenced through environment configuration; no value is included here.
- Alloy has read-only Docker socket and host journal access.

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
- No restore runbook was found.

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
- No restore runbook was found.

Monitoring/logging relevance:

- Docker logs should be collected by Alloy if the container is running.

Security notes:

- Treat n8n persistent data as sensitive.
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
- No restore runbook was found.

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
- No restore runbook was found.

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
| Homepage | `home.kai.coach` | Inventory marks restricted/internal |
| Uptime Kuma | `status.kai.coach` | Inventory marks restricted/internal |
| Grafana | `grafana.kai.coach` | Uses internal TLS and Authelia forward auth |
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
| Gamebuilds Filebrowser | `8088` |
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
| Speedtest Tracker | App config/history and env-file usage |
| Arr stack | Service configs and possible API tokens in persistent config |
| Jellyfin | Media library config and user/server metadata |
| Gamebuilds Filebrowser | Filebrowser database/settings and served file access |

## Existing Backup And Restore Evidence

Verified backup scripts:

| Service | File |
|---|---|
| Immich | `scripts/backups/backup-immich.sh` |
| Vaultwarden | `scripts/backups/backup-vault.sh` |

Verified restore runbooks:

| Area | File |
|---|---|
| Caddy | `runbooks/restore-caddy.md` |
| Immich | `runbooks/restore-immich.md` |
| Media drive | `runbooks/restore-media-drive.md` |
| Vaultwarden | `runbooks/restore-vaultwarden.md` |

## Services Needing Backup / Restore Documentation

| Service/stack | Reason |
|---|---|
| Authelia | Auth config, mounted secrets, Redis data |
| n8n | Persistent workflows and likely credential data |
| Homepage/Uptime Kuma | Dashboard config and monitoring history |
| Logging | Grafana data and Loki data |
| Monitoring | Prometheus data |
| Arr stack | Persistent service configs |
| Jellyfin | Persistent config and custom web file |
| VPN/qBittorrent | Persistent VPN and qBittorrent config |
| Speedtest Tracker | Persistent config/history |
| Gamebuilds | Database/settings and file storage |
| DDNS | Infrastructure dependency and credential restore handling |
| Wedding address form | Needs verification whether all state is static or handled by n8n |

## Retired Services

| Service | Reason | Retirement note |
|---|---|---|
| OnlyOffice | Unused service; Compose file exposed `8082:80` on all interfaces if started | Archived under `/srv/docker/_retired` and removed from active repo inventory |

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
- Grafana is configured behind Caddy as `grafana.kai.coach` with internal TLS and Authelia forward auth.

Needs verification:

- Which services are actively monitored in Uptime Kuma.
- Whether alerting is configured.
- Whether all expected running containers are visible to Alloy.
- Whether the configured monitoring/logging stack is currently running.

## Security Review Items

| Item | Reason |
|---|---|
| n8n UI exposure | `n8n.kai.coach` is internal/private only; UI/admin access should not be publicly reachable |
| Address-form webhook exposure | `address.kai.coach` remains public and `/api/wedding-address` proxies internally to `n8n:5678` |
| Caddy routes without Authelia import | Review intended auth model for `vault.kai.coach`, `tools.kai.coach`, and `address.kai.coach` |
| Internal DNS routes | `auth.kai.coach`, `vault.kai.coach`, `tools.kai.coach`, and `n8n.kai.coach` are intentionally internal/private through Pi-hole DNS; Caddy routes remain valid for internal access |
| Non-DDNS Caddy routes | `vault.kai.coach`, `auth.kai.coach`, `tools.kai.coach`, and `n8n.kai.coach` are configured in Caddy but are not managed by the Porkbun DDNS container |
| Docker socket mounts | Homepage and Alloy have read-only Docker socket access |
| Host mounts | Glances, node-exporter, cAdvisor, and Alloy mount host paths |
| VPN stack privileges | Gluetun uses `NET_ADMIN` and `/dev/net/tun` |

## Open Questions / Human Verification Needed

- Which configured stacks are currently running in production?
- Which trusted client networks should use Pi-hole internal DNS for `n8n.kai.coach`?
- Which trusted client networks should use Pi-hole internal DNS for `auth.kai.coach`, `vault.kai.coach`, and `tools.kai.coach`?
- Are `grafana.kai.coach`, `home.kai.coach`, and `status.kai.coach` reachable only from trusted networks?
- Should Vaultwarden rely only on its own authentication, or should there be additional proxy-layer authentication?
- Where are live `.env` files backed up, if at all?
- Does Uptime Kuma monitor all public and critical private services?
- Are Prometheus, Grafana, Loki, Authelia, n8n, and Arr configs intentionally excluded from current backup scripts?
- Should `inventory/services.md` link to this inventory to reduce documentation drift?
