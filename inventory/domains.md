# Domain Inventory

## Public Domains
- `jellyfin.kai.coach` → Jellyfin
- `seerr.kai.coach` → Seerr
- `immich.kai.coach` → Immich

## Restricted / Internal
- `vault.kai.coach` → Vaultwarden
- `home.kai.coach` → Homepage
- `status.kai.coach` → Uptime Kuma
  - Uses internal TLS in Caddy
- `books.kai.coach` → Calibre Web Automated
  - Uses internal TLS in Caddy
- `shelf.kai.coach` → Shelfmark
  - Uses internal TLS in Caddy
- `paperless.kai.coach` → Paperless-ngx
  - Uses internal TLS in Caddy

## Notes
- Domain management includes Porkbun DDNS.
- Caddy is the reverse proxy in front of the public services.
- Books routes are documented as internal/private; route presence is not evidence of public exposure.
- The Paperless route is documented as internal/private; route presence is not evidence of public exposure.
