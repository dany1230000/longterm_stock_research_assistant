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

Status: complete

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

Status: complete

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

## Phase 18 - v6.6 ETF Library Status

Status: complete

Objective: carry ETF library completeness status from maintenance scripts into
static export, backend status, Flutter repositories, and the app UI.

- Add `etfPriceHistoryOutOfCatalogCount` to static export and static status.
- Add `outOfCatalogCount` to backend operations/status `etfPriceHistory`.
- Add the field to Flutter operations models and repositories.
- Show retained history count in app status details.
- Make classified gaps distinct from unclassified maintenance gaps.
- Add backend and frontend tests.

Completed in v6.6:

- Static export, operations/status, Flutter repositories, and app status now
  carry out-of-catalog ETF history counts.
- Classified ETF history gaps no longer show the same program action as
  unclassified `not_saved` gaps.
- Targeted and full validation passed with accepted WARN states only.

## Phase 19 - v6.7 Public Gap Release Guard

Status: complete

Objective: make release check enforce that public ETF history gaps are
classified.

- Run public static-data check with `--max-unclassified-gap 0`.
- Keep classified `official_empty` and `source_error` gaps as explainable data
  status, not release failures.
- Add docs and release-check artifact coverage.

Completed in v6.7:

- Release check now runs the public static-data check with
  `--max-unclassified-gap 0`.
- The public static-data step passes when ETF history gaps are classified and
  no `not_saved` maintenance gap remains.
- The static public regression guard still fails same-release regressions, but
  treats stale local ignored static exports as warnings when the public Pages
  release is newer.
- Targeted and full validation passed with accepted WARN states only.

## Phase 20 - v6.8 ETF Gap Detail Export

Status: complete

Objective: make classified ETF history gaps inspectable at symbol level in the
public static data contract.

- Export `etf_price_history_gaps.json` beside the static ETF history index.
- Include code-level gap reason, row count, source status, latest attempt time,
  requested month count, and error message.
- Surface `etfPriceHistoryGapDetailCount` in static status, manifest, and public
  static-data checks.
- Keep gap details as maintenance evidence only; do not treat unavailable
  histories as usable backtest data.

Completed in v6.8:

- Static export writes `etf_price_history_gaps.json` and includes it in the
  manifest files map.
- Static status, static export summary, compact output, and public static checks
  report `etfPriceHistoryGapDetailCount`.
- Public static checks warn if the gap-detail file is present but has fewer
  rows than the missing ETF history count.
- Targeted and full validation passed with accepted WARN states only.

## Phase 21 - v6.9 Gap Detail Status

Status: complete

Objective: carry symbol-level ETF gap detail readiness into backend operations
status and the app settings page.

- Add `gapDetailCount` to the backend multi-ETF price-history index and
  operations/status response.
- Add `etfPriceHistoryGapDetailCount` to Flutter operations models and
  repositories.
- Show `缺口明細` in the app ETF data library status so users can distinguish
  classified gap evidence from raw missing counts.
- Add backend, repository, and widget tests.

## Phase 22 - v6.10 Gap Reason Samples

Status: complete

Objective: make classified ETF history gaps easier to inspect without opening
the full gap-detail JSON.

- Add short `gapReasonSamples` code lists to backend ETF history index.
- Export samples in static public status, manifest, ETF history index, and gap
  detail files.
- Carry samples through operations/status and Flutter repositories.
- Show short sample codes in the app settings ETF data-library status.
- Keep samples as maintenance evidence only; unavailable histories are still
  excluded from history/backtest/comparison views.

## Phase 23 - v6.11 Gap Detail API

Status: complete

Objective: expose full ETF price-history gap detail through a backend endpoint
so maintenance tools and future UI can inspect gaps without downloading static
JSON manually.

- Add `GET /api/etf/history/gaps`.
- Support `reason`, `limit`, and `fromCatalog` query parameters.
- Return gap reason counts, samples, detail rows, and catalog row count when the
  catalog universe is requested.
- Keep the endpoint read-only and clearly scoped to data verification.

## Phase 24 - v6.12 Gap Detail UI

Status: complete

Objective: make symbol-level ETF price-history gap details inspectable inside
the app instead of requiring manual JSON/API checks.

- Add frontend models for ETF price-history gap detail rows.
- Add repository support for live proxy, static public, cached, and mock modes.
- Add a settings-page `ETF gap details` panel with code, reason, source status,
  row count, attempt time, and short error text.
- Keep gap details as maintenance status only; unavailable rows are not used by
  history, backtest, comparison, or AI performance data.
- Validation passed with Flutter analyze/test/build, backend tests, release
  check WARN with failures=0, and git diff check.

## Phase 25 - v6.13 Gap Detail Filters

Status: complete

Objective: make the symbol-level ETF price-history gap detail panel faster to
inspect by reason without changing any history/backtest eligibility.

- Add reason filter chips to the settings `ETF gap details` panel.
- Show a filtered row count when a reason is selected.
- Keep the full list available through an `all` chip.
- Keep gap details as maintenance status only; unavailable rows are not used by
  history, backtest, comparison, or AI performance data.
- Validation passed with Flutter analyze/test/build, backend tests, release
  check WARN with failures=0, and git diff check.

## Phase 26 - v6.14 Symbol Search Filter Counts

Status: complete

Objective: make the ETF/stock search sheet show how many ETF rows match the
current readiness filter for the active query.

- Show a filtered ETF count against the current query candidate count.
- Add stable widget coverage for `all`, `ready`, and `catalogOnly` filters.
- Keep catalog-only rows clearly separate from history-ready rows.
- Do not change history/backtest/comparison eligibility.
- Validation passed with Flutter analyze/test/build, backend tests, release
  check WARN with failures=0, and git diff check.

## Phase 27 - v6.15 Symbol Search Readiness Mix

Status: complete

Objective: show the ETF search query's data availability mix before the user
switches filters or selects a symbol.

- Show `history-ready` and `catalog-only` counts for the active query.
- Add widget coverage for the query readiness count keys.
- Keep catalog-only rows visible but separate from history-ready rows.
- Do not change history/backtest/comparison eligibility.
- Validation: `flutter analyze`, `flutter test`, `flutter build web`,
  backend tests, release check WARN with failures=0, and `git diff --check`.

## Phase 28 - v6.16 Selected ETF Capability Badges

Status: complete

Objective: make the currently selected ETF's usable functions visible after a
symbol is selected.

- Show compact capability badges for history, backtest, comparison, and AI
  context.
- Show ready and paused states without changing eligibility rules.
- Add widget coverage for history-ready and catalog-only selected ETF states.
- Keep labels descriptive and avoid any trading-instruction wording.
- Validation: `dart format --set-exit-if-changed .`, `flutter analyze`,
  `flutter test`, `flutter build web`, backend tests, release check WARN with
  failures=0, and `git diff --check`.

## Phase 29 - v6.17 Pages Release Tag Trigger

Status: complete

Objective: keep GitHub Pages static release metadata aligned with the current
tag instead of falling back to stale default metadata.

- Trigger the Pages workflow on `00631l-lab-v*` tag pushes.
- Inject release metadata from the tag ref during tag-triggered builds.
- Avoid stale default release tags when static export runs without an exact tag.
- Add backend tests for workflow coverage and metadata fallback behavior.
- Validation: `dart format --set-exit-if-changed .`, `flutter analyze`,
  `flutter test`, `flutter build web`, backend tests, release check WARN with
  failures=0, and `git diff --check`.

## Phase 30 - v6.18 Pages Release Tag Polling

Status: complete

Objective: publish correct static release metadata without relying on a tag ref
deployment that GitHub Pages may reject.

- Keep Pages deployment on `main`.
- Poll remote tags during the Pages build so a just-pushed release tag can be
  used before static export runs.
- Keep untagged fallback metadata when no release tag is available.
- Add workflow tests for the tag polling step.
- Validation: `dart format --set-exit-if-changed .`, `flutter analyze`,
  `flutter test`, `flutter build web`, backend tests, release check WARN with
  failures=0, and `git diff --check`.

## Phase 31 - v6.19 Pages Deploy Status Alignment

Status: complete

Objective: keep the local Pages deployment checker aligned with the v6.18
main-branch tag polling flow.

- Pass the expected git SHA into the public Pages smoke check.
- Include public release marker metadata in the deploy status summary.
- Downgrade stale workflow-run warnings only when the public release marker
  already matches expected HEAD.
- Keep mismatched public release metadata as a warning.

Completed in v6.19:

- Pages deploy status now passes the expected SHA to public Pages smoke checks.
- Public release marker metadata is included in the status summary.
- Stale workflow WARN states are downgraded only when the public marker matches
  expected HEAD.
- Public Pages marker and strict static-data checks passed on v6.19.

## Phase 32 - v6.20 Symbol Search Ranking

Status: complete

Objective: make the top-left ETF/stock search behave more like a production
symbol picker.

- Rank exact ETF code matches first.
- Rank code-prefix and code-contains matches before name-only matches.
- Prefer history-ready rows over catalog-only rows for equal match quality.
- Keep readiness labels truthful and do not change eligibility rules.

Completed in v6.20:

- Search results now rank code matches ahead of name-only matches.
- Equal-rank results prefer history-ready rows before catalog-only rows.
- Widget coverage verifies `0050` appears first for a symbol-like query.

## Phase 33 - v6.21 Comparison Readiness

Status: complete

Objective: make ETF comparison data readiness explicit when selected or basket
symbols do not have enough history rows for the comparison chart.

- Show candidate, comparison-ready, and skipped counts in the comparison panel.
- List skipped ETF codes when their active-range history has fewer than two rows.
- Keep skipped rows out of chart, basket, and table calculations.
- Keep catalog-only rows visible as data status, not usable comparison data.

Completed in v6.21:

- The comparison panel reports candidate, comparison-ready, and skipped rows.
- Skipped code samples are visible and excluded from chart/table calculations.
- Widget coverage verifies a catalog-only selected ETF appears as skipped.
- Full validation passed with accepted WARN states only.

## Phase 34 - v6.22 Comparison Skipped Details

Status: complete

Objective: make skipped ETF comparison rows explain why they were excluded
without changing source data or comparison eligibility.

- Show compact skipped-row detail with code, active-range row count, and source
  status.
- Keep skipped rows outside chart/table calculations.
- Keep the comparison page concise and data-status focused.

Completed in v6.22:

- Skipped comparison rows now show code, active-range row count, and source
  status as compact detail chips.
- Widget coverage verifies catalog-only skipped detail appears.
- Full validation passed with accepted WARN states only.

## Phase 35 - v6.23 Compact Comparison Controls

Status: complete

Objective: reduce vertical clutter in the ETF comparison section on mobile
without changing comparison data, filters, or basket behavior.

- Keep filter and action controls reachable.
- Make comparison action buttons occupy one horizontal row.
- Preserve existing stable button keys for widget tests and user flows.

Completed in v6.23:

- Comparison actions now render in a horizontal strip.
- Existing filter, basket, and action behavior is unchanged.
- Widget coverage verifies the compact action strip is present.
- Full validation passed with accepted WARN states only.

## Phase 36 - v6.24 Compact Comparison Guidance

Status: complete

Objective: shorten the ETF comparison guidance so the chart and readiness data
appear sooner on phone screens.

- Replace the long comparison guidance sentence with a short data-rule hint.
- Keep readiness and skipped details as the primary explanation.
- Preserve comparison behavior and no-advice wording.

Completed in v6.24:

- Long comparison guidance was replaced with a compact data-rule hint.
- Widget coverage now verifies the short hint.
- Full validation passed with accepted WARN states only.

## Phase 37 - v6.25 Compact Loading Shell

Status: complete

Objective: make the public web and Flutter pending-data loading states feel like
the ETF research room app instead of a large centered splash card.

- Replace the centered public `index.html` loading card with a compact app
  shell containing symbol, quote placeholder, data placeholders, and nav labels.
- Add compact Flutter loading skeleton keys for status, quote, metrics, and
  section content.
- Keep the loading state descriptive only; do not change live/static/mock data
  rules.

Completed in v6.25:

- Public `index.html` loading now uses a compact app shell instead of a large
  centered card.
- Flutter pending-data loading now includes status, quote, metric, and section
  skeleton keys.
- Playwright mobile screenshots verified both the loading shell and loaded root
  page; screenshot artifacts were removed before staging.
- Full validation passed with accepted WARN states only.

## Phase 38 - v6.26 Overview Date Axis Fit

Status: complete

Objective: make the overview one-year sparkline date axis readable on phone
screens.

- Add horizontal chart edge padding so the first and last date ticks are not
  pinned to the container edge.
- Align start, middle, and end date labels to their natural positions.
- Add widget coverage for the start and end date tick keys.
- Do not change historical price calculations.

Completed in v6.26:

- Overview sparkline now uses x-axis edge padding so start and end dates stay
  inside the chart area on phone screens.
- Start/end date labels have stable widget keys.
- Playwright mobile screenshot verified the right-side date is visible; generated
  screenshots were removed before staging.
- Full validation passed with accepted WARN states only.

## Phase 39 - v6.27 Overview Core Strip

Status: complete

Objective: reduce first-screen vertical weight by making the overview core
metrics a compact horizontal strip.

- Keep the quote card and one-year chart visually closer together.
- Limit the change to the overview core data block.
- Preserve source labels and all data calculations.

Completed in v6.27:

- Overview core metrics now use a horizontally scrollable compact strip.
- Widget coverage verifies the overview core metric strip is present on phone
  width.
- Playwright mobile screenshot verified the chart moves closer to the quote
  section; generated screenshots were removed before staging.
- Full validation passed with accepted WARN states only.

## Phase 40 - v6.28 AI Daily Briefing Hero

Status: complete

Objective: make the AI page open with a compact daily interpretation instead of
making users scan technical status blocks first.

- Add a top `今日 AI 判讀` card on the AI page.
- Group holdings date, intraday NAV time, source status, TX weight, TSMC weight,
  premium-discount context, and the first program action.
- Keep detailed AI/status panels below the new daily briefing.
- Keep the summary rule-based and non-instructional.

Completed in v6.28:

- AI page now starts with a compact `今日 AI 判讀` card.
- The card groups daily holdings, intraday NAV, source status, TX/TSMC weights,
  premium-discount context, and the first program action.
- Widget coverage verifies the AI daily briefing card and non-instructional
  wording.
- Full validation passed with accepted WARN states only.

## Phase 41 - v6.29 Position Account Strip

Status: complete

Objective: make the position page account summary shorter on phone screens while
keeping local-only storage and calculations unchanged.

- Convert the position account metric grid into a horizontal compact strip.
- Keep market value, P/L, symbol, and local position state available.
- Add widget coverage for the new strip.
- Do not change position calculations, JSON export, or clear behavior.

Completed in v6.29:

- Position account metrics now use a horizontal compact strip.
- Shared range context uses its own generic strip so backtest/history and
  position keys do not collide.
- Widget coverage verifies the position account metric strip.
- Full validation passed with accepted WARN states only.

## Phase 42 - v6.30 Chart Touch Detail Key

Status: complete

Objective: make history/backtest chart touch-detail UI easier to test and
polish safely.

- Add a stable key to `_ChartTouchDetail`.
- Verify the history page renders chart touch-detail panels.
- Keep price, history, backtest, and comparison calculations unchanged.

Completed in v6.30:

- `_ChartTouchDetail` now has the stable key
  `00631l-line-chart-touch-detail`.
- Widget coverage verifies history/backtest chart touch-detail panels render.
- Full validation passed with accepted WARN states only.

## Phase 43 - v6.31 History Chart Date Labels

Status: complete

Objective: make history/backtest chart dates and selected-point detail easier
to read on narrow phone screens.

- Wrap start/middle/end axis labels in compact bordered chips.
- Let date labels scale within their available width instead of clipping.
- Convert chart touch detail from a crowded one-row layout into primary and
  secondary lines.
- Add widget coverage for axis-label and touch-detail line keys.
- Keep price-history ingestion, split adjustment, and backtest formulas
  unchanged.

Completed in v6.31:

- History/backtest chart axis labels now use compact bordered chips.
- Axis date labels scale down within their available width on phone screens.
- Chart touch detail now uses separate primary and secondary lines.
- Widget coverage verifies the new chart-axis and touch-detail line keys.
- Full validation passed with accepted WARN states only.

## Phase 44 - v6.32 Compact Date Range Controls

Status: complete

Objective: make history/backtest date controls clearer and shorter on mobile
without changing data or formulas.

- Add an active date-range summary above start/end date buttons.
- Mark the range as latest one-year default or custom range.
- Reuse the same treatment in history and backtest.
- Add widget coverage for the range summary.
- Keep historical performance, split adjustment, and backtest calculations
  unchanged.

Completed in v6.32:

- History/backtest date controls now show a compact active-range summary.
- The summary labels default latest one-year and custom ranges.
- Widget coverage verifies the shared range-summary key.
- Full validation passed with accepted WARN states only.

## Phase 45 - v6.33 Position Quick Actions

Status: complete

Objective: shorten the position page action area on phone screens while keeping
position data local-only.

- Replace the wrapped action bar with a horizontal quick-action strip.
- Keep save, JSON export, and clear behavior unchanged.
- Add stable keys for each action tile.
- Keep position calculations, local storage, and export JSON unchanged.

Completed in v6.33:

- Position actions now use a horizontal quick-action strip.
- Save, JSON export, and clear retain the same local-only behavior.
- Widget coverage verifies the three quick-action tile keys.
- Full validation passed with accepted WARN states only.

## Phase 46 - v6.34 AI Daily Bullets

Status: complete

Objective: make the AI page open with concrete daily interpretation instead of
requiring the user to scan lower detailed panels.

- Show the first rule-based analysis bullets inside the top AI briefing card.
- Keep source, holdings date, NAV time, and program action context visible.
- Add widget coverage for the daily bullet area.
- Keep rule-based analysis as the only active provider.

Completed in v6.34:

- The AI hero now shows the first two rule-based daily interpretation bullets.
- Source, holdings date, NAV time, and program action context remain visible.
- Widget coverage verifies the daily briefing bullet area.
- Full validation passed with accepted WARN states only.

## Phase 47 - v6.35 Overview Daily Summary Strip

Status: complete

Objective: make the first overview screen show the daily data state in one
compact line before the user reaches the chart and detailed cards.

- Add a compact daily summary strip below the quote header.
- Group frontend mode, official holdings date, intraday NAV time,
  premium/discount status, history coverage, and first AI brief.
- Add widget coverage for the strip.
- Keep data sources, price-history formulas, backtest formulas, and split
  adjustment unchanged.

Completed in v6.35:

- Added a compact overview daily summary strip below the quote header.
- The strip groups frontend mode, official daily holdings date, intraday NAV
  time, premium/discount status, history coverage, and first rule-based AI
  brief.
- Widget coverage verifies the new strip in overview and phone-width tests.
- Full validation passed with accepted WARN states only.

## Phase 48 - v6.36 Compact Quote Header

Status: complete

Objective: reduce duplicate information above the overview chart so the first
mobile screen reaches the chart and core status sooner.

- Hide the 00631L quote meta strip because v6.35 daily summary already carries
  NAV/session/history context.
- Keep quote meta available for non-00631L selected ETF contexts.
- Add widget coverage that 00631L overview hides the duplicate meta strip.
- Keep data sources, history, backtest, and AI logic unchanged.

Completed in v6.36:

- 00631L overview quote header no longer shows the duplicate NAV/session/history
  meta strip.
- Non-00631L selected ETF contexts keep the quote meta strip.
- Widget coverage verifies the 00631L overview hides the duplicate quote meta
  strip.
- Full validation passed with accepted WARN states only.

## Phase 49 - v6.37 Overview Summary Mode Badge

Status: complete

Objective: make the overview daily summary header cleaner after mobile
inspection showed the long mode/AI text was truncated.

- Move frontend mode into a compact header badge.
- Remove the duplicate MODE chip.
- Keep AI as a short chip in the summary row.
- Keep data sources, formulas, and AI provider unchanged.

Completed in v6.37:

- Moved frontend mode into the `今日摘要` header badge.
- Removed the duplicate MODE chip.
- Kept AI as a compact summary chip.
- Full validation passed with accepted WARN states only.

## Phase 50 - v6.38 Fast Summary Loading State

Status: complete

Objective: keep the overview daily summary strip from showing temporary
error/unavailable labels while the fast startup shell is still waiting for full
details.

- Pass the full-data loading state into the overview daily summary strip.
- Show loading/pending labels during transient startup.
- Preserve real source-status labels after full data finishes loading.
- Add widget coverage for the fast-start summary state.

Completed in v6.38:

- Overview daily summary strip shows `loading` / `pending` during fast startup
  instead of transient source errors.
- True source labels remain after full data completes.
- Widget coverage verifies fast-start summary labels avoid temporary
  `error` / `unavailable` text.
- Full validation passed with accepted WARN states only.

## Phase 51 - v6.39 Overview Duplicate Core Cleanup

Status: complete

Objective: make the mobile overview first screen less repetitive by removing
the 00631L-only `核心資料` card that duplicated the quote header, daily summary,
and chart panel.

- Keep quote header and daily summary as the first-screen data state.
- Move directly into the price/exposure chart after the daily summary.
- Keep non-00631L selected ETF core-data panels because they still provide
  selected-symbol context.
- Update widget coverage and docs.

Completed in v6.39:

- Removed the duplicated 00631L overview `核心資料` card.
- The overview now flows from quote header to `今日摘要` into the
  price/exposure chart.
- Non-00631L selected ETF core panels remain available.
- Removed obsolete strip/helper code and updated widget coverage.
- Full validation passed with accepted WARN states only.

## Phase 52 - v6.40 Compact Holdings Digest

Status: complete

Objective: keep official holdings visible in the overview while reducing the
height of the holdings digest on phone screens.

- Replace tall holdings info cards with compact horizontal digest tiles.
- Keep TX futures, TSMC stock, and stock/futures/cash mix visible.
- Preserve the daily-snapshot wording and source truth.
- Add widget coverage and release docs.

Completed in v6.40:

- Replaced the overview holdings card grid with compact horizontal digest
  tiles.
- TX, TSMC, and stock/futures/cash mix remain visible in the overview.
- Widget coverage verifies the compact digest strip on phone width.
- Full validation passed with accepted WARN states only.

## Phase 53 - v6.41 Daily Summary Simplification

Status: complete

Objective: make the overview `今日摘要` strip fit phone screens better and avoid
raw technical source-contract text.

- Keep only DAY, LIVE, and HIS summary chips.
- Remove duplicate P/D and AI chips from the overview summary.
- Display intraday source as TWSE/Yuanta/status instead of raw contract IDs.
- Add widget coverage and docs.

Completed in v6.41:

- Overview daily summary now keeps DAY, LIVE, and HIS only.
- Removed duplicate P/D and AI summary chips.
- Intraday source caption maps raw contract IDs to user-facing source labels.
- Widget coverage verifies the fast-start summary does not show removed or raw
  technical labels.
- Full validation passed with accepted WARN states only.

## Phase 54 - v6.42 History Range Selection State

Status: complete

Objective: make history/backtest date ranges visibly selectable on phone
screens.

- Keep the latest one-year default.
- Keep manual start/end date controls.
- Show selected state for 1Y, 3Y, and all-data range chips.
- Label short-history edge cases truthfully as all data when the selected range
  spans the full verified coverage.
- Do not change historical price data, split-adjustment logic, or backtest
  formulas.

Completed in v6.42:

- History and backtest quick range chips now show selected state.
- The default latest-one-year range remains selected on load.
- The all-data range is labeled truthfully when it spans the full verified
  coverage.
- Widget coverage verifies selected chip states for history and backtest.
- Full validation passed with accepted WARN states only.

## Phase 55 - v6.43 Overview Summary Grid Fit

Status: complete

Objective: make the overview daily summary fully visible on phone width without
horizontal clipping.

- Replace the horizontally scrolling DAY/LIVE/HIS summary row with a fixed
  three-column grid.
- Shorten LIVE to time-only and HIS to row-count plus coverage years.
- Keep source labels truthful and keep static history separate from live
  intraday data.
- Add phone-width widget coverage that DAY, LIVE, and HIS all stay inside the
  summary card.

Completed in v6.43:

- Overview daily summary now uses a fixed three-column DAY/LIVE/HIS grid.
- LIVE shows time-only and HIS shows row count plus coverage years to fit phone
  width.
- Phone-width widget coverage verifies all three badges stay inside the summary
  card.
- Full validation passed with accepted WARN states only.

## Phase 56 - v6.44 Holdings Digest Grid Fit

Status: complete

Objective: make the overview official holdings digest fully visible on phone
width.

- Replace the horizontally scrolling TX/TSMC/MIX digest with a fixed three-cell
  row.
- Shorten the MIX label while preserving stock/futures/cash context.
- Scale long percentages inside their tile instead of clipping the third tile.
- Keep official holdings as daily snapshot data, not live intraday holdings.
- Add phone-width widget coverage for the three digest badges.

Completed in v6.44:

- Overview official holdings digest now uses a fixed three-cell row.
- The mix tile title is shortened and long percentage values scale inside the
  tile.
- Phone-width widget coverage verifies TX, 2330, and MIX stay inside the digest
  row.
- Full validation passed with accepted WARN states only.

## Phase 57 - v6.45 Holdings Digest Label Polish

Status: complete

Objective: remove remaining ellipsis from the overview official holdings
digest titles on phone width.

- Shorten the three digest labels to `期貨`, `台積電`, and `股期現金`.
- Keep badges as TX, 2330, and MIX.
- Preserve the official daily snapshot wording and values.
- Add/update widget coverage for the new compact labels.

Completed in v6.45:

- Holdings digest labels are now `期貨`, `台積電`, and `股期現金`.
- TX / 2330 / MIX badges remain unchanged.
- Targeted and full validation passed with accepted WARN states only.

## Phase 58 - v6.46 History/Backtest Top Compact

Status: complete

Objective: shorten the top of the history/backtest page on phone screens so
date controls, chart, and backtest content appear sooner.

- Replace the large history/backtest header with a compact top strip.
- Keep selected ETF, source status, coverage, latest close, row count, and
  default one-year range visible.
- Move detailed price-history quality and split-adjustment notes into an
  expandable panel.
- Keep price-history data, split adjustment, performance, and backtest formulas
  unchanged.

Completed in v6.46:

- History/backtest now starts with a compact top strip instead of a large
  header card.
- Detailed price-history quality notes are still available in an expandable
  `資料品質` panel.
- Existing selected-ETF history tests were updated to expand the quality panel
  before checking split-adjustment details.
- Full validation passed with accepted WARN states only.

## Phase 59 - v6.47 Position Empty Hint Compact

Status: complete

Objective: shorten the local position page empty state so account summary,
local-only actions, and input fields fit better on phones.

- Replace the large no-position empty panel with a compact hint strip.
- Keep local-only storage, JSON export, clear action, and position calculations
  unchanged.
- Add widget coverage for the compact hint.

Completed in v6.47:

- Position empty state now uses a compact hint strip.
- Local-only inputs, JSON export, clear action, and estimate details remain
  unchanged.
- Full validation passed with accepted WARN states only.

## Phase 60 - v6.48 AI Fact Row Compact

Status: complete

Objective: make the AI daily briefing facts scan faster on phone width.

- Keep the rule-based AI daily briefing and disclaimer unchanged.
- Render content, intraday NAV, and history facts as one compact row on phones.
- Preserve the wider multi-card layout.
- Add phone-width widget coverage.

Completed in v6.48:

- AI daily briefing facts now fit in a compact three-cell row on phone width.
- Wider layouts keep the existing multi-card fact layout.
- Full validation passed with accepted WARN states only.

## Phase 61 - v6.49 Backtest Result Compact

Status: complete

Objective: shorten the backtest result area on phone screens without removing
key result data.

- Keep the quick result strip as the primary backtest result summary.
- Add annualized return and volatility to the quick result strip.
- Remove the duplicated 2x2 result grid below the input panel.
- Keep backtest formulas, date range controls, cost inputs, and charts
  unchanged.

Completed in v6.49:

- Backtest quick result strip now includes annualized return and volatility.
- Removed the duplicated result metric grid below the parameter panel.
- Targeted widget test and full validation passed with accepted WARN states
  only.

## Phase 62 - v6.50 AI Detail Progressive Disclosure

Status: complete

Objective: make the AI page first screen focus on the daily briefing and
concise summary instead of repeated detailed cards.

- Keep the daily AI briefing at the top.
- Move detailed snapshot and daily interpretation cards into advanced AI detail.
- Keep rule-based provider behavior and non-instructional wording unchanged.
- Add widget coverage for hidden-before-expansion and visible-after-expansion
  behavior.

Completed in v6.50:

- Detailed AI snapshot and interpretation cards now live inside advanced AI
  detail.
- AI page first screen opens with the daily briefing and concise summary.
- Full validation passed with accepted WARN states only.

## Phase 63 - v6.51 Position Advanced Fields

Status: complete

Objective: keep the local-only position page shorter on phones by moving
optional position inputs behind progressive disclosure.

- Keep share count and average cost as the always-visible essential fields.
- Move total assets, fee, and note into an advanced position-fields panel.
- Keep local-only storage, calculations, JSON export, and clear behavior
  unchanged.
- Add widget coverage for hidden-before-expansion and visible-after-expansion
  behavior.

Completed in v6.51:

- Position page now keeps only share count and average cost visible by default.
- Optional total assets, fee, and note moved into an advanced fields panel.
- Targeted and full validation passed with accepted WARN states only.

## Phase 64 - v6.52 Startup Summary States

Status: complete

Objective: make the first-screen overview feel ready during background refresh
instead of showing generic loading text.

- Replace generic `loading` labels in the DAY / LIVE / HIS overview row with
  user-facing background states.
- Keep static history row count visible when history is already available.
- Keep live intraday NAV truthfully labeled as backend-dependent.
- Add widget coverage for the fast first screen state.

Completed in v6.52:

- Fast-start overview summary now shows `syncing`, `checking`, and ready
  static-history counts instead of generic loading text.
- Targeted fast-start widget test and full validation passed with accepted
  WARN states only.

## Phase 65 - v6.53 Summary Caption Fit

Status: complete

Objective: remove remaining caption ellipsis from the first-screen DAY / LIVE /
HIS summary row on phone width.

- Shorten the DAY caption to `daily`.
- Shorten the LIVE caption to `backend`.
- Use compact year-range captions for history coverage.
- Keep source and calculation behavior unchanged.

Completed in v6.53:

- Overview summary captions are now short enough for phone cards.
- Removed the old unused full-year helper after analyze caught it.
- Targeted and full validation passed with accepted WARN states only.

## Phase 66 - v6.54 Background Refresh Banner

Status: complete

Objective: make the fast-first-screen refresh banner read like app status
instead of a long loading message.

- Shorten the loading-state banner to a compact background-refresh sentence.
- Keep the fallback/error state truthful but shorter.
- Keep quote, chart, summary row, source labels, and data behavior unchanged.
- Update widget coverage for the new wording.

Completed in v6.54:

- Fast-first-screen loading banner now uses a compact background-refresh
  sentence.
- Fallback banner remains explicit and shorter.
- Targeted and full validation passed with accepted WARN states only.

## Phase 67 - v6.55 Quote Title Name

Status: complete

Objective: remove the duplicated `00631L 00631L` quote header label on the
public first screen.

- Use the 00631L profile name when price history only provides the code as the
  name.
- Keep selected non-00631L ETF names driven by history/catalog data.
- Keep quote, NAV, holdings, and calculation behavior unchanged.
- Add widget coverage that the duplicate quote title is gone.

Completed in v6.55:

- 00631L quote header now falls back to `元大台灣50正2` when history name is
  only the code.
- Widget coverage verifies `00631L 00631L` is not rendered.
- Targeted and full validation passed with accepted WARN states only.

## Phase 68 - v6.56 Fast Static History Overlay

Status: complete

Objective: keep the public first-screen chart usable while live-proxy full
details are still loading.

- Merge static public price history into the fast startup payload when live
  fast data reports price history as deferred or unavailable.
- Keep live intraday NAV, official holdings, and static history labels
  distinct.
- Add repository regression coverage so this first-screen fallback cannot
  regress.
- Verify the public page after release.

Completed in v6.56:

- Fast startup now overlays static public price history when live fast data
  still has deferred/unavailable price history.
- Operations price-history metadata also merges from static fallback when the
  live fast payload lacks usable rows.
- Repository coverage verifies the fast static-history overlay path.
- Full validation passed with accepted WARN states only.

## Phase 69 - v6.57 Holdings Unavailable State

Status: complete

Objective: prevent zero-value placeholder holdings snapshots from looking like
official digest data on the public overview screen.

- Detect holdings snapshots that have error status, zero fund net asset value,
  zero outstanding units, or no holding lines.
- Render a compact unavailable state instead of TX/TSMC/mix tiles when the
  snapshot is not usable.
- Keep valid official holdings digest behavior unchanged.
- Add widget coverage for the unavailable state.

Completed in v6.57:

- Overview holdings digest now checks snapshot usability before rendering
  TX/TSMC/mix tiles.
- Error/zero-value placeholder snapshots render a compact unavailable state
  instead of 0-value digest tiles.
- Widget coverage verifies both valid digest and unavailable digest states.
- Full validation passed with accepted WARN states only.

## Phase 70 - v6.58 Compact Quote Short Name

Status: complete

Objective: keep the first quote card readable on phone width by avoiding the
long 00631L fund registration name in the card title.

- Show `00631L 元大台灣50正2` in the quote card for the 00631L context.
- Keep selected non-00631L ETF titles driven by catalog/history data.
- Do not change price, NAV, holdings, source labels, or calculations.
- Add widget coverage for the compact quote title.

Completed in v6.58:

- The 00631L quote card title now renders as `00631L 元大台灣50正2`.
- Non-00631L selected ETF titles remain driven by catalog/history data.
- Widget coverage verifies the compact quote title and duplicate code title
  guard.
- Full validation passed with accepted WARN states only.

## Phase 71 - v6.59 First-Screen Refresh Quiet State

Status: complete

Objective: keep the mobile public homepage focused on quote, chart, and
official daily context by hiding the background-refresh banner when usable
first-screen data is already available.

- Hide the background-refresh strip during normal fast startup if quote plus
  history or official holdings context is usable.
- Keep fallback/error strip behavior when full data fails.
- Keep DAY / LIVE / HIS summary badges visible as the compact data-state
  indicator.
- Do not change price, holdings, intraday NAV, backtest, selected ETF, or AI
  calculations.

Completed in v6.59:

- The normal background-refresh strip is hidden when the first screen already
  has a quote plus usable history or official holdings context.
- Full-data failure keeps the fallback/error strip visible.
- Widget coverage verifies the quiet fast-start state.
- Full validation passed with accepted WARN states only.

## Phase 72 - v6.60 Quote Premium Source Guard

Status: complete

Objective: keep the 00631L quote-card premium/discount display tied to live
intraday NAV instead of mixing catalog/static reference values with unavailable
live labels.

- Use intraday NAV premium/discount only for the 00631L quote-card premium box.
- Show unavailable when intraday NAV is unavailable.
- Keep non-00631L selected ETF catalog premium/discount behavior unchanged.
- Add widget coverage for the intraday-only guard.
- Do not change parsers, source data, history, backtest, position, or AI logic.

Completed in v6.60:

- 00631L quote-card premium/discount now uses intraday NAV only.
- When intraday NAV is unavailable, the quote premium box shows unavailable.
- Non-00631L selected ETF catalog behavior is unchanged.
- Widget coverage verifies the intraday-only source guard.
- Full validation passed with accepted WARN states only.

## Phase 73 - v6.61 Summary Available Values

Status: complete

Objective: make the first-screen DAY / LIVE / HIS summary row show real
available values during background refresh instead of generic syncing/checking
labels.

- Show official holdings date when the snapshot is usable.
- Show intraday NAV time when it is available.
- Keep history row count and coverage when static/public history is available.
- Use syncing/checking only for the specific missing data item.
- Do not change data sources, calculations, selected ETF behavior, or AI logic.

Completed in v6.61:

- DAY shows the holdings date when the snapshot is usable.
- LIVE shows the intraday NAV time when present.
- HIS keeps row count/coverage when history is available.
- Syncing/checking labels are reserved for missing data only.
- Full validation passed with accepted WARN states only.

## Phase 74 - v6.62 Exposure Unavailable Guard

Status: complete

Objective: prevent invalid official-holdings snapshots from rendering as
zero-value exposure data on the overview chart panel.

- Render the overview exposure strip only when holdings snapshot data is usable.
- Keep the price chart visible when holdings are unavailable.
- Let the existing holdings-status card explain unavailable holdings.
- Add widget coverage for valid and unavailable holdings snapshots.
- Do not change holdings parsing, price history, intraday NAV, backtest,
  position, selected ETF, or AI logic.

Completed in v6.62:

- The overview exposure strip now renders only when the holdings snapshot is
  usable.
- The price chart remains visible when holdings are unavailable.
- Widget coverage verifies both valid and unavailable exposure-strip states.
- Full validation passed with accepted WARN states only.

## Phase 75 - v6.63 Summary Final Unavailable State

Status: complete

Objective: make the overview DAY/LIVE/HIS summary row distinguish known
unavailable/error states from background loading.

- Prefer `unavailable` plus the actual source status when a source explicitly
  reports error/unavailable.
- Keep `syncing` / `checking` only for sources that are still genuinely
  waiting for detail data.
- Add widget coverage for fast startup with a known holdings error.
- Do not change source fetching, parsers, history, backtest, position, or AI
  logic.

Completed in v6.63:

- Summary chips now show `unavailable` plus the actual source status when a
  source explicitly reports error/unavailable.
- Background-sync wording remains only for genuinely pending detail data.
- Widget coverage verifies fast startup with a known holdings error.
- Full validation passed with accepted WARN states only.

## Phase 76 - v6.64 Holdings Unavailable Wording

Status: complete

Objective: make the overview holdings-unavailable card read like a product
status, not a technical backend debug message.

- Replace technical `live backend` / `official holdings` copy with concise
  user-facing data status text.
- Avoid showing placeholder trade dates when holdings are unusable.
- Keep the status badge truthful (`error`, `stale`, `mock`, etc.).
- Add widget coverage for the unavailable wording.
- Do not change holdings parsing, repository behavior, price history, intraday
  NAV, backtest, position, or AI logic.

Completed in v6.64:

- Holdings-unavailable cards now use concise data-status wording.
- Unusable snapshots show the source status badge instead of a placeholder
  trade date.
- Widget coverage verifies the unavailable wording and date suppression.
- Full validation passed with accepted WARN states only.

## Phase 77 - v6.65 Summary Pending Labels

Status: complete

Objective: make overview summary pending states read like a localized app UI
instead of debug/loading text.

- Replace `syncing` / `checking` pending values with short Chinese labels.
- Keep final source status labels such as `error`, `unavailable`, and
  `live proxy` truthful.
- Add widget coverage for intraday pending state without changing source
  behavior.
- Do not change data fetching, source-status decisions, price history,
  holdings parsing, backtest, position, or AI logic.

Completed in v6.65:

- Pending summary labels now use `同步中`, `連線中`, and `檢查中`.
- Final source labels remain truthful.
- Widget coverage verifies the intraday pending state with a no-intraday fast
  startup fixture.
- Full validation passed with accepted WARN states only.

## Phase 78 - v6.66 Mobile Exposure Strip Cleanup

Status: complete

Objective: remove duplicated and clipped official-exposure text from the phone
overview chart panel.

- Hide the narrow official-exposure summary strip on phone width.
- Keep the price chart visible.
- Keep official holdings visible in the dedicated digest card below the chart.
- Preserve the wider desktop side-by-side exposure panel.
- Add/update widget coverage so the phone overview has holdings digest without
  the clipped exposure strip.
- Do not change holdings calculations, source data, price history, backtest,
  position, or AI logic.

Completed in v6.66:

- Removed the narrow phone-width official-exposure strip below the overview
  chart.
- Removed the now-unused inline exposure strip widgets.
- Kept the wider desktop side-by-side `官方曝險` panel unchanged.
- Updated phone-width widget coverage to require the holdings digest while the
  narrow exposure strip is absent.
- Full validation passed with accepted WARN states only.

## Phase 79 - v6.67 History Chart-First Mobile Layout

Status: complete

Objective: make the history/backtest page show the key chart before detailed
date controls on phone screens.

- Move range chips, current range summary, and price charts before detailed
  start/end date controls.
- Group start/end date controls under a `日期設定` expansion panel.
- Remove duplicate history top badges when code and name are identical.
- Keep split-adjusted price history, backtest formulas, selected ETF behavior,
  position tracking, and AI logic unchanged.

Completed in v6.67:

- The history page now starts with scan-first range controls and charts.
- Detailed date controls live under `日期設定`.
- The history top badge row deduplicates repeated labels.
- Widget tests verify the chart appears before date settings and that date
  controls remain reachable.

## Phase 80 - v6.68 History Top Density

Status: complete

Objective: reduce the top height of the history/backtest page so the chart
appears sooner on phone screens.

- Remove duplicated summary tiles from the top history card.
- Move data-quality details below the price-history chart block.
- Keep range chips, current range summary, and chart as the primary content.
- Preserve price-history data, split adjustment, backtest formulas, position,
  and AI behavior.

Completed in v6.68:

- The history top card no longer repeats four summary tiles.
- `資料品質` now appears below the price-history block.
- Widget tests verify `價格歷史` appears before `資料品質`.

## Phase 81 - v6.69 Position Metric Fit

Status: complete

Objective: make the local position account summary fit phone width without
clipping.

- Replace the compact-phone horizontal metric strip with a 2x2 grid.
- Preserve the wider horizontal layout on larger screens.
- Keep local-only storage, position calculations, export, clear actions, and
  quote source labels unchanged.

Completed in v6.69:

- Position account metrics now wrap into a 2x2 layout on phone width.
- Widget coverage verifies the account summary labels stay within the strip.

## Phase 82 - v6.70 Position Unavailable Wording

Status: complete

Objective: remove raw English fallback text from the local position account
summary on phone screens.

- Show a localized unavailable percentage label when unrealized percentage
  cannot be calculated.
- Keep local-only storage, position calculations, export, clear actions, and
  quote source labels unchanged.
- Add widget coverage for the localized unavailable state.

Completed in v6.70:

- The unrealized result percentage now shows `尚無比例` when the percentage is
  unavailable.
- Widget coverage verifies the phone account summary renders the localized
  state.

## Phase 83 - v6.71 Settings First Screen Cleanup

Status: complete

Objective: make the account/settings tab feel like a user page instead of a
maintenance console on the first screen.

- Keep account, local-only position data, selected ETF, and frontend mode first.
- Move backend persistence and deeper data diagnostics into the existing
  advanced panels.
- Avoid raw technical labels such as `data path not writable` on the first
  settings screen.
- Keep all diagnostics available for maintenance users.

Completed in v6.71:

- The settings header now shows local-only context, selected ETF, and frontend
  mode.
- The daily status metric points users to advanced diagnostics instead of
  showing a scary maintenance state on the first screen.
- Widget coverage verifies technical diagnostics stay out of the first screen.

## Phase 84 - v6.72 Settings Data Mode Caption

Status: complete

Objective: keep the account/settings first screen from surfacing raw backend
error captions in the data-mode card.

- Map backend error or unavailable states to a user-facing static-data fallback
  caption on the settings first screen.
- Keep detailed backend status available in advanced diagnostics.
- Add widget coverage for backend-error settings mode.

Completed in v6.72:

- The settings data-mode card now says static data remains available when the
  backend is unavailable or in error.
- Backend status calculations and deeper diagnostics are unchanged.

## Phase 85 - v6.73 History Chart Axis Cleanup

Status: complete

Objective: make history/backtest chart dates easier to read on mobile.

- Remove duplicate in-chart x-axis date text from the reusable history chart.
- Keep the clearer below-chart start/middle/end date strip and touch detail.
- Preserve price-history data, calculations, selected ETF behavior, and
  backtest formulas.

Completed in v6.73:

- History charts now rely on the dedicated date strip below the chart, avoiding
  overlap between x-axis dates and y-axis labels on phone width.
- Widget coverage for the history chart still verifies the date strip and touch
  detail are present.

## Phase 86 - v6.74 History Range Context Fit

Status: complete

Objective: make the history/backtest range context and mini charts fit phone
width without truncation or layout overflow.

- Wrap the current chart range metric strip into two columns on compact
  screens.
- Keep the wider horizontal range strip for desktop and tablet widths.
- Give compact mini chart cards enough height for their chart, date strip, and
  touch detail.
- Add widget coverage for the compact range-context layout.

Completed in v6.74:

- Phone-width history/backtest range metrics now use a 2-column wrap instead
  of a clipped horizontal strip.
- The compact mini chart grid no longer overflows when chart date strips and
  touch detail are visible.

## Phase 87 - v6.75 AI Answer-First Layout

Status: complete

Objective: make the AI tab read like a daily interpretation page instead of a
status-grid page.

- Route the AI tab to a clean answer-first section.
- Keep the daily rule-based interpretation and program actions visible near
  the top.
- Move source grids, generated-time metadata, matrices, and completeness notes
  into an advanced detail panel.
- Preserve the existing rule-based analysis data and non-instructional scope.

Completed in v6.75:

- The AI page now opens with the daily interpretation and concise summary.
- Detailed AI status cards remain available under `進階 AI 明細`.

## Phase 88 - v6.76 Position First-Screen Trim

Status: complete

Objective: make the position page start with account context and input work
instead of repeated local-only explanation.

- Hide the redundant position page title card.
- Keep account summary, quick actions, and input controls visible.
- Preserve local-only storage, JSON export, and position calculations.
- Update widget coverage for the shorter first screen.

Completed in v6.76:

- The position tab now starts directly with account summary, actions, and input
  controls.

## Phase 89 - v6.77 ETF Gap Reason Alignment

Status: complete

Objective: make ETF data-completion status explain every missing catalog symbol.

- Count catalog-only symbols without local history rows as `not_saved`.
- Include those symbols in `coverageTierCounts.unavailable`.
- Keep data provenance truthful; do not infer or synthesize missing history.
- Add backend unit coverage for the aligned status summary.

Completed in v6.77:

- Local ETF status now reports completionGap=116 with matching gap reasons:
  not_saved=96 and official_empty=20 in the current data state.

## Phase 90 - v6.78 ETF Library Readable Summary

Status: complete

Objective: make ETF data-library completeness readable in the app before
showing detailed maintenance metrics.

- Add a concise ETF data-library summary to the settings ETF panel.
- Show usable history count, missing history count, and classified gap reasons.
- Keep detailed diagnostics available below the summary.
- Keep data eligibility and source parsing unchanged.

Completed in v6.78:

- The settings ETF data-library panel now starts with a readable summary card.
- Widget coverage verifies the classified-gap state with 231 / 347 usable ETF
  histories, official-empty 96, source-error 20, and unclassified 0.

## Phase 91 - v6.79 Settings Compact Summary

Status: complete

Objective: make the settings/account first screen shorter and more app-like.

- Replace the tall overview metric grid with a compact summary card.
- Keep account state, selected ETF, data mode, release version, and daily status
  visible as short badges.
- Keep technical diagnostics and ETF data-library details below the first
  screen.

Completed in v6.79:

- `_SettingsQuickSummaryGrid` now renders a compact summary card keyed as
  `00631l-settings-quick-summary-compact`.
- Widget coverage verifies the compact settings summary remains on the first
  screen while advanced diagnostics stay hidden.

## Phase 92 - v6.80 Search Static ETF Readiness

Status: complete

Objective: make the left-top ETF search sheet use the static-public ETF library
readiness metadata during fast startup.

- Merge static-public ETF library readiness counts into cached fast startup
  operations data when the live backend has not returned ETF-wide readiness yet.
- Prefer live backend readiness when it is more complete than static fallback.
- Keep the fix in the repository layer so widgets do not duplicate fallback
  logic.

Completed in v6.80:

- `Cached00631LRepository` now merges ETF-wide static readiness metadata in the
  same fast-startup path that already merges static 00631L price history.
- Repository coverage verifies ready/missing/gap reason counts are preserved in
  fast startup.

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
