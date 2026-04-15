# Restore Immich

## Goal

Restore Immich after a rebuild, failed update, database corruption, or missing media mount.

---

## Verify Storage First

Immich depends on `/mnt/media` being mounted before the containers start.

Verify:

```bash
df -h
ls /mnt/media
```

Expected folders:

- photos
- downloads
- backups

Verify Immich library path exists:

```bash
ls /mnt/media/photos/immich
```

Expected folders may include:

- library
- upload
- thumbs
- encoded-video
- profile

If `/mnt/media` is not mounted, fix storage before restoring Immich.

---

## Restore Immich Files

Verify stack files exist:

```bash
ls -R /srv/docker/immich
```

Expected files:

- compose.yaml
- .env
- config.yml

If missing, restore from homelab repo:

```bash
mkdir -p /srv/docker/immich
cp ~/homelab/compose/immich/compose.yaml /srv/docker/immich/
cp ~/homelab/configs/immich/config.yml /srv/docker/immich/
```

Restore `.env` manually from your password manager or secure backup location.

---

## Verify Database Backup Exists

List backups:

```bash
ls -lh /mnt/backupshare/immich
```

Expected backup files may include:

- postgres dump
- compressed archive
- config backup

If restoring from a local backup directory:

```bash
ls -lh ~/backups/immich
```

---

## Restore Immich Database

If you have a PostgreSQL dump:

```bash
docker compose down
docker compose up -d database
```

Wait a few seconds for Postgres to start, then restore:

```bash
cat immich-postgres-backup.sql | docker exec -i immich_postgres psql -U postgres
```

If using a compressed backup:

```bash
gunzip -c immich-postgres-backup.sql.gz | docker exec -i immich_postgres psql -U postgres
```

---

## Start Immich Stack

```bash
cd /srv/docker/immich
docker compose pull
docker compose up -d
```

Verify:

```bash
docker ps
docker logs immich-server --tail 50
docker logs immich-machine-learning --tail 50
docker logs immich-postgres --tail 50
```

Expected:

- immich-server running
- machine learning container healthy
- postgres healthy
- redis healthy

---

## Verify Application Access

Test locally:

```bash
curl http://localhost:2283
```

Test externally:

- immich.kai.coach

If using Caddy, verify reverse proxy is working:

```bash
curl -I https://immich.kai.coach
```

Expected:

- HTTP 200 or 302
- login page loads
- existing users remain
- photos appear

---

## Verify Media and Uploads

Verify library folders still exist:

```bash
ls /mnt/media/photos/immich/library
```

Verify uploads work:

- upload a test image
- confirm thumbnail generation works
- confirm machine learning jobs process successfully
- confirm search still works

---

## Common Issues

### Missing `/mnt/media`

Symptoms:

- immich-server fails to start
- library folders missing
- upload failures
- blank photo library

Fix:

```bash
sudo mount -a
df -h
```

### PostgreSQL Container Fails

Check:

```bash
docker logs immich-postgres --tail 100
```

Common causes:

- corrupted database volume
- wrong credentials in `.env`
- missing volume mount
- not enough free disk space

### Machine Learning Container Unhealthy

Check:

```bash
docker logs immich-machine-learning --tail 100
```

This may happen after updates and can often be fixed with:

```bash
docker compose restart immich-machine-learning
```

### Reverse Proxy Failure

If `immich.kai.coach` fails but localhost works:

```bash
docker logs caddy --tail 100
curl http://localhost:2283
```

This usually indicates:

- Caddy issue
- DNS issue
- incorrect upstream port
- backend container name mismatch

---

## Things to Watch Out For

- always verify `/mnt/media` before starting Immich
- back up the database before large updates
- keep config.yml and compose.yaml in Git
- keep `.env` out of Git
- machine learning may take time to recover after restart
- large libraries can take time to rescan after rebuild
