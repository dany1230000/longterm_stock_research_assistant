# 00631L Lab v5.22 Overview Data Time Strip

## Completed Scope

- Added a compact update-time strip to the overview first screen.
- The strip separates:
  - `DAY`: official daily holdings snapshot.
  - `LIVE`: intraday NAV and premium/discount data.
  - `TX`: TAIFEX TX quote data when available.
  - `HIS`: historical price coverage.
- Non-00631L selected ETFs show catalog/history timing without reusing 00631L
  holdings as if it belonged to the selected ETF.

## Why

Users reported that the homepage timing was hard to understand. This release
makes data frequency visible before the chart and summary sections:

- Holdings ratio is official daily data.
- Intraday NAV is live only when the backend is connected.
- TX quote has its own TAIFEX data time and may be unavailable or stale.
- Historical prices come from static/proxy history and are not intraday data.

## Boundaries

- No new investment action guidance.
- No expansion into stock trading workflows.
- No mock or fallback data is labeled as official.
