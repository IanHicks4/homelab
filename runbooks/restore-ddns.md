# Restore DDNS

## Purpose And Scope

Restore the Porkbun DDNS stack after a rebuild, failed update, lost configuration, or missing credentials.

This runbook is based on:

- `scripts/backups/backup-ddns.sh`
- `compose/ddns/compose.yaml`

Covered container:

- `porkbun-ddns`

## Backup Archive Contains

Backup archives are stored under:

```bash
/mnt/backupshare/ddns/archive/
```

Expected archive name:

```bash
ddns-YYYY-MM-DD.tar.gz
```

The backup script archives:

```bash
/srv/docker/ddns
```

Expected live configuration may include `.env` or other files under `/srv/docker/ddns`. Exact contents need verification from the selected archive.

## Backup Archive Does Not Contain

- Files matching `*.log`.
- Porkbun account-side DNS history.
- Pi-hole internal DNS records.
- Docker images or containers.

## Prerequisites

Verify the backup share and archive:

```bash
mountpoint /mnt/backupshare
ls -lh /mnt/backupshare/ddns/archive
```

Verify the compose file exists:

```bash
ls -lh compose/ddns/compose.yaml
```

## Restore Assumptions

- Public DDNS should remain limited to intended public subdomains: `jellyfin`, `seerr`, `immich`, and `address`.
- Internal-only names must stay in Pi-hole/internal DNS and must not be added to public DDNS.
- Porkbun API credentials are restored only from the backup archive or approved secret store.
- Restore commands may require an account with permission to write `/srv/docker/ddns` and manage containers.

## Restore Procedure

Select an archive:

```bash
ls -lh /mnt/backupshare/ddns/archive/ddns-*.tar.gz
```

Stop DDNS:

```bash
docker stop porkbun-ddns
```

Move current directory aside:

```bash
mv /srv/docker/ddns /srv/docker/ddns.restore-old-$(date +%F-%H%M%S)
mkdir -p /srv/docker/ddns
```

Extract the selected archive:

```bash
tar -xzf /mnt/backupshare/ddns/archive/ddns-YYYY-MM-DD.tar.gz -C /srv/docker/ddns
```

Validate expected files without printing secrets:

```bash
ls -la /srv/docker/ddns
test -f /srv/docker/ddns/.env
```

Validate intended public subdomain configuration from compose:

```bash
grep 'SUBDOMAINS:' compose/ddns/compose.yaml
```

Start DDNS:

```bash
docker start porkbun-ddns
```

If the container was recreated instead of stopped, start from compose:

```bash
cd compose/ddns
docker compose up -d
```

Keep `/srv/docker/ddns.restore-old-*` until restore is confirmed.

## Ownership And Permissions Notes

- `.env` must be readable by the compose process/container environment.
- Keep credential files restricted to trusted admins.
- Do not loosen permissions unless logs show a clear read problem.

## Validation Steps

Verify container and logs:

```bash
docker ps --filter name=porkbun-ddns
docker logs porkbun-ddns --tail 100
```

Validate intended public DNS records:

```bash
dig +short jellyfin.kai.coach
dig +short seerr.kai.coach
dig +short immich.kai.coach
dig +short address.kai.coach
```

Validate internal-only names are not public DDNS targets:

```bash
dig +short auth.kai.coach
dig +short vault.kai.coach
dig +short tools.kai.coach
dig +short n8n.kai.coach
dig +short home.kai.coach
dig +short status.kai.coach
dig +short grafana.kai.coach
```

Expected:

- `porkbun-ddns` is running.
- Logs show successful update attempts or no credential/config errors.
- Public records resolve as expected for `jellyfin`, `seerr`, `immich`, and `address`.
- Internal-only hostnames do not get added to public DDNS.

## Rollback Steps

Stop DDNS:

```bash
docker stop porkbun-ddns
```

Move failed restore aside:

```bash
mv /srv/docker/ddns /srv/docker/ddns.failed-restore-$(date +%F-%H%M%S)
```

Restore previous directory:

```bash
mv /srv/docker/ddns.restore-old-YYYY-MM-DD-HHMMSS /srv/docker/ddns
```

Start DDNS:

```bash
docker start porkbun-ddns
```

## Security And Sensitivity Notes

- `.env` contains Porkbun API credentials and is sensitive.
- Do not commit `.env`, restored credentials, or provider API material to Git.
- Do not paste API keys or secret keys into tickets, logs, or chat.
- Do not add internal-only names to public DDNS.

## Known Limitations

- Porkbun provider-side history and account settings are not restored from this archive.
- Pi-hole local DNS is not backed up by this DDNS archive.
- DNS propagation and TTL behavior may delay validation.
- Backup scheduling is not proven by this runbook; verify separately.
