# 00631L v6.97 Overview Summary Chips

## Scope

This release polishes the overview first screen. It replaces the compact
`DAY / LIVE / HIS` labels in the daily summary strip with user-facing labels:

- `官方內容物`
- `盤中 NAV`
- `歷史資料`

The values remain compact for phone width: holdings date uses `MM/DD`, intraday
time uses `HH:mm`, and price history keeps row count plus coverage years.

## Behavior

- The overview still shows one compact three-column summary row.
- Backend warmup, unavailable, cached, static, and source labels are preserved.
- The advanced update-clock panel still keeps the technical `DAY / LIVE / HIS`
  badges for users who expand details.
- This change is UI-only; it does not alter parser, static data, backend, or
  price-history behavior.

## Validation

- Widget coverage confirms the phone-width summary row contains the new labels.
- The same test confirms the old `DAY / LIVE / HIS` badges no longer appear in
  the first-screen summary strip.
