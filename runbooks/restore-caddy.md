# Restore Caddy

## Goal

Restore Caddy reverse proxy configuration after a rebuild, container failure, or configuration issue.

---

## Verify DNS and Networking First

Before restoring Caddy, verify:

- the server has a LAN IP
- Tailscale is connected
- Porkbun DDNS is running
- DNS records point to the correct public IP or Tailscale IP

Check:

```bash
ip addr
tailscale status
tailscale ip -4
curl ifconfig.me
```

Verify DNS resolution:

```bash
nslookup jellyfin.kai.coach
nslookup immich.kai.coach
nslookup seerr.kai.coach
nslookup vault.kai.coach
```

---

## Restore Caddy Files

Verify the Caddy stack exists:

```bash
ls -R /srv/docker/caddy
```

Expected files:

- compose.yaml
- Caddyfile
- .env (if applicable)

If missing, restore from homelab repo:

```bash
mkdir -p /srv/docker/caddy
cp ~/homelab/compose/caddy/compose.yaml /srv/docker/caddy/
cp ~/homelab/configs/caddy/Caddyfile /srv/docker/caddy/
```

Restore any `.env` file manually if one is used.

---

## Validate Caddyfile Syntax

Open the config:

```bash
nano /srv/docker/caddy/Caddyfile
```

Validate syntax:

```bash
docker run --rm \
  -v /srv/docker/caddy/Caddyfile:/etc/caddy/Caddyfile \
  caddy:latest caddy validate --config /etc/caddy/Caddyfile
```

Expected result:

```text
Valid configuration
```

---

## Restore and Start Container

```bash
cd /srv/docker/caddy
docker compose pull
docker compose up -d
```

Verify:

```bash
docker ps
docker logs caddy --tail 50
```

Expected:

- container is running
- no TLS errors
- no syntax errors
- no upstream resolution failures

---

## Verify Reverse Proxy Targets

Verify backend containers are running before troubleshooting Caddy itself:

```bash
docker ps
```

Expected backend services:

- Jellyfin
- Immich
- Vaultwarden
- Seerr
- Homepage

Test direct container access from the server:

```bash
curl http://localhost:8096
curl http://localhost:2283
curl http://localhost:3002
curl http://localhost:5055
```

If those fail, fix the backend service first before troubleshooting Caddy.

---

## Verify Public Access

Test each domain in a browser:

- jellyfin.kai.coach
- immich.kai.coach
- seerr.kai.coach
- vault.kai.coach
- home.kai.coach

You can also test from CLI:

```bash
curl -I https://jellyfin.kai.coach
curl -I https://immich.kai.coach
curl -I https://seerr.kai.coach
curl -I https://vault.kai.coach
```

Expected:

- HTTP 200 or 302 response
- valid TLS certificate
- service loads successfully

---

## Common Issues

### DNS Still Points to Wrong IP

Run:

```bash
nslookup jellyfin.kai.coach
curl ifconfig.me
```

If the DNS record is stale, restart DDNS:

```bash
cd /srv/docker/ddns
docker compose up -d
docker logs porkbun-ddns --tail 50
```

### Backend Container Is Down

If Caddy returns 502 Bad Gateway:

```bash
docker ps
docker logs <container-name> --tail 50
```

Most common causes:

- backend container stopped
- wrong internal port
- wrong Docker network
- storage mount missing
- `.env` file missing

### Vaultwarden Internal TLS Issues

Vaultwarden is intentionally restricted to Tailscale users and uses internal TLS.

Verify:

```bash
tailscale status
curl -k https://vault.kai.coach
```

### Homepage Fails to Load

Verify Homepage container is running:

```bash
docker logs homepage --tail 50
```

Check for YAML syntax issues in:

- services.yaml
- bookmarks.yaml
- widgets.yaml
- settings.yaml

---

## Things to Watch Out For

- Caddy depends on backend containers being healthy
- DNS problems often look like Caddy problems
- missing `.env` files can break upstream services
- wrong Docker container names can break reverse proxy targets
- Vaultwarden may work in browser but fail in desktop apps if DNS or certificate trust is wrong
- Homepage YAML syntax errors can stop the container from loading
