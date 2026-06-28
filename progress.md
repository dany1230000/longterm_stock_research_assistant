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
- v6.19 validation PASS/WARN accepted: `dart format --set-exit-if-changed .`
  PASS, `flutter analyze` PASS, `flutter test` PASS (98 tests),
  `flutter build web` PASS, backend tests PASS (273 tests),
  `scripts\00631l_release_check.cmd` WARN with failures=0, and
  `git diff --check` PASS.
- v6.19 committed/pushed as `82947d3`, tag
  `00631l-lab-v6.19-pages-deploy-status-alignment`.
- Public Pages marker and strict public static-data checks passed on v6.19.
- Started v6.20 to make the top-left ETF search rank exact code and
  history-ready matches before looser catalog matches.
- Added a widget test for code-match ranking and a visible rank contract through
  hidden keys.
- Full v6.20 validation passed, v6.20 committed/pushed as `0b65726`, tag
  `00631l-lab-v6.20-symbol-search-ranking`. Public Pages marker and strict
  public static-data checks passed on v6.20.
- Started v6.21 to clarify ETF comparison readiness when selected or basket
  symbols have insufficient price-history rows.
- Added comparison readiness metadata for candidate, comparison-ready, and
  skipped rows.
- Added a widget test that selects a catalog-only ETF and verifies it is shown
  as skipped instead of being used in the comparison chart.
- v6.21 validation PASS/WARN accepted: `dart format --set-exit-if-changed .`
  PASS after formatting one test file; `flutter analyze` PASS; `flutter test`
  PASS (100 tests); `flutter build web` PASS; backend tests PASS (273 tests);
  `scripts\00631l_release_check.cmd` WARN with failures=0; `git diff --check`
  PASS.
- v6.21 committed/pushed as `1fe7c57`, tag
  `00631l-lab-v6.21-comparison-readiness`. Public Pages marker and strict
  public static-data checks passed on v6.21.
- Started v6.22 to show compact skipped-row reason details in the ETF
  comparison panel.
- Added skipped-row detail chips showing code, active-range rows, and source
  status.
- v6.22 validation PASS/WARN accepted: `dart format --set-exit-if-changed .`
  PASS after formatting two Dart files; `flutter analyze` PASS; `flutter test`
  PASS (100 tests); `flutter build web` PASS; backend tests PASS (273 tests);
  `scripts\00631l_release_check.cmd` WARN with failures=0; `git diff --check`
  PASS.
- v6.22 committed/pushed as `f13fb19`, tag
  `00631l-lab-v6.22-comparison-skipped-details`. Public Pages marker and strict
  public static-data checks passed on v6.22.
- Started v6.23 to compact comparison action controls for mobile.
- Updated comparison actions to a horizontal scroll strip and added widget
  coverage for the strip key.
- v6.23 validation PASS/WARN accepted: `dart format --set-exit-if-changed .`
  PASS after formatting one test file; `flutter analyze` PASS; `flutter test`
  PASS (100 tests); `flutter build web` PASS; backend tests PASS (273 tests);
  `scripts\00631l_release_check.cmd` WARN with failures=0; `git diff --check`
  PASS.
- v6.23 committed/pushed as `89281f8`, tag
  `00631l-lab-v6.23-compact-comparison-controls`. Public Pages marker and
  strict public static-data checks passed on v6.23.
- Started v6.24 to shorten comparison guidance and keep readiness data closer
  to the chart.
- Replaced the long comparison guidance line with a compact data-rule hint and
  updated widget coverage.
- v6.24 validation PASS/WARN accepted: `dart format --set-exit-if-changed .`
  PASS after formatting two Dart files; `flutter analyze` PASS; `flutter test`
  PASS (100 tests); `flutter build web` PASS; backend tests PASS (273 tests);
  `scripts\00631l_release_check.cmd` WARN with failures=0; `git diff --check`
  PASS.
- Started v6.25 after Playwright inspection showed the first public screen was
  still dominated by the pre-Flutter `web/index.html` loading card.
- Replaced the public web loading card with a compact app-like shell and added
  Flutter loading skeleton keys for status, quote, metrics, and section content.
- v6.25 validation PASS/WARN accepted: `dart format --set-exit-if-changed .`
  PASS; `flutter analyze` PASS; `flutter test` PASS (101 tests);
  `flutter build web` PASS; backend tests PASS (273 tests);
  `scripts\00631l_release_check.cmd` WARN with failures=0; `git diff --check`
  PASS. Playwright mobile screenshots verified compact loading and loaded root
  states; generated screenshots were removed.
- Started v6.26 after the v6.25 loaded mobile screenshot showed the overview
  sparkline end-date label was still too close to the right edge.
- Added overview chart x-axis edge padding plus start/mid/end date alignment
  helpers and widget keys for start/end date ticks.
- v6.26 validation PASS/WARN accepted: `dart format --set-exit-if-changed .`
  PASS; `flutter analyze` PASS; `flutter test` PASS (101 tests);
  `flutter build web` PASS; backend tests PASS (273 tests);
  `scripts\00631l_release_check.cmd` WARN with failures=0; `git diff --check`
  PASS. Playwright mobile screenshot verified the end-date label is no longer
  clipped; generated screenshots were removed.
- Started v6.27 to reduce first-screen vertical weight after reviewing the
  overview screenshot.
- Changed the overview core metrics from a 2x2 grid to a horizontal compact
  strip and added widget coverage for the strip key.
- v6.27 validation PASS/WARN accepted: `dart format --set-exit-if-changed .`
  PASS; `flutter analyze` PASS; `flutter test` PASS (101 tests);
  `flutter build web` PASS; backend tests PASS (273 tests);
  `scripts\00631l_release_check.cmd` WARN with failures=0; `git diff --check`
  PASS. Playwright mobile screenshot verified a shorter core-data block; the
  screenshot artifact was removed.
- Started v6.28 to make the AI page open with a compact daily interpretation.
- Added a `今日 AI 判讀` hero card that groups holdings date, intraday NAV time,
  source status, TX/TSMC weights, premium-discount context, and the first
  program action while keeping detailed panels below it.
- v6.28 validation PASS/WARN accepted: `dart format --set-exit-if-changed .`
  PASS; `flutter analyze` PASS; `flutter test` PASS (101 tests);
  `flutter build web` PASS; backend tests PASS (273 tests);
  `scripts\00631l_release_check.cmd` WARN with failures=0; `git diff --check`
  PASS.
- Started v6.29 to reduce the position page height on phone screens.
- Changed the local-only position account metrics to a horizontal compact strip
  and added widget coverage for the new strip key.
- v6.29 validation PASS/WARN accepted: `dart format --set-exit-if-changed .`
  PASS; `flutter analyze` PASS; `flutter test` PASS (101 tests);
  `flutter build web` PASS; backend tests PASS (273 tests);
  `scripts\00631l_release_check.cmd` WARN with failures=0; `git diff --check`
  PASS.
- Started v6.30 to improve the history/backtest chart touch-detail test hook.
- Added a stable `00631l-line-chart-touch-detail` key and widget coverage so
  date/value interaction can be polished safely in follow-up slices.
- v6.30 validation PASS/WARN accepted: `dart format --set-exit-if-changed .`
  PASS; `flutter analyze` PASS; `flutter test` PASS (101 tests);
  `flutter build web` PASS; backend tests PASS (273 tests);
  `scripts\00631l_release_check.cmd` WARN with failures=0; `git diff --check`
  PASS.
- Public v6.30 strict static-data check PASS for
  `00631l-lab-v6.30-chart-touch-detail-key` with rowCount 2837, coverage
  2014-10-31 to 2026-06-26, and unclassified ETF gap 0.
- Started v6.31 to make history/backtest chart date labels and touch details
  easier to read on narrow phone screens.
- Added compact bordered axis-label chips with stable start/middle/end keys and
  changed chart touch detail into primary/secondary lines.
- Added widget coverage for the new chart-axis and touch-detail line keys.
- Initial targeted test command used the wrong test-name filter and ran zero
  tests; reran the correct `history section shows price history when available`
  widget test and it passed.
- v6.31 full validation PASS/WARN accepted: `dart format
  --set-exit-if-changed .` PASS after formatting two Dart files;
  `flutter analyze` PASS; `flutter test` PASS (101 tests);
  `flutter build web` PASS; backend tests PASS (273 tests);
  `scripts\00631l_release_check.cmd` WARN with failures=0; `git diff --check`
  PASS.
- v6.31 committed/pushed as `e39bc94`, tag
  `00631l-lab-v6.31-history-chart-date-labels`.
- Public Pages marker and strict public static-data checks passed on v6.31.
- Started v6.32 to make the history/backtest date controls clearer on mobile.
- Added a compact active-range summary above start/end date buttons and shared
  it across history and backtest.
- Targeted widget tests for history price history and backtest inputs passed.
- v6.32 full validation PASS/WARN accepted: `dart format
  --set-exit-if-changed .` PASS; `flutter analyze` PASS; `flutter test`
  PASS (101 tests); `flutter build web` PASS; backend tests PASS (273 tests);
  `scripts\00631l_release_check.cmd` WARN with failures=0; `git diff --check`
  PASS.
- v6.32 committed/pushed as `a2dd000`, tag
  `00631l-lab-v6.32-compact-date-range-controls`.
- Public Pages marker and strict public static-data checks passed on v6.32.
- Started v6.33 to compact the local-only position action area.
- Replaced the wrapped save/export/clear action bar with a horizontal quick
  action strip and stable per-action keys.
- Targeted position widget test passed.
- v6.33 full validation PASS/WARN accepted: `dart format
  --set-exit-if-changed .` PASS; `flutter analyze` PASS; `flutter test`
  PASS (101 tests); `flutter build web` PASS; backend tests PASS (273 tests);
  `scripts\00631l_release_check.cmd` WARN with failures=0; `git diff --check`
  PASS.
- v6.33 committed/pushed as `49faacf`, tag
  `00631l-lab-v6.33-position-quick-actions`.
- Public Pages marker and strict public static-data checks passed on v6.33.
- Started v6.34 to make the AI page more answer-first.
- Added the first two rule-based analysis bullets to the top AI daily briefing
  card and covered the new area with a widget test.
- Targeted AI widget test passed.
- v6.34 full validation PASS/WARN accepted: `dart format
  --set-exit-if-changed .` PASS; `flutter analyze` PASS; `flutter test`
  PASS (101 tests); `flutter build web` PASS; backend tests PASS (273 tests);
  `scripts\00631l_release_check.cmd` WARN with failures=0; `git diff --check`
  PASS.
- Started v6.35 to improve first-screen overview clarity.
- Added a compact overview daily summary strip below the quote header. It groups
  frontend mode, official daily holdings date, intraday NAV time,
  premium/discount status, history coverage, and the first rule-based AI brief.
- Targeted overview widget tests passed.
- v6.35 full validation PASS/WARN accepted: `dart format
  --set-exit-if-changed .` PASS after formatting two Dart files;
  `flutter analyze` PASS; `flutter test` PASS (101 tests);
  `flutter build web` PASS; backend tests PASS (273 tests);
  `scripts\00631l_release_check.cmd` WARN with failures=0; `git diff --check`
  PASS.
- v6.35 committed/pushed as `8ca8a31`, tag
  `00631l-lab-v6.35-overview-daily-summary-strip`.
- Public Pages marker and strict public static-data checks passed on v6.35.
- Started v6.36 to reduce duplicate overview header information.
- Hid the 00631L quote meta strip because the new daily summary strip now shows
  the same NAV/session/history context.
- Targeted quote-header and phone-width widget tests passed after updating the
  old quote-meta expectations.
- v6.36 full validation PASS/WARN accepted: `dart format
  --set-exit-if-changed .` PASS; `flutter analyze` PASS; `flutter test`
  PASS (101 tests); `flutter build web` PASS; backend tests PASS (273 tests);
  `scripts\00631l_release_check.cmd` WARN with failures=0; `git diff --check`
  PASS.
- v6.36 committed/pushed as `7937e77`, tag
  `00631l-lab-v6.36-compact-quote-header`.
- Public Pages marker and strict public static-data checks passed on v6.36.
- Playwright mobile screenshot confirmed the chart reaches the first screen, but
  the `今日摘要` header still used a long truncated mode/AI sentence.
- Started v6.37 to move frontend mode into a compact badge and keep AI as a
  short summary chip.
- v6.37 target widget tests passed.
- v6.37 full validation PASS/WARN accepted: `dart format
  --set-exit-if-changed .` PASS; `flutter analyze` PASS; `flutter test`
  PASS (101 tests); `flutter build web` PASS; backend tests PASS (273 tests);
  `scripts\00631l_release_check.cmd` WARN with failures=0; `git diff --check`
  PASS.
- Started v6.38 after Playwright inspection showed the fast-start overview
  summary strip could briefly show `error` / `unavailable` before full live and
  static data finished loading.
- Passed `detailsLoading` into the overview daily summary strip and changed the
  transient startup labels to `loading` / `pending` while preserving real source
  labels after full data arrives.
- Added widget coverage for the fast-start summary strip and documented the
  release in README/docs index.
- v6.38 validation PASS/WARN accepted: `dart format --set-exit-if-changed .`
  PASS; `flutter analyze` PASS; `flutter test` PASS (101 tests);
  `flutter build web` PASS; backend tests PASS (273 tests);
  `scripts\00631l_release_check.cmd` WARN with failures=0; `git diff --check`
  PASS.
- v6.38 committed/pushed as `da2e69d`, tag
  `00631l-lab-v6.38-fast-summary-loading-state`.
- Public Pages marker and strict public static-data checks passed on v6.38.
- Started v6.39 after mobile screenshot inspection showed the 00631L-only
  `核心資料` card repeated quote/daily-summary/chart data and compressed the
  first screen.
- Removed the duplicated 00631L overview core-data card while keeping selected
  non-00631L core-data panels.
- Targeted v6.39 widget tests passed after switching assertions from the removed
  card to the stable visible chart/title anchors.
- Error: PowerShell rejected `&&` again while chaining format/test commands.
  Resolution: ran the commands separately.
- v6.39 validation PASS/WARN accepted: `dart format --set-exit-if-changed .`
  PASS; `flutter analyze` PASS; `flutter test` PASS (101 tests);
  `flutter build web` PASS; backend tests PASS (273 tests);
  `scripts\00631l_release_check.cmd` WARN with failures=0; `git diff --check`
  PASS.
- v6.39 committed/pushed as `c9964ca`, tag
  `00631l-lab-v6.39-overview-duplicate-core-cleanup`.
- Public Pages marker and strict public static-data checks passed on v6.39.
- Started v6.40 after v6.39 mobile inspection showed the official holdings
  digest still used tall cards; changed it to a compact horizontal strip for
  TX, TSMC, and stock/futures/cash mix.
- Targeted holdings-digest widget test passed.
- v6.40 validation PASS/WARN accepted: `dart format --set-exit-if-changed .`
  PASS; `flutter analyze` PASS; `flutter test` PASS (101 tests);
  `flutter build web` PASS; backend tests PASS (273 tests);
  `scripts\00631l_release_check.cmd` WARN with failures=0; `git diff --check`
  PASS.
- v6.40 committed/pushed as `b3e6520`, tag
  `00631l-lab-v6.40-compact-holdings-digest`.
- Public Pages marker and strict public static-data checks passed on v6.40.
- Started v6.41 after mobile screenshot inspection showed `今日摘要` still had
  duplicated P/D and AI chips plus raw `twse_a_k_json` text.
- Simplified `今日摘要` to DAY / LIVE / HIS and mapped intraday source contracts
  to user-facing labels.
- Targeted fast-start widget test passed.
- v6.41 validation PASS/WARN accepted: `dart format --set-exit-if-changed .`
  PASS; `flutter analyze` PASS; `flutter test` PASS (101 tests);
  `flutter build web` PASS; backend tests PASS (273 tests);
  `scripts\00631l_release_check.cmd` WARN with failures=0; `git diff --check`
  PASS.
- Started v6.42 after confirming history/backtest quick range controls existed
  but did not show selected state.
- Added selected-state date-range chips for history and backtest while keeping
  the latest one-year default and manual start/end date controls.
- Error: the first targeted widget assertion cast the wrapper
  `_RangeActionChip` to `ChoiceChip`. Resolution: assert the descendant
  `ChoiceChip` inside the keyed wrapper.
- Error: short fixture history made a 3-year clamped range look identical to
  all data. Resolution: classify one-year first, full coverage second, and
  three-year third so the explicit all-data range is labeled truthfully.
- Targeted v6.42 widget tests passed for history price history and backtest
  inputs.
- v6.42 validation PASS/WARN accepted: `dart format --set-exit-if-changed .`
  PASS; `flutter analyze` PASS; `flutter test` PASS (101 tests);
  `flutter build web` PASS; backend tests PASS (273 tests);
  `scripts\00631l_release_check.cmd` WARN with failures=0; `git diff --check`
  PASS.
- Started v6.43 after public mobile screenshot inspection showed the overview
  `HIS` summary chip was clipped off the right edge at 390px width.
- Changed overview daily summary from a horizontal scroll strip to a fixed
  three-column DAY/LIVE/HIS grid.
- Shortened the LIVE value to time-only and HIS to row-count plus coverage
  years so the first screen remains readable.
- Targeted phone-width widget test passed and verifies DAY/LIVE/HIS remain
  inside the summary card.
- v6.43 validation PASS/WARN accepted: `dart format --set-exit-if-changed .`
  PASS; `flutter analyze` PASS; `flutter test` PASS (101 tests);
  `flutter build web` PASS; backend tests PASS (273 tests);
  `scripts\00631l_release_check.cmd` WARN with failures=0; `git diff --check`
  PASS.
- Started v6.44 after v6.43 mobile screenshot confirmed the DAY/LIVE/HIS
  summary fit, but the official holdings `MIX` tile was still partially clipped.
- Changed the overview official holdings digest from horizontal scrolling to a
  fixed three-cell row.
- Shortened the third tile label to `股 / 期 / 現金` and let long percentages
  scale down inside the tile.
- Targeted phone-width widget test passed and verifies TX, 2330, and MIX stay
  inside the digest row.
- v6.44 validation PASS/WARN accepted: `dart format --set-exit-if-changed .`
  PASS; `flutter analyze` PASS; `flutter test` PASS (101 tests);
  `flutter build web` PASS; backend tests PASS (273 tests);
  `scripts\00631l_release_check.cmd` WARN with failures=0; `git diff --check`
  PASS.
- Started v6.45 after the v6.44 mobile screenshot showed the holdings digest
  no longer clipped but the TSMC and MIX titles still used ellipsis.
- Shortened holdings digest titles to `期貨`, `台積電`, and `股期現金` while
  keeping TX / 2330 / MIX badges.
- Targeted holdings digest widget test passed.
- v6.45 validation PASS/WARN accepted: `dart format --set-exit-if-changed .`
  PASS; `flutter analyze` PASS; `flutter test` PASS (101 tests);
  `flutter build web` PASS; backend tests PASS (273 tests);
  `scripts\00631l_release_check.cmd` WARN with failures=0; `git diff --check`
  PASS.
- v6.45 public marker and strict public static-data checks passed. Public
  release marker reports rowCount 2837 and coverage 2014-10-31 to 2026-06-26.
- Playwright mobile screenshot confirmed the overview DAY/LIVE/HIS summary and
  holdings digest labels fit after v6.45.
- Started v6.46 after the next UX bottleneck was identified as history/backtest
  first-screen density.
- Error: attempted to run a one-off Node Playwright script with `require("playwright")`;
  the repo does not install Playwright as a Node module. The same error repeated
  through `npx -p playwright node`. Resolution: stop repeating that path and
  rely on code/widget inspection plus CLI screenshots where available.
- Implemented a compact history/backtest top strip and moved detailed
  price-history quality notes into an expandable `資料品質` panel.
- Targeted history widget test passed after the UI change.
- Initial full Flutter test failed because selected-ETF tests still expected
  split-adjustment details while the new quality panel was collapsed. Resolution:
  tests now expand `資料品質` before checking those details, and the search button
  is brought back into view before the same test opens search again.
- v6.46 validation PASS/WARN accepted: `dart format --set-exit-if-changed .`
  PASS; `flutter analyze` PASS; `flutter test` PASS (101 tests);
  `flutter build web` PASS; backend tests PASS (273 tests);
  `scripts\00631l_release_check.cmd` WARN with failures=0; `git diff --check`
  PASS.
- v6.46 committed/pushed as `7b72f1b`, tag
  `00631l-lab-v6.46-history-backtest-top-compact`.
- Public Pages marker and strict public static-data check passed on v6.46.
- Started v6.47 to compact the local position page empty state.
- Replaced the large no-position empty panel with a compact hint strip and
  added widget coverage.
- v6.47 validation PASS/WARN accepted: `dart format --set-exit-if-changed .`
  PASS; `flutter analyze` PASS; `flutter test` PASS (101 tests);
  `flutter build web` PASS; backend tests PASS (273 tests);
  `scripts\00631l_release_check.cmd` WARN with failures=0; `git diff --check`
  PASS.
- v6.47 committed/pushed as `d59245e`, tag
  `00631l-lab-v6.47-position-empty-hint-compact`.
- Public Pages marker and strict public static-data check passed on v6.47.
- Started v6.48 to make AI daily briefing facts fit one phone-width row.
- Changed the AI hero fact cards to render as a compact three-cell row on
  phone width and added widget coverage.
- v6.48 validation PASS/WARN accepted: `dart format --set-exit-if-changed .`
  PASS; `flutter analyze` PASS; `flutter test` PASS (102 tests);
  `flutter build web` PASS; backend tests PASS (273 tests);
  `scripts\00631l_release_check.cmd` WARN with failures=0; `git diff --check`
  PASS.
- v6.48 committed/pushed as `438f669`, tag
  `00631l-lab-v6.48-ai-fact-row-compact`.
- Public Pages marker and strict public static-data check passed on v6.48.
- Started v6.49 to remove duplicated backtest result cards and keep the
  backtest result summary in one compact strip.
- Error: PowerShell blocked `npx.ps1` under the current execution policy while
  taking a screenshot. Resolution: use `npx.cmd` for Playwright CLI commands.
- Added annualized return and volatility to the backtest quick result strip,
  added a stable key, removed the duplicated 2x2 result grid, and updated
  widget coverage.
- v6.49 validation PASS/WARN accepted: `dart format --set-exit-if-changed .`
  PASS; `flutter analyze` PASS; `flutter test` PASS (102 tests);
  `flutter build web` PASS; backend tests PASS (273 tests);
  `scripts\00631l_release_check.cmd` WARN with failures=0; `git diff --check`
  PASS.
- v6.49 committed/pushed as `b3d09e2`, tag
  `00631l-lab-v6.49-backtest-result-compact`.
- Public Pages marker and strict public static-data check passed on v6.49.
- Started v6.50 to shorten the AI page first screen by moving detailed snapshot
  and interpretation cards into the advanced AI detail panel.
- Targeted AI widget test passed after verifying detail cards are hidden before
  expansion and visible after expansion.
- v6.50 validation PASS/WARN accepted: `dart format --set-exit-if-changed .`
  PASS; `flutter analyze` PASS; `flutter test` PASS (102 tests);
  `flutter build web` PASS; backend tests PASS (273 tests);
  `scripts\00631l_release_check.cmd` WARN with failures=0; `git diff --check`
  PASS.
- Started v6.51 to reduce the local position page form length on phone
  screens.
- Moved optional total-assets, fee, and note inputs into an advanced position
  fields panel while keeping share count and average cost visible.
- Targeted position widget test passed after verifying optional fields are
  hidden before expansion and visible after opening the panel.
- v6.51 validation PASS/WARN accepted: `dart format --set-exit-if-changed .`
  PASS; `flutter analyze` PASS; `flutter test` PASS (102 tests);
  `flutter build web` PASS; backend tests PASS (273 tests);
  `scripts\00631l_release_check.cmd` WARN with failures=0; `git diff --check`
  PASS.
- Started v6.52 after the public phone screenshot showed the first-screen
  DAY/LIVE/HIS row still displayed generic `loading` text while history was
  already visible.
- Replaced the fast-start summary labels with `syncing`, `checking`, and
  visible static history counts so the first screen reads as background refresh
  rather than a stuck load.
- Targeted fast-start widget test passed.
- v6.52 validation PASS/WARN accepted: `dart format --set-exit-if-changed .`
  PASS; `flutter analyze` PASS; `flutter test` PASS (102 tests);
  `flutter build web` PASS; backend tests PASS (273 tests);
  `scripts\00631l_release_check.cmd` WARN with failures=0; `git diff --check`
  PASS.
- Started v6.53 after the public v6.52 phone screenshot still showed clipped
  DAY/LIVE/HIS captions.
- Shortened the fast-start DAY and LIVE captions and added a compact history
  coverage year format for the overview summary row.
- Error: initial v6.53 analyze found the old `_summaryCoverageYears` helper was
  unused after the compact coverage helper took over. Resolution: removed the
  unused helper and reran analyze successfully.
- v6.53 validation PASS/WARN accepted: `dart format --set-exit-if-changed .`
  PASS; `flutter analyze` PASS; `flutter test` PASS (102 tests);
  `flutter build web` PASS; backend tests PASS (273 tests);
  `scripts\00631l_release_check.cmd` WARN with failures=0; `git diff --check`
  PASS.
- Started v6.54 after the v6.53 phone screenshot showed the first-screen
  refresh banner was still a long loading-style sentence above the quote card.
- Shortened the fast-first-screen banner to a compact background-refresh status
  and kept fallback wording truthful.
- Error: the first v6.54 text replacement missed the ternary comma in
  `_DetailsLoadStateStrip`. Resolution: added the comma and reran the targeted
  test successfully.
- Error: full Flutter test still expected the previous long fallback wording.
  Resolution: updated the assertion to verify fallback visibility instead of a
  brittle long sentence.
- v6.54 validation PASS/WARN accepted: `dart format --set-exit-if-changed .`
  PASS; `flutter analyze` PASS; `flutter test` PASS (102 tests);
  `flutter build web` PASS; backend tests PASS (273 tests);
  `scripts\00631l_release_check.cmd` WARN with failures=0; `git diff --check`
  PASS.
- Started v6.55 after the public v6.54 phone screenshot showed the quote header
  title as `00631L 00631L`.
- Added a display fallback so 00631L uses the profile name when history only
  supplies the code as the name.
- v6.55 validation PASS/WARN accepted: `dart format --set-exit-if-changed .`
  PASS; `flutter analyze` PASS; `flutter test` PASS (102 tests);
  `flutter build web` PASS; backend tests PASS (273 tests);
  `scripts\00631l_release_check.cmd` WARN with failures=0; `git diff --check`
  PASS.
- v6.55 committed/pushed as `be1cb26`, tag
  `00631l-lab-v6.55-quote-title-name`; public marker and strict public static
  data checks passed.
- Started v6.56 after the public mobile screenshot showed the overview trend
  card still displayed `unavailable` during live-proxy background refresh even
  though static public price history was already available.
- Implemented fast-start data merging in `Cached00631LRepository` so static
  public price history overlays live fast data when live price history is still
  deferred or unavailable.
- Added a repository regression test for the fast static-history overlay path.
- Targeted repository test passed: `flutter test
  test\etf_00631l_proxy_repository_test.dart`.
- v6.56 validation PASS/WARN accepted: `dart format --set-exit-if-changed .`
  PASS; `flutter analyze` PASS; `flutter test` PASS (103 tests);
  `flutter build web` PASS; backend tests PASS (273 tests);
  `scripts\00631l_release_check.cmd` WARN with failures=0; `git diff --check`
  PASS.
- v6.56 committed/pushed as `0f0e7a0`, tag
  `00631l-lab-v6.56-fast-static-history-overlay`; public marker and strict
  static data checks passed.
- Playwright mobile screenshot verified the overview chart now displays static
  history instead of `unavailable` during background refresh.
- Started v6.57 after the same screenshot showed the holdings digest rendering
  zero/unavailable values from an unusable snapshot.
- Added a holdings snapshot usability guard and compact unavailable state.
- Added widget coverage that the overview hides holdings digest tiles when the
  snapshot is unavailable.
- Targeted widget test passed: `flutter test
  test\etf_00631l_widget_test.dart --name "overview hides holdings digest when
  snapshot is unavailable"`.
- Error: first full v6.57 validation failed because the existing holdings
  digest widget test still expected the previous holdings subtitle text.
  Resolution: updated the test to assert the new unavailable-state key is absent
  when valid holdings digest data is present, then reran the targeted tests.
- v6.57 validation PASS/WARN accepted: `dart format --set-exit-if-changed .`
  PASS; `flutter analyze` PASS; `flutter test` PASS (104 tests);
  `flutter build web` PASS; backend tests PASS (273 tests);
  `scripts\00631l_release_check.cmd` WARN with failures=0; `git diff --check`
  PASS.
- v6.57 committed/pushed as `bdc7359`, tag
  `00631l-lab-v6.57-holdings-unavailable-state`; public marker and strict
  static data checks passed.
- Playwright mobile screenshot verified the holdings panel now shows a compact
  unavailable state instead of 0-value digest tiles.
- Started v6.58 after the public screenshot showed the quote card title still
  using a long 00631L fund name that truncates on phone width.
- Changed the 00631L quote card title to `00631L 元大台灣50正2` while leaving
  non-00631L selected ETF titles data-driven.
- Targeted quote-header widget test passed.
- v6.58 validation PASS/WARN accepted: `dart format --set-exit-if-changed .`
  PASS; `flutter analyze` PASS; `flutter test` PASS (104 tests);
  `flutter build web` PASS; backend tests PASS (273 tests);
  `scripts\00631l_release_check.cmd` WARN with failures=0; `git diff --check`
  PASS.
- v6.58 committed/pushed as `035fe53`, tag
  `00631l-lab-v6.58-compact-quote-short-name`; public marker and strict
  static data checks passed.
- Playwright mobile screenshot verified the compact title fits, and identified
  the remaining first-screen noise: the background-refresh banner appears even
  when quote, chart, and holdings context are already visible.
- Started v6.59 to hide the normal background-refresh banner when first-screen
  data is already usable, while keeping fallback/error status visible.
- Targeted fast-start widget test passed after adding the first-screen usability
  guard.
- v6.59 validation PASS/WARN accepted: `dart format --set-exit-if-changed .`
  PASS; `flutter analyze` PASS; `flutter test` PASS (104 tests);
  `flutter build web` PASS; backend tests PASS (273 tests);
  `scripts\00631l_release_check.cmd` WARN with failures=0; `git diff --check`
  PASS.
- v6.59 committed/pushed as `bbd3207`, tag
  `00631l-lab-v6.59-first-screen-refresh-quiet-state`; public marker and strict
  static data checks passed.
- Playwright mobile screenshot verified the background-refresh banner is gone,
  and identified a remaining source-label issue: the 00631L quote premium box
  can show a catalog/static reference value while intraday NAV is unavailable.
- Started v6.60 to make the 00631L quote premium box use intraday NAV only.
- Targeted widget test passed for the no-intraday NAV quote premium guard.
- v6.60 validation PASS/WARN accepted: `dart format --set-exit-if-changed .`
  PASS; `flutter analyze` PASS; `flutter test` PASS (105 tests);
  `flutter build web` PASS; backend tests PASS (273 tests);
  `scripts\00631l_release_check.cmd` WARN with failures=0; `git diff --check`
  PASS.
- v6.60 committed/pushed as `28683e1`, tag
  `00631l-lab-v6.60-quote-premium-source-guard`; public marker and strict
  static data checks passed.
- Playwright mobile screenshot verified the quote premium box is source-guarded,
  and identified that DAY/LIVE still used generic syncing/checking labels even
  when usable date/time values were present.
- Started v6.61 to show available DAY/LIVE/HIS values during background
  refresh and reserve syncing/checking for missing items only.
- Targeted fast-start widget test passed for the updated summary row behavior.
- v6.61 validation PASS/WARN accepted: `dart format --set-exit-if-changed .`
  PASS; `flutter analyze` PASS; `flutter test` PASS (105 tests);
  `flutter build web` PASS; backend tests PASS (273 tests);
  `scripts\00631l_release_check.cmd` WARN with failures=0; `git diff --check`
  PASS.
- v6.61 committed/pushed as `dc56515`, tag
  `00631l-lab-v6.61-summary-available-values`; public marker and strict static
  data checks passed.
- Playwright mobile screenshot found the overview exposure strip could still
  show 0% stock/futures/cash values when the holdings snapshot was invalid.
- Started v6.62 to hide the overview exposure strip unless holdings are usable.
- Targeted holdings widget tests passed for valid and unavailable exposure strip
  states.
- v6.62 validation PASS/WARN accepted: `dart format --set-exit-if-changed .`
  PASS; `flutter analyze` PASS; `flutter test` PASS (105 tests);
  `flutter build web` PASS; backend tests PASS (273 tests);
  `scripts\00631l_release_check.cmd` WARN with failures=0; `git diff --check`
  PASS.
- v6.62 committed/pushed as `2fc7772`, tag
  `00631l-lab-v6.62-exposure-unavailable-guard`; public marker and strict
  static-data checks passed.
- Playwright mobile screenshot confirmed the zero-value exposure strip is gone.
  Started v6.63 after the same screenshot showed DAY/LIVE summary chips could
  still use background-sync wording despite a known source error/unavailable
  state.
- v6.63 now prioritizes explicit error/unavailable summary states over
  `syncing`/`checking` wording for known final source states.
- Targeted v6.63 widget test passed for fast startup with a known holdings
  error.
- v6.63 validation PASS/WARN accepted: `dart format --set-exit-if-changed .`
  PASS; `flutter analyze` PASS; `flutter test` PASS (106 tests);
  `flutter build web` PASS; backend tests PASS (273 tests);
  `scripts\00631l_release_check.cmd` WARN with failures=0; `git diff --check`
  PASS.
- v6.63 committed/pushed as `a59de71`, tag
  `00631l-lab-v6.63-summary-unavailable-state`; public marker and strict
  static-data checks passed.
- Playwright mobile screenshot confirmed the DAY chip now shows
  unavailable/error. Started v6.64 to remove technical holdings-unavailable
  wording and avoid displaying placeholder dates for unusable snapshots.
- Targeted v6.64 widget test passed for the holdings-unavailable wording.
- v6.64 validation PASS/WARN accepted: `dart format --set-exit-if-changed .`
  PASS; `flutter analyze` PASS; `flutter test` PASS (106 tests);
  `flutter build web` PASS; backend tests PASS (273 tests);
  `scripts\00631l_release_check.cmd` WARN with failures=0; `git diff --check`
  PASS.
- v6.64 committed/pushed as `6479134`, tag
  `00631l-lab-v6.64-holdings-unavailable-wording`; public marker and strict
  static-data checks passed.
- Playwright mobile screenshot confirmed the holdings-unavailable card is now
  product wording. Started v6.65 to replace debug-like pending labels in the
  overview summary row.
- Error: the first v6.65 fast-start test expected `連線中` in a fixture that
  already had an intraday NAV data time. Resolution: keep that test focused on
  removing old English labels and add a no-intraday fast-start fixture for the
  localized pending state.
- Targeted v6.65 fast-start widget tests passed.
- v6.65 validation PASS/WARN accepted: `dart format --set-exit-if-changed .`
  PASS; `flutter analyze` PASS; `flutter test` PASS (107 tests);
  `flutter build web` PASS; backend tests PASS (273 tests);
  `scripts\00631l_release_check.cmd` WARN with failures=0; `git diff --check`
  PASS.
- v6.65 committed/pushed as `d3ce7b2`, tag
  `00631l-lab-v6.65-summary-pending-labels`; public marker and strict
  static-data checks passed.
- Playwright mobile screenshot confirmed pending labels are localized and live
  data can populate the quote, summary, and holdings panels. Started v6.66
  because the phone chart still showed a long exposure strip that duplicated
  the holdings digest and clipped the right edge.
- Targeted v6.66 holdings-digest widget test passed after hiding the phone
  exposure strip.
- Error: the first full v6.66 validation failed because a default-width widget
  test expected `官方曝險` to be absent even though the desktop side-by-side
  exposure panel still legitimately renders it. Resolution: keep the no
  `官方曝險` assertion scoped to the phone-width readability test.
- v6.66 validation PASS/WARN accepted: `dart format --set-exit-if-changed .`
  PASS; `flutter analyze` PASS; `flutter test` PASS (108 tests);
  `flutter build web` PASS; backend tests PASS (273 tests);
  `scripts\00631l_release_check.cmd` WARN with failures=0; `git diff --check`
  PASS.
- v6.66 committed/pushed as `9375f85`, tag
  `00631l-lab-v6.66-mobile-exposure-strip-cleanup`; public marker and strict
  static-data checks passed.
- Public mobile screenshot confirmed the duplicated phone exposure strip is
  gone. Multi-tab inspection found the history/backtest phone page still spent
  its first screen on date controls before the chart, and the history badge row
  showed duplicate 00631L labels.
- Started v6.67 to make history/backtest chart-first on phones.
- v6.67 moved price charts before the detailed date controls, grouped the
  start/end controls under `日期設定`, and deduplicated the history badge row.
- Targeted history/backtest widget tests passed.
- v6.67 validation PASS/WARN accepted: `dart format --set-exit-if-changed .`
  PASS; `flutter analyze` PASS; `flutter test` PASS (108 tests);
  `flutter build web` PASS; backend tests PASS (273 tests);
  `scripts\00631l_release_check.cmd` WARN with failures=0; `git diff --check`
  PASS.
- v6.67 committed/pushed as `ed730fa`, tag
  `00631l-lab-v6.67-history-chart-first`; public marker and strict static-data
  checks passed.
- Public history-page screenshot confirmed chart-first ordering, but the chart
  still only began near the bottom of the first screen because the top history
  card repeated four summary tiles and `資料品質` appeared before the price
  chart block.
- Started v6.68 to reduce history/backtest top density.
- v6.68 removed the top summary tile grid and moved `資料品質` below the
  price-history chart block.
- Targeted history/backtest widget tests passed.
- v6.68 validation PASS/WARN accepted: `dart format --set-exit-if-changed .`
  PASS; `flutter analyze` PASS; `flutter test` PASS (108 tests);
  `flutter build web` PASS; backend tests PASS (273 tests);
  `scripts\00631l_release_check.cmd` WARN with failures=0; `git diff --check`
  PASS.
- v6.68 committed/pushed as `a54b6c5`, tag
  `00631l-lab-v6.68-history-top-density`; public marker and strict static-data
  checks passed.
- Public position-page inspection showed the account metric strip clipped the
  `未實現損益` tile on phone width.
- Started v6.69 to make the position account summary fit compact screens.
- v6.69 changed the position account metric strip to a 2x2 layout on compact
  widths while preserving the wider horizontal layout.
- Targeted position widget tests and `flutter analyze` passed.
- v6.69 validation PASS/WARN accepted: `dart format --set-exit-if-changed .`
  PASS; `flutter analyze` PASS; `flutter test` PASS (109 tests);
  `flutter build web` PASS; backend tests PASS (273 tests);
  `scripts\00631l_release_check.cmd` WARN with failures=0; `git diff --check`
  PASS.
- v6.69 committed/pushed as `15d1c8f`, tag
  `00631l-lab-v6.69-position-metric-fit`; public marker and strict static-data
  checks passed.
- Public position-page screenshot after v6.69 showed the metric layout fits,
  but the unrealized result still contained raw `unavailable` text for a
  missing percentage.
- Started v6.70 to localize the position unavailable percentage wording without
  changing local-only storage or position calculations.
- Targeted v6.70 validation PASS: `dart format` on touched Dart files,
  `flutter test test\etf_00631l_widget_test.dart --name "position account summary fits"`,
  and `flutter analyze`.
- v6.70 validation PASS/WARN accepted: `dart format --set-exit-if-changed .`
  PASS; `flutter analyze` PASS; `flutter test` PASS (109 tests);
  `flutter build web` PASS; backend tests PASS (273 tests);
  `scripts\00631l_release_check.cmd` WARN with failures=0; `git diff --check`
  PASS.
- v6.70 committed/pushed as `9473aa1`, tag
  `00631l-lab-v6.70-position-unavailable-wording`; public marker and strict
  static-data checks passed. Public static data row count is 2837 with coverage
  2014-10-31 to 2026-06-26.
- Public position-page screenshot confirmed the unrealized result now shows the
  localized unavailable percentage label.
- Started v6.71 after the public settings screenshot showed backend
  persistence diagnostics on the first account/settings screen.
- v6.71 keeps technical diagnostics available in advanced panels while making
  the first settings screen focus on account, local-only data, selected ETF,
  and frontend mode.
- Targeted v6.71 validation PASS: `dart format` on touched Dart files,
  `flutter analyze`, and `flutter test test\etf_00631l_widget_test.dart
  --plain-name "settings first screen keeps technical diagnostics advanced"`.
- v6.71 validation PASS/WARN accepted: `dart format --set-exit-if-changed .`
  PASS; `flutter analyze` PASS; `flutter test` PASS (110 tests);
  `flutter build web` PASS; backend tests PASS (273 tests);
  `scripts\00631l_release_check.cmd` WARN with failures=0; `git diff --check`
  PASS.
- v6.71 committed/pushed as `e203f0c`, tag
  `00631l-lab-v6.71-settings-first-screen`; public marker and strict
  static-data checks passed. Public settings screenshot confirmed the first
  screen now shows account/local/ETF context instead of persistence warnings.
- Started v6.72 because the same settings screenshot still showed the data-mode
  tile caption as a backend error. The first screen should explain static data
  remains usable and leave backend error detail in advanced diagnostics.
- Targeted v6.72 validation PASS: `dart format` on touched Dart files,
  `flutter analyze`, and `flutter test test\etf_00631l_widget_test.dart
  --plain-name "settings data mode softens backend errors on first screen"`.
- v6.72 validation PASS/WARN accepted: `dart format --set-exit-if-changed .`
  PASS; `flutter analyze` PASS; `flutter test` PASS (111 tests);
  `flutter build web` PASS; backend tests PASS (273 tests);
  `scripts\00631l_release_check.cmd` WARN with failures=0; `git diff --check`
  PASS.
- v6.72 committed/pushed as `83e505b`, tag
  `00631l-lab-v6.72-settings-data-mode-caption`; public marker and strict
  static-data checks passed. Public settings screenshot confirmed the data-mode
  caption now explains static data remains usable while details stay below.
- Started v6.73 after the public history/backtest screenshot showed duplicate
  in-chart x-axis dates crowding the y-axis labels. The clearer below-chart date
  strip already provides range context.
- Targeted v6.73 validation PASS: `dart format` on the touched Dart file,
  `flutter analyze`, and `flutter test test\etf_00631l_widget_test.dart
  --plain-name "history section shows price history when available"`.
- v6.73 validation PASS/WARN accepted: `dart format --set-exit-if-changed .`
  PASS; `flutter analyze` PASS; `flutter test` PASS (111 tests);
  `flutter build web` PASS; backend tests PASS (273 tests);
  `scripts\00631l_release_check.cmd` WARN with failures=0; `git diff --check`
  PASS.
- v6.73 committed/pushed as `a73595b`, tag
  `00631l-lab-v6.73-history-chart-axis-cleanup`; public marker and strict
  static-data checks passed. Public history screenshot confirmed in-chart
  x-axis date labels are gone.
- Started v6.74 after the same public history/backtest screenshot showed the
  current range context cards still clipping on phone width.
- v6.74 changed the range-context metric strip to a compact 2-column wrap on
  phone width while keeping the horizontal layout on wider screens.
- Adding phone-width widget coverage exposed a mini chart overflow; v6.74 also
  increased compact mini chart card height so the date strip and touch detail
  fit.
- Targeted v6.74 validation PASS: `dart format` on touched Dart files,
  `flutter analyze`, and `flutter test test\etf_00631l_widget_test.dart
  --plain-name "history range context wraps on phone width"`.
- v6.74 validation PASS/WARN accepted: `dart format --set-exit-if-changed .`
  PASS; `flutter analyze` PASS; `flutter test` PASS (112 tests);
  `flutter build web` PASS; backend tests PASS (273 tests);
  `scripts\00631l_release_check.cmd` WARN with failures=0; `git diff --check`
  PASS.
- v6.74 committed/pushed as `39ade98`, tag
  `00631l-lab-v6.74-history-range-context-fit`; public marker and strict
  static-data checks passed. Public history screenshot confirmed the range
  context uses a 2x2 compact layout and mini charts no longer overflow.
- Started v6.75 after public AI-page inspection showed the daily
  interpretation was followed by a broad status quick-view before the written
  summary.
- v6.75 adds a clean `_AiSectionV2` route for the AI tab: daily interpretation
  and program actions stay visible first, while source grids, matrices, and
  completeness details move into `進階 AI 明細`.
- Targeted v6.75 validation PASS: `dart format` on touched Dart files and
  `flutter test test\etf_00631l_widget_test.dart --plain-name "AI and settings sections render clean status wording"`.
- v6.75 validation PASS/WARN accepted: `dart format --set-exit-if-changed .`
  PASS; `flutter analyze` PASS; `flutter test` PASS (112 tests);
  `flutter build web` PASS; backend tests PASS (273 tests);
  `scripts\00631l_release_check.cmd` WARN with failures=0; `git diff --check`
  PASS.
- v6.75 committed/pushed as `02b1234`, tag
  `00631l-lab-v6.75-ai-answer-first`; public marker and strict static-data
  checks passed. Public AI screenshot confirmed the tab now opens with daily
  interpretation and keeps deeper status detail below.
- Started v6.76 after reviewing the position page first screen. The local-only
  title card repeated information already shown by the account summary and
  action bar.
- v6.76 hides the redundant position page title card so account summary,
  actions, and input controls appear sooner.
- Targeted v6.76 validation PASS: `dart format` on touched Dart files,
  `flutter analyze`, and `flutter test test\etf_00631l_widget_test.dart
  --plain-name "position section saves local-only data controls"`.
- v6.76 validation PASS/WARN accepted: `dart format --set-exit-if-changed .`
  PASS; `flutter analyze` PASS; `flutter test` PASS; `flutter build web`
  PASS; backend tests PASS (273 tests); `scripts\00631l_release_check.cmd`
  WARN with failures=0; `git diff --check` PASS.
- v6.76 committed/pushed as `5e5cd93`, tag
  `00631l-lab-v6.76-position-first-screen-trim`; public marker and strict
  static-data checks passed. Public position screenshot confirmed the page now
  starts with account summary and input controls.
- Started v6.77 after local ETF price-history status showed completionGap=116
  while gapReasonCounts only explained 20 symbols.
- v6.77 classifies catalog-only missing ETF histories as `not_saved` and adds
  them to the unavailable coverage tier, without inventing price-history data.
- Targeted v6.77 validation PASS: `py -m unittest
  backend.tests.test_etf_price_history.EtfPriceHistoryTests.test_status_summary_omits_full_item_dump`
  and `py backend\scripts\import_etf_price_history.py --status-only --summary-only`.
- v6.77 validation PASS/WARN accepted: `dart format --set-exit-if-changed .`
  PASS; `flutter analyze` PASS; `flutter test` PASS; `flutter build web`
  PASS; backend tests PASS (273 tests); `scripts\00631l_release_check.cmd`
  WARN with failures=0; `git diff --check` PASS.
- Public v6.77 strict static-data check passed after release: public data now
  reports ready 231 / catalog 347, missing 116, official_empty 96,
  source_error 20, and unclassified 0.
- Started v6.78 after confirming the app still exposed the ETF data-library
  state as detailed maintenance metrics before a plain summary.
- Added a readable settings summary for ETF data-library completeness while
  keeping detailed diagnostics below it.
- Added widget coverage for the classified public-style gap state: 231 / 347
  usable ETF histories, official-empty 96, source-error 20, unclassified 0.
- Started v6.79 after public settings inspection showed the first screen still
  spent too much height on a large overview grid.
- Replaced the settings overview grid with a compact summary card that keeps
  account state, selected ETF, frontend mode, release version, and daily status
  as short badges.
- Added widget coverage for the compact settings summary key.
- Started v6.80 after public search-sheet inspection showed the ETF database
  readiness summary could still use catalog-only fallback counts during fast
  startup.
- v6.80 merges static-public ETF library readiness metadata into cached fast
  startup operations data when live backend ETF-wide readiness is missing.
- Targeted v6.80 validation PASS: `flutter test
  test\etf_00631l_proxy_repository_test.dart --plain-name "cached fast startup
  overlays static public price history"` now verifies ETF ready/missing/gap
  counts from static fallback.
- Started v6.81 after the public search sheet still showed English internal
  result chips (`history-ready`, `catalog-only`) below the corrected database
  readiness summary.
- v6.81 changes those chips to Chinese current-result labels and keeps the
  global database readiness summary above them.
- Targeted v6.81 validation PASS: `flutter test
  test\etf_00631l_widget_test.dart --plain-name "catalog-only ETF selection
  shows missing history guidance"`.
- Started v6.82 after the expanded ETF database detail panel still exposed
  internal English labels such as catalog, history source, long-term, and
  recent.
- v6.82 replaces those expanded-detail labels with Chinese user-facing labels.
- Targeted v6.82 validation PASS: `flutter test
  test\etf_00631l_widget_test.dart --plain-name "symbol search shows ETF data
  completion status"`.
- Started v6.83 after the public expanded search detail showed both the loaded
  ETF list count and full readiness denominator. The data was correct, but the
  labels needed clearer context.
- v6.83 renames the loaded-list count to `目前清單` and keeps `統計母數` for the
  full readiness denominator.
- Targeted v6.83 validation PASS: `flutter test
  test\etf_00631l_widget_test.dart --plain-name "symbol search shows ETF data
  completion status"`.
- Started v6.84 after comparing public ETF gap status with stale local ignored
  static output. Public Pages has 116 classified ETF history gaps and zero
  unclassified gaps; local `web\00631l-static-data` was old v5.96 output
  because local Pages build skipped public attempt restore by default.
- v6.84 changes `scripts\00631l_build_pages_static.cmd` so public ETF
  import-attempt evidence is restored by default, with
  `--skip-restore-public-attempts` kept for offline builds.
- v6.84 targeted validation PASS: static Pages pipeline test and
  `scripts\00631l_restore_public_etf_attempts.cmd`.
- v6.84 local status after restore PASS: 347 catalog rows, 231 ready histories,
  116 classified gaps, attempted 116, `not_saved=0`.
- v6.84 full validation PASS/WARN accepted: `dart format --set-exit-if-changed .`
  PASS; `flutter analyze` PASS; `flutter test` PASS; `flutter build web`
  PASS; backend tests PASS (273 tests); `scripts\00631l_release_check.cmd`
  WARN with failures=0; `git diff --check` PASS.
- Started v6.85 after settings gap-detail review showed internal reason keys
  still visible in the public UI.
- v6.85 adds display helpers for ETF gap reasons and coverage tiers, keeping
  raw keys in models/API while showing readable labels in settings summaries,
  filter chips, row badges, and sample-code details.
- v6.85 targeted widget validation PASS for gap detail rows, gap reason filter,
  and ETF data completion denominator tests.
- v6.85 full validation PASS/WARN accepted: `dart format --set-exit-if-changed .`
  PASS; `flutter analyze` PASS; `flutter test` PASS; `flutter build web`
  PASS; backend tests PASS (273 tests); `scripts\00631l_release_check.cmd`
  WARN with failures=0; `git diff --check` PASS.
- Started v6.86 after public settings inspection showed visible raw status
  labels such as `local-only`, `rule_based`, `static_official`, `available`,
  and comparison readiness keys.
- v6.86 adds a display helper for common source/status keys and applies it to
  account/settings, position, AI, selected ETF, and comparison surfaces while
  leaving raw data-contract keys unchanged.
- Targeted v6.86 widget validation PASS: position controls, AI/settings clean
  status wording, and ETF data-library readiness.
- v6.86 full validation PASS/WARN accepted: `dart format --set-exit-if-changed .`
  PASS; `flutter analyze` PASS; `flutter test` PASS; `flutter build web`
  PASS; backend tests PASS (273 tests); `scripts\00631l_release_check.cmd`
  WARN with failures=0; `git diff --check` PASS.
- Started v6.87 after public overview screenshot still showed raw `cached` in
  the DAY summary chip.
- v6.87 localizes overview DAY/LIVE/HIS summary captions and known unavailable
  states while keeping raw source keys in lower-level contracts.
- Targeted v6.87 widget validation PASS: known unavailable holdings summary and
  intraday pending summary.
- v6.87 full validation PASS/WARN accepted: `dart format --set-exit-if-changed .`
  PASS; `flutter analyze` PASS; `flutter test` PASS; `flutter build web`
  PASS; backend tests PASS (273 tests); `scripts\00631l_release_check.cmd`
  WARN with failures=0; `git diff --check` PASS.
- Started v6.88 after public mobile review showed the overview holdings `MIX`
  tile compressed stock, futures, and cash/margin into one hard-to-read value.
- v6.88 changes that tile to `曝險結構` with separate stock, futures, and
  cash/margin percentage rows while keeping TX and TSMC tiles unchanged.
- Targeted v6.88 widget validation PASS: overview holdings digest on phone.
- v6.88 full validation PASS/WARN accepted: `dart format --set-exit-if-changed .`
  PASS; `flutter analyze` PASS; `flutter test` PASS; `flutter build web`
  PASS; backend tests PASS (273 tests); `scripts\00631l_release_check.cmd`
  WARN with failures=0; `git diff --check` PASS.
- Started v6.89 after public AI-page inspection showed raw implementation
  wording such as `static public mode`, `rows`, `cached`, and
  `public backend proxy` on the first screen.
- v6.89 adds an AI-display text mapper for user-facing bullets/actions/fact
  cards while preserving raw model and API keys.
- Targeted v6.89 widget validation PASS: AI and settings clean status wording.
- v6.89 full validation PASS/WARN accepted: `dart format --set-exit-if-changed .`
  PASS; `flutter analyze` PASS; `flutter test` PASS; `flutter build web`
  PASS; backend tests PASS (273 tests); `scripts\00631l_release_check.cmd`
  WARN with failures=0; `git diff --check` PASS.
- Started v6.90 after public v6.89 static data check showed `etfCatalogRows=343`
  while the ETF price-history index had 347 symbols. The Pages export warning
  showed `etfCatalogUpdateFailed=HTTP 502`, so the catalog had regressed during
  a transient source failure.
- v6.90 merges committed ETF catalog seed rows into the runtime catalog payload
  by code and warns whenever public history contains symbols outside the
  catalog snapshot.
- Targeted v6.90 backend validation PASS: catalog seed merge and public
  out-of-catalog warning tests.
- v6.90 static export update smoke PASS: `etfCatalogRows=347`,
  `etfRows=347`, `etfOutOfCatalog=0`.
- v6.90 full validation PASS/WARN accepted: `dart format --set-exit-if-changed .`
  PASS; `flutter analyze` PASS; `flutter test` PASS; `flutter build web`
  PASS; backend tests PASS (274 tests); `scripts\00631l_release_check.cmd`
  WARN with failures=0; `git diff --check` PASS.
- Started v6.91 after public mobile screenshots showed remaining raw
  implementation wording on history and AI first-screen surfaces.
- v6.91 maps additional analysis phrases (`official holdings`,
  `live intraday NAV`, `intraday NAV`, `price history`, and `readiness`) to
  product-facing labels, applies source-label mapping to the history header, and
  maps today-snapshot / selected-ETF AI bullets before rendering.
- Targeted v6.91 widget validation PASS: `flutter test
  test\etf_00631l_widget_test.dart`.
- v6.91 full validation PASS/WARN accepted: `dart format --set-exit-if-changed .`
  PASS; `flutter analyze` PASS; `flutter test` PASS; `flutter build web`
  PASS; backend tests PASS (274 tests); `scripts\00631l_release_check.cmd`
  WARN with failures=0; `git diff --check` PASS.
