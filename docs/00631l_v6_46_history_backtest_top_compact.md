# 00631L v6.46 history/backtest top compact

v6.46 reduces the first-screen height of the history/backtest page on phones.

## What changed

- Replaced the large history/backtest header card with a compact top strip.
- Kept the key items visible: selected ETF, source status, coverage, latest close, default range, row count, and date-edit availability.
- Moved detailed price-history quality, split-adjustment, and source notes into an expandable `資料品質` panel.
- Kept the default history/backtest range at latest one year.

## Data behavior

- No price-history source, split-adjustment, performance, or backtest calculation behavior changed.
- Static public history remains distinct from live intraday NAV.
- The page still labels missing or fallback data truthfully instead of treating it as official.

## Validation focus

- Widget coverage verifies the compact history/backtest top strip and data-quality expansion are present.
- The change is UI density only; history and backtest formulas stay unchanged.
