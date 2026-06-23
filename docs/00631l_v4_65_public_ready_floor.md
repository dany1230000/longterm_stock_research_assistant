# 00631L v4.65 Public Ready Floor

Release goal: make public backend ETF history readiness regressions visible without comparing JSON by hand.

## What Changed

- `scripts\00631l_public_backend_status.cmd` now accepts readiness floors:
  - `--min-price-history-rows <rows>`
  - `--min-etf-ready-count <count>`
- The output summary includes:
  - `minPriceHistoryRows`
  - `minEtfReadyCount`
- If public ETF history ready count falls below the configured floor, the script reports `WARN`.

## Usage

```cmd
scripts\00631l_public_backend_status.cmd --min-price-history-rows 2800 --min-etf-ready-count 200 --soft-fail
```

This is useful after a hosted backend restart. If ready ETF history falls back to seed-only coverage, the command reports a clear readiness warning.

## Notes

The default floors remain low so normal release checks do not fail on a fresh local setup. Use stricter floors during public deployment verification.
