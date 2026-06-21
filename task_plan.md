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
- Keep static history separate from live intraday data.

## Phase 4 - ETF Selection and Comparison

Status: in_progress

- Make the top-left ETF/search control the primary way to switch ETF context.
- v4.18 improved ETF search result readiness labels so imported price-history ETFs and catalog-only ETFs are visually distinct.
- Allow user-selected comparison baskets instead of always comparing against 00631L.
- v4.19 clarified the comparison basket UI and added a widget test for toggling comparison chips.
- Keep 00631L-specific official holdings separate from generic ETF price history.

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
