# 00631L v6.38 fast summary loading state

## Goal

Keep the first overview screen calm while the fast startup shell is waiting for
the heavier holdings, intraday, AI, and maintenance payloads.

## What Changed

- The overview `今日摘要` strip now receives the same `detailsLoading` state as
  the rest of the fast-start UI.
- While full data is still loading, the summary strip shows `loading` or
  `pending` instead of temporary `error` / `unavailable` labels.
- Once full data arrives, the strip returns to the real source status labels and
  values.
- True source errors after loading are still displayed; this only changes the
  transient startup state.

## Validation

- Widget coverage checks that the fast-start summary strip renders loading
  labels and does not show transient `error` or `unavailable` text.
- Data sources, ETF history, backtest calculations, and source labeling rules
  are unchanged.
