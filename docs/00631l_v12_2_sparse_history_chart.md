# 00631L v12.2 sparse history chart

## Goal

Avoid blank-looking history charts when the selected date range only has one
valid price point.

## Change

- `_LineChartPanel` now shows a sparse-data state when fewer than two valid
  points are available.
- Large charts show the latest date/value and a hint to adjust the range.
- Compact mini charts show a one-line sparse-data state that fits small card
  heights without overflow.

## Expected behavior

- A one-point range no longer looks like a broken blank chart.
- The date and value remain visible.
- No historical value is inferred or fabricated.

## Verification

- Widget tests cover sparse history data on phone width.
- Existing full validation keeps chart layout and forbidden wording checks in
  place.
