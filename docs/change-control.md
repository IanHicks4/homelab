# Homelab Change Control

## Purpose

Provide a lightweight, practical process for changing the homelab without treating production as an experiment. The goal is small, reviewable, reversible changes with clear evidence and documentation.

The human owner/operator retains final production authority.

## Change Classes

### Docs-Only

Examples:

- Updating service inventory.
- Adding restore runbooks.
- Correcting alert documentation.

Expected controls:

- Scoped documentation diff.
- Evidence check against repository files or explicit human facts.
- No runtime commands required.

### Repo-Only Config

Examples:

- Compose, Caddy, monitoring, or backup-script changes not yet applied to a runtime.

Expected controls:

- Syntax/config validation where available.
- Clear production promotion plan.
- No claim that production changed until runtime evidence exists.

### Lab Change

Examples:

- Testing a new service or configuration in codex-lab or another non-production VM.

Expected controls:

- Isolated test scope.
- Test data rather than production secrets.
- Documented differences between lab and OptiPlex production.

### Production Change

Examples:

- Updating a running Compose stack under `/srv/docker`.
- Changing public DNS, Caddy routing, bind addresses, or container access.

Expected controls:

- Human approval.
- Backup or snapshot when state is at risk.
- Explicit rollback and validation steps.
- Repository reconciliation through `reconcile/<task-name>`.

### Security-Sensitive Change

Examples:

- Authentication, public exposure, DDNS, VPN, secrets, certificates, Docker socket access, or firewall changes.

Expected controls:

- Review exposure before and after.
- Keep secret values out of Git and chat.
- Prefer lab validation.
- Require explicit rollback and post-change security checks.

## Required Pre-Change Review

Before implementation, record or discuss:

### Goal

- What problem is being solved?
- What is the desired final state?
- What evidence will prove success?

### Blast Radius

- Which services, users, routes, data, or hosts can be affected?
- Is downtime expected?
- Could the change alter public exposure or authentication?

### Dependencies

- Required mounts such as `/mnt/media` or `/mnt/backupshare`.
- External networks such as Docker `proxy`.
- DNS, Pi-hole, Tailscale, Caddy, Authelia, databases, and upstream providers.
- Host-specific devices or paths.

### Rollback Plan

- What exact state will be preserved?
- What command or file move restores the prior state?
- When will rollback be triggered?
- How long will previous data/config be retained?

### Validation Plan

- Syntax/config checks.
- Container or service health checks when permitted.
- Internal and public access tests as applicable.
- Data integrity and application-specific checks.
- Monitoring and alert verification.

## Production Principles

- Avoid direct production experimentation when a lab alternative exists.
- Prefer testing in codex-lab or another isolated lab environment.
- Make one understandable change at a time.
- Prefer changes that are reversible with `mv`, a backup archive, a snapshot, or a Git revert.
- Do not combine unrelated cleanup with a production fix.
- Treat public exposure, authentication, storage, and secrets as higher-risk changes.
- Do not let Codex make uncontrolled production changes.

## Implementation Flow

### 1. Inspect

- Read current repository configuration.
- Compare it with explicitly confirmed operational state.
- Identify drift before editing.
- Mark unknown facts as `needs verification`.

### 2. Backup Or Snapshot If Needed

- Use the stack backup script when persistent state is involved.
- Verify the backup destination is available.
- For VM/LXC or broad host changes, consider a Proxmox snapshot or backup according to the approved operational process.
- Do not commit backup archives to Git.

### 3. Edit

- Use a short-lived branch.
- Change only scoped files.
- Keep secrets out of repository files.
- Preserve existing conventions.

### 4. Validate

- Run non-destructive repository checks first.
- Validate in the lab when possible.
- Validate production only after approval and promotion.
- Check expected access and confirm unintended access is absent.

### 5. Commit

- Review the complete diff.
- Use a focused commit message.
- Commit only intended files.
- Do not commit `.env`, private keys, databases, runtime data, or archives.

### 6. Document

- Update inventory, runbooks, alerting, or change notes as needed.
- Document the final state, not an abandoned intermediate state.
- Merge production reconciliation into `main` before dependent Codex documentation work when practical.

## Rollback Expectations

Every production or security-sensitive change needs a usable rollback.

- Preserve previous files or directories with timestamps.
- Keep the previous version until validation is complete.
- Define rollback triggers before making the change.
- Restore in dependency-aware order.
- Re-run validation after rollback.
- Document rollback outcomes if the change failed.

For docs-only changes, rollback is normally a Git revert or follow-up correction.

## Validation Expectations

Validation should match the change:

- Config change: syntax and application validation.
- Bind/exposure change: verify intended interface and confirm unintended interfaces are closed.
- DNS change: verify public and internal resolution separately.
- Backup change: create or inspect an archive and perform periodic restore testing.
- Alerting change: verify query state, contact point delivery, No Data behavior, and silence behavior.
- Retired service: confirm active config, documentation, monitoring, DNS, and backups no longer treat it as active.

If a check cannot be performed, say so explicitly.

## Secret Handling

Never commit:

- `.env` files.
- API keys or tokens.
- Passwords or application credentials.
- Private keys or certificate private material.
- WireGuard keys or VPN credentials.
- Porkbun credentials.
- Authelia secret files.
- Vaultwarden data.
- n8n credentials/workflow state copied from production.
- Backup archives or database dumps.

Use placeholders only in documentation. Restore secret material from the approved secret store or protected backup location.

Before committing, inspect:

```bash
git status --short
git diff --name-only
git diff
```

## Documentation Expectations

- Document facts supported by repository evidence or explicit human confirmation.
- Do not infer public exposure from a Caddy route alone.
- Do not claim a service is running without runtime evidence or human confirmation.
- Do not claim scheduling from script presence alone.
- Use `scheduled operationally; verify on host` when appropriate.
- Use `needs verification` for unresolved state.
- Keep access classifications current: public, Pi-hole internal DNS, Tailscale/private, localhost, or container-only.
- Link backup scripts and restore runbooks by exact repository path.

## Homelab Examples

### Retiring Unused Services

For OnlyOffice or Gamebuilds retirement:

1. Confirm the service is no longer needed.
2. Identify dependencies, DNS, Caddy routes, monitoring, data, and backup references.
3. Preserve data if required.
4. Remove or archive active configuration through a reviewed branch.
5. Validate no port or route remains active.
6. Move the service to retired documentation.

### Changing DDNS Or Public Exposure

For limiting public DDNS to `jellyfin`, `seerr`, `immich`, and `address`:

1. Review intended public versus internal names.
2. Validate internal Pi-hole/Tailscale access before removing public DNS.
3. Make a small DNS/config change.
4. Verify public records and confirm internal-only names no longer resolve publicly.
5. Update exposure documentation.

### Adding Backup Scripts

1. Identify persistent and sensitive state.
2. Define exclusions and clean-stop order.
3. Confirm `/mnt/backupshare` handling.
4. Test archive creation in an approved environment.
5. Add a matching restore runbook.
6. Mark scheduling as `needs verification` unless documented.

### Hardening Glances Bind Address

1. Confirm Homepage depends on Glances widgets.
2. Change the listener from all interfaces to the Tailscale IP.
3. Verify `100.77.136.106:61208` works for Homepage.
4. Confirm LAN-wide exposure is reduced.
5. Keep the accepted-risk note for host and Docker socket access; bind hardening does not remove that risk.

### Alerting Changes

1. Review query behavior in healthy, failing, and No Data states.
2. Verify threshold, reduce function, pending duration, severity labels, and notification policy.
3. Test the Discord contact point without exposing its webhook.
4. Document UI-managed state as `needs verification` unless provisioned as code.
5. Confirm Uptime Kuma and Grafana alert responsibilities remain distinct.
