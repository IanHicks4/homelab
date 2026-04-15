# Troubleshooting

## General Checks

When something breaks, check these first:

```bash
docker ps
df -h
mount | grep /mnt
tailscale status
ip addr
```

Verify:

- expected containers are running
- `/mnt/media` is mounted
- `/mnt/backupshare` is mounted
- Tailscale is connected
- server has LAN and Tailscale IPs

---

## Container Fails to Start

Check logs:

```bash
docker logs <container-name> --tail 100
```

Common causes:

- missing `.env`
- missing bind mount
- missing `/mnt/media`
- bad permissions
- invalid config syntax
- port already in use

Check ports:

```bash
sudo ss -tulpn
```

Check compose syntax:

```bash
docker compose config
```

---

## Missing `/mnt/media`

Symptoms:

- Jellyfin libraries empty
- Sonarr/Radarr root folders missing
- qBittorrent cannot write downloads
- Immich photos missing
- containers fail to start

Fix:

```bash
sudo mount -a
df -h
ls /mnt/media
```

Check `/etc/fstab`:

```bash
sudo nano /etc/fstab
sudo blkid
```

---

## Missing `/mnt/backupshare`

Symptoms:

- backup scripts fail
- backup destination missing
- SMB mount not available

Fix:

```bash
sudo mount -a
df -h
mount | grep backupshare
```

Check credentials file:

```bash
sudo cat /root/.smb/backupshare
sudo chmod 600 /root/.smb/backupshare
```

---

## Docker Compose Fails

Validate compose file:

```bash
docker compose config
```

Common causes:

- missing `.env`
- indentation errors
- duplicate keys
- bad YAML syntax
- invalid volume path

---

## Homepage Fails to Start

Check logs:

```bash
docker logs homepage --tail 100
```

Common causes:

- YAML syntax error
- missing dash in bookmarks or services
- invalid widget syntax
- wrong indentation

Validate configs:

```bash
docker exec homepage cat /app/config/bookmarks.yaml
docker exec homepage cat /app/config/services.yaml
```

---

## Caddy Returns 502 Bad Gateway

Check Caddy logs:

```bash
docker logs caddy --tail 100
```

Check backend service:

```bash
docker ps
curl http://localhost:<service-port>
```

Common causes:

- backend container down
- wrong upstream port
- wrong container name
- wrong Docker network
- missing storage mount

---

## DNS Problems

Check DNS resolution:

```bash
nslookup jellyfin.kai.coach
nslookup immich.kai.coach
nslookup vault.kai.coach
```

Check public IP:

```bash
curl ifconfig.me
```

If DNS records are stale:

```bash
cd /srv/docker/ddns
docker compose up -d
docker logs porkbun-ddns --tail 50
```

---

## Tailscale Problems

Check status:

```bash
tailscale status
tailscale ip -4
```

Restart if needed:

```bash
sudo systemctl restart tailscaled
sudo tailscale up
```

Common symptoms:

- cannot access Vaultwarden
- cannot SSH remotely
- desktop app cannot connect
- internal DNS not resolving

---

## qBittorrent / Gluetun Issues

Check container health:

```bash
docker ps
docker logs gluetun --tail 100
docker logs qbittorrent --tail 100
```

Check forwarded port:

```bash
docker exec gluetun cat /tmp/gluetun/forwarded_port
```

Check qBittorrent config:

```bash
grep -E 'Session\\Port|Connection\\PortRangeMin' /srv/docker/vpn/qbittorrent/qBittorrent/qBittorrent.conf
```

Common causes:

- Gluetun unhealthy
- VPN disconnected
- forwarded port changed
- qBittorrent still using old port
- tracker issue
- permissions issue on downloads folder

---

## Jellyfin Problems

Check logs:

```bash
docker logs jellyfin --tail 100
```

Common symptoms:

- libraries missing
- playback failures
- Intro Skipper not working
- metadata missing

Verify media path:

```bash
ls /mnt/media/movies
ls /mnt/media/tv
```

---

## Immich Problems

Check logs:

```bash
docker logs immich-server --tail 100
docker logs immich-machine-learning --tail 100
docker logs immich-postgres --tail 100
```

Common symptoms:

- photos missing
- uploads failing
- thumbnails not generating
- machine learning unhealthy
- postgres errors

Verify storage:

```bash
ls /mnt/media/photos/immich
```

---

## Vaultwarden Problems

Check logs:

```bash
docker logs vaultwarden --tail 100
```

Common symptoms:

- login page unavailable
- desktop app "Failed to fetch"
- admin page inaccessible
- browser extension sync fails

Check:

```bash
nslookup vault.kai.coach
curl -k https://vault.kai.coach
tailscale status
```

---

## Permission Problems

Common symptoms:

- containers cannot write files
- downloads fail
- backups fail
- media scan failures

Fix common ownership issue:

```bash
sudo chown -R 1000:1000 /mnt/media
sudo chmod -R 775 /mnt/media
```

For Docker folders:

```bash
sudo chown -R $USER:$USER /srv/docker
```

---

## Reboot Checklist

After reboot:

```bash
docker ps
df -h
tailscale status
```

Verify:

- `/mnt/media` mounted
- `/mnt/backupshare` mounted
- all containers running
- Tailscale connected
- reverse proxy working
