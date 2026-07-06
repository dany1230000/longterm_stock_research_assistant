# 00631L v16.69 Account Density Polish

This release tightens the phone layout for the position and settings pages.

## Changes

- Position summary uses a shorter account strip on phone width.
- Position metrics use smaller horizontal tiles so cost, value, P/L, and weight stay in one compact row.
- Settings preferences use a shorter horizontal chip strip instead of taller cards on phone width.
- No data source, parser, backtest, or AI behavior changed.

## Validation

- Phone layout widget tests cover the tighter position and settings heights.
- Forbidden trading wording scan remains part of the release check.
- Source labels remain truthful: live, static, mock, cached, stale, and error states are not relabeled.
