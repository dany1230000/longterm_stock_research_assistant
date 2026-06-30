# 00631L lab v9.40 static price preview

Release goal: make the public PWA first screen useful faster while keeping
full historical data available for history and backtest pages.

## Changes

- Static export now writes `price_preview.json`.
- `price_preview.json` keeps a recent 400-day window from the full adjusted
  price history.
- `Static00631LRepository.fetchFastLabData()` reads `price_preview.json` first.
- `Static00631LRepository.fetchLabData()` still reads the full
  `price_history.json`.

## User Impact

- The overview can render the recent chart and core context before full live
  backend or full static history loading finishes.
- History and backtest still use the complete static price history when loaded.
- Live intraday NAV still requires the public backend.

## Verification

- Backend export test covers `price_preview.json` and manifest metadata.
- Flutter repository test verifies fast static loading does not request the full
  `price_history.json` before the full data path.
