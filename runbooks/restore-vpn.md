# Restore VPN/qBittorrent/Gluetun

## Purpose And Scope

Restore the VPN stack after a rebuild, failed update, lost Gluetun configuration, or qBittorrent configuration loss.

This runbook is based on:

- `scripts/backups/backup-vpn.sh`
- `compose/vpn/compose.yaml`

Covered containers:

- `gluetun`
- `qbittorrent`

## Backup Archive Contains

Backup archives are stored under:

```bash
/mnt/backupshare/vpn/archive/
```

Expected archive name:

```bash
vpn-YYYY-MM-DD.tar.gz
```

The backup script archives:

```bash
/srv/docker/vpn
```

Expected paths include:

```bash
/srv/docker/vpn/gluetun
/srv/docker/vpn/qbittorrent
```

## Backup Archive Does Not Contain

- `/mnt/media` downloads or media files.
- Log files.
- Lockfiles.
- Shell history files excluded by the backup script.
- Docker images, containers, or the `/dev/net/tun` device.

## Prerequisites

Verify the backup share and archive:

```bash
mountpoint /mnt/backupshare
ls -lh /mnt/backupshare/vpn/archive
```

Verify `/mnt/media` is mounted:

```bash
mountpoint /mnt/media
ls -la /mnt/media
```

Verify the compose file exists:

```bash
ls -lh compose/vpn/compose.yaml
```

## Restore Assumptions

- `/dev/net/tun` exists on the host.
- `/mnt/media` is already mounted.
- VPN provider credentials and WireGuard values are restored only from approved secure sources or the selected backup archive.
- qBittorrent uses `network_mode: service:gluetun`, so qBittorrent depends on Gluetun.
- Restore commands may require an account with permission to write `/srv/docker/vpn` and manage containers.

## Restore Procedure

Select an archive:

```bash
ls -lh /mnt/backupshare/vpn/archive/vpn-*.tar.gz
```

Stop containers in backup-script order:

```bash
docker stop qbittorrent
docker stop gluetun
```

Move the current directory aside:

```bash
mv /srv/docker/vpn /srv/docker/vpn.restore-old-$(date +%F-%H%M%S)
mkdir -p /srv/docker/vpn
```

Extract the selected archive:

```bash
tar -xzf /mnt/backupshare/vpn/archive/vpn-YYYY-MM-DD.tar.gz -C /srv/docker/vpn
```

Validate expected directories:

```bash
test -d /srv/docker/vpn/gluetun
test -d /srv/docker/vpn/qbittorrent
```

Start containers in dependency order:

```bash
docker start gluetun
docker start qbittorrent
```

If containers were recreated instead of stopped, start from compose:

```bash
cd compose/vpn
docker compose up -d
```

Keep `/srv/docker/vpn.restore-old-*` until restore is confirmed.

## Ownership And Permissions Notes

- qBittorrent uses `PUID=1000` and `PGID=1000`.
- Gluetun needs access to `/dev/net/tun` and `NET_ADMIN`.
- Restored qBittorrent config should be writable by UID/GID `1000`.
- Permission or capability errors usually appear in container logs.

## Validation Steps

Verify containers:

```bash
docker ps --filter name=gluetun
docker ps --filter name=qbittorrent
docker logs gluetun --tail 100
docker logs qbittorrent --tail 100
```

Validate qBittorrent private UI:

```bash
curl -I http://100.77.136.106:8080
```

Validate VPN egress from the Gluetun network namespace:

```bash
docker exec gluetun wget -qO- https://ifconfig.me
```

Expected:

- Gluetun reports healthy VPN connection or clean startup logs.
- qBittorrent UI loads through `100.77.136.106:8080`.
- qBittorrent is running through Gluetun, not a separate network path.
- Downloads point to expected `/mnt/media` paths.

## Rollback Steps

Stop containers:

```bash
docker stop qbittorrent
docker stop gluetun
```

Move failed restore aside:

```bash
mv /srv/docker/vpn /srv/docker/vpn.failed-restore-$(date +%F-%H%M%S)
```

Restore previous directory:

```bash
mv /srv/docker/vpn.restore-old-YYYY-MM-DD-HHMMSS /srv/docker/vpn
```

Start containers:

```bash
docker start gluetun
docker start qbittorrent
```

## Security And Sensitivity Notes

- `.env`, `wg0.conf`, WireGuard private keys, VPN provider credentials, and qBittorrent config are sensitive.
- Do not commit restored config, `.env`, or VPN secret files to Git.
- qBittorrent should remain reachable only through the private/Tailscale-bound Gluetun port.
- Do not paste VPN secrets into tickets, logs, or chat.

## Known Limitations

- `/mnt/media` is not included and must already be mounted.
- VPN provider-side state and forwarded port availability are external dependencies.
- Excluded lockfiles and logs are not restored.
- Backup scheduling is not proven by this runbook; verify separately.
