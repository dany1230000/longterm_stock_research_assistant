# v4.99 Mobile Home Context

## Scope

v4.99 focuses on the first screen and selected ETF context in the ETF research room.
It does not change official data fetchers, TX live source behavior, public backend
maintenance, or historical price calculations.

## Changes

- The top bar now shows the currently selected ETF name under `ETF 研究室`.
- The first screen keeps quote, chart, and core status visible without opening a
  large data-debug card.
- Price-field, split-adjustment, coverage, and selected ETF code are shown in a
  compact `DATA` ribbon.
- The full data-correctness panel is still available inside `更多資料`.
- Widget tests now verify that the bottom navigation has no standalone ETF tab,
  and that selected ETF context continues through overview, position, and AI.

## Data Rules

- `00631L` official holdings remain daily snapshots.
- Intraday NAV remains a live-backend feature when a backend is connected.
- Static public data remains historical data only.
- Selected ETF history uses the loaded ETF price-history source and must not
  reuse 00631L holdings as if it belonged to another ETF.
- This release is descriptive and does not provide investment guidance.
