# ETF Research Room Task Plan

Goal: turn the current 00631L-focused PWA into a reliable ETF research room that is mobile-first, data-correct, deployable, and useful for daily review without presenting investment instructions.

## Phase 1 - Current Baseline Summary

Status: complete

- Public app is live on GitHub Pages.
- Public backend is live on Render.
- 00631L has official Yuanta basic/holdings data, TWSE intraday NAV, TAIFEX TX quote status, static public price history, backtest, local position tracking, rule-based AI summary, ETF catalog, and selected ETF price history.
- v4.15 fixed stale TX quote labeling so old TAIFEX quote data is not displayed as current live data.

## Phase 2 - v4.16 Homepage Clarity and Roadmap

Status: complete

Objective: make the first screen easier to understand and document the product direction.

- Add a product goal roadmap document.
- Make the homepage price chart default to roughly one year of data.
- Add visible date labels to the homepage chart.
- Add touch tooltip support so a tapped chart point shows date and value.
- Keep source labels explicit: live, static, cached, stale, mock, or error.

## Phase 3 - Data Correctness and Coverage

Status: in_progress

- Verify 00631L split-adjusted calculations and expose the adjusted/raw distinction more clearly.
- v4.17 added model flags and an overview `資料正確性` panel for price field, split adjustment, coverage, row count, and source.
- Add stronger validation for selected ETF histories.
- Surface coverage, missing data, split adjustment, and source status in a compact user-facing way.
- v4.22 changed 00631L price-history and static export updates to incremental-by-default, with `--full-refresh` for explicit full-range refreshes.
- v4.23 made static export merge committed seed history before incremental update, so CI runners without local data avoid full-range refreshes.
- v4.24 added per-symbol incremental updates for generic ETF price-history import.
- v4.25 keeps release check ETF status output concise while retaining detailed validation commands.
- v4.26 labels ETF price-history coverage as long-term, recent, unavailable, or error so comparisons do not hide coverage limits.
- v4.27 keeps static status backward-compatible by reading ETF tier counts from the static index when older manifests lack them.
- v4.28 prints ETF price-history readiness and tier counts in the static export CLI summary line.
- v4.29 derives ETF coverage tier counts from legacy static ETF JSON metadata when older static exports lack manifest/index tier counts.
- v4.30 adds a release-check guard for missing static ETF tier summaries when ETF history is ready.
- v4.31 reconciles legacy static ETF row/ready counts with derived coverage tier counts.
- Keep static history separate from live intraday data.

## Phase 4 - ETF Selection and Comparison

Status: in_progress

- Make the top-left ETF/search control the primary way to switch ETF context.
- v4.18 improved ETF search result readiness labels so imported price-history ETFs and catalog-only ETFs are visually distinct.
- Allow user-selected comparison baskets instead of always comparing against 00631L.
- v4.19 clarified the comparison basket UI and added a widget test for toggling comparison chips.
- Keep 00631L-specific official holdings separate from generic ETF price history.

## Phase 8 - v5.96 Missing ETF Reason Probe

Status: complete

Objective: turn remaining ETF price-history gaps from an opaque `not_saved` bucket into maintainable evidence.

- Add a safe missing-ETF probe command that attempts a small batch of missing catalog ETF histories without touching unrelated repos.
- Preserve import-attempt evidence so missing ETFs can move from `not_saved` to `official_empty`, `source_error`, `validation_error`, or ready history.
- Expose attempted-count metadata through backend status, static export, public check output, and Flutter operations status.
- Keep generated attempts and history data local/ignored; only code, tests, docs, and scripts are committed.
- Keep live/static/mock source labels truthful and keep user-visible text free of trading instructions.

Completed in v5.96:

- Added attempted-count metadata to backend ETF history index, static export, operations status, public checker, and Flutter operations model.
- Added `scripts\00631l_probe_missing_etf_reasons.cmd`.
- Fixed importer `--status-only --from-catalog` so catalog-only missing ETFs are counted as `not_saved` gaps.
- Verified status now reports catalog 347, ready 231, missing/not_saved 116, attempted 0 before any missing probe run.

## Phase 9 - v5.97 Public Pages Missing ETF Probe

Status: complete

Objective: make the public static deployment perform a small missing-ETF probe before static export so `not_saved` gaps can gradually become ready histories or classified attempt evidence.

- Add a lightweight GitHub Pages workflow step that probes a limited batch of missing ETF histories before export.
- Keep the step `continue-on-error` so source outages do not block static history for 00631L.
- Add a local opt-in flag to the Pages build helper for the same probe.
- Document that probe output is generated deployment data, not committed runtime state.

Completed in v5.97:

- GitHub Pages static workflow now runs a 20-symbol missing ETF reason probe before static export.
- Local `scripts\00631l_build_pages_static.cmd --probe-missing` verifies the same path on demand.
- Backend tests lock the workflow and local script behavior.
- Local probe run classified 20 missing ETF attempts and produced `etfPriceHistoryAttemptedCount=20` in the generated static output.

## Phase 10 - v5.98 Public ETF Count Consistency

Status: complete

Objective: make public static-data checks explain ETF catalog/history count differences instead of hiding them.

- Add `etfPriceHistoryRowCount`, completion total, and completion gap to public static check output.
- Warn when the ETF history index has more symbols than the current catalog snapshot.
- Keep this as a visibility/checking change only; do not alter source data or app calculations.

Completed in v5.98:

- Public static checker now prints ETF history row count and completion gap.
- Count mismatch between public catalog and ETF history index is surfaced as WARN with failures=0.
- Public check on v5.97 output now reports history=345, catalog=343, completionGap=114.

## Phase 11 - v5.99 Skip Attempted Missing ETF Probe

Status: complete

Objective: make scheduled public missing-ETF probes continue to later missing
symbols instead of repeating symbols that already have local import-attempt
evidence.

- Add `--skip-attempted` to `backend/scripts/import_etf_price_history.py`.
- Use it in the local missing-reason probe helper and GitHub Pages workflow.
- Add importer and pipeline tests so batch selection filters existing attempt
  evidence before applying the probe limit.
- Document the maintenance behavior and keep generated attempts ignored.

Completed in v5.99:

- `--skip-attempted` skips existing import-attempt evidence in missing-only
  batches before `--limit` is applied.
- Local probe helper and Pages workflow both use the flag.
- Targeted backend tests, full Flutter/backend validation, and release check
  passed with only accepted WARN states.
- Public Pages marker and static data check passed on v5.99, but public
  `attemptedCount` stayed at 20 because a clean GitHub Actions runner does not
  retain the previous `_attempts` directory.

## Phase 12 - v6.0 Public Attempt Carry-Forward

Status: complete

Objective: restore public ETF import-attempt evidence from the previous static
export before the next public missing-ETF probe runs.

- Add a script that reads public `etf_price_history_index.json` and restores
  `lastImportAttempt` payloads into the local ETF price-history store.
- Run that restore step in the GitHub Pages workflow before missing-only ETF
  imports and probes.
- Keep missing-only batches on `--skip-attempted` so restored evidence advances
  the next batch.
- Add tests, docs, and release-check required artifacts.

Completed in v6.0:

- Added public static attempt restore script and Windows wrapper.
- GitHub Pages restores public attempt evidence before missing-only ETF imports.
- Missing-only local and public batches skip already-attempted symbols.
- Restore dry-run confirmed the current public index can restore 20 attempt
  records.
- Full validation passed with accepted WARN states only.
- Public Pages marker and static check passed on v6.0. Public attempted count
  increased from 20 to 40, proving carry-forward works.

## Phase 13 - v6.1 Public Probe Batches

Status: complete

Objective: reduce the remaining `not_saved` ETF gap more quickly by probing a
small bounded series of batches per public deployment.

- Run three missing-ETF probe batches per GitHub Pages deployment.
- Keep each batch limited to 20 symbols.
- Keep each batch on `--missing-only --skip-attempted`.
- Mirror the same three-batch behavior in local Pages build when
  `--probe-missing` is requested.
- Add tests and docs.

Completed in v6.1:

- Pages workflow runs three 20-symbol missing probe batches after restore.
- Local Pages build mirrors the same three-batch probe.
- Targeted and full validation passed with accepted WARN states only.
- Public Pages marker and static check passed on v6.1. Public attempted count
  increased to 100 and `not_saved` dropped to 16.

## Phase 14 - v6.2 Public Unclassified ETF Gap

Status: complete

Objective: make the remaining unprobed ETF history gap visible as its own
public static-data check metric.

- Add `etfPriceHistoryUnclassifiedGapCount` to the public static checker.
- Derive it from `etfPriceHistoryGapReasonCounts.not_saved`.
- Print it in the compact summary as `etfUnclassified`.
- Add tests and docs.

Completed in v6.2:

- Public static checker now reports unclassified ETF gaps directly.
- Targeted and full validation passed with accepted WARN states only.
- Public Pages marker and static check passed on v6.2. Public unclassified gap
  dropped to 2.

## Phase 15 - v6.3 Public Unclassified Gap Threshold

Status: complete

Objective: add an explicit maintenance threshold for the unclassified ETF gap.

- Add `--max-unclassified-gap` to the public static checker.
- Return WARN with failures empty when the current unclassified gap is above the
  target.
- Add tests and docs.

Completed in v6.3:

- Public static checker supports `--max-unclassified-gap`.
- Targeted and full validation passed with accepted WARN states only.
- Public Pages marker and static check passed on v6.3. The threshold check
  correctly returned WARN/failures=0 because two ETF gaps remain unclassified.
- Diagnosis found those two codes, `009823` and `009824`, are present in the
  public static catalog but absent from the committed seed catalog used by the
  import/probe step.

## Phase 16 - v6.4 Runtime Catalog Probe

Status: complete

Objective: use a current runtime ETF catalog for public missing-only imports and
probe batches, with seed fallback when live catalog import is unavailable.

- Import the current TWSE ETF catalog before ETF history imports in Pages.
- Fall back to the committed seed catalog if catalog import fails.
- Point broad import, missing-only import, and probe batches at
  `backend/data/etf_catalog.json`.
- Mirror the same behavior in local Pages build helper.
- Add tests and docs.

Completed in v6.4:

- Pages workflow and local Pages helper import runtime ETF catalog before ETF
  price-history refresh/probe work.
- Runtime catalog falls back to committed seed when live catalog import fails.
- Targeted and full validation passed with accepted WARN states only.

## Phase 17 - v6.5 Public Catalog Universe

Status: complete

Objective: distinguish the current runtime ETF catalog universe from retained
ETF history index evidence in public static-data checks.

- Report retained history rows outside the current catalog as
  `etfPriceHistoryOutOfCatalogCount`.
- Keep unclassified ETF gaps as the maintenance signal.
- Stop warning solely because the retained history index has more symbols than
  the current catalog snapshot.
- Add tests and docs.

Completed in v6.5:

- Public static checker reports `etfPriceHistoryOutOfCatalogCount` and compact
  `etfOutOfCatalog`.
- Public static checker no longer warns only because retained history rows
  exceed the current catalog snapshot.
- WARN behavior remains when out-of-catalog rows still include unclassified
  gaps.
- Targeted and full validation passed with accepted WARN states only.

## Phase 5 - Backtest and Position UX

Status: in_progress

- Default backtest window to one year.
- Keep start/end dates configurable.
- Make results compact on mobile.
- Improve local-only position entry, export, and clear flows.
- v4.20 added compact status rows for backtest settings and local-only position tracking.

## Phase 6 - AI Daily Analysis

Status: in_progress

- Make rule-based AI focus on today's data state, holdings changes, intraday status, historical context, and app actions.
- v4.21 added a compact AI daily briefing for readiness, data source/time, coverage, and program-action items.
- Keep external LLM as a disabled adapter only.
- Keep all output descriptive and non-instructional.

## Phase 7 - App Store Readiness

Status: pending

- Keep PWA as the production baseline.
- Prepare Android/iOS frontend-shell notes.
- Confirm backend remains public and persistent before any store package.

## Verification Gate

Before commit/tag/push for each implementation slice:

- `dart format --set-exit-if-changed .`
- `flutter analyze`
- `flutter test`
- `flutter build web`
- `py -m unittest discover -s backend\tests`
- `scripts\00631l_release_check.cmd`
- `git diff --check`
