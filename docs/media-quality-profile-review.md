# Media Quality Profile Review

Review date: 2026-06-22

## Executive summary

The repository contains recent Sonarr and Radarr exports (committed 2026-06-21) covering quality profiles, quality definitions, and custom formats. These exports provide enough evidence to review the exported application state, but not enough to compare it reliably with Recyclarr's intended state: Compose defines a Recyclarr v8 service with `./recyclarr:/config`, while `compose/arr/recyclarr/` is absent from the repository checkout.

The strongest likely issue is Radarr's `[Anime] Remux-1080p` profile. It requires a minimum custom-format score of 100, but its only non-zero custom-format score is `AV1 = -10000`. On the evidence in the export, a release cannot reach the minimum score, so the profile may reject all downloads. This should be checked in Radarr before changing it, including whether any movies use the profile.

The purpose-built `TV - Main 1080p` and `Movies - Main 1080p` profiles are internally coherent 1080p strategies with positive release-group scores and strong rejection scores. Their custom-format upgrade-until scores are 10000, much higher than the apparent scores normally attainable. This can be intentional to keep accepting incremental custom-format improvements, but it may also allow more replacement downloads than the owner wants.

Several stock or older-looking profiles coexist with the purpose-built profiles. The exports do not include series/movie assignments, so they cannot establish which profiles are active, duplicated in practice, or safe to remove. No single quality strategy is assumed here: broad profiles improve availability, narrow profiles improve consistency, and aggressive custom-format upgrades improve preference matching at the cost of bandwidth, storage churn, and download activity.

## Files inspected

- `compose/arr/compose.yaml`
- `inventory/media-profiles/sonarr-quality-profiles.json`
- `inventory/media-profiles/sonarr-quality-definitions.json`
- `inventory/media-profiles/sonarr-custom-formats.json`
- `inventory/media-profiles/radarr-quality-profiles.json`
- `inventory/media-profiles/radarr-quality-definitions.json`
- `inventory/media-profiles/radarr-custom-formats.json`
- `docs/service-inventory.md` (service, volume, and access context only)
- `inventory/services.md` (brief service-purpose cross-check)

Expected but missing:

- `compose/arr/recyclarr/`
- Any Recyclarr YAML configuration under the expected bind-mount source
- Series/movie-to-profile assignments or usage counts
- Recyclarr sync logs or other evidence tying the exported state to a particular Recyclarr run

Evidence boundary: the six JSON files are treated as point-in-time application exports because that is how they are named and committed. No API calls were made, so this review does not independently prove that they still match current runtime state.

## Sonarr profile summary

| Profile | Upgrades | Allowed quality scope | Quality cutoff | CF score limits | Apparent intent |
|---|---:|---|---|---|---|
| `Any` | No | SD through 1080p, excluding 1080p Remux and all 2160p | SDTV | Min 0; cutoff 0; all CFs score 0 | Broad legacy/default catch-all; accepts many qualities but never upgrades |
| `SD` | No | SDTV, 480p WEB/DVD/Bluray, Bluray-576p | SDTV | Min 0; cutoff 0; all CFs score 0 | SD-only, availability-oriented profile |
| `HD-720p` | No | HDTV/WEB/Bluray 720p | HDTV-720p | Min 0; cutoff 0; all CFs score 0 | Fixed 720p profile |
| `HD-1080p` | No | HDTV/WEB/Bluray 1080p | HDTV-1080p | Min 0; cutoff 0; all CFs score 0 | Fixed 1080p profile without Remux |
| `Ultra-HD` | No | HDTV/WEB/Bluray 2160p | HDTV-2160p | Min 0; cutoff 0; all CFs score 0 | Fixed 2160p profile without Remux |
| `WEB-DL (1080p/720p)` | Yes | HDTV, WEB, and Bluray at 720p/1080p | WEB 1080p group | Min 0; upgrade-until 10000; 33 non-zero CFs | Broad HD profile preferring WEB groups/providers while allowing 720p fallback; appears older or alternate |
| `Main` | Yes | HDTV, WEBRip, Bluray, and WEBDL 1080p | WEBDL-1080p | Min 0; upgrade-until 0; all CFs score 0 | Simple 1080p profile with quality upgrades but no CF preferences |
| `TV - Main 1080p` | Yes | WEB 1080p only | WEB 1080p group | Min 0; upgrade-until 10000; all 37 CFs non-zero | Strict WEB-only 1080p profile with group/provider preferences and rejection rules |

`TV - Main 1080p` scores WEB tiers at 1600-1700, providers/streaming boosts at 75, and repacks at 5-7. It assigns `-10000` to x265 HD, non-original language, AV1, bad dual groups, BR-DISK, extras, LQ, release-title LQ, and upscaled releases. Those are policy decisions rather than universally correct choices; for example, rejecting x265/AV1 favors compatibility but may use more storage, while rejecting non-original language may exclude acceptable dubbed or alternate-language releases.

## Radarr profile summary

| Profile | Upgrades | Allowed quality scope | Quality cutoff | CF score limits | Apparent intent |
|---|---:|---|---|---|---|
| `Any` | No | Almost every listed quality from pre-release sources through 2160p and BR-DISK (Raw-HD excluded) | Bluray-480p | Min 0; cutoff 0; all CFs score 0 | Very broad legacy/default catch-all; availability over quality consistency |
| `SD` | No | WORKPRINT/CAM/TELESYNC/TELECINE/REGIONAL/DVDSCR and normal SD qualities | Bluray-480p | Min 0; cutoff 0; all CFs score 0 | Broad SD profile, including low-quality pre-release sources |
| `HD-720p` | No | HDTV/WEB/Bluray 720p | Bluray-720p | Min 0; cutoff 0; all CFs score 0 | Fixed 720p profile |
| `HD-1080p` | No | HDTV/WEB/Bluray/Remux 1080p | Bluray-1080p | Min 0; cutoff 0; all CFs score 0 | Fixed 1080p profile; Remux is allowed but upgrades are disabled |
| `Ultra-HD` | No | HDTV/WEB/Bluray/Remux 2160p | Remux-2160p | Min 0; cutoff 0; all CFs score 0 | Fixed UHD profile; accepts any allowed first download and does not upgrade |
| `HD Blueray + Web` | Yes | Bluray-720p plus WEB/Bluray 1080p | Bluray-1080p | Min 0; upgrade-until 10000; 27 non-zero CFs | HD fallback profile favoring high-tier WEB/Bluray groups and editions; name contains `Blueray` typo |
| `Main` | Yes | HDTV, WEBRip, Bluray, and WEBDL 1080p | WEBDL-1080p | Min 0; upgrade-until 0; all CFs score 0 | Simple 1080p profile with quality upgrades but no CF preferences |
| `[Anime] Remux-1080p` | Yes | SD through grouped Remux 1080p, excluding HDTV-720p/1080p and standalone Bluray-1080p | Remux 1080p group | **Min 100**; upgrade-until 10000; only AV1 is non-zero at -10000 | Apparently intended for anime Remux, but no positive anime scoring formats are present |
| `Movies - Main 1080p` | Yes | Bluray-720p plus WEB/Bluray 1080p; no 1080p Remux | Bluray-1080p | Min 0; upgrade-until 10000; 25 non-zero CFs | Purpose-built 1080p movie profile with tier preferences and rejection rules |

`Movies - Main 1080p` scores HD Bluray/WEB tiers at 1600-1800, repacks at 5-7, and selected source attributes at 15-20. It rejects x265 HD, 3D, AV1, bad dual groups, black-and-white editions, BR-DISK, extras, generated dynamic HDR, line/mic dubs, LQ, sing-along, and upscaled releases at `-10000`. This is a compatibility- and conventional-edition-oriented policy, not a universal optimum.

## Recyclarr configuration summary

- Compose declares `ghcr.io/recyclarr/recyclarr:8`, runs it as UID/GID 1000, and bind-mounts `./recyclarr` to `/config`.
- The expected host directory `compose/arr/recyclarr/` is absent in this checkout.
- No Recyclarr instance names, quality-profile names, template IDs, custom-format mappings, scores, or quality-definition settings are available for inspection.
- Therefore, profile-name mismatches between Recyclarr and the exports cannot be tested. The exported CF patterns resemble a guide-derived configuration, but resemblance is not evidence of the missing Recyclarr configuration.
- No sensitive Recyclarr fields were found because no Recyclarr config was present. If a config is later supplied, URLs and API keys should be treated as sensitive/redacted fields.

## Custom formats present

Sonarr contains 37 custom formats:

- Rejections/technical: `BR-DISK`, `LQ`, `LQ (Release Title)`, `x265 (HD)`, `Extras`, `AV1`, `Bad Dual Groups`, `Upscaled`, `Language: Not Original`.
- Repacks: `Repack/Proper`, `Repack2`, `Repack3`.
- Services/sources: `AMZN`, `ATV`, `ATVP`, `CC`, `DCU`, `DSNP`, `HMAX`, `HBO`, `HULU`, `iT`, `MAX`, `NF`, `PMTP`, `PCOK`, `PLAY`, `ROKU`, `SHO`, `STAN`, `SYFY`.
- Tiers/boosts: `HD Streaming Boost`, `UHD Streaming Boost`, `WEB Tier 01`, `WEB Tier 02`, `WEB Tier 03`, `WEB Scene`.

Every Sonarr custom format has a non-zero score in at least one exported profile. Five stock/simple profiles and `Main` nevertheless score all of them at zero.

Radarr contains 48 custom formats:

- Tiers/repacks: `HD Bluray Tier 01-03`, `WEB Tier 01-03`, `Repack/Proper`, `Repack2`, `Repack3`.
- Rejections/technical: `BR-DISK`, `LQ`, `Generated Dynamic HDR`, `LQ (Release Title)`, `Sing-Along Versions`, `3D`, `x265 (HD)`, `Extras`, `AV1`, `Bad Dual Groups`, `Black and White Editions`, `Upscaled`, `Line/Mic Dubbed`.
- Services/sources: `AMZN`, `ATV`, `ATVP`, `BCORE`, `CRiT`, `DSNP`, `HBO`, `HMAX`, `Hulu`, `iT`, `MAX`, `MA`, `NF`, `PCOK`, `PMTP`, `PLAY`, `ROKU`, `STAN`.
- Editions: `Remaster`, `Criterion Collection`, `Masters of Cinema`, `Vinegar Syndrome`, `Theatrical Cut`, `Special Edition`, `IMAX`, `IMAX Enhanced`.

Radarr formats that have a zero score in every exported profile are `AMZN`, `ATV`, `ATVP`, `DSNP`, `HBO`, `HMAX`, `Hulu`, `iT`, `MAX`, `NF`, `PCOK`, `PMTP`, `PLAY`, `ROKU`, `STAN`, and `Theatrical Cut`. They can still match and appear in history, but they do not affect selection under the exported profiles.

## Findings

### Green / looks consistent

- The purpose-built profile names align with their allowed resolutions: `TV - Main 1080p` allows only WEB 1080p, and `Movies - Main 1080p` allows a 720p fallback plus WEB/Bluray 1080p.
- Their quality cutoffs are within their allowed sets: WEB 1080p for TV and Bluray-1080p for movies.
- Strong negative scores are paired with minimum score 0 in the two main profiles, so a release matching one `-10000` rejection should be excluded unless offset by an unexpectedly large positive combination.
- Positive tier scores are ordered consistently: higher-numbered preference tiers receive slightly lower scores, and repack scores increase from Proper through Repack3.
- Sonarr has no globally zero-scored custom format; every exported Sonarr CF affects at least one profile.
- Standard resolution-specific profile scopes generally match their names.

### Yellow / needs review

- **Recyclarr comparison unavailable:** the configured bind-mount source is absent. It is unknown whether configuration is intentionally untracked, generated during deployment, missing from the checkout, or lost. This also prevents checking requested profile-name mismatches.
- **Profile usage is unknown:** the exports do not show series/movie assignments. Stock profiles, `Main`, and similarly scoped purpose-built profiles may be active alternatives, migration leftovers, or unused defaults.
- **Potential predecessor profiles:** Sonarr's `WEB-DL (1080p/720p)` overlaps `TV - Main 1080p`; Radarr's `HD Blueray + Web` overlaps `Movies - Main 1080p`. They differ materially, so they are not exact duplicates, but owners should confirm whether both generations are intentional.
- **Upgrade-until CF score 10000:** the purpose-built/guide-like profiles have positive scores typically in the low thousands, and a single release normally cannot match every mutually exclusive tier/provider. A 10000 threshold may intentionally keep CF upgrades open, but can lead to repeated upgrades whenever a better-scoring release appears. Whether that is excessive depends on bandwidth, storage churn, and owner preference. Any claim about the intended upstream value **needs external reference verification**.
- **Radarr globally zero-scored formats:** 15 service/source formats and `Theatrical Cut` exist but never influence selection. Keeping them can be useful for future policy or observability; otherwise they add configuration surface without selection effect.
- **Simple profiles ignore CF policy:** `Main` and stock profiles score every CF at zero. If assigned, they can accept releases that the purpose-built profiles strongly reject, including LQ or unwanted encodes. That may be intentional for availability or special cases.
- **Broad Radarr defaults:** `Any` and `SD` allow CAM, TELESYNC, TELECINE, WORKPRINT, and DVDSCR. Because upgrades are disabled, a first accepted low-quality release will not later improve under those profiles. This favors immediate availability and may cause missed upgrades.
- **No-upgrade HD/UHD profiles:** the stock resolution profiles have sensible cutoffs but `upgradeAllowed=false`; therefore the cutoff does not drive later replacement. This is stable and bandwidth-efficient, but may retain a lower-ranked first download.
- **Sonarr definition values look unusually permissive:** most HD/UHD definitions omit `maxSize` and show `preferredSize: 995`; SD definitions prefer 95 and cap at 100. The export alone does not establish application-version semantics, but values near 995 appear unusually high and merit UI verification to ensure large releases are not effectively unconstrained. Interpretation against current Sonarr behavior **needs external reference verification**.
- **Radarr definition values need validation:** normal SD through UHD qualities generally contain `minSize` only, with no exported `maxSize` or `preferredSize`; low pre-release qualities cap at 100/prefer 95. If omission means no upper limit in the installed version, large files may remain eligible. Current field semantics **need external reference verification**.
- **Minimum sizes may be restrictive:** examples include Sonarr Bluray-1080p at 50.4 and Remux-2160p at 187.4, and Radarr Remux-1080p at 102. These may be deliberate quality floors, but can miss efficient encodes or niche releases. Units and recommended ranges **need external reference verification**.
- **Naming quality:** `HD Blueray + Web` likely means `HD Blu-ray + Web`. This is cosmetic unless external automation expects an exact name; without Recyclarr config, rename impact cannot be assessed.
- **Compatibility tradeoffs:** rejecting x265 HD and AV1 can improve playback compatibility but sacrifices smaller modern encodes. Rejecting non-original language, alternate editions, black-and-white editions, or dubs can prevent unwanted variants but may exclude desired content.

### Red / likely issue

- **Radarr `[Anime] Remux-1080p` appears unable to download:** `minFormatScore=100`, while its only non-zero CF is `AV1=-10000`; all other 47 formats score 0. A non-AV1 candidate scores 0 and fails the 100 minimum, while an AV1 candidate scores -10000. Unless behavior outside this export supplies scores, no candidate can qualify.
- **Recyclarr is not reproducible from this checkout:** Compose expects `compose/arr/recyclarr/`, but the directory is absent. Starting from only the repository would not provide the declared service with its intended configuration. This does not prove the runtime host lacks config, but it is a likely repository/deployment gap.

No other red finding is asserted from profile names or apparent defaults because assignment data and the intended Recyclarr configuration are missing.

## Questions for the human owner

1. Is `compose/arr/recyclarr/` intentionally excluded from version control, and where is the non-secret portion of the intended configuration maintained?
2. Which Sonarr series and Radarr movies use each profile? In particular, is `[Anime] Remux-1080p` assigned to anything?
3. Is the anime profile incomplete, or were anime-specific custom formats expected but never created/scored?
4. Are `WEB-DL (1080p/720p)` and `HD Blueray + Web` older profiles retained for migration, or deliberate alternatives to the named TV/movie main profiles?
5. Should the main profiles continue upgrading for every incremental CF improvement, or should downloads stop after a practical preference score?
6. Are x265 and AV1 rejected due to known client compatibility limits, or could storage-efficient codecs be acceptable?
7. Are dubbed, non-original-language, alternate edition, IMAX, special-edition, and black-and-white releases wanted for any libraries?
8. Are the permissive/large quality-definition size values intentional for high-bitrate media, and what storage/file-size targets should govern TV, movies, and Remux content?
9. Are the broad `Any`/`SD` Radarr profiles used? If so, is retaining a CAM or other pre-release first download without upgrades acceptable?
10. Were these exports taken immediately after a successful Recyclarr sync, and which Recyclarr version/config revision produced them?

## Recommended next steps

1. In the Radarr UI, inspect `[Anime] Remux-1080p`, its current assignments, and its custom-format scores. Treat this as validation only; do not change it until the intended anime strategy is confirmed.
2. Locate or restore the non-secret Recyclarr YAML. Keep credentials outside the committed config or represented only by environment/secret references. Then perform a fresh read-only name/score comparison.
3. Export or record profile assignment counts so unused and migration-era profiles can be distinguished from active policy. Do not delete profiles based only on this report.
4. Confirm desired resolution, source, codec, language, edition, bandwidth, and maximum-size tradeoffs with the owner before proposing configuration changes.
5. Verify installed-version quality-definition units and omission semantics in Sonarr/Radarr. Any comparison with TRaSH Guides or upstream recommended values **needs external reference verification**.
6. After owner decisions and external verification, prepare a separate proposed change review. A Recyclarr sync/apply plan is intentionally out of scope at this stage.

## No changes applied

No Sonarr, Radarr, Recyclarr, Compose, `.env`, or production configuration changes were applied. No Docker commands, API calls, `sudo`, or SSH were used. The only repository change is this requested review report; no Recyclarr sync/apply plan was generated.
