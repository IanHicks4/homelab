# Storage Inventory

## Local Filesystems

### Root Disk
- Device: `/dev/nvme0n1`
- Main mounted partition: `/dev/nvme0n1p2`
- Mountpoint: `/`
- Filesystem: `ext4`
- Size: `233G`
- Used: `104G`
- Available: `118G`

### EFI Partition
- Device: `/dev/nvme0n1p1`
- Mountpoint: `/boot/efi`
- Filesystem: `vfat`
- Size: `1.1G`

### Media Disk
- Device: `/dev/sda1`
- Mountpoint: `/mnt/media`
- Filesystem: `ext4`
- Size: `7.3T`
- Used: `1.7T`
- Available: `5.2T`

## Network Storage

### Backup Share
- Source: `//192.168.1.154/Backups`
- Mountpoint: `/mnt/backupshare`
- Filesystem: `cifs`
- Size: `1.9T`
- Used: `921G`
- Available: `942G`

## Notes
- `/mnt/media` is the primary content/storage mount for media-related services.
- `/mnt/backupshare` is the remote backup target mounted from the desktop PC.

## Books Storage

- `/mnt/media/books/library` is the canonical book library mounted by Calibre Web Automated.
- `/mnt/media/books/ingest` is the shared ingest path used by Calibre Web Automated and Shelfmark.
- Shelfmark also has the current intentional writable bind mount `/mnt/media:/media`.
- The broad Shelfmark mount should be reviewed later, but it must not be narrowed without testing existing behavior.
- Books backup design is pending; no books backup script or tested restore is represented in the repository.
