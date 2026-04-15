# Restore Media Drive

## Goal

Restore access to `/mnt/media` after a reboot, drive disconnect, rebuild, mount failure, or missing directories.

---

## Verify Disk Is Detected

Check attached disks:

```bash
lsblk
```

Also check UUIDs and filesystem types:

```bash
sudo blkid
```

Expected:

- media drive appears
- filesystem is ext4
- UUID matches expected drive

---

## Verify Mount Point Exists

```bash
ls /mnt
```

If `/mnt/media` does not exist:

```bash
sudo mkdir -p /mnt/media
```

Set ownership if needed:

```bash
sudo chown -R $USER:$USER /mnt/media
```

---

## Verify `/etc/fstab`

Open:

```bash
sudo nano /etc/fstab
```

Expected entry should look similar to:

```fstab
UUID=<media-drive-uuid> /mnt/media ext4 defaults,nofail 0 2
```

If UUID changed, update it using output from:

```bash
sudo blkid
```

---

## Mount the Drive

```bash
sudo mount -a
```

Verify:

```bash
df -h
mount | grep media
```

Expected:

- `/mnt/media` is mounted
- correct disk size appears
- mount survives reboot

---

## Verify Folder Structure

```bash
ls /mnt/media
```

Expected folders:

- movies
- tv
- downloads
- photos

Verify deeper paths:

```bash
ls /mnt/media/photos
ls /mnt/media/downloads
```

Expected Immich path:

```bash
ls /mnt/media/photos/immich
```

Expected folders may include:

- library
- upload
- thumbs
- encoded-video
- profile

---

## Fix Ownership and Permissions

If Docker containers cannot access the drive:

```bash
sudo chown -R 1000:1000 /mnt/media
sudo chmod -R 775 /mnt/media
```

If only specific folders have issues:

```bash
sudo chown -R 1000:1000 /mnt/media/downloads
sudo chown -R 1000:1000 /mnt/media/photos
```

---

## Restart Dependent Containers

After storage is restored, restart services that depend on it:

```bash
cd /srv/docker/vpn
docker compose up -d

cd /srv/docker/arr
docker compose up -d

cd /srv/docker/jellyfin
docker compose up -d

cd /srv/docker/immich
docker compose up -d
```

Verify:

```bash
docker ps
```

Expected services:

- qBittorrent
- Gluetun
- Sonarr
- Radarr
- Bazarr
- Jellyfin
- Immich

---

## Validate Applications

### Jellyfin

Verify:

- movies appear
- TV shows appear
- playback works
- libraries are not empty

### Arr Stack

Verify:

- Sonarr root folder exists
- Radarr root folder exists
- qBittorrent download path exists
- completed download handling still works

### Immich

Verify:

- existing photos appear
- uploads work
- thumbnails generate
- machine learning container is healthy

---

## Common Issues

### Disk Not Detected

Check:

```bash
dmesg | tail -50
sudo fdisk -l
```

Possible causes:

- loose USB cable
- failing enclosure
- failing drive
- insufficient power
- bad USB port

### Wrong UUID in `/etc/fstab`

Symptoms:

- boot delays
- `/mnt/media` missing
- `mount -a` errors

Check:

```bash
sudo blkid
sudo mount -a
```

### Permission Problems

Symptoms:

- container cannot write files
- Jellyfin cannot scan media
- qBittorrent download failures
- Immich upload failures

Fix:

```bash
sudo chown -R 1000:1000 /mnt/media
sudo chmod -R 775 /mnt/media
```

### Missing Folders

If the drive mounted but expected folders are missing:

```bash
mkdir -p /mnt/media/movies
mkdir -p /mnt/media/tv
mkdir -p /mnt/media/downloads
mkdir -p /mnt/media/photos
```

---

## Things to Watch Out For

- always verify `/mnt/media` before starting media-related containers
- avoid unplugging the drive without stopping containers first
- keep the drive label and UUID documented
- if using USB storage, enclosure or cable issues are common failure points
- missing mounts often look like broken containers when the real issue is storage
