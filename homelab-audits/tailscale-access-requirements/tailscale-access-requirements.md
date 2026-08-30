# Tailscale Access Requirements Audit

Audit date: 2026-08-30 (UTC)

Scope: repository-only, read-only inspection of network requirements

Runtime status: not inspected

## Executive Summary

The repository strongly supports an access model centered on the Dell OptiPlex named `server`, whose documented Tailscale IP is `100.77.136.106`. Ten application ports are explicitly published on that address, and Glances is explicitly configured to listen on it. The repo also documents private HTTPS routes through Caddy and Pi-hole internal DNS. These facts prove configured listeners and intended access paths, but they do not identify every human client that actually uses them or prove current runtime reachability.

The strongest cross-host requirements are:

- the OptiPlex/Homepage stack calling the Raspberry Pi Pi-hole at Tailscale IP `100.111.36.105` over HTTP;
- the OptiPlex monitoring stack scraping the Pi-hole LXC at LAN IP `192.168.1.53` on TCP/9100;
- the OptiPlex using the desktop at LAN IP `192.168.1.154` as a CIFS/SMB backup target; and
- internal clients reaching Caddy on the OptiPlex over HTTPS after resolving private names through Pi-hole.

Repository configuration also makes Homepage call several services through the OptiPlex's own Tailscale address. A future policy must account for these server-originated/self-addressed calls if Tailscale policy enforcement applies to them; that behavior needs a lab test.

There is evidence of intended remote SSH administration of the OptiPlex and a Homepage link to the p360 Proxmox UI, but Git does not prove which human devices use either path. The p360 is documented only with LAN IP `192.168.1.101`; no current p360 Tailscale identity or address is recorded. `codex-lab` is documented as a VM on p360, but no current Tailnet address or existing MCP listener is represented.

No repository artifact was found defining Tailscale ACLs/Grants, tags, MagicDNS settings, Tailscale SSH, subnet-route advertisement or acceptance, or an exit node. There are many `192.168.1.x` dependencies, but none proves that `192.168.1.0/24` is advertised into the Tailnet. The largest unknowns are which people/devices use which services, how Tailnet clients receive Pi-hole DNS, whether remote clients use a subnet router to reach LAN-only endpoints, and whether runtime-only cross-host dependencies exist.

### Evidence Model

- **Repo-configured:** a checked-in Compose/configuration file declares the endpoint or dependency. This is desired-state evidence, not runtime proof.
- **Historical runtime evidence:** a dated audit recorded live observations. It is valid only for its audit date.
- **Inferred:** the repository indicates likely intent, but does not prove the initiating identity, transport path, or actual use.
- **Planned architecture:** supplied in this audit request and deliberately kept separate from current requirements.

Important evidence conflicts or gaps:

- `docs/audits/monitoring-compose-drift-2026-08-21.md` records live monitoring state on 2026-08-21 and also records drift between the live and tracked Compose files. It does not prove current state on 2026-08-30 or that the configured Pi-hole scrape was healthy.
- `docs/audits/books-stack-review-2026-08-21.md` confirms the books listeners were live on 2026-08-21. It does not prove they are live now.
- `compose/caddy/Caddyfile` contains internal-TLS routes for `vikunja.kai.coach`, `books.kai.coach`, and `shelf.kai.coach`, but `inventory/domains.md` omits Vikunja and does not prove Pi-hole records for the books names. DNS configuration and current resolution need verification.
- `configs/homepage/services.yaml` links to `https://p360:8006`, while `inventory/hardware.md` records p360 only as `192.168.1.101`. The repo does not establish whether `p360` is resolved by LAN DNS, Pi-hole, `/etc/hosts`, or MagicDNS.

## Confirmed or Strongly Supported Access Flows

These are configured or historically observed flows. “Strong” does not mean currently running; the confidence column describes exactly what the repository establishes.

| Source | Destination | Protocol/Port | Purpose | Evidence | Confidence |
|---|---|---|---|---|---|
| Homepage container on OptiPlex `server` | Glances on the same node via `100.77.136.106` | HTTP/TCP 61208 | CPU and process widgets; direct dashboard link | `configs/homepage/services.yaml`; `compose/homepage-stack/compose.yaml`; `docs/service-inventory.md` | High for repo configuration; current runtime needs verification |
| Homepage container on OptiPlex `server` | IT Tools, Speedtest Tracker, Sonarr, Radarr, qBittorrent, Bazarr, and Prowlarr on the same node via `100.77.136.106` | HTTP/TCP 8085, 8082, 8989, 7878, 8080, 6767, 9696 | Homepage widgets and/or site monitoring | `configs/homepage/services.yaml`; matching files under `compose/`; `docs/service-inventory.md` | High for repo configuration; whether self-addressed traffic is policy-relevant needs testing |
| Homepage container on OptiPlex `server` | Raspberry Pi Pi-hole `100.111.36.105` | HTTP/TCP 80 | Pi-hole status widget | `configs/homepage/services.yaml`; `inventory/ips.md` | High for repo configuration; current runtime needs verification |
| Homepage container on OptiPlex `server` | Pi-hole LXC `192.168.1.53` | HTTP/TCP 80 | Pi-hole status widget | `configs/homepage/services.yaml` | High for repo configuration; LXC host/current state needs verification |
| Prometheus on OptiPlex `server` | Pi-hole LXC `192.168.1.53` | HTTP/TCP 9100 | node-exporter metrics scrape | `compose/monitoring/prometheus.yml`; `docs/alerting.md`; `docs/service-inventory.md` | High for repo configuration; the monitoring stack was running on 2026-08-21, but target health was not audited |
| OptiPlex `server` (`192.168.1.100`) | `desktop-ianpc` (`192.168.1.154`) | CIFS/SMB, normally TCP 445 | Mount `//192.168.1.154/Backups` at `/mnt/backupshare` for service backups | `inventory/storage.md`; `inventory/hardware.md`; `runbooks/rebuild-optiplex.md`; `scripts/backups/*.sh` | Strongly supported dependency; mount/runtime status needs verification |
| Trusted internal client identities, not identified in Git | Caddy on OptiPlex `100.77.136.106` | HTTPS/TCP 443 | Private web routes including Homepage, Uptime Kuma, Grafana, n8n, Authelia, IT Tools, Vaultwarden, and possibly Vikunja/books services | `compose/caddy/Caddyfile`; `docs/service-inventory.md`; `inventory/domains.md` | Medium: intended private access is documented, but client identities and several DNS records need verification |
| Tailnet client identities, not identified in Git | OptiPlex `100.77.136.106` | HTTP/TCP 3000, 6767, 7878, 8080, 8082, 8083, 8084, 8085, 8989, 9696; Glances TCP 61208 | Direct private access to Homepage, Bazarr, Radarr, qBittorrent, Speedtest Tracker, books apps, IT Tools, Sonarr, Prowlarr, and Glances | `compose/arr/compose.yaml`; `compose/vpn/compose.yaml`; `compose/books/compose.yaml`; `compose/homepage-stack/compose.yaml`; `compose/it-tools/compose.yaml`; `compose/speedtest-tracker/compose.yaml` | High for listener configuration; actual users and continued need for each direct port need verification |
| Human admin device, not identified in Git | OptiPlex `server` | SSH/TCP 22 | Remote host administration | `inventory/ports.md`; `runbooks/rebuild-optiplex.md`; `runbooks/troubleshooting.md` | Medium: installation and intended remote use are documented; actual source devices and current SSH mode need verification |

The dated books audit provides the only direct runtime confirmation for Tailscale-bound application listeners: on **2026-08-21**, `100.77.136.106:8083/tcp` and `:8084/tcp` were published by running, healthy containers (`docs/audits/books-stack-review-2026-08-21.md`). This is historical evidence, not a current-state claim.

## Human Access Requirements

### Proven by repository evidence

- The repo configures private service entry points on the OptiPlex Tailscale address. Direct endpoints are listed in the table above.
- Caddy is configured on TCP/80 and TCP/443, and private routes use internal TLS. `docs/service-inventory.md` says Pi-hole resolves at least `home.kai.coach`, `status.kai.coach`, `grafana.kai.coach`, and `n8n.kai.coach` to `100.77.136.106`; it also describes `auth.kai.coach`, `vault.kai.coach`, and `tools.kai.coach` as Pi-hole/internal names.
- The OptiPlex rebuild procedure enables OpenSSH, installs Tailscale, and lists inability to SSH remotely as a Tailscale failure symptom (`runbooks/rebuild-optiplex.md`, `runbooks/troubleshooting.md`).
- Homepage presents links for the p360 Proxmox UI, Pi-hole administration, the router, and multiple private applications (`configs/homepage/services.yaml`, `configs/homepage/bookmarks.yaml`). A link proves configured discoverability, not that a human uses it.

### Inferred requirements

- **Human administration of OptiPlex over SSH:** likely required, but the allowed source device set is unknown. `mint-admin`, `desktop-ianpc`, and `iphone-ian` are documented Tailnet nodes in `inventory/ips.md`; the file does not say which, if any, originate SSH.
- **Human administration of p360 over HTTPS/TCP 8006:** likely because Homepage links to `https://p360:8006` and p360 is documented as a Proxmox lab node. Current access may be LAN-only. No existing p360 Tailnet identity is proven.
- **Human administration of Pi-hole:** likely through `http://100.111.36.105/admin/` for the Pi 4 and `http://192.168.1.53/admin` for the LXC. Homepage links/widgets prove configured endpoints but not actual human use.
- **Router administration:** Homepage links to `http://192.168.1.1`. Remote Tailnet use would require a subnet route or another access mechanism, neither of which is represented.
- **Private application use:** likely over TCP/443 via internal DNS and, for some tools, direct Tailscale ports. Actual client devices and whether direct-port access remains necessary alongside Caddy need verification.

### Needs verification from the human operator

- Which human devices need SSH to the OptiPlex, p360, Raspberry Pi, Pi-hole LXC, `codex-lab`, or any other VM/LXC?
- Is SSH ordinary OpenSSH carried over Tailscale networking, Tailscale SSH, LAN SSH, or a combination?
- Is `https://p360:8006` used remotely over Tailscale/subnet routing or only from the LAN?
- Which devices use the private web applications, and should phones/non-admin personal devices have the same rights as admin workstations?
- Which direct application ports are deliberately used by humans rather than only by Homepage integrations?
- Do clients trust the Caddy internal CA, and is TCP/80 required for any private-route redirect/bootstrap behavior in addition to TCP/443?

An exposed listener or Homepage link was not treated as proof of actual human use.

## Machine-to-Machine Requirements

### Cross-host dependencies supported by the repository

1. **Homepage on OptiPlex to Raspberry Pi Pi-hole:** `100.111.36.105:80/tcp` for the Pi-hole widget. Because the target is a Tailscale IP, this is directly relevant to a least-privilege Tailnet policy.
2. **Homepage on OptiPlex to Pi-hole LXC:** `192.168.1.53:80/tcp` for the Pi-hole widget. This is a LAN flow when the OptiPlex uses its LAN interface; whether any Tailnet-originated client depends on a subnet router for the same endpoint is unknown.
3. **Prometheus on OptiPlex to Pi-hole LXC:** `192.168.1.53:9100/tcp` for node-exporter metrics. The dated monitoring audit confirms the monitoring containers were running on 2026-08-21, but it explicitly did not validate Prometheus targets end-to-end.
4. **OptiPlex to desktop backup target:** `192.168.1.154` via CIFS/SMB, normally TCP/445. All represented backup scripts write beneath `/mnt/backupshare`; the mount source is documented as `//192.168.1.154/Backups`.
5. **Homepage to services through the OptiPlex's own Tailscale IP:** TCP/61208, 8085, 8082, 8989, 7878, 8080, 6767, and 9696. These are explicit widget/site-monitor URLs. Test whether the eventual Tailnet policy must grant the OptiPlex access to its own Tailscale-addressed listeners.

### Same-host/container dependencies that should not require Tailnet rules

- Caddy proxies over the external Docker `proxy` network to Seerr, Vaultwarden, Immich, Homepage, Uptime Kuma, Grafana, n8n, Authelia, IT Tools, Vikunja, Calibre Web Automated, Shelfmark, and the wedding address form (`compose/caddy/Caddyfile` and service Compose files).
- Caddy reaches host-network Jellyfin at `host.docker.internal:8096`.
- Caddy's protected routes call Authelia at `authelia:9091` for forward authentication.
- Alloy discovers local Docker logs and pushes them to `loki:3100` (`compose/logging/alloy/config.alloy`).
- Prometheus scrapes local node-exporter through `host.docker.internal:9100` and cAdvisor through `cadvisor:8080` (`compose/monitoring/prometheus.yml`).
- Homepage reaches Calibre Web Automated through `calibre-web-automated:8083` for its widget.
- n8n and the address form communicate through Caddy/Docker networking for the public webhook path.

These dependencies matter operationally but are not evidence for Tailnet node-to-node permission. Docker-internal configuration that may exist only in untracked application state was not inspected.

### Important machine-to-machine unknowns

- Uptime Kuma monitor definitions are stored in runtime data and are not represented in readable repo configuration; their destinations are unknown.
- Application integrations stored in service databases/config directories (for example Arr integrations, webhook targets, notification targets, and backup scheduling) are not proven by Git.
- No off-host log shipping is configured in the tracked Alloy file; it collects local Docker/journal logs only.
- No repository evidence proves that Home Assistant or another VM/LXC initiates Tailnet or LAN flows.

## Subnet Routing Requirements

No checked-in Tailscale subnet-router configuration was found. Specifically, the repo contains no `--advertise-routes`, `--accept-routes`, route approval, or Tailnet policy route declaration. Therefore this audit does **not** establish that `192.168.1.0/24` or any other subnet is currently routed through Tailscale.

The repo does establish LAN dependencies on:

| LAN destination | Documented use | Tailnet/subnet implication |
|---|---|---|
| `192.168.1.1` | Router administration bookmark | A remote Tailnet client would need a subnet route or other gateway path; actual remote use needs verification. |
| `192.168.1.53:80` | Homepage Pi-hole LXC widget/admin link | OptiPlex can likely use its local LAN interface; personal Tailnet-device use would require verified routing. |
| `192.168.1.53:9100` | Prometheus scrape | This is an OptiPlex-to-LAN flow and does not by itself require a Tailscale subnet router. |
| `192.168.1.101:8006` or hostname `p360:8006` | Proxmox administration | The IP is documented in hardware inventory; the Homepage link uses only `p360`. Resolution and remote path need verification. |
| `192.168.1.154:445` | Desktop SMB backup share | OptiPlex-to-LAN dependency; no Tailnet route is proven or necessarily needed. |

Other relevant observations:

- `compose/vpn/compose.yaml` contains a **commented-out** `FIREWALL_OUTBOUND_SUBNETS=192.168.1.0/24`. It concerns Gluetun's VPN firewall, not Tailscale route advertisement, and is not active configuration.
- The Pi 4 has both LAN `192.168.1.56` and Tailscale `100.111.36.105` addresses in inventory. The Pi-hole LXC at `192.168.1.53` is a distinct documented target, but its hypervisor and Tailnet membership are not recorded.
- The repository does not prove whether all personal Tailnet devices receive Pi-hole DNS through Tailscale, use LAN DHCP DNS while at home, or use some other resolver while remote.

Before narrowing policy, verify the active subnet router(s), advertised/approved prefixes, route consumers, and whether routed destinations should be granted individually or by a narrowly scoped subnet role. Do not assume every personal device needs the full LAN `/24`.

## MCP Future Requirements

The following requirements come from the requested future architecture, not from evidence of current production listeners or traffic:

| Source | Destination | Protocol/Port | Status | Purpose/notes |
|---|---|---|---|---|
| `codex-lab` VM | OptiPlex homelab-agent | TCP/9443 | **Planned architecture** | Narrow MCP agent access. The repo currently documents the OptiPlex as `server`/`100.77.136.106`, but no homelab-agent listener is represented. |
| `codex-lab` VM | p360 Proxmox API | HTTPS/TCP 8006 | **Planned architecture** | Narrow Proxmox API access. The repo currently documents p360 at LAN `192.168.1.101`; its intended Tailscale node identity/address needs verification. |

`docs/codex-workflow.md` proves that `codex-lab` is intended as a Proxmox VM and a safe repository workspace. It does not prove either future MCP flow is deployed. These flows should later be granted to the `codex-lab` machine identity only, not to every personal device or every VM.

## Needs Human Verification

- [ ] Which devices Ian SSHes from and which hosts/VMs/LXCs he SSHes to.
- [ ] Whether SSH uses normal OpenSSH over Tailnet IPs/MagicDNS, Tailscale SSH, LAN addresses, or multiple methods.
- [ ] Which internal web services Ian accesses from phone, laptop, desktop, `mint-admin`, or other devices.
- [ ] Which Tailscale-bound direct ports are intentionally used and which can eventually be replaced by Caddy-only access.
- [ ] Whether all personal Tailnet devices need access to the LAN subnet, or only selected admin devices.
- [ ] Which node advertises `192.168.1.0/24` or other subnet routes, if any, and which devices accept/use them.
- [ ] Whether any services communicate across physical hosts in ways not represented in Git, including Uptime Kuma, Arr integrations, notification systems, webhooks, and schedulers.
- [ ] Whether any device acts as a Tailscale exit node or depends on one.
- [ ] Whether Tailscale MagicDNS is enabled and whether the hostname `p360` depends on MagicDNS, Pi-hole, LAN DNS, or local host configuration.
- [ ] Which resolver(s) Tailnet clients use remotely and whether TCP/UDP 53 to `100.111.36.105`, `192.168.1.53`, or another address must be allowed.
- [ ] Whether Home Assistant or other VMs/LXCs need Tailnet-to-LAN, LAN-to-Tailnet, or node-to-node access.
- [ ] Whether the p360 currently runs Tailscale and, if so, its stable node identity/Tailscale IP.
- [ ] The current Tailscale identity/address of `codex-lab` and whether it needs any non-MCP access.
- [ ] Whether Homepage's calls to the OptiPlex's own Tailscale address are evaluated by Tailnet policy and require an explicit self-access grant.
- [ ] Whether human Proxmox access on TCP/8006 should remain separate from `codex-lab` API access.
- [ ] Whether remote human access to Pi-hole admin, router admin, and the Pi-hole LXC is required.
- [ ] Whether TCP/80 to the OptiPlex is required from Tailnet clients or TCP/443 alone is sufficient for private applications.
- [ ] Whether `books.kai.coach`, `shelf.kai.coach`, and `vikunja.kai.coach` have active Pi-hole records and which clients use them.
- [ ] Whether the SMB backup share ever needs to be reached through Tailscale rather than the OptiPlex's local LAN.
- [ ] Whether all listed Compose stacks, direct listeners, monitoring targets, and backup jobs are currently active.

## Candidate Policy Groups

These are logical roles only. They are not proposed ACL/Grant syntax, tags, or a final policy.

| Candidate role | Possible members, subject to verification | Intended scope |
|---|---|---|
| `human-admin` | Ian's explicitly approved admin workstation(s) | SSH, Proxmox administration, infrastructure dashboards, and selected sensitive application admin ports. |
| `personal-device` | Phone and non-admin personal clients | User-facing private services over HTTPS, without broad SSH, hypervisor, monitoring, or subnet rights. |
| `prod-server` | OptiPlex `server` | Production Docker host; source of monitoring, Homepage, DNS-widget, and backup flows; destination for private services. |
| `hypervisor` | p360 | Proxmox management/API destination, kept distinct from general servers and guests. |
| `infra-dns` | Raspberry Pi Pi-hole and Pi-hole LXC if it joins the Tailnet | DNS service and narrowly selected admin/monitoring endpoints. |
| `backup-target` | `desktop-ianpc` when Tailnet access is actually required | SMB destination only; avoid inheriting broad personal-device access merely because the desktop is also personal. |
| `mcp-client` | `codex-lab` | Source role limited to explicitly approved MCP/API destinations. |
| `mcp-server` | OptiPlex homelab-agent endpoint | Destination role for TCP/9443 only from approved MCP clients. |
| `mcp-managed` | p360 or other explicitly managed systems | Narrow management/API destinations; do not imply blanket shell or LAN access. |
| `subnet-router` | Only verified route-advertising node(s) | Routing capability separated from permission to reach every routed destination. |

Future policy design considerations:

- Prefer stable node identity/role membership over embedding the documented `100.x` addresses as the main authorization model.
- Separate human administration, personal service consumption, machine monitoring, backups, and MCP automation. They have different trust levels.
- Treat subnet-route availability and permission to use routed destinations as separate decisions. Grant only needed hosts/ports where practical.
- Preserve DNS reachability before relying on private hostnames, but determine the actual resolver targets and client groups first.
- Account for Homepage's server-side calls separately from a human clicking Homepage links.
- Decide whether direct Tailscale-bound app ports remain intentional. Several bypass Caddy, internal TLS, and any Caddy/Authelia controls.
- Keep planned `codex-lab` MCP permissions independent of human Proxmox administration and unrelated OptiPlex services.
- Validate changes first with a small canary set and an operator recovery path; the repository alone cannot supply a safe complete rule set.
- Re-audit current Tailnet machines, users, tags, DNS, routes, SSH, and exit-node state through approved read-only runtime evidence before writing a policy.

No Tailscale policy, ACL, Grant, tag, firewall, DNS, Docker, or production configuration was created or changed by this audit.
