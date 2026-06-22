# Active Media Quality Profile Decision Memo

Decision memo date: 2026-06-22

## Executive summary

This memo converts the repository review into owner decisions for the two active profiles only:

- Sonarr: `TV - Main 1080p`, assigned to all 39 exported series.
- Radarr: `Movies - Main 1080p`, assigned to all 180 exported movies.

The current policy is conservative about sources and playback compatibility. TV is restricted to 1080p WEB releases. Movies allow Bluray-720p as a fallback and WEB/Bluray 1080p as preferred sources. Both profiles reject x265 HD and AV1, and both remain eligible for custom-format upgrades until score 10000.

The lowest-risk decision is to keep the current source, codec, language, and edition policies until the owner documents playback-client capabilities, availability problems, desired editions/languages, and acceptable replacement-download activity. The 10000 upgrade-until score and quality-definition limits deserve measurement and UI verification before any later configuration proposal. This is not a recommendation to apply or sync changes.

No media quality policy is universally correct. Wider source/codec acceptance improves availability and can reduce storage use, while narrower acceptance improves consistency and compatibility. More aggressive upgrades improve preference matching at the cost of bandwidth, disk writes, and repeated downloads.

## Evidence used

- `docs/media-quality-profile-review.md`
- `compose/arr/recyclarr/configs/sonarr.yml`
- `compose/arr/recyclarr/configs/radarr.yml`
- `compose/arr/recyclarr/settings.yml`
- `inventory/media-profiles/sonarr-quality-profiles.json`
- `inventory/media-profiles/sonarr-quality-definitions.json`
- `inventory/media-profiles/sonarr-custom-formats.json`
- `inventory/media-profiles/sonarr-series.json`
- `inventory/media-profiles/radarr-quality-profiles.json`
- `inventory/media-profiles/radarr-quality-definitions.json`
- `inventory/media-profiles/radarr-custom-formats.json`
- `inventory/media-profiles/radarr-movies.json`

The JSON files are point-in-time exports, not independently verified live state. No API or Recyclarr command was run. The repository shows guide-style profile/template references, but any claim about current external guide intent or recommended values **needs external reference verification**. Sensitive connection fields are referenced indirectly and no secret values are included here.

## Active profile baseline

| Setting | Sonarr: `TV - Main 1080p` | Radarr: `Movies - Main 1080p` |
|---|---|---|
| Exported profile ID | 8 | 9 |
| Assignment count | 39 of 39 exported series | 180 of 180 exported movies |
| Upgrades enabled | Yes | Yes |
| Allowed qualities | `WEB 1080p` group: WEBDL-1080p and WEBRip-1080p | Bluray-720p; `WEB 1080p` group; Bluray-1080p |
| Quality cutoff | `WEB 1080p` group | Bluray-1080p |
| Minimum CF score | 0 | 0 |
| Minimum upgrade CF score | 1 | 1 |
| Upgrade-until CF score | 10000 | 10000 |
| Major positive scores | WEB Tier 01/02/03: 1700/1650/1600; WEB Scene: 1600; providers and streaming boosts: 75; repacks: 5/6/7 | HD Bluray Tier 01/02/03: 1800/1750/1700; WEB Tier 01/02/03: 1700/1650/1600; BCORE/CRiT/MA: 15/20/20; repacks: 5/6/7 |
| Major rejection scores | `-10000`: x265 HD, AV1, non-original language, bad dual groups, BR-DISK, extras, LQ, release-title LQ, upscaled | `-10000`: x265 HD, AV1, 3D, bad dual groups, black-and-white editions, BR-DISK, extras, generated dynamic HDR, line/mic dubbed, LQ, release-title LQ, sing-along, upscaled |

The configured Recyclarr profile names match these exported active profiles. This baseline describes current repository evidence; it does not authorize a config change.

## Decision 1: TV source strategy

### Current behavior

`TV - Main 1080p` allows only the grouped WEBDL-1080p and WEBRip-1080p qualities. Bluray, HDTV, 720p, Remux, and 2160p are not allowed. The cutoff is the WEB 1080p group.

### Benefits

- Produces a consistent 1080p WEB-oriented library.
- Avoids larger Bluray/Remux sources and lower-resolution fallback downloads.
- Reduces source-type upgrades and likely limits storage growth.
- Matches the profile name and all 39 exported series assignments.

### Downsides

- A series or episode with no acceptable 1080p WEB release can remain missing.
- Bluray releases cannot fill gaps or provide a potentially higher-quality source.
- No 720p fallback is available for rare, old, or poorly distributed content.

### Low-risk option

Keep strict WEB-only 1080p. Handle any observed missing episodes as evidence for a later exception policy rather than widening the profile preemptively.

### Higher-change option

Allow Bluray-1080p, or allow 720p WEB/Bluray as fallback. Bluray broadens high-quality availability but may increase file size and source upgrades. A 720p fallback improves availability but can create later 720p-to-1080p replacement downloads.

### Recommended owner decision

Choose **keep strict WEB-only 1080p** unless missing-episode history shows a recurring source-availability problem. If broadening is needed, decide separately whether the problem calls for Bluray-1080p, 720p fallback, or both; these have different storage and upgrade effects.

### Evidence needed before changing config

- Count and age of monitored episodes missing because no 1080p WEB candidate was accepted.
- Examples of rejected Bluray/720p candidates that would have filled real gaps.
- Typical TV file-size budget and tolerance for replacement downloads.
- Playback/storage constraints and whether source consistency matters to the owner.

## Decision 2: Movie source strategy

### Current behavior

`Movies - Main 1080p` allows Bluray-720p as a fallback, grouped WEBDL/WEBRip-1080p, and Bluray-1080p. Its cutoff is Bluray-1080p. It does not allow 1080p Remux or any 2160p quality.

### Benefits

- The 720p fallback improves availability for movies lacking acceptable 1080p releases.
- WEB and Bluray 1080p support balances availability and quality.
- Excluding Remux and 2160p limits file-size growth.
- All 180 exported movies use this single, consistent policy.

### Downsides

- A 720p fallback can later be replaced by 1080p, increasing download activity.
- Bluray-720p may be undesirable if the owner wants a firm 1080p floor.
- Excluding 1080p Remux prevents the highest-bitrate disc-derived option for selected movies.

### Low-risk option

Keep the current 720p fallback plus WEB/Bluray 1080p. This preserves current availability and storage behavior.

### Higher-change option

Remove Bluray-720p to enforce a 1080p floor, or add 1080p Remux for higher-bitrate disc sources. Removing fallback may leave older/niche movies missing. Adding Remux can substantially increase storage, network use, and later upgrades.

### Recommended owner decision

Choose **keep the current source set** until the owner reviews how many files are actually Bluray-720p and whether those are temporary successes or unwanted outcomes. Consider 1080p Remux only if the owner explicitly prefers larger high-bitrate files and has a storage budget for them.

2160p/4K should be evaluated as a separate future profile with explicit client, HDR, storage, and library-assignment decisions. It is not part of this memo's active-profile decision.

### Evidence needed before changing config

- Count of current Bluray-720p movie files and availability of acceptable 1080p replacements.
- Missing-movie/rejection examples where the fallback was useful.
- Estimated storage impact of representative 1080p Remux files.
- Direct-play/transcoding capability across movie playback clients.
- Owner preference for uniform resolution versus maximum availability.

## Decision 3: Codec policy

### Current behavior

Both active profiles assign `-10000` to `x265 (HD)` and `AV1`. With minimum CF score 0, these matches are intended to reject affected releases unless other scores unexpectedly offset the penalty.

### Benefits

- Favors broadly compatible codecs and reduces the chance of client-side decode or direct-play failures.
- Can reduce server transcoding demand where clients do not support HEVC/x265 or AV1.
- Keeps current behavior predictable across the whole active library.

### Downsides

- Excludes storage-efficient encodes that may provide similar perceived quality at smaller sizes.
- AV1 support is improving across newer clients, so a blanket rejection may be more restrictive than necessary.
- x265 HD and AV1 rejection can reduce release availability for some content.

### Low-risk option

Continue rejecting both codecs until every important playback path has been tested and transcoding expectations are documented.

### Higher-change option

Allow x265 HD first, because client support may be broader in the owner's environment, or allow AV1 if all required clients can decode it. These are separate decisions; allowing one does not require allowing the other.

### Recommended owner decision

Choose **continue rejecting x265 HD and AV1 for now**, unless a client capability inventory and sample playback tests demonstrate acceptable direct play or intentional transcoding. If relaxing policy, evaluate x265 and AV1 independently.

### Evidence needed before changing config

- Codec support for every required TV, streaming device, browser, and mobile client.
- Sample direct-play and subtitle-enabled playback results for x265 and AV1.
- Server transcoding capacity and whether remote playback is common.
- Measured size savings from representative releases.
- Any current missing-download cases attributable specifically to codec rejection.

## Decision 4: Language policy

### Current behavior

The active TV profile assigns `-10000` to `Language: Not Original`. The active movie profile does not contain an equivalent exported non-original-language rejection, although it rejects `Line/Mic Dubbed` at `-10000`.

### Benefits

- TV releases are more likely to preserve the work's original spoken language.
- Avoids unwanted dubs and ambiguity where release naming does not clearly describe audio tracks.
- Provides consistent automatic behavior across all 39 exported series.

### Downsides

- Can reject wanted dubs, multilingual releases, or content where the household prefers another language.
- A global rule may not fit children's content, language-learning libraries, accessibility needs, or specific series.
- Release metadata can be imperfect, so matching behavior should be checked with real rejected examples.

### Low-risk option

Continue rejecting non-original-language TV releases globally, with no change to the active profile.

### Higher-change option

Relax the rule only for clearly defined use cases, such as named series, a separate library policy, or a documented household language requirement. A global relaxation is broader than necessary when exceptions are limited.

### Recommended owner decision

Choose **keep original-language TV as the default**, and document any specific series or audience that requires dubbed or multilingual releases before considering a scoped exception.

### Evidence needed before changing config

- Household language and subtitle preferences.
- Specific series currently missing because of this rejection.
- Examples showing how multilingual and dubbed releases match the current CF.
- Whether exceptions can be isolated without changing behavior for all 39 series; implementation options **need external reference verification**.

## Decision 5: Edition policy

### Current behavior

The active movie profile rejects 3D, black-and-white editions, generated dynamic HDR, sing-along versions, and other unwanted technical/release variants at `-10000`. It scores `Remaster`, `Criterion Collection`, `Masters of Cinema`, `Vinegar Syndrome`, `Theatrical Cut`, `Special Edition`, `IMAX`, and `IMAX Enhanced` at 0, so those edition CFs do not influence ranking in the exported active profile.

### Benefits

- Strong rejection of clearly unwanted variants reduces surprise replacements.
- Neutral edition scores avoid automatically preferring a specialty edition over a conventional release.
- Current policy prioritizes predictable playback and conventional versions.

### Downsides

- Blanket rejection may exclude an edition the owner actually wants for a particular title.
- Neutral IMAX, Special Edition, or curated-label formats do not express positive owner preferences.
- Edition names and content differences are title-specific; a global preference can select an unintended cut.

### Low-risk option

Continue rejecting the current unwanted editions and leave IMAX, Special Edition, remaster, curated-label, and theatrical formats neutral.

### Higher-change option

Explicitly prefer selected editions, keep them neutral, or intentionally ignore/remove their selection effect. Positive global scores may trigger replacements and may favor an edition that is not universally preferable. Any distinction between neutral and ignored behavior in a future Recyclarr configuration **needs external reference verification**.

### Recommended owner decision

Choose **retain current rejections and keep the other edition formats neutral** unless the owner can name editions that should be preferred across most movies. Handle title-specific edition wishes separately rather than assuming a universal hierarchy.

### Evidence needed before changing config

- Owner preference for theatrical versus extended/special cuts.
- Specific titles where IMAX, remaster, or curated-label releases are desired.
- Whether edition-driven replacements are acceptable.
- Verification of how each CF identifies releases and how a selected template expects to score it; this **needs external reference verification**.

## Decision 6: Upgrade behavior

### Current behavior

Both active profiles allow upgrades, require only a one-point CF improvement for CF upgrades, have minimum CF score 0, and use an upgrade-until CF score of 10000. The major positive tier scores are roughly 1600-1800, with smaller provider, source, and repack additions.

### Benefits

- A 10000 ceiling can intentionally keep guide-style profiles open to any later release with a better attainable score.
- Incremental upgrades can replace lower-tier groups or less-preferred sources with better matches.
- The same rule is consistently applied across all active assignments.

### Downsides

- The threshold appears much higher than ordinarily attainable combinations in these exports, so CF upgrades may effectively remain open indefinitely.
- A one-point minimum improvement permits small changes, such as repack score differences, to trigger replacement activity.
- Repeated downloads increase bandwidth, disk writes, import activity, and temporary storage requirements.

### Low-risk option

Keep 10000 until actual replacement activity is measured. This preserves current guide-style behavior and avoids choosing an unsupported target score.

### Higher-change option

Lower the upgrade-until score to a practical, owner-selected stopping point. A lower value can reduce churn but may stop before a later preferred tier/provider/repack is available. Selecting a specific value requires analysis of mutually exclusive and combinable CF matches; any claim about an upstream recommended value **needs external reference verification**.

### Recommended owner decision

Choose **keep 10000 temporarily and measure upgrades**, then decide whether replacement frequency is acceptable. If churn is excessive, define a stopping objective in plain language before choosing a numeric score—for example, stop after a top release tier, with or without a preferred provider/repack.

### Evidence needed before changing config

- Recent upgrade-history counts per series/movie and the score difference for each replacement.
- Bandwidth, disk-write, and temporary-space impact of those upgrades.
- Which positive CF combinations are realistically attainable and mutually exclusive.
- Owner tolerance for quality improvements versus replacement frequency.
- Current guide/template score semantics **need external reference verification**.

## Decision 7: Quality definition/file size policy

### Current behavior

Recyclarr selects `series` quality definitions for Sonarr and `movie` definitions for Radarr. The exports do not state units. Sonarr's HD/UHD entries generally omit `maxSize` and show `preferredSize: 995`; its SD entries typically prefer 95 and cap at 100. Radarr's normal SD/UHD entries generally show `minSize` without exported `maxSize` or `preferredSize`, while early/pre-release qualities cap at 100 and prefer 95.

For currently allowed qualities, notable minimum values include Sonarr WEBDL/WEBRip-1080p at 15 and Radarr WEBDL/WEBRip-1080p at 12.5, Bluray-1080p at 50.8, and Bluray-720p at 25.7. These numbers should not be converted into file sizes without confirming application-version units and runtime interpretation.

### Benefits

- Minimum-size floors can filter very low-bitrate or mislabeled releases.
- Generous upper limits preserve availability for high-bitrate content.
- Shared definition types can keep policy consistent within each application.

### Downsides

- A minimum that is too high can reject efficient encodes or niche content.
- An absent or extremely high effective maximum can allow unexpectedly large downloads.
- Export-field omissions and values such as 995 are ambiguous without current UI/version semantics.

### Low-risk option

Make no size-policy decision until the owner verifies units, displayed limits, and effective behavior in the Sonarr/Radarr UI.

### Higher-change option

After verification, set owner-specific minimum, preferred, and maximum targets based on runtime and storage budgets. This can control outliers but risks missed downloads if limits are too narrow.

### Recommended owner decision

Choose **verify in the UI before changing anything**. Record the installed-version units and effective minimum/preferred/maximum values for the qualities allowed by the two active profiles. Do not infer a correct limit from the raw JSON alone.

### Evidence needed before changing config

- UI screenshots or sanitized notes showing units and effective limits.
- Installed Sonarr/Radarr version semantics; this **needs external reference verification** if repository evidence is insufficient.
- File-size distribution by runtime and quality for current TV episodes and movies.
- Available storage, growth target, bandwidth limits, and acceptable outlier size.
- Examples of releases rejected as too small or accepted despite being unexpectedly large.

## Out of scope

- The unassigned Radarr `[Anime] Remux-1080p` profile has zero exported movie assignments and is not referenced by the active Radarr config. Its apparent minimum-score problem is acknowledged but will not be fixed or otherwise tuned in this memo.
- Cleanup, deletion, renaming, or repair of unused, stock, predecessor, or alternate profiles.
- A 2160p/4K implementation. It may be considered later as a separate profile decision if explicitly requested.
- Changes to Recyclarr YAML, custom-format definitions, quality definitions, assignments, Compose, or service configuration.
- Any Recyclarr sync/apply plan or execution.

## Recommended next steps

1. The owner records one decision for each section: TV sources, movie sources, x265, AV1, TV language, movie editions, upgrade behavior, and size-policy verification.
2. Collect the evidence listed under any section where the owner wants behavior to change, prioritizing missing-download examples, client codec tests, replacement history, and UI-confirmed size semantics.
3. Reassess the owner decisions against fresh sanitized exports if the current exports are no longer representative.
4. If changes are later authorized, prepare a separate documentation-only impact review. Do not derive or execute a sync/apply plan from this memo.

## No changes applied

No Sonarr, Radarr, Recyclarr, YAML, Compose, script, environment, export, runbook, or service configuration was changed. No Docker command, API call, `sudo`, or SSH was used. This memo is the only file created. No Recyclarr sync/apply was run or proposed.
