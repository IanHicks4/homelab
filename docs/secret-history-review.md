# Secret and Git History Review

Review date: 2026-08-21  
Checked-out branch: `codex/repo-health-review`  
Checked-out commit: `9ccead0`

## 1. Executive summary

Two substantive findings were identified in the reachable repository history:

1. A sensitive Immich background-image URL is still present in the checked-out `HEAD` and in older history. A remediation commit exists on `main`/`origin/main`, but it is not contained in the checked-out review branch.
2. A WireGuard private key was committed historically. It is no longer present as a literal in the checked-out `HEAD`; the active key has been rotated, so this exposure is treated as mitigated.

No other apparent real credential was identified by the repository-wide pattern review. In particular, no committed non-example `.env` file, PEM/OpenSSH private-key block, common cloud/provider token, JWT, credential-bearing database URL, HTTP basic-auth URL, or SSH key material was found in the reachable refs reviewed.

The immediate action is to revoke or regenerate the affected Immich share/background link and bring the existing environment-variable remediation into this branch before it is merged or used as a base. Git history rewriting is not recommended at this time because the WireGuard credential has been rotated and the Immich URL can be invalidated.

## 2. Review method

The review was repository-only and did not inspect live hosts, containers, `/srv/docker`, external services, or APIs.

The following evidence was reviewed:

- Working-tree and branch state with `git status` and ref/commit metadata.
- Reachable commit history using `git log --all` and `git rev-list --all`.
- Tracked filenames in current `HEAD` and history, with special attention to `.env`, key, secret, and credential filenames.
- Current and historical blobs using filename-only or redacted searches for passwords, API keys, tokens, bearer credentials, JWTs, private-key markers, WireGuard keys, credential-bearing URLs, and sensitive URL query parameters.
- Relevant commit metadata and file-change lists without reproducing suspected values.
- Current `.gitignore`, example environment files, Compose references, Homepage configuration, runbooks, scripts, docs, inventory, and sanitized media-profile exports insofar as they matched secret-related patterns.

Searches were deliberately value-suppressing. Sensitive URL query strings and credential values are not included here. The scope was all commits reachable from locally visible refs; this is a pattern-based review, not a guarantee about unreachable/pruned Git objects or copies held outside this repository.

## 3. Current HEAD findings

### Finding CH-1: Immich background URL remains in checked-out HEAD

- **Path:** `configs/homepage/settings.yaml`
- **Commit:** `9ccead0` (checked-out `HEAD`)
- **Concern type:** Immich URL containing a token-like query parameter
- **Location:** Current `HEAD` and history
- **Redacted form:** `https://immich.kai.coach/[REDACTED]?[REDACTED]`
- **Severity:** Medium
- **Recommended action:** Revoke or regenerate the referenced Immich share/link, then update this branch to contain the already-created environment-variable placeholder remediation. Keep the replacement value only in the local ignored Homepage environment file.

The checked-out branch does not contain remediation commit `abaf0b4`. The locally visible `main` and `origin/main` refs do contain that commit and point at `3e40aa7`, where the setting is represented by a Homepage environment-variable placeholder. This is a branch divergence issue, not evidence that the remediation commit failed.

### Other current-state observations

- No tracked file named exactly `.env` was found in `HEAD`; tracked environment files use the `.env.example` suffix.
- Current Compose secret references use environment placeholders or mounted secret files in the reviewed matches.
- `compose/vpn/compose.yaml` uses an environment-variable reference for the WireGuard key in current `HEAD`; the historical literal is not present there now.
- Example values such as `REPLACE_ME`, empty assignments, and the commented sample in `configs/homepage/proxmox.yaml` appear intentionally non-secret.

## 4. Git history findings

### Finding GH-1: Historical WireGuard private key

- **Path:** `compose/vpn/compose.yaml`
- **Introduced by:** `987f93e`
- **Removed by:** `6683940`
- **Concern type:** Historical WireGuard private key credential
- **Location:** History-only
- **Severity:** High at time of exposure; mitigated after rotation
- **Recommended action:** No further action unless the repository becomes public or the key appears in current `HEAD`.

The active key has been rotated, and the current file uses an environment placeholder. No key value is reproduced in this report.

### Finding GH-2: Historical Immich token-like URL

- **Path:** `configs/homepage/settings.yaml`
- **First sensitive version found:** `47c8b46`
- **Later sensitive change found:** `053e5ce`
- **Sanitizing commit:** `abaf0b4`
- **Concern type:** Immich background/share URL with a token-like query parameter
- **Location:** History and checked-out `HEAD`; sanitized on `main`/`origin/main`
- **Severity:** Medium
- **Recommended action:** Revoke or regenerate the affected Immich link, retain the URL only in an ignored local environment file, and ensure active development branches contain `abaf0b4` or an equivalent reviewed change.

The URL was present in reachable snapshots after its initial addition and was changed again in a later sync commit. The report therefore treats any prior form of that link as exposed.

### Negative history findings

Across reachable refs, the review did not find:

- A committed non-example `.env` file.
- PEM, RSA, EC, DSA, or OpenSSH private-key blocks.
- Common AWS, GitHub, Slack, Google, or OpenAI token formats.
- JWT-shaped bearer credentials.
- Credential-bearing HTTP basic-auth, PostgreSQL, MySQL, or MongoDB URLs.
- SSH public-key material.
- Additional literal secret assignments that survived placeholder and example-value classification.

## 5. Files/paths of concern

| Path | Commit(s) | Concern type | State | Severity |
|---|---|---|---|---|
| `configs/homepage/settings.yaml` | `47c8b46`, `053e5ce`, current `9ccead0`; sanitized by `abaf0b4` | Sensitive Immich URL with token-like query parameter | Current on review branch and historical; sanitized on `main` | Medium |
| `compose/vpn/compose.yaml` | Introduced `987f93e`; removed `6683940` | Historical WireGuard private key credential | History-only | High at exposure; mitigated |

No other path met the threshold for a secret finding. Files containing secret-related words but only placeholders, example values, secret-file paths, instructions, or exported application metadata were not classified as exposures.

## 6. Severity and recommended action

| Finding | Why it matters | Recommended action | Priority |
|---|---|---|---|
| CH-1 / GH-2 | Anyone able to read the URL may be able to retrieve or reference the associated Immich asset, depending on Immich link semantics and current server state. | Revoke/regenerate the link; keep its replacement in the ignored local environment file; bring the sanitation commit into the review branch. | Now |
| GH-1 | A WireGuard private key can authenticate a peer and must be assumed compromised once committed. | Rotation is already complete. Confirm operational records identify the old peer/key as revoked; otherwise take no further action. | Completed/verify |

## 7. Values that should be rotated/revoked

- **Immich share/background link:** Revoke or regenerate the link associated with the URL in `configs/homepage/settings.yaml`. Do this even if the asset is low sensitivity, because the query parameter was committed and remains readable in history.
- **WireGuard private key:** Already rotated according to the supplied remediation context. No second rotation is indicated by repository evidence unless the replacement key is later found in Git or another exposed location.

No evidence was found that the placeholder-backed Homepage API keys, Vaultwarden admin token, DDNS credentials, Grafana password, Vikunja database password, Recyclarr API keys, or current WireGuard key were committed as real values.

## 8. Items that appear sanitized now

- `main` and `origin/main` contain commit `abaf0b4`, which replaces the Immich background URL with a Homepage environment-variable placeholder.
- `compose/vpn/compose.yaml` uses an environment-variable reference in current `HEAD`, following removal commit `6683940`.
- Secret-bearing environment files are represented by `.env.example` files with blank or explicit replacement values.
- `compose/arr/recyclarr/secrets.yml.example` contains replacement markers, while the real `secrets.yml` path is ignored.
- Authelia Compose configuration references mounted secret files rather than embedding secret values.
- `.gitignore` excludes `.env` variants, Recyclarr secrets, common databases/logs/runtime data, and named backup locations.

The Immich item is sanitized on `main`, but not on the currently checked-out branch. That distinction should be resolved before treating the whole local checkout as clean.

## 9. Whether history rewrite is recommended

History rewrite is **not recommended at this time**.

- The historical WireGuard credential was rotated, making revocation/rotation the effective remediation.
- The Immich URL should be revoked or regenerated; after invalidation, retaining the redacted historical record poses substantially less operational risk.
- Rewriting shared history would disrupt branches and clones and would not remove existing external copies.

Reconsider a coordinated rewrite only if the repository is to become public, the Immich link cannot be invalidated, the historical WireGuard key is discovered to remain active, or a future review finds a non-rotatable/highly sensitive secret. Even then, rotation or revocation remains necessary because history rewriting cannot recall existing clones.

## 10. Follow-up remediation tasks

1. Revoke or regenerate the affected Immich link without recording the replacement value in Git.
2. Store the replacement Homepage background URL in the ignored local environment file referenced by the Homepage stack.
3. Rebase or merge the review branch onto current `main`, or otherwise apply the reviewed placeholder change, so `configs/homepage/settings.yaml` is sanitized in this branch before further use.
4. Confirm the old WireGuard peer/key is revoked in operational records; do not record the key itself.
5. Add a secret-scanning check to the review workflow that reports filenames and rule identifiers while masking matched values. Include URL query parameters such as `token`, `key`, `signature`, `expires`, `auth`, `access`, `shared`, and similar names.
6. Extend `scripts/check_secrets.sh` in a separate reviewed task to scan tracked history or run a dedicated secret scanner in CI. Test it against synthetic fixtures, not real credentials.
7. Add a PR-review item requiring confirmation that branches are based on current `main` before declaring a remediated path clean.
8. Repeat a redacted scan before any change in repository visibility. Do not make the repository public until current branches and exposed links have been reviewed.
