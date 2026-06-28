# 00631L v6.39 overview duplicate core cleanup

## Goal

Make the mobile overview first screen more direct by removing the duplicated
00631L `核心資料` card.

## What Changed

- 00631L overview now flows from quote header to `今日摘要` and then directly to
  the price/exposure chart.
- The removed card repeated holdings date, intraday NAV, history coverage, and
  return context already available in the quote header, daily summary strip,
  and chart panel.
- Non-00631L selected ETF views still keep their own `${code} 核心資料` panel
  because they do not have the 00631L-specific daily summary.
- The hidden technical/status details remain under `更多資料`.

## Validation

- Widget coverage now expects the 00631L overview to omit `核心資料`.
- Non-00631L core data coverage remains unchanged.
- Data sources, historical calculations, backtest formulas, and source status
  labels are unchanged.
