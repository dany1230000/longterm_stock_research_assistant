# 00631L lab v5.48 selected ETF data context

v5.48 makes selected ETF data quality visible in the app UI.

## Changes

- Added a selected ETF data-context card for non-00631L symbols.
- The card appears on the overview page after the readiness banner.
- The same card appears in the selected ETF AI page.
- It shows:
  - selected ETF code
  - price history status
  - row count and coverage range
  - price field used for history analysis
  - split-adjustment context
  - backtest readiness
  - live NAV scope
- It clearly states that live intraday NAV mapping is currently complete for
  00631L only.
- It keeps the analysis descriptive and marked as non-advisory.

## Why

The app is moving toward an ETF research-room product. Users can already search
other ETFs, but each selected ETF must show whether its data is sufficient for
history and backtest views. This release keeps those labels visible without
pretending that catalog/static data is live intraday data.

## Validation

Run:

```cmd
flutter analyze
flutter test
flutter build web
py -m unittest discover -s backend\tests
scripts\00631l_release_check.cmd
git diff --check
```

`WARN` remains acceptable only when `failures=[]` and the warning is an expected
local or off-hours data state.
