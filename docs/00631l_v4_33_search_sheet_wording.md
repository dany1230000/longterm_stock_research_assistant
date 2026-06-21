# 00631L lab v4.33 search sheet wording

v4.33 cleans up the top-left ETF / stock-code search sheet.

## What Changed

- Replaced legacy garbled labels in the selector title, description, input label, hint, close tooltip, and clear tooltip.
- The readiness badge now says `可用歷史 N`.
- Empty-query status now says `熱門清單`.
- Stock search count now says `個股 N`.
- History-ready ETF rows state that the selected ETF can show historical data and backtest after switching.

## Why

The selector is the main path for switching the research context to another ETF. It must look like a production app, not a debug panel, and it must make data readiness clear.

## Scope

- UI wording only.
- No new data source.
- No broker integration, notification, or investment guidance.
