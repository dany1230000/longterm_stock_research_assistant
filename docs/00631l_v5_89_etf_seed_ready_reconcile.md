# 00631L lab v5.89 ETF seed readiness reconcile

## Scope

v5.89 reconciles one verified local ETF price-history file into the committed
static seed set.

`00407A` had official TWSE STOCK_DAY rows in local cache but was not yet present
in `backend/seeds/etf_price_history_seed/`. That made local static status show
one more ready ETF than GitHub Pages.

## Data Added

- code: `00407A`
- source: TWSE STOCK_DAY JSON
- sourceStatus: `official`
- coverage: `2026-06-24` to `2026-06-26`
- row count: 3

This is a short recent-history seed, not a reconstructed long-term series.
Other ETFs without official rows remain visible as unavailable gaps.

## Validation

`backend\tests\test_static_pages_pipeline.py` now asserts the `00407A` seed file
exists with the broader committed seed set. Static export continues to report
ready and missing counts explicitly.
