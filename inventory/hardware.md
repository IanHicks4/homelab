# Hardware Inventory

## Dell OptiPlex
- Hostname: `server`
- Purpose: Primary homelab server / main Docker host
- LAN IP: `192.168.1.100`
- Tailscale IP: `100.77.136.106`
- OS disk: NVMe root disk mounted at `/`
- Attached storage: External 7.3T disk mounted at `/mnt/media`

### Notes
- This host runs the main Docker workloads including media, reverse proxy, monitoring, DDNS, and utility services.
- Add CPU, RAM, and exact model details later if desired.

## Raspberry Pi 4
- Hostname: `raspberrypi`
- Purpose: Infrastructure node
- LAN IP: `192.168.1.56`
- Tailscale IP: `100.111.36.105`

### Notes
- Intended role: Pi-hole, Unbound, and lightweight infra services.

## Desktop PC
- Hostname: `desktop-ianpc`
- Purpose: Backup target / SMB share host
- LAN IP: `192.168.1.154`
- Tailscale IP: `100.117.228.49`

## Router
- Model: Verizon router
- Purpose: Main LAN gateway and internet edge

## Storage Summary
- Root disk: `238.5G` NVMe
- Media disk: `7.3T` mounted at `/mnt/media`
- SMB backup share: `//192.168.1.154/Backups` mounted at `/mnt/backupshare`
