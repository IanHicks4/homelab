# Rebuild OptiPlex

## Goal

Restore the OptiPlex to a working state after OS corruption, drive failure, or full rebuild.

---

## Install Ubuntu

- Install Ubuntu Server LTS
- Set hostname to `server`
- Create primary user
- Enable OpenSSH during install
- Apply updates after first boot

```bash
sudo apt update && sudo apt upgrade -y
sudo reboot
```

---

## Install Core Packages

```bash
sudo apt install -y \
  curl \
  git \
  vim \
  htop \
  btop \
  unzip \
  cifs-utils \
  smartmontools \
  ca-certificates \
  gnupg \
  lsb-release
```

---

## Install Docker

```bash
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
newgrp docker
```

Verify:

```bash
docker ps
docker compose version
```

---

## Install Tailscale

```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
```

Verify:

```bash
tailscale status
tailscale ip -4
```

Expected Tailscale IP should be similar to:

```text
100.x.x.x
```

---

## Restore Mount Points

### Media Drive

Create mountpoint:

```bash
sudo mkdir -p /mnt/media
```

Find drive UUID:

```bash
sudo blkid
```

Example `/etc/fstab` entry:

```fstab
UUID=<media-drive-uuid> /mnt/media ext4 defaults,nofail 0 2
```

Mount:

```bash
sudo mount -a
df -h
```

Verify `/mnt/media` exists and contains:

- movies
- tv
- downloads
- photos

### SMB Backup Share

Create mountpoint:

```bash
sudo mkdir -p /mnt/backupshare
```

Create SMB credentials file:

```bash
sudo mkdir -p /root/.smb
sudo nano /root/.smb/backupshare
```

Contents:

```text
username=<username>
password=<password>
```

Protect file:

```bash
sudo chmod 600 /root/.smb/backupshare
```

Example `/etc/fstab` entry:

```fstab
//192.168.1.154/Backups /mnt/backupshare cifs credentials=/root/.smb/backupshare,uid=1000,gid=1000,nofail,x-systemd.automount 0 0
```

Mount:

```bash
sudo mount -a
df -h
```

---

## Restore Homelab Repo

Clone repo:

```bash
cd ~
git clone <repo-url> homelab
```

Verify:

```bash
find ~/homelab -type f | sort
```

---

## Restore Docker Stack Files

Create Docker root folder:

```bash
sudo mkdir -p /srv/docker
sudo chown -R $USER:$USER /srv/docker
```

Copy compose and config files from repo back into `/srv/docker`.

Example:

```bash
cp -r ~/homelab/compose/* /srv/docker/
cp -r ~/homelab/configs/caddy /srv/docker/caddy/
cp -r ~/homelab/configs/homepage /srv/docker/homepage-stack/
```

Restore `.env` files manually from your password manager or secure backup location.

---

## Restore Containers in Dependency Order

### Infrastructure First

```bash
cd /srv/docker/ddns
docker compose up -d

cd /srv/docker/caddy
docker compose up -d
```

### Dashboard / Monitoring

```bash
cd /srv/docker/homepage-stack
docker compose up -d
```

### Media Stack

```bash
cd /srv/docker/vpn
docker compose up -d

cd /srv/docker/arr
docker compose up -d

cd /srv/docker/jellyfin
docker compose up -d
```

### Applications

```bash
cd /srv/docker/immich
docker compose up -d

cd /srv/docker/vaultwarden
docker compose up -d
```

---

## Validation Checklist

### Docker

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

### Mounts

```bash
df -h
```

Verify:

- `/mnt/media`
- `/mnt/backupshare`

### Network

```bash
ip addr
tailscale ip -4
```

Verify:

- LAN IP present
- Tailscale IP present

### Reverse Proxy

Verify:

- jellyfin.kai.coach
- immich.kai.coach
- seerr.kai.coach
- vault.kai.coach

### Media Paths

Verify media libraries still exist:

```bash
ls /mnt/media
```

Expected folders:

- movies
- tv
- downloads
- photos

---

## Things to Watch Out For

The biggest failure points during rebuild will likely be:

- forgetting to mount `/mnt/media`
- forgetting to mount `/mnt/backupshare`
- missing `.env` files
- restoring stacks before storage exists
- forgetting to restore Tailscale before testing internal services
- forgetting Docker group membership after reinstall
