# 00631L lab v6.8 ETF gap detail export

v6.8 adds a public static ETF history gap detail file so data maintenance can
see which ETF histories are unavailable and why.

## What Changed

- Static export writes `etf_price_history_gaps.json`.
- The file lists unavailable or validation-failed ETF histories with:
  - code
  - gapReason
  - rowCount
  - sourceStatus
  - lastAttemptAt
  - requestedMonths
  - errorMessage
- Manifest, status, and public static checks expose
  `etfPriceHistoryGapDetailCount`.
- Public static checks warn when the detail count is lower than the missing
  history count.

## Meaning

`etf_price_history_gaps.json` is maintenance evidence. It does not turn missing
history into usable data and does not change backtest calculations. It makes the
remaining classified gaps easier to inspect before future import or source
repairs.
