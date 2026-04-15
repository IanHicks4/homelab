# Services Inventory

| Service | Host | Purpose | Access |
|---|---|---|---|
| Caddy | server | Reverse proxy / TLS termination | 80, 443 |
| Porkbun DDNS | server | Dynamic DNS updates | Internal/background |
| Homepage | server | Dashboard | Port 3000 |
| Uptime Kuma | server | Service monitoring | Port 3001 |
| Glances | server | System metrics | Internal/container |
| qBittorrent | server | Torrent client | Port 8080 |
| Gluetun | server | VPN container for qBittorrent stack | Port 6881/8080 pathing in stack |
| Jellyfin | server | Media server | Port 8096 / `jellyfin.kai.coach` |
| Immich Server | server | Photo management | Port 2283 / `immich.kai.coach` |
| Immich Postgres | server | Immich database | Internal only |
| Immich Redis | server | Immich cache/queue | Internal only |
| Immich Machine Learning | server | Immich ML service | Internal only |
| Prowlarr | server | Indexer manager | Port 9696 |
| Sonarr | server | TV automation | Port 8989 |
| Radarr | server | Movie automation | Port 7878 |
| Bazarr | server | Subtitle automation | Port 6767 |
| Seerr | server | Media requests | Port 5055 / `seerr.kai.coach` |
| FlareSolverr | server | Cloudflare challenge helper | Port 8191 |
| Recyclarr | server | arr profile sync | Internal/background |
| Vaultwarden | server | Password manager | Port 8088 / `vault.kai.coach` |
