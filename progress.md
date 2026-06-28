# ETF Research Room Progress

## 2026-06-20

- Started next-goal planning after v4.15.
- Read repo status and recent release summaries.
- Confirmed the next implementation slice should prioritize first-screen clarity and chart date/touch behavior before adding broader product scope.
- Added product goal plan and v4.16 release summary.
- Updated the overview chart to use a roughly one-year window with date labels and touch tooltip support.
- Started v4.17 data correctness work.
- Added model-level adjusted-price and non-unit adjustment flags.
- Added the overview `資料正確性` panel and tests.
- Started v4.18 ETF search readiness work.
- Updated the top-left ETF search sheet to show clearer history-ready and catalog-only states.
- Started v4.19 comparison basket clarity work.
- Added guidance that ETF comparison is a 1-5 item user-selected basket and covered chip toggling with a widget test.
- Started v4.20 backtest and position compact UX work.
- Added compact status rows for backtest parameters and local-only position storage status.
- Started v4.21 AI daily clarity work.
- Added AI daily status, source/time, and program-action summary blocks.
- Started v4.22 historical price update reliability work.
- Changed 00631L price-history and static export updates to default incremental mode from the latest cached month.
- Started v4.23 static seed-first export hardening.
- Added CI-like test coverage for empty local cache plus committed seed history before static export update.
- Started v4.24 generic ETF history incremental update work.
- Added per-symbol incremental update starts for ETF price-history imports and verified 0050 incremental refresh.
- Started v4.25 concise ETF status output work.
- Added `--summary-only` for multi-ETF price-history status and switched release check to the concise path.
- Started v4.26 ETF history coverage tier work.
- Added long-term/recent/unavailable/error coverage tier counts across backend status, static export, and frontend operations status.
- Started v4.27 static status tier fallback work.
- Added fallback reading from `etf_price_history_index.json` when an older static manifest lacks ETF coverage tier counts.
- Started v4.28 static export summary output work.
- Added ETF ready rows and coverage tier counts to the static export `[summary]` line.
- Started v4.29 legacy static tier fallback work.
- Added read-only tier derivation from older static ETF price JSON files when manifest/index tier metadata is absent.
- Started v4.30 static tier release guard work.
- Added release-check validation that ready static ETF history must expose usable coverage tier summary metadata.
- Started v4.31 legacy static count reconcile work.
- Made static status derive legacy ETF row/ready counts together with tier counts for consistent maintenance output.

## 2026-06-27

- Resumed after v5.95 (`87f1967`, `00631l-lab-v5.95-public-gap-summary`).
- Current next slice is v5.96: add a missing ETF reason probe and attempted-count metadata so public/static status can show how many missing ETFs have actual import-attempt evidence.
- Error: mistakenly ran `dart format` over Python files. Dart formatter failed parsing Python as expected; rerun formatting only for Dart files.
- Discovery: `scripts\00631l_probe_missing_etf_reasons.cmd --status-only` runs, but the current importer status path only counted saved store codes, so catalog-only missing symbols did not appear in `gapReasonCounts`. v5.96 will fix the status path to include catalog codes when `--from-catalog` is supplied.
- Implemented v5.96 attempted-count plumbing across backend index/static export/public checker/operations status and Flutter model/repositories/UI.
- Added `scripts\00631l_probe_missing_etf_reasons.cmd` and `docs\00631l_v5_96_missing_etf_reason_probe.md`.
- Fixed importer status-only catalog mode; probe status now reports `rowCount=347`, `readyCount=231`, `not_saved=116`, `attemptedCount=0`.
- Validation before commit: `flutter analyze` PASS; `flutter test` PASS (95 tests); `flutter build web` PASS; backend tests PASS (258 tests); `scripts\00631l_release_check.cmd` WARN with failures=0; `git diff --check` PASS.
- v5.96 committed and pushed as `d6a20f6`, tag `00631l-lab-v5.96-missing-etf-reason-probe`.
- Public Pages marker updated to v5.96 and `scripts\00631l_check_public_static_data.cmd --expected-sha d6a20f6 --strict-release` PASS. Public ETF static status: ready 231, catalog 347, missing/not_saved 116, attempted 0.
- Started v5.97 to run a small missing ETF probe in public Pages build before static export.
- Implemented v5.97 Pages missing ETF probe step and local `--probe-missing` helper flag.
- Ran `scripts\00631l_build_pages_static.cmd --probe-missing`: PASS. It probed 20 missing ETF symbols, produced warnings for official empty months, had failures=0, and generated static output with `etfPriceHistoryAttemptedCount=20`.
- v5.97 validation: `flutter analyze` PASS; `flutter test` PASS (95 tests); `flutter build web` PASS; backend tests PASS (258 tests); `scripts\00631l_release_check.cmd` WARN with failures=0; `git diff --check` PASS.
- v5.97 committed and pushed as `d0e87eb`, tag `00631l-lab-v5.97-pages-missing-probe`.
- Public Pages marker updated to v5.97 and strict public static check PASS. Public output now shows `etfPriceHistoryAttemptedCount=20`, `official_empty=20`, `not_saved=94`.
- Started v5.98 after observing that public checker printed catalog rows but not ETF history row count/completion gap, making catalog/history count differences hard to interpret.
- Implemented v5.98 public ETF count consistency output and WARN behavior.
- Public static check now reports `etfPriceHistoryRowCount=345`, `etfCatalogRowCount=343`, `etfPriceHistoryCompletionGap=114`, and WARN/failures=0 for the count mismatch.
- v5.98 validation: `flutter analyze` PASS; `flutter test` PASS (95 tests); `flutter build web` PASS; backend tests PASS (259 tests); `scripts\00631l_release_check.cmd` WARN with failures=0; `git diff --check` PASS.
- Started v5.99 to prevent the public missing-ETF probe from repeatedly checking symbols that already have import-attempt evidence.
- Added `--skip-attempted` to `backend\scripts\import_etf_price_history.py` and wired it into the local probe helper plus GitHub Pages workflow.
- Added importer and static pipeline tests for the skip-attempted behavior.
- Added `docs\00631l_v5_99_skip_attempted_probe.md` and indexed it in README/docs/release-check required artifacts.
- Targeted validation PASS: `py -m unittest backend.tests.test_etf_price_history backend.tests.test_static_pages_pipeline backend.tests.test_release_check`; `scripts\00631l_probe_missing_etf_reasons.cmd --status-only` PASS with ready 231, attempted 20, gap 116.
- Full v5.99 validation PASS/WARN accepted: `flutter analyze` PASS; `flutter test` PASS (95 tests); `flutter build web` PASS; backend tests PASS (261 tests); `scripts\00631l_release_check.cmd` WARN with failures=0; `git diff --check` PASS.
- v5.99 committed/pushed as `34e5f5f`, tag `00631l-lab-v5.99-skip-attempted-probe`.
- Public Pages marker updated to v5.99 and public static check PASS, but public `etfPriceHistoryAttemptedCount` remained 20 (`official_empty=20`, `not_saved=96`). Finding: GitHub Actions runners do not keep the local `_attempts` directory, so public deployments need to restore attempt evidence from the previous static export before probing.
- Started v6.0 public ETF attempt carry-forward.
- Added `backend\scripts\restore_public_etf_attempts.py` and `scripts\00631l_restore_public_etf_attempts.cmd`.
- Updated GitHub Pages workflow to restore public attempt evidence before missing-only ETF imports, and changed missing-only batch helpers to use `--skip-attempted`.
- Added v6.0 tests and docs for public attempt carry-forward.
- Targeted v6.0 validation PASS: `py -m unittest backend.tests.test_public_etf_attempt_restore backend.tests.test_static_pages_pipeline backend.tests.test_release_check`.
- Public restore dry-run PASS: `scripts\00631l_restore_public_etf_attempts.cmd --dry-run` restored 20 public attempt records from the current static index.
- Full v6.0 validation PASS/WARN accepted: `flutter analyze` PASS; `flutter test` PASS (95 tests); `flutter build web` PASS; backend tests PASS (263 tests); `scripts\00631l_release_check.cmd` WARN with failures=0; `git diff --check` PASS.
- v6.0 committed/pushed as `48c8385`, tag `00631l-lab-v6.0-public-attempt-carry-forward`.
- Public Pages marker updated to v6.0 and public static check WARN/failures=0. Attempted count increased to 40, with `official_empty=20`, `source_error=20`, `not_saved=74`.
- Started v6.1 to run three bounded missing-ETF probe batches per Pages deployment.
- Updated Pages workflow and local Pages build helper to run three 20-symbol probe batches with `--skip-attempted`.
- Added `docs\00631l_v6_1_public_probe_batches.md` and release-check/docs index entries.
- Targeted v6.1 validation PASS: `py -m unittest backend.tests.test_static_pages_pipeline backend.tests.test_release_check`.
- Full v6.1 validation PASS/WARN accepted: `flutter analyze` PASS; `flutter test` PASS (95 tests); `flutter build web` PASS; backend tests PASS (263 tests); `scripts\00631l_release_check.cmd` WARN with failures=0; `git diff --check` PASS.
- v6.1 committed/pushed as `d89f554`, tag `00631l-lab-v6.1-public-probe-batches`.
- Public Pages marker updated to v6.1 and public static check PASS. Attempted count increased to 100; `not_saved` dropped to 16; `official_empty=80`; `source_error=20`.
- Started v6.2 to expose the remaining unprobed ETF gap as `etfPriceHistoryUnclassifiedGapCount`.
- Updated public static checker, tests, README, docs index, release-check artifact list, and v6.2 summary.
- Targeted v6.2 validation PASS: `py -m unittest backend.tests.test_public_static_data_check backend.tests.test_release_check`.
- Full v6.2 validation PASS/WARN accepted: `flutter analyze` PASS; `flutter test` PASS (95 tests); `flutter build web` PASS; backend tests PASS (264 tests); `scripts\00631l_release_check.cmd` WARN with failures=0; `git diff --check` PASS.
- v6.2 committed/pushed as `66a8b62`, tag `00631l-lab-v6.2-public-unclassified-gap`.
- Public Pages marker updated to v6.2 and public static check PASS. Attempted count increased to 114; unclassified `not_saved` gap dropped to 2.
- Started v6.3 to add `--max-unclassified-gap` to the public static-data checker.
- Updated checker, tests, README, docs index, release-check artifact list, and v6.3 summary.
- Targeted v6.3 validation PASS: `py -m unittest backend.tests.test_public_static_data_check backend.tests.test_release_check`.
- Full v6.3 validation PASS/WARN accepted: `flutter analyze` PASS; `flutter test` PASS (95 tests); `flutter build web` PASS; backend tests PASS (265 tests); `scripts\00631l_release_check.cmd` WARN with failures=0; `git diff --check` PASS.
- v6.3 committed/pushed as `42974a6`, tag `00631l-lab-v6.3-public-gap-threshold`.
- Public Pages marker updated to v6.3. `scripts\00631l_check_public_static_data.cmd --max-unclassified-gap 0` returned WARN/failures=0 with `etfUnclassified=2`.
- Diagnosed remaining public `not_saved` symbols: `009823` and `009824`. They are not present in the committed seed catalog used by the import/probe step.
- Started v6.4 to import a runtime ETF catalog before Pages ETF price-history imports and use that runtime catalog for missing-only probes.
- Updated Pages workflow and local Pages build helper to import runtime ETF catalog with seed fallback before ETF history refresh/probe work.
- Targeted v6.4 validation PASS: `py -m unittest backend.tests.test_static_pages_pipeline backend.tests.test_release_check`.
- Full v6.4 validation PASS/WARN accepted: `flutter analyze` PASS; `flutter test` PASS (95 tests); `flutter build web` PASS; backend tests PASS (265 tests); `scripts\00631l_release_check.cmd` WARN with failures=0; `git diff --check` PASS.
- Public Pages marker updated to v6.4 and public static check showed all ETF
  gaps classified: `etfPriceHistoryUnclassifiedGapCount=0`, with remaining
  gap reasons split between official empty and source error states.
- Started v6.5 to stop treating retained, classified out-of-catalog history
  rows as a standalone public static-data WARN.
- Updated the public static checker to report
  `etfPriceHistoryOutOfCatalogCount` / compact `etfOutOfCatalog`, while keeping
  WARN behavior when out-of-catalog rows still contain unclassified gaps.
- Added v6.5 docs and release-check required artifact entries.
- Targeted v6.5 validation PASS: `py -m unittest backend.tests.test_public_static_data_check backend.tests.test_release_check`.
- Full v6.5 validation PASS/WARN accepted: `flutter analyze` PASS;
  `flutter test` PASS (95 tests); `flutter build web` PASS; backend tests PASS
  (266 tests); `scripts\00631l_release_check.cmd` WARN with failures=0;
  `git diff --check` PASS.
- Error: PowerShell rejected `&&` as a command separator during tag/push.
  Resolution: run tag and push commands separately.
- v6.5 committed/pushed as `ca1679e`, tag
  `00631l-lab-v6.5-public-catalog-universe`.
- Public Pages marker and public static checks passed on v6.5. Public static
  data reports `etfPriceHistoryUnclassifiedGapCount=0`,
  `etfPriceHistoryOutOfCatalogCount=2`, `official_empty=94`, and
  `source_error=20`.
- Started v6.6 to carry the public ETF library universe metrics into static
  export, backend operations status, Flutter repositories, and app status UI.
- Error: PowerShell file rewrite via `Set-Content` corrupted the Dart screen
  file encoding. Resolution: restored only the affected file from HEAD and
  continued with small `apply_patch` edits.
- Added `etfPriceHistoryOutOfCatalogCount` / `outOfCatalogCount` across static
  export, operations/status, Flutter models, proxy/static/cached repositories,
  and app status details.
- Updated classified-gap handling so unclassified `not_saved` gaps drive probe
  actions, while classified gaps are shown as status evidence.
- Targeted v6.6 validation PASS: `py -m unittest backend.tests.test_price_history_backtest backend.tests.test_public_static_data_check`; `flutter test test\etf_00631l_proxy_repository_test.dart test\etf_00631l_widget_test.dart`.
- Full v6.6 validation PASS/WARN accepted: `flutter analyze` PASS;
  `flutter test` PASS (95 tests); `flutter build web` PASS; backend tests PASS
  (266 tests); `scripts\00631l_release_check.cmd` WARN with failures=0;
  `git diff --check` PASS.
- v6.6 committed/pushed as `8fcbbb2`, tag
  `00631l-lab-v6.6-etf-library-status`.
- Public Pages marker and public static check passed on v6.6. Public static
  data reports ready 232 / rows 347, unclassified gap 0, out-of-catalog 0,
  official empty 95, and source error 20.
- Started v6.7 to make release check enforce `--max-unclassified-gap 0` for the
  public static-data check.
- Initial v6.7 release check found `static_public_regression_guard` failing
  because local ignored static export was older than the public Pages export
  and had one fewer ETF ready row. Fixed the guard so same-release regressions
  still fail, while stale local exports warn and ask for regeneration.
- Targeted v6.7 validation PASS: `py -m unittest
  backend.tests.test_static_public_regression_guard
  backend.tests.test_release_check`; `scripts\00631l_guard_static_public_regression.cmd`
  returns WARN with failures=0 for the stale local export case.
- Full v6.7 validation PASS/WARN accepted: `dart format --set-exit-if-changed .`
  PASS; `flutter analyze` PASS; `flutter test` PASS (95 tests);
  `flutter build web` PASS; backend tests PASS (268 tests);
  `scripts\00631l_release_check.cmd` WARN with failures=0; `git diff --check`
  PASS.
- v6.7 committed/pushed as `2b286bb`, tag
  `00631l-lab-v6.7-public-gap-release-guard`.
- Public Pages marker updated to v6.7 and public static check passed with
  `etfPriceHistoryUnclassifiedGapCount=0`, `etfPriceHistoryOutOfCatalogCount=0`,
  ready 232 / rows 347, official empty 95, and source error 20.
- Started v6.8 to export symbol-level ETF history gap details for public static
  maintenance checks.
- Added `etf_price_history_gaps.json` to static export, manifest/status
  `etfPriceHistoryGapDetailCount`, and public static checker output.
- Targeted v6.8 validation PASS: `py -m unittest
  backend.tests.test_price_history_backtest
  backend.tests.test_public_static_data_check backend.tests.test_release_check`.
- Full v6.8 validation PASS/WARN accepted: `dart format --set-exit-if-changed .`
  PASS; `flutter analyze` PASS; `flutter test` PASS (95 tests);
  `flutter build web` PASS; backend tests PASS (269 tests);
  `scripts\00631l_release_check.cmd` WARN with failures=0; `git diff --check`
  PASS.
- v6.8 committed/pushed as `8098ac8`, tag
  `00631l-lab-v6.8-etf-gap-detail-export`.
- Public Pages marker updated to v6.8 and public static check passed with
  `etfPriceHistoryGapDetailCount=115`, ready 232 / rows 347, unclassified gap 0.
- Started v6.9 to carry gap-detail readiness into backend operations status and
  Flutter app settings.
- Added backend `gapDetailCount`, Flutter `etfPriceHistoryGapDetailCount`,
  repository mappings, and settings UI `缺口明細` text.
- Targeted v6.9 validation PASS: backend ETF history/endpoints/static tests and
  Flutter proxy/widget tests passed. Initial format check changed two Dart files;
  rerun after formatting is required for final validation.
- Full v6.9 validation PASS/WARN accepted: `dart format --set-exit-if-changed .`
  PASS after formatting; `flutter analyze` PASS; `flutter test` PASS (95 tests);
  `flutter build web` PASS; backend tests PASS (269 tests);
  `scripts\00631l_release_check.cmd` WARN with failures=0; `git diff --check`
  PASS.
- Started v6.10 to add compact ETF price-history gap reason samples.
- Added `gapReasonSamples` to backend ETF price-history index, static public
  export/status/manifest, operations/status, Flutter models and repositories,
  app settings status detail, and public static-data check output.
- Error: accidentally ran `dart format` on Python files again. Dart formatter
  rejected Python syntax and did not modify those files. Resolution: reran
  `dart format` only on Dart files.
- Targeted validation PASS: backend ETF price-history/static/public/endpoints
  tests passed, `flutter analyze` passed, and targeted Flutter proxy/widget
  tests passed.
- Full v6.10 validation PASS/WARN accepted: `flutter analyze` PASS,
  `flutter test` PASS (95 tests), `flutter build web` PASS, backend tests PASS
  (269 tests), `scripts\00631l_release_check.cmd` WARN with failures=0, and
  `git diff --check` PASS.
- v6.10 committed/pushed as `4ccfc5f`, tag
  `00631l-lab-v6.10-gap-reason-samples`.
- Public Pages marker updated to v6.10. Strict public static-data check PASS
  with gap samples for `official_empty` and `source_error`.
- Started v6.11 to add a read-only ETF history gap detail endpoint.
- Added `GET /api/etf/history/gaps` with `reason`, `limit`, and `fromCatalog`.
- Targeted backend tests for store gap details and endpoint filtering passed.
- Full v6.11 validation PASS/WARN accepted: `flutter analyze` PASS,
  `flutter test` PASS (95 tests), `flutter build web` PASS, backend tests PASS
  (271 tests), `scripts\00631l_release_check.cmd` WARN with failures=0, and
  `git diff --check` PASS.
- Started v6.12 to bring ETF price-history gap details into the app settings
  page.
- Added red tests for proxy/static repository gap-detail mapping and settings
  UI rows. The first targeted run failed as expected because
  `fetchEtfPriceHistoryGaps`, `EtfPriceHistoryGapDetails`, and
  `EtfPriceHistoryGapDetail` did not exist yet.
- Implemented gap-detail models, live proxy/static/cached/mock repositories,
  an on-demand provider, and the settings `ETF gap details` maintenance panel.
- Targeted v6.12 validation PASS: `flutter test
  test\etf_00631l_proxy_repository_test.dart test\etf_00631l_widget_test.dart`
  passed.
- Full v6.12 validation PASS/WARN accepted: `dart format
  --set-exit-if-changed lib test` PASS, `flutter analyze` PASS,
  `flutter test` PASS (97 tests), `flutter build web` PASS, backend tests PASS
  (271 tests), `scripts\00631l_release_check.cmd` WARN with failures=0, and
  `git diff --check` PASS.
- Started v6.13 to make ETF gap details filterable by reason inside the app
  settings page.
- Added a red widget test for selecting the `source_error` reason. The first
  compile attempt exposed a copied-string test setup error; after fixing the
  setup, the test failed on the missing filter key as expected.
- Implemented local reason filter chips in the `ETF gap details` panel and kept
  filtering client-side only.
- Targeted v6.13 validation PASS: `flutter test
  test\etf_00631l_proxy_repository_test.dart test\etf_00631l_widget_test.dart`
  passed.
- Full v6.13 validation PASS/WARN accepted: `dart format
  --set-exit-if-changed .` PASS, `flutter analyze` PASS, `flutter test` PASS
  (98 tests), `flutter build web` PASS, backend tests PASS (271 tests),
  `scripts\00631l_release_check.cmd` WARN with failures=0, and
  `git diff --check` PASS.
- Started v6.14 to make the ETF/stock search sheet clearer when readiness
  filters are used.
- Added a red widget test for `all`, `ready`, and `catalogOnly` filter counts.
  The test failed on the missing count key as expected.
- Added a visible ETF filtered/candidate count in the search status strip and
  a stable key for widget coverage.
- Targeted v6.14 validation PASS: `flutter test
  test\etf_00631l_widget_test.dart` passed.
- Full v6.14 validation PASS/WARN accepted: `dart format
  --set-exit-if-changed .` PASS, `flutter analyze` PASS, `flutter test` PASS
  (98 tests), `flutter build web` PASS, backend tests PASS (271 tests),
  `scripts\00631l_release_check.cmd` WARN with failures=0, and
  `git diff --check` PASS.
- Started v6.15 to show a query-level ETF readiness mix in the top-left search
  sheet.
- Added a red widget test for `history-ready` and `catalog-only` query count
  keys. It failed on the missing key as expected.
- Added visible query-level `history-ready` and `catalog-only` counts without
  changing filter behavior or ETF eligibility.
- Targeted v6.15 validation PASS: `flutter test
  test\etf_00631l_widget_test.dart` passed.
- Full v6.15 validation PASS/WARN accepted: `dart format
  --set-exit-if-changed .` PASS, `flutter analyze` PASS, `flutter test`
  PASS (98 tests), `flutter build web` PASS, backend tests PASS (271 tests),
  `scripts\00631l_release_check.cmd` WARN with failures=0, and
  `git diff --check` PASS.
- v6.15 committed/pushed as `1b05413`, tag
  `00631l-lab-v6.15-symbol-search-readiness-mix`.
- Public Pages marker updated to v6.15. Strict public static-data check PASS
  with rows 2837, coverage 2014-10-31 to 2026-06-26, ready 232 / rows 347,
  and unclassified ETF gap 0.
- Started v6.16 to show selected ETF capability badges after a symbol is
  chosen.
- Added red widget tests for catalog-only and history-ready selected ETF
  capability badges. The targeted run failed on missing badge keys as expected.
- Added selected ETF capability badges to the overview readiness banner and the
  history/backtest readiness strip.
- Targeted v6.16 validation PASS: `flutter test
  test\etf_00631l_widget_test.dart --name "catalog-only ETF selection shows
  missing history guidance|selecting ETF loads selected ETF history view"`
  passed, then full `flutter test test\etf_00631l_widget_test.dart` passed
  (31 tests).
- Full v6.16 validation PASS/WARN accepted: `dart format
  --set-exit-if-changed .` PASS, `flutter analyze` PASS, `flutter test` PASS
  (98 tests), `flutter build web` PASS, backend tests PASS (271 tests),
  `scripts\00631l_release_check.cmd` WARN with failures=0, and
  `git diff --check` PASS.
- v6.16 committed/pushed as `c2d78aa`, tag
  `00631l-lab-v6.16-selected-etf-capability-badges`.
- Public Pages marker updated to v6.16 by SHA and strict public static-data
  check passed, but the marker showed stale release tag
  `00631l-lab-v5.72-release-metadata-tags`.
- Started v6.17 to fix Pages release metadata when the branch workflow runs
  before the release tag is visible.
- Added red backend tests for Pages tag-trigger coverage and static export
  untagged metadata fallback. They failed on missing tag trigger and stale
  fallback metadata as expected.
- Added Pages tag push trigger, tag-derived release metadata env, and untagged
  static export fallback. Targeted backend tests passed.
- Full v6.17 validation PASS/WARN accepted: `dart format
  --set-exit-if-changed .` PASS, `flutter analyze` PASS, `flutter test` PASS
  (98 tests), `flutter build web` PASS, backend tests PASS (272 tests),
  `scripts\00631l_release_check.cmd` WARN with failures=0, and
  `git diff --check` PASS.
- v6.17 committed/pushed as `f4abf0e`, tag
  `00631l-lab-v6.17-pages-release-tag-trigger`.
- Public Pages marker wait for v6.17 stayed on v6.16 and the tag-triggered run
  failed in the deploy job. The build job passed, but the GitHub Pages
  environment did not accept the tag-ref deployment path.
- Started v6.18 to keep Pages deployment on `main` and poll for the release tag
  before static export.
- Replaced the tag-trigger workflow path with a `Resolve release metadata` step
  that fetches tags, waits briefly for a matching `00631l-lab-v*` tag on HEAD,
  and falls back to untagged metadata if no tag appears.
- Full v6.18 validation PASS/WARN accepted: `dart format
  --set-exit-if-changed .` PASS, `flutter analyze` PASS, `flutter test` PASS
  (98 tests), `flutter build web` PASS, backend tests PASS (272 tests),
  `scripts\00631l_release_check.cmd` WARN with failures=0, and
  `git diff --check` PASS.
- Public Pages marker updated to v6.18 and strict public static-data check
  passed with release tag `00631l-lab-v6.18-pages-release-tag-polling`.
- Started v6.19 to align the Pages deploy status checker with the v6.18
  main-branch tag polling release flow.
- Added a regression test for stale/cancelled workflow noise when the public
  release marker already matches the expected HEAD.
- Updated the deploy status checker to pass expected SHA into public Pages
  smoke checks and summarize public release marker metadata.
