# Restore Vaultwarden

## Goal

Restore Vaultwarden after a rebuild, failed update, database corruption, or configuration issue.

---

## Verify Storage and Config Files

Verify Vaultwarden files exist:

```bash
ls -R /srv/docker/vaultwarden
```

Expected files:

- compose.yaml
- .env
- data directory

If missing, restore from homelab repo:

```bash
mkdir -p /srv/docker/vaultwarden
cp ~/homelab/compose/vaultwarden/compose.yaml /srv/docker/vaultwarden/
```

Restore `.env` manually from your password manager or secure backup location.

Expected `.env` values may include:

```env
ADMIN_TOKEN=<vaultwarden-admin-token>
```

---

## Verify Backup Exists

Check backup location:

```bash
ls -lh /mnt/backupshare/vaultwarden
```

Expected backup files may include:

- vaultwarden-backup-YYYY-MM-DD.tar.gz
- db.sqlite3
- attachments/
- sends/
- config.json
- rsa_key*
- icon_cache/

If restoring from a local backup directory:

```bash
ls -lh ~/backups/vaultwarden
```

---

## Restore Vaultwarden Data

Stop the stack if already running:

```bash
cd /srv/docker/vaultwarden
docker compose down
```

Restore backup archive:

```bash
tar -xvzf vaultwarden-backup-YYYY-MM-DD.tar.gz -C /srv/docker/vaultwarden/
```

Verify restored contents:

```bash
ls -R /srv/docker/vaultwarden/data
```

Expected important files:

- db.sqlite3
- config.json
- attachments/
- sends/
- rsa_key.pem
- rsa_key.pub.pem

Fix permissions if needed:

```bash
sudo chown -R 1000:1000 /srv/docker/vaultwarden
```

---

## Start Vaultwarden

```bash
cd /srv/docker/vaultwarden
docker compose pull
docker compose up -d
```

Verify:

```bash
docker ps
docker logs vaultwarden --tail 50
```

Expected:

- container is running
- no database errors
- no missing file errors
- no admin token errors

---

## Verify Access

Test locally:

```bash
curl http://localhost:8080
```

If using Caddy and Tailscale-only access:

```bash
curl -k https://vault.kai.coach
```

Verify:

- login page loads
- existing accounts remain
- vault items exist
- browser extension sync works
- mobile app sync works
- desktop app login works

---

## Verify Admin Panel

Open:

- vault.kai.coach/admin

Log in using the admin token from `.env`.

Verify:

- SMTP settings
- signup settings
- domain settings
- organization settings

---

## Common Issues

### Missing `.env`

Symptoms:

- admin page inaccessible
- container fails to start
- missing environment variable errors

Fix:

```bash
nano /srv/docker/vaultwarden/.env
```

Restore:

```env
ADMIN_TOKEN=<vaultwarden-admin-token>
```

Restart:

```bash
docker compose up -d
```

### Missing `config.json`

Symptoms:

- environment variables appear ignored
- Vaultwarden settings differ from expected
- warning messages about overridden variables

Check:

```bash
ls /srv/docker/vaultwarden/data/config.json
```

Vaultwarden may prefer settings stored in `config.json` over compose environment variables.

### Desktop App Fails But Browser Works

Symptoms:

- browser login works
- browser extension works
- desktop app shows "Failed to fetch"

Check:

```bash
nslookup vault.kai.coach
curl -k https://vault.kai.coach
tailscale status
```

Possible causes:

- DNS resolution issue
- Tailscale disconnected
- certificate trust issue
- incorrect reverse proxy config

### Database Corruption

Check:

```bash
docker logs vaultwarden --tail 100
```

If needed, restore `db.sqlite3` from backup.

---

## Things to Watch Out For

- keep `.env` out of Git
- keep compose.yaml in Git
- always back up `db.sqlite3` before major updates
- preserve `rsa_key*` files or existing logins may break
- browser working does not guarantee desktop app works
- Vaultwarden may use `config.json` values instead of compose variables
