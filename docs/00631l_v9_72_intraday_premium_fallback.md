# 00631L lab v9.72 intraday premium fallback

v9.72 fixes a live-data display edge case in the TWSE ETF intraday feed.

## What changed

- TWSE `all_etf.txt` can return market price and estimated NAV while leaving the
  premium/discount field blank.
- The backend now derives `premiumDiscountPct` from the same official row when
  `g` is blank:

```text
(marketPrice / estimatedNav - 1) * 100
```

- The Flutter model exposes `resolvedPremiumDiscountPct` so the public PWA can
  show the same value even before the public backend is redeployed.
- ETF catalog rows use the same fallback, which keeps ETF search and comparison
  rows consistent.

## Data rules

- This only applies when `marketPrice` and `estimatedNav` are both present and
  `estimatedNav > 0`.
- If either value is missing, the premium/discount remains unavailable.
- Source labels remain unchanged. A fallback calculation from official TWSE
  fields is still shown with its original source contract, not as a new source.

## Verification

- Backend parser tests cover blank TWSE `g` fields.
- Flutter parser, model, and proxy repository tests cover the same edge case.
- No TX live source changes are included in this version.
