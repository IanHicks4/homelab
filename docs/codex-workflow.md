# Codex Workflow

## Purpose

Define how the human owner, ChatGPT, and Codex collaborate on homelab repository work without creating uncontrolled production changes.

The workflow keeps `main` as the shared synchronization point, uses short-lived task branches, and separates repository work in codex-lab from production state under `/srv/docker` on the OptiPlex.

## Roles And Responsibilities

### Human Owner/Operator

- Owns production and makes final decisions.
- Approves scope, risk, downtime, and production changes.
- Provides operational facts that are not available in the repository.
- Decides when a lab-tested change is promoted to production.
- Resolves ambiguity when repository evidence and live production differ.

### ChatGPT Lead Sysadmin

- Acts as Lead Sysadmin, Infrastructure Architect, and Technical Mentor.
- Helps define scope, implementation approach, rollback, and validation.
- Reviews technical decisions and challenges unsafe assumptions.
- Distinguishes repository evidence from operational claims.
- Does not replace human approval for production changes.

### Codex Junior Sysadmin

- Performs scoped repository tasks in codex-lab.
- Inspects relevant files before editing.
- Changes only files allowed by the task.
- Uses existing repository patterns and avoids unrelated refactors.
- Reports files changed, verification performed, and unresolved uncertainty.
- Does not make uncontrolled production changes.

### Git `main` Branch

- Acts as the shared synchronization point for the OptiPlex, codex-lab, and other clones.
- Should contain reconciled production-derived changes before Codex documents or builds on them.
- Should remain reviewable and free of secrets, backup archives, and live runtime data.

### Production Host

- Production services run on the OptiPlex under `/srv/docker`.
- The source-of-truth Git checkout is `~/homelab` on the OptiPlex.
- Production-derived changes are normally made or reconciled from the OptiPlex on a short-lived branch.
- Direct production experimentation should be avoided when a lab alternative exists.

### codex-lab VM

- A Proxmox VM used as a safe workspace for Codex.
- Uses a clone of the homelab repository.
- Is the preferred location for documentation, review, and scoped repository edits.
- Is not a substitute for validating host-specific production behavior.

## Branching Model

### `main`

- Shared, reviewed synchronization point.
- New task branches should start from the latest `main`.
- Production-derived facts should be merged into `main` before Codex documents them unless the human explicitly supplies those facts.

### `reconcile/<task-name>`

Use for short-lived OptiPlex production/reconciliation work.

Examples:

```text
reconcile/glances-bind
reconcile/ddns-public-scope
reconcile/backup-scripts
```

### `codex/<task-name>`

Use for short-lived Codex documentation, review, or scoped repository work.

Examples:

```text
codex/alerting-docs
codex/restore-runbooks
codex/service-inventory
```

Avoid long-lived Codex branches. A stale branch accumulates conflicts and may document old production state.

## Standard Codex Task Startup Checklist

Before starting a task:

```bash
git status --short
git fetch origin
git switch main
git pull origin main
git switch -c codex/<task-name>
```

Then:

- [ ] Confirm the working tree is clean or understand every existing change.
- [ ] Read the task scope and prohibited actions.
- [ ] Inspect the relevant files before editing.
- [ ] Check for repository-local instructions.
- [ ] Identify whether the task is docs-only, repo config, lab, or production-sensitive.
- [ ] Separate facts proven by the repo from facts supplied by the human.
- [ ] Summarize the files inspected and planned edits when requested.
- [ ] Ask for clarification only when repository evidence and reasonable assumptions cannot resolve a material risk.

## Standard Codex Task Completion Checklist

- [ ] Confirm only allowed files changed.
- [ ] Review `git diff --name-only`, `git diff --stat`, and `git diff`.
- [ ] Run relevant non-destructive checks permitted by the task.
- [ ] Check for accidental secrets, `.env` files, private keys, and backup archives.
- [ ] Confirm uncertain operational claims say `needs verification`.
- [ ] If scheduling is operational but not documented in Git, say `scheduled operationally; verify on host`.
- [ ] Confirm no unrelated formatting or metadata churn was introduced.
- [ ] Summarize files changed and verification performed.
- [ ] State any checks that could not be performed.
- [ ] Commit and open a PR when requested by the human workflow.

## What Codex May Do

Within task scope, Codex may:

- Make documentation-only edits.
- Inspect repository files.
- Make scoped edits to explicitly allowed files.
- Run local, non-destructive repository commands.
- Use `git status`, `git diff`, `git log`, searches, formatters, and permitted tests.
- Create short-lived `codex/<task-name>` branches.
- Document repository evidence and facts explicitly provided by the human.

## What Codex May Not Do Without Explicit Approval

- Run `sudo`.
- Run Docker commands.
- SSH to production or another system.
- Edit live files under `/srv/docker`.
- Modify `.env` files, secrets, API keys, tokens, private keys, WireGuard keys, Porkbun credentials, or application credentials.
- Delete files or use destructive Git/filesystem commands.
- Make broad refactors outside the requested scope.
- Change public exposure, DNS, firewall, authentication, or production routing without explicit scope and approval.
- Commit backup archives, databases, generated runtime state, or production secrets.

Task instructions may impose stricter limits. The stricter scope wins.

## Handling Stale Branches

Do not continue blindly on an old `codex/*` branch.

1. Check branch age and divergence:

   ```bash
   git status --short
   git branch --show-current
   git fetch origin
   git log --oneline --decorate --graph --all --max-count=20
   ```

2. If the branch has no unique work, create a fresh branch from updated `main`.
3. If it has useful commits, preserve them and rebase, merge, or cherry-pick only after reviewing conflicts.
4. Do not discard user work.
5. Close or delete stale branches only with human approval or after their work is safely merged.

## Handling Production-Derived Changes

Production changes may originate on the OptiPlex because live state exists under `/srv/docker`.

Preferred flow:

1. Inspect production and define the intended change.
2. Create `reconcile/<task-name>` from current `main`.
3. Reconcile approved production changes into repository files without copying secrets.
4. Validate the repository diff.
5. Commit, review, and merge into `main`.
6. Sync codex-lab from `main`.
7. Start Codex documentation/review work from a new `codex/<task-name>` branch.

Before Codex documents a production change, the repository representation should normally be committed and merged into `main`. If the human provides an operational fact that is not yet represented in Git, Codex may document it only when explicitly requested and should clearly identify its evidence source.

Examples of careful wording:

- `Configured in repo` when a file proves the configuration.
- `Confirmed by the human operator` when explicitly supplied.
- `Scheduled operationally; verify on host` when scheduling is outside Git.
- `Needs verification` when neither repository evidence nor explicit human confirmation exists.

## Evidence Requirements Before Accepting Completion

A task is complete only when the evidence matches the claim.

- File presence: show the expected path exists.
- Documentation edits: review the rendered structure or source and run `git diff --check`.
- Repository configuration: cite the relevant compose/config/script lines.
- Tests/checks: report the command and outcome.
- Production status: require explicit runtime evidence or human confirmation.
- Scheduling: require repository documentation or mark it operational and subject to host verification.
- Public exposure: require DNS/routing evidence or explicit human confirmation.
- Restore coverage: require the matching backup script/runbook file to exist.

Codex completion summaries should include:

- Files changed.
- Behavior or documentation updated.
- Verification performed.
- Remaining risks, uncertainty, or checks not run.
