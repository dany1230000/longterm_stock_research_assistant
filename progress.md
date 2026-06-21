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
