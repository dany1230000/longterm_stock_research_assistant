# 00631L lab v3.7 complete data UI summary

v3.7 focuses on using the existing 00631L data more completely in the PWA.
It does not add TX live, additional ETFs, notifications, automated trading, or investment guidance.

## What Changed

- The overview now shows price history completeness:
  - row count
  - coverage range
  - latest close
  - latest daily return
  - latest OHLC
  - volume
  - trailing 52-week high and low
  - whether NAV and premium/discount fields are available in the historical price data
- The history tab now includes compact trend charts for:
  - close price
  - cumulative return
  - drawdown
  - volume
  - TX weight
  - TSMC weight
  - stock exposure
  - futures exposure
  - cash and margin
  - NAV
- The history table now shows OHLC, NAV, premium/discount, volume, daily return, and drawdown when available.
- The AI tab now includes a complete-data daily briefing generated from existing app data:
  - price history coverage
  - latest close and daily return
  - 52-week range
  - performance and drawdown
  - latest official holdings weights
  - intraday NAV sample range
  - report/export/backup state

## Data Boundaries

- Holdings remain official daily snapshots, not intraday holdings.
- Intraday NAV and premium/discount still require the backend live source.
- Static public mode can show history and backtest from generated official price history.
- Missing fields remain marked unavailable. The app does not fill missing official fields with mock data.

## Non-Advice Boundary

All new text describes data coverage, data freshness, historical changes, and system state.
It remains non-advisory and does not include trading instructions.
