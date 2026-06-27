# 00631L lab v6.9 gap detail status

v6.9 carries ETF history gap detail counts into backend operations status and
the app settings page.

## What Changed

- Backend ETF history index includes `gapDetailCount`.
- `/api/etf/00631l/operations/status` exposes `etfPriceHistory.gapDetailCount`.
- Static public repository reads `etfPriceHistoryGapDetailCount` from static
  status or the ETF history index.
- Flutter operations status keeps `etfPriceHistoryGapDetailCount`.
- The app settings page includes a compact `缺口明細` count beside the ETF
  history gap reason summary.

## Meaning

The count is a maintenance signal. It tells whether unavailable ETF histories
have symbol-level evidence in `etf_price_history_gaps.json`. It does not make
unavailable histories usable for comparison or backtest.
