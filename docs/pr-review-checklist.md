# Pull Request Review Checklist

## Purpose

Provide a practical review checklist for homelab pull requests before merging into `main`. The checklist is intended for both `reconcile/*` production-derived branches and `codex/*` documentation/repository branches.

## Pre-Review Checks

- [ ] Branch has a clear, short-lived name: `reconcile/<task-name>` or `codex/<task-name>`.
- [ ] Branch is based on the latest `main`.
- [ ] Working tree status is understood.
- [ ] Only expected files changed.
- [ ] No `.env` files were added.
- [ ] No API keys, tokens, passwords, private keys, WireGuard keys, Porkbun credentials, or application credentials are present.
- [ ] No backup archives, database dumps, runtime databases, or generated service data are present.
- [ ] Production-derived changes were reconciled without copying live secrets.

Useful pre-review commands:

```bash
git status --short
git fetch origin
git diff --name-only origin/main...HEAD
git diff --stat origin/main...HEAD
```

## Diff Review Checklist

- [ ] Diff matches the stated PR goal.
- [ ] No unrelated refactors or formatting churn.
- [ ] No accidental deletion of config, docs, or data paths.
- [ ] Paths, container names, domains, ports, and script names match repository evidence.
- [ ] New files are in the correct directory.
- [ ] Shell commands in docs are copy-pasteable and non-destructive by default.
- [ ] Risky cleanup uses preservation or `mv` before deletion.
- [ ] Comments explain only non-obvious behavior.
- [ ] Markdown tables and code fences render correctly.

Review the full diff:

```bash
git diff origin/main...HEAD
```

## Security Checklist

- [ ] No secret values are present in source, docs, examples, command output, or screenshots.
- [ ] `.env` files remain ignored and untracked.
- [ ] Private keys, certificate private material, and WireGuard keys are absent.
- [ ] Backup archives and restored runtime directories are absent.
- [ ] Public exposure changes are explicit and justified.
- [ ] Internal-only services remain on Pi-hole DNS, Tailscale, localhost, or container networks as intended.
- [ ] Docker socket and host-mount risks are documented where relevant.
- [ ] Auth and reverse-proxy changes preserve the intended security model.
- [ ] Sensitive backup/restore instructions avoid printing secret contents.

Example secret-pattern searches:

```bash
git grep -nEi '(api[_-]?key|secret[_-]?key|private[_-]?key|password|token|wireguard)' -- .
git diff origin/main...HEAD | grep -nEi '(api[_-]?key|secret[_-]?key|private[_-]?key|password|token|wireguard)'
find . -type f \( -name '.env' -o -name '*.pem' -o -name '*.key' -o -name '*.tar.gz' \) -print
```

Matches require review; names and placeholders may be legitimate. Never paste real values into review comments.

## Operational Checklist

- [ ] Change class is identified: docs-only, repo-only config, lab, production, or security-sensitive.
- [ ] Blast radius is understood.
- [ ] Dependencies and mounts are identified.
- [ ] Backup or snapshot requirement is addressed.
- [ ] Rollback steps are specific and usable.
- [ ] Start/stop order respects dependencies.
- [ ] Expected downtime is stated.
- [ ] Production promotion steps are separate from repository edits.
- [ ] Host-specific behavior is marked `needs verification` unless validated.
- [ ] Scheduling claims are supported by Git evidence or say `scheduled operationally; verify on host`.

## Documentation Checklist

- [ ] Documentation reflects the final intended state.
- [ ] Repository evidence and human-confirmed operational facts are distinguished.
- [ ] Public versus internal/private access is explicit.
- [ ] Backup script and restore runbook paths exist.
- [ ] Retired services are not listed as active.
- [ ] Sensitive-state warnings are present where needed.
- [ ] Uncertain facts use `needs verification`.
- [ ] No Caddy route is treated as proof of public exposure by itself.
- [ ] Related inventory, alerting, runbook, or workflow docs are updated when in scope.

## Validation Evidence Checklist

- [ ] PR description lists validation commands run.
- [ ] Results are summarized, not merely claimed.
- [ ] `git diff --check` passes.
- [ ] Syntax/config checks pass when applicable.
- [ ] Lab validation evidence is included for behavior changes.
- [ ] Production validation is included only when actually performed and approved.
- [ ] Access checks cover both intended reachability and unintended exposure.
- [ ] Rollback was reviewed, and restore testing is noted when relevant.
- [ ] Checks not run are stated explicitly.

Useful commands:

```bash
git diff --check
git status --short
git diff --name-only origin/main...HEAD
git diff --stat origin/main...HEAD
git diff origin/main...HEAD
```

## Merge Checklist

- [ ] Human owner/operator approves production or security-sensitive changes.
- [ ] Review comments are resolved.
- [ ] Branch is current enough with `main` to merge safely.
- [ ] Required checks pass.
- [ ] Commit history is understandable and scoped.
- [ ] Final diff contains only approved files.
- [ ] Merge method follows the repository's current practice. Needs verification if not documented.
- [ ] Branch can be removed after merge when no longer needed.

Review recent history and divergence:

```bash
git log --oneline --decorate --graph --all --max-count=20
```

## Post-Merge Sync Checklist

### OptiPlex

- [ ] Confirm no uncommitted production reconciliation work will be overwritten.
- [ ] Sync the repository checkout:

  ```bash
  git status --short
  git switch main
  git pull origin main
  ```

- [ ] Promote repository changes to `/srv/docker` only through the approved production process.
- [ ] Validate affected production services when a production change is applied.

### codex-lab

- [ ] Confirm no useful uncommitted Codex work is being discarded.
- [ ] Sync from `main`:

  ```bash
  git status --short
  git switch main
  git pull origin main
  ```

- [ ] Delete or close the merged `codex/*` branch when appropriate.
- [ ] Start the next task from a fresh branch based on updated `main`.

## Useful Commands

```bash
git status --short
git diff --name-only
git diff --stat
git diff
git log --oneline --decorate --graph --all --max-count=20
git switch main && git pull origin main
```

For a branch review against remote `main`:

```bash
git fetch origin
git diff --name-only origin/main...HEAD
git diff --stat origin/main...HEAD
git diff origin/main...HEAD
```

Before merge, the reviewer should be able to answer:

- What changed?
- Why is it needed?
- What can break?
- How is it validated?
- How is it rolled back?
- What remains uncertain?
