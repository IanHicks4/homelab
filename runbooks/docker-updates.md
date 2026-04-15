# Docker Updates

## Goal

Safely update the OptiPlex, Ubuntu packages, Docker Engine, containers, and compose stacks without breaking services.

---

## Check Current System State

Check uptime, mounts, and running containers before making changes:

```bash
uptime
df -h
docker ps
```

Verify:

- `/mnt/media` is mounted
- `/mnt/backupshare` is mounted if backups are stored there
- all expected containers are running
- no containers are stuck restarting

---

## Create Backups Before Updating

Back up important applications before large updates:

```bash
~/homelab/scripts/backup-vault.sh
~/homelab/scripts/backup-immich.sh
```

Optional: back up Docker compose files and configs:

```bash
cp -r /srv/docker ~/docker-backup-$(date +%F)
```

---

## Update Ubuntu Packages

Refresh repositories and install updates:

```bash
sudo apt update
sudo apt upgrade -y
sudo apt autoremove -y
```

Check whether a reboot is required:

```bash
if [ -f /var/run/reboot-required ]; then
  echo "Reboot required"
fi
```

Check pending firmware updates:

```bash
fwupdmgr get-updates
```

If firmware updates are available:

```bash
sudo fwupdmgr update
```

---

## Reboot if Needed

If a kernel update, firmware update, or reboot-required file exists:

```bash
sudo reboot
```

After reboot, reconnect and verify:

```bash
uname -r
docker ps
df -h
tailscale status
```

---

## Update Docker Engine

Update Docker packages if needed:

```bash
curl -fsSL https://get.docker.com | sh
```

Verify:

```bash
docker --version
docker compose version
```

---

## Update Individual Docker Stacks

Go stack by stack so if something breaks, it is easy to identify.

### DDNS

```bash
cd /srv/docker/ddns
docker compose pull
docker compose up -d
```

### Caddy

```bash
cd /srv/docker/caddy
docker compose pull
docker compose up -d
```

### Homepage

```bash
cd /srv/docker/homepage-stack
docker compose pull
docker compose up -d
```

### VPN Stack

```bash
cd /srv/docker/vpn
docker compose pull
docker compose up -d
```

### Arr Stack

```bash
cd /srv/docker/arr
docker compose pull
docker compose up -d
```

### Jellyfin

```bash
cd /srv/docker/jellyfin
docker compose pull
docker compose up -d
```

### Immich

```bash
cd /srv/docker/immich
docker compose pull
docker compose up -d
```

### Vaultwarden

```bash
cd /srv/docker/vaultwarden
docker compose pull
docker compose up -d
```

---

## Remove Old Docker Images

After verifying everything works:

```bash
docker image prune -a
docker volume prune
```

Be careful with `docker volume prune` because it removes unused volumes permanently.

Safer option:

```bash
docker image prune -a
```

---

## Validation Checklist

### Verify Containers

```bash
docker ps
```

Expected services:

- Caddy
- Homepage
- Uptime Kuma
- qBittorrent
- Gluetun
- Jellyfin
- Immich
- Vaultwarden
- Sonarr
- Radarr
- Bazarr
- Prowlarr
- Seerr
- Recyclarr
- Porkbun DDNS

### Verify Mounts

```bash
df -h
```

Verify:

- `/mnt/media`
- `/mnt/backupshare`

### Verify Reverse Proxy

Open and test:

- jellyfin.kai.coach
- immich.kai.coach
- seerr.kai.coach
- vault.kai.coach

### Verify VPN Stack

```bash
docker logs gluetun --tail 50
docker exec gluetun cat /tmp/gluetun/forwarded_port
```

Verify:

- Gluetun is healthy
- forwarded port exists
- qBittorrent still works

### Verify Immich

- photos load
- uploads work
- machine learning container is healthy

### Verify Jellyfin

- media libraries still load
- playback works
- Intro Skipper plugin still functions

### Verify Vaultwarden

- web vault opens
- browser extension sync works
- desktop app login still works

---

## Things to Watch Out For

- always back up Vaultwarden and Immich before updates
- do not run `docker volume prune` unless you are certain
- update one stack at a time instead of everything at once
- reboot after kernel updates
- verify `/mnt/media` is mounted before starting containers
- Gluetun updates may change forwarded ports
- Immich updates sometimes require database migrations
- Homepage or Caddy updates may fail if config syntax changed
