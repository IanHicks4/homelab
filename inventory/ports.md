# Port Inventory

## Public / Reverse Proxy
- `80/tcp` → Caddy HTTP
- `443/tcp` → Caddy HTTPS

## App Ports
- `2283/tcp` → Immich
- `3000/tcp` → Homepage
- `3001/tcp` → Uptime Kuma
- `5055/tcp` → Seerr
- `6767/tcp` → Bazarr
- `6881/tcp` → qBittorrent
- `6881/udp` → qBittorrent
- `7878/tcp` → Radarr
- `8080/tcp` → qBittorrent Web UI
- `8088/tcp` → Vaultwarden
- `8096/tcp` → Jellyfin
- `8191/tcp` → FlareSolverr
- `8989/tcp` → Sonarr
- `9696/tcp` → Prowlarr

## Admin / Infrastructure
- `22/tcp` → SSH
- `41641/udp` → Tailscale
- `53/tcp` / `53/udp` → systemd-resolved on localhost
- `5353/udp` → Avahi/mDNS-style listener shown on multiple interfaces
