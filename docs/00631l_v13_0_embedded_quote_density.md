# 00631L v13.0 embedded quote density

v13.0 tightens the overview market quote area.

## What changed

- Removed the repeated ETF full name from the embedded overview quote card on
  phones.
- Kept the selected ETF identity in the top-left symbol button and app header.
- Kept source status visible beside the quote price.
- Tightened the widget height guard for the embedded quote header.

## Why

The overview first screen should lead with price, premium/discount status, data
time, and the one-year chart. The full ETF name was already available in the app
header and symbol selector, so repeating it inside the market stack made the
top area feel too large.

## Validation

- `flutter analyze`
- `flutter test`
- `flutter build web`
- `py -m unittest discover -s backend\tests`
- `scripts\00631l_release_check.cmd`
- `git diff --check`
