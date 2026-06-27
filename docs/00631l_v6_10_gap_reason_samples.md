# 00631L lab v6.10 gap reason samples

v6.10 adds compact ETF price-history gap samples across backend, static export,
public checks, and the app settings page.

## What Changed

- Multi-ETF price-history index now includes `gapReasonSamples`.
- Static public export writes samples into `status.json`, `manifest.json`,
  `etf_price_history_index.json`, and `etf_price_history_gaps.json`.
- `/api/etf/00631l/operations/status` exposes
  `etfPriceHistory.gapReasonSamples`.
- Flutter proxy/static/cached repositories preserve the sample map.
- The settings ETF data-library card shows short `sample codes` beside the gap
  reason summary.
- Public static-data check prints a compact samples summary when available.

## Meaning

Samples answer which ETF codes are behind each gap reason without making the
main UI noisy. They are maintenance evidence only. An ETF still needs verified
price-history rows before history, backtest, or comparison views can use it.

## Data Contract

Example:

```json
{
  "gapReasonCounts": {
    "official_empty": 95,
    "source_error": 20
  },
  "gapReasonSamples": {
    "official_empty": ["00999", "00998"],
    "source_error": ["00997"]
  }
}
```

Each reason keeps only a short code sample. The full symbol-level detail stays
in `etf_price_history_gaps.json`.
