# Media Quality Profile Review

Review date: 2026-06-22

## Executive summary

The repository contains sanitized Recyclarr configuration and recent Sonarr/Radarr exports (committed 2026-06-21). This is enough evidence for a bounded comparison of intended Recyclarr targets with exported application state. The configured Sonarr profile `TV - Main 1080p` exists as exported profile ID 8, and the configured Radarr profile `Movies - Main 1080p` exists as exported profile ID 9. Supporting Recyclarr state mappings agree with those identities, but are not treated as authoritative or as proof of a recent successful sync.

All 39 exported Sonarr series use `TV - Main 1080p`, and all 180 exported Radarr movies use `Movies - Main 1080p`. The stock, simple, predecessor-looking, and anime profiles therefore have zero assignments in these point-in-time exports. This reduces their immediate operational risk but does not prove they remain unused in current runtime state.

Radarr's unassigned `[Anime] Remux-1080p` profile still contains a likely functional defect: it requires a minimum custom-format score of 100, while its only non-zero score is `AV1 = -10000`. It appears unable to accept a release if assigned. The Radarr state mapping records this profile as previously mapped, while the current sanitized config no longer references it; that supports, but does not prove, a stale or retired-profile explanation.

The active purpose-built profiles are internally coherent 1080p strategies. Their upgrade-until custom-format score of 10000 may intentionally keep accepting incremental preference improvements, but can increase replacement downloads. No single quality strategy is assumed here: broad profiles improve availability, narrow profiles improve consistency, and aggressive upgrades improve preference matching at the cost of bandwidth, storage churn, and download activity.

## Files inspected

- `compose/arr/compose.yaml`
- `compose/arr/recyclarr/configs/sonarr.yml`
- `compose/arr/recyclarr/configs/radarr.yml`
- `compose/arr/recyclarr/settings.yml`
- `compose/arr/recyclarr/secrets.yml.example` (placeholder names only)
- `compose/arr/recyclarr/state/sonarr/1153ded073204a37/custom-format-mappings.json`
- `compose/arr/recyclarr/state/sonarr/1153ded073204a37/quality-profile-mappings.json`
- `compose/arr/recyclarr/state/radarr/d1cc094bdf78f1bf/custom-format-mappings.json`
- `compose/arr/recyclarr/state/radarr/d1cc094bdf78f1bf/quality-profile-mappings.json`
- `inventory/media-profiles/sonarr-quality-profiles.json`
- `inventory/media-profiles/sonarr-quality-definitions.json`
- `inventory/media-profiles/sonarr-custom-formats.json`
- `inventory/media-profiles/radarr-quality-profiles.json`
- `inventory/media-profiles/radarr-quality-definitions.json`
- `inventory/media-profiles/radarr-custom-formats.json`
- `inventory/media-profiles/sonarr-series.json`
- `inventory/media-profiles/radarr-movies.json`

Expected files missing: none from the requested inspection set.

The configs reference sensitive connection fields indirectly, and the example secrets file contains placeholders only. No secret value is reproduced here.

Evidence boundary: the JSON files are treated as point-in-time application exports. State mapping JSON is used only to corroborate stored name/ID relationships; it does not prove current ownership, completeness, or a successful sync. No API or sync call was made, so the report does not independently prove that repository evidence matches current runtime state.

## Sonarr profile summary

| Profile | Exported series | Upgrades | Allowed quality scope | Quality cutoff | CF score limits | Apparent intent |
|---|---:|---:|---|---|---|---|
| `Any` | 0 | No | SD through 1080p, excluding 1080p Remux and all 2160p | SDTV | Min 0; cutoff 0; all CFs score 0 | Broad legacy/default catch-all; accepts many qualities but never upgrades |
| `SD` | 0 | No | SDTV, 480p WEB/DVD/Bluray, Bluray-576p | SDTV | Min 0; cutoff 0; all CFs score 0 | SD-only, availability-oriented profile |
| `HD-720p` | 0 | No | HDTV/WEB/Bluray 720p | HDTV-720p | Min 0; cutoff 0; all CFs score 0 | Fixed 720p profile |
| `HD-1080p` | 0 | No | HDTV/WEB/Bluray 1080p | HDTV-1080p | Min 0; cutoff 0; all CFs score 0 | Fixed 1080p profile without Remux |
| `Ultra-HD` | 0 | No | HDTV/WEB/Bluray 2160p | HDTV-2160p | Min 0; cutoff 0; all CFs score 0 | Fixed 2160p profile without Remux |
| `WEB-DL (1080p/720p)` | 0 | Yes | HDTV, WEB, and Bluray at 720p/1080p | WEB 1080p group | Min 0; upgrade-until 10000; 33 non-zero CFs | Broad HD profile preferring WEB groups/providers while allowing 720p fallback; appears older or alternate |
| `Main` | 0 | Yes | HDTV, WEBRip, Bluray, and WEBDL 1080p | WEBDL-1080p | Min 0; upgrade-until 0; all CFs score 0 | Simple 1080p profile with quality upgrades but no CF preferences |
| `TV - Main 1080p` | 39 | Yes | WEB 1080p only | WEB 1080p group | Min 0; upgrade-until 10000; all 37 CFs non-zero | Recyclarr-targeted WEB-only 1080p profile with group/provider preferences and rejection rules |

`TV - Main 1080p` scores WEB tiers at 1600-1700, providers/streaming boosts at 75, and repacks at 5-7. It assigns `-10000` to x265 HD, non-original language, AV1, bad dual groups, BR-DISK, extras, LQ, release-title LQ, and upscaled releases. Those are policy decisions rather than universally correct choices; for example, rejecting x265/AV1 favors compatibility but may use more storage, while rejecting non-original language may exclude acceptable dubbed or alternate-language releases.

## Radarr profile summary

| Profile | Exported movies | Upgrades | Allowed quality scope | Quality cutoff | CF score limits | Apparent intent |
|---|---:|---:|---|---|---|---|
| `Any` | 0 | No | Almost every listed quality from pre-release sources through 2160p and BR-DISK (Raw-HD excluded) | Bluray-480p | Min 0; cutoff 0; all CFs score 0 | Very broad legacy/default catch-all; availability over quality consistency |
| `SD` | 0 | No | WORKPRINT/CAM/TELESYNC/TELECINE/REGIONAL/DVDSCR and normal SD qualities | Bluray-480p | Min 0; cutoff 0; all CFs score 0 | Broad SD profile, including low-quality pre-release sources |
| `HD-720p` | 0 | No | HDTV/WEB/Bluray 720p | Bluray-720p | Min 0; cutoff 0; all CFs score 0 | Fixed 720p profile |
| `HD-1080p` | 0 | No | HDTV/WEB/Bluray/Remux 1080p | Bluray-1080p | Min 0; cutoff 0; all CFs score 0 | Fixed 1080p profile; Remux is allowed but upgrades are disabled |
| `Ultra-HD` | 0 | No | HDTV/WEB/Bluray/Remux 2160p | Remux-2160p | Min 0; cutoff 0; all CFs score 0 | Fixed UHD profile; accepts any allowed first download and does not upgrade |
| `HD Blueray + Web` | 0 | Yes | Bluray-720p plus WEB/Bluray 1080p | Bluray-1080p | Min 0; upgrade-until 10000; 27 non-zero CFs | HD fallback profile favoring high-tier WEB/Bluray groups and editions; name contains `Blueray` typo |
| `Main` | 0 | Yes | HDTV, WEBRip, Bluray, and WEBDL 1080p | WEBDL-1080p | Min 0; upgrade-until 0; all CFs score 0 | Simple 1080p profile with quality upgrades but no CF preferences |
| `[Anime] Remux-1080p` | **0** | Yes | SD through grouped Remux 1080p, excluding HDTV-720p/1080p and standalone Bluray-1080p | Remux 1080p group | **Min 100**; upgrade-until 10000; only AV1 is non-zero at -10000 | Likely broken if assigned, but unused in the assignment export |
| `Movies - Main 1080p` | 180 | Yes | Bluray-720p plus WEB/Bluray 1080p; no 1080p Remux | Bluray-1080p | Min 0; upgrade-until 10000; 25 non-zero CFs | Recyclarr-targeted 1080p movie profile with tier preferences and rejection rules |

`Movies - Main 1080p` scores HD Bluray/WEB tiers at 1600-1800, repacks at 5-7, and selected source attributes at 15-20. It rejects x265 HD, 3D, AV1, bad dual groups, black-and-white editions, BR-DISK, extras, generated dynamic HDR, line/mic dubs, LQ, sing-along, and upscaled releases at `-10000`. This is a compatibility- and conventional-edition-oriented policy, not a universal optimum.

## Recyclarr configuration summary

- Compose declares `ghcr.io/recyclarr/recyclarr:8`, runs it as UID/GID 1000, and bind-mounts `./recyclarr` to `/config`.
- Sonarr instance `series` references secret-backed connection fields, selects quality-definition type `series`, and targets one named profile: `TV - Main 1080p` using template ID `72dae194fc92bf828f32cde7744e51a1`. It enables unmatched-score reset, old-CF deletion, and replacement of existing CF definitions.
- Radarr instance `movies` references secret-backed connection fields, selects quality-definition type `movie`, and targets one named profile: `Movies - Main 1080p` using template ID `d1d67249d3890e49bc12e275d989a7e9`. It enables the same reset/delete/replace behavior.
- Both configured profile names match the exports exactly. Sonarr profile ID 8 has 39 exported series assignments; Radarr profile ID 9 has 180 exported movie assignments.
- Sonarr state maps the configured profile/template pair to exported service ID 8. Its 37 CF mappings match all 37 exported Sonarr CF names and service IDs.
- Radarr state maps the configured movie profile/template pair to exported service ID 9. It also retains a mapping for `[Anime] Remux-1080p` at service ID 8 even though that profile is not referenced by the current config.
- Radarr state contains 40 CF mappings, all of which appear in the 48-CF app export. The eight export-only CFs are `Remaster`, `Criterion Collection`, `Masters of Cinema`, `Vinegar Syndrome`, `Theatrical Cut`, `Special Edition`, `IMAX`, and `IMAX Enhanced`.
- The state files support name/ID continuity but cannot establish whether the current config has been synced since it changed. In particular, the extra anime mapping and eight app-only Radarr CFs may be historical remnants, evidence of config/export timing differences, or intentionally retained state.
- Because `delete_old_custom_formats` and `replace_existing_custom_formats` are enabled, a future sync could delete or replace CFs. This report does not infer the exact effect and does not propose or run a sync/apply plan.
- `secrets.yml.example` contains placeholder key names only. Real connection data is referenced through sensitive fields and is not included in this report.

## Custom formats present

Sonarr contains 37 custom formats:

- Rejections/technical: `BR-DISK`, `LQ`, `LQ (Release Title)`, `x265 (HD)`, `Extras`, `AV1`, `Bad Dual Groups`, `Upscaled`, `Language: Not Original`.
- Repacks: `Repack/Proper`, `Repack2`, `Repack3`.
- Services/sources: `AMZN`, `ATV`, `ATVP`, `CC`, `DCU`, `DSNP`, `HMAX`, `HBO`, `HULU`, `iT`, `MAX`, `NF`, `PMTP`, `PCOK`, `PLAY`, `ROKU`, `SHO`, `STAN`, `SYFY`.
- Tiers/boosts: `HD Streaming Boost`, `UHD Streaming Boost`, `WEB Tier 01`, `WEB Tier 02`, `WEB Tier 03`, `WEB Scene`.

Every Sonarr custom format has a non-zero score in at least one exported profile. Five stock/simple profiles and `Main` nevertheless score all of them at zero. All 37 exported names have matching entries in the supporting Sonarr state mapping.

Radarr contains 48 custom formats:

- Tiers/repacks: `HD Bluray Tier 01-03`, `WEB Tier 01-03`, `Repack/Proper`, `Repack2`, `Repack3`.
- Rejections/technical: `BR-DISK`, `LQ`, `Generated Dynamic HDR`, `LQ (Release Title)`, `Sing-Along Versions`, `3D`, `x265 (HD)`, `Extras`, `AV1`, `Bad Dual Groups`, `Black and White Editions`, `Upscaled`, `Line/Mic Dubbed`.
- Services/sources: `AMZN`, `ATV`, `ATVP`, `BCORE`, `CRiT`, `DSNP`, `HBO`, `HMAX`, `Hulu`, `iT`, `MAX`, `MA`, `NF`, `PCOK`, `PMTP`, `PLAY`, `ROKU`, `STAN`.
- Editions: `Remaster`, `Criterion Collection`, `Masters of Cinema`, `Vinegar Syndrome`, `Theatrical Cut`, `Special Edition`, `IMAX`, `IMAX Enhanced`.

Radarr formats that have a zero score in every exported profile are `AMZN`, `ATV`, `ATVP`, `DSNP`, `HBO`, `HMAX`, `Hulu`, `iT`, `MAX`, `NF`, `PCOK`, `PMTP`, `PLAY`, `ROKU`, `STAN`, and `Theatrical Cut`. They can still match and appear in history, but they do not affect selection under the exported profiles. The first 15 are present in the Radarr state mapping and therefore appear synced but neutral under the exported profiles. `Theatrical Cut` is one of eight exported CFs absent from the state mapping.

## Findings

### Green / looks consistent

- **Configured profile names match:** Recyclarr targets `TV - Main 1080p` and `Movies - Main 1080p`; exact-name profiles exist at Sonarr ID 8 and Radarr ID 9. Supporting state mappings identify the same service IDs.
- **Assignments align with configured targets:** all 39 exported Sonarr series use profile ID 8, and all 180 exported Radarr movies use profile ID 9. No exported item uses another profile.
- **Sonarr CF mapping is complete by name:** all 37 state-mapped formats exist in the Sonarr export, with no export-only or state-only names.
- **Radarr mapped CFs exist:** all 40 names in the supporting Radarr state mapping exist in the app export; there are no state-only names.
- The purpose-built profile names align with their allowed resolutions: `TV - Main 1080p` allows only WEB 1080p, and `Movies - Main 1080p` allows a 720p fallback plus WEB/Bluray 1080p.
- Their quality cutoffs are within their allowed sets: WEB 1080p for TV and Bluray-1080p for movies.
- Strong negative scores are paired with minimum score 0 in the two main profiles, so a release matching one `-10000` rejection should be excluded unless offset by an unexpectedly large positive combination.
- Positive tier scores are ordered consistently: higher-numbered preference tiers receive slightly lower scores, and repack scores increase from Proper through Repack3.
- Sonarr has no globally zero-scored custom format; every exported Sonarr CF affects at least one profile.
- Standard resolution-specific profile scopes generally match their names.

### Yellow / needs review

- **Point-in-time evidence:** the repository now supports comparison, but no API call or sync was run. If the exports and sanitized config were captured at different times, apparent drift may already have changed.
- **Potential predecessor/legacy profiles are unused in the exports:** Sonarr's `WEB-DL (1080p/720p)` overlaps `TV - Main 1080p`, and Radarr's `HD Blueray + Web` overlaps `Movies - Main 1080p`. All stock/simple/alternate profiles have zero current exported assignments. This supports a legacy interpretation but does not justify deletion without confirming rollback/migration intent and current runtime usage.
- **Upgrade-until CF score 10000:** the purpose-built/guide-like profiles have positive scores typically in the low thousands, and a single release normally cannot match every mutually exclusive tier/provider. A 10000 threshold may intentionally keep CF upgrades open, but can lead to repeated upgrades whenever a better-scoring release appears. Whether that is excessive depends on bandwidth, storage churn, and owner preference. Any claim about the intended upstream value **needs external reference verification**.
- **Radarr globally zero-scored formats:** 15 service/source formats are mapped in Recyclarr state but neutral in every exported profile; `Theatrical Cut` is also globally neutral and absent from state. Neutral formats can be intentional profile/template data or useful for observability, but they do not influence current exported selection. Their intended upstream scoring **needs external reference verification**.
- **Eight Radarr export-only formats:** the eight edition-related formats absent from state are used inconsistently: seven receive a positive score in `HD Blueray + Web` (all except `Theatrical Cut`), while the assigned `Movies - Main 1080p` scores all eight at zero. They may be remnants of the unused predecessor profile, but state files alone cannot prove provenance. With old-CF deletion enabled, future sync impact should be reviewed before execution.
- **Simple profiles ignore CF policy but are unassigned:** `Main` and stock profiles score every CF at zero. They could accept releases rejected by the purpose-built profiles if assigned, but the assignment exports show no current use.
- **Broad Radarr defaults:** `Any` and `SD` allow CAM, TELESYNC, TELECINE, WORKPRINT, and DVDSCR. Because upgrades are disabled, a first accepted low-quality release will not later improve under those profiles. This favors immediate availability and may cause missed upgrades.
- **No-upgrade HD/UHD profiles:** the stock resolution profiles have sensible cutoffs but `upgradeAllowed=false`; therefore the cutoff does not drive later replacement. This is stable and bandwidth-efficient, but may retain a lower-ranked first download.
- **Sonarr definition values look unusually permissive:** most HD/UHD definitions omit `maxSize` and show `preferredSize: 995`; SD definitions prefer 95 and cap at 100. The export alone does not establish application-version semantics, but values near 995 appear unusually high and merit UI verification to ensure large releases are not effectively unconstrained. Interpretation against current Sonarr behavior **needs external reference verification**.
- **Radarr definition values need validation:** normal SD through UHD qualities generally contain `minSize` only, with no exported `maxSize` or `preferredSize`; low pre-release qualities cap at 100/prefer 95. If omission means no upper limit in the installed version, large files may remain eligible. Current field semantics **need external reference verification**.
- **Minimum sizes may be restrictive:** examples include Sonarr Bluray-1080p at 50.4 and Remux-2160p at 187.4, and Radarr Remux-1080p at 102. These may be deliberate quality floors, but can miss efficient encodes or niche releases. Units and recommended ranges **need external reference verification**.
- **Naming quality:** `HD Blueray + Web` likely means `HD Blu-ray + Web`. It is unassigned and not referenced by current Recyclarr config, but a rename/removal could still affect historical processes or manual use.
- **Compatibility tradeoffs:** rejecting x265 HD and AV1 can improve playback compatibility but sacrifices smaller modern encodes. Rejecting non-original language, alternate editions, black-and-white editions, or dubs can prevent unwanted variants but may exclude desired content.

### Red / likely issue

- **Radarr `[Anime] Remux-1080p` is likely broken if assigned:** `minFormatScore=100`, while its only non-zero CF is `AV1=-10000`; all other 47 formats score 0. A non-AV1 candidate scores 0 and fails the minimum, while an AV1 candidate scores -10000. The assignment export confirms zero movies use it, so it is not an active download blocker for the 180 exported movies. Its presence in state but absence from current config suggests historical management, not current intent, although state is only supporting evidence.

The previous red finding that Recyclarr configuration was absent/non-reproducible is resolved: sanitized config, settings, a placeholder secrets example, and supporting state mappings are now present. No other red issue is asserted from the available point-in-time evidence.

## Questions for the human owner

1. Were the sanitized config, state mappings, and application/assignment exports captured from the same config revision and around the same time?
2. Was `[Anime] Remux-1080p` deliberately retired, or is anime support expected to return? If retired, should it remain available as an unassigned fallback?
3. Are `WEB-DL (1080p/720p)` and `HD Blueray + Web` retained for rollback/migration, or are they obsolete alternatives to the configured main profiles?
4. Are the eight Radarr edition formats absent from state intentional local additions, remnants of the unassigned `HD Blueray + Web` profile, or expected template content?
5. Should the assigned main profiles continue upgrading for every incremental CF improvement, or should downloads stop after a practical preference score?
6. Are the 15 state-mapped but globally zero-scored Radarr service/source formats intentionally neutral?
7. Are x265 and AV1 rejected due to known client compatibility limits, or could storage-efficient codecs be acceptable?
8. Are dubbed, non-original-language, alternate edition, IMAX, special-edition, and black-and-white releases wanted for any libraries?
9. Are the permissive/large quality-definition size values intentional for high-bitrate media, and what storage/file-size targets should govern TV and movies?
10. Should unused stock/alternate profiles remain for manual recovery, or is eventual cleanup desired after a separate impact review?

## Recommended next steps

1. Establish capture timestamps/config revisions for the sanitized YAML, state mappings, and exports. If freshness is uncertain, obtain new sanitized exports through an owner-approved process before making recommendations; do not infer runtime state from these files indefinitely.
2. Confirm whether anime and the predecessor-looking profiles are retired, rollback options, or future-use profiles. Do not delete or repair them based only on zero assignments.
3. Review the eight Radarr export-only edition formats and the 16 globally zero-scored formats against owner intent. Because deletion/replacement is enabled, determine expected future-sync treatment before any sync is planned.
4. Confirm desired resolution, source, codec, language, edition, bandwidth, replacement-download, and maximum-size tradeoffs with the owner.
5. Verify installed-version quality-definition units and omission semantics in Sonarr/Radarr. Any comparison with TRaSH Guides or upstream recommended values **needs external reference verification**.
6. After owner decisions and external verification, prepare a separate read-only proposed-change review. Do not apply changes or produce a sync/apply plan yet.

## No changes applied

No Sonarr, Radarr, Recyclarr, Compose, `.env`, script, runbook, backup, or production configuration changes were applied. No Docker commands, API calls, `sudo`, or SSH were used. Only this review document was edited. No Recyclarr sync/apply was run, and no sync/apply plan was generated.
