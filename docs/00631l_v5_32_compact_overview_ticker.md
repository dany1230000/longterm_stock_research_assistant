# 00631L lab v5.32 compact overview ticker

## Scope

v5.32 improves the mobile first screen by reducing the height of the overview
update-time area. The goal is to show the quote, data mode, update timestamps,
and chart earlier without hiding the update-source distinction.

## Changes

- Converted the overview update-time block into a single horizontal ticker.
- Kept DAY, LIVE, TX, and HIS labels visible.
- Reduced each update chip width and vertical padding.
- Kept the overview chart expanded by default.

## Data Notes

- `DAY` remains official daily holdings data.
- `LIVE` remains intraday NAV data from the backend when available.
- `TX` remains the existing TX quote source status; this release does not change
  TX data sourcing.
- `HIS` remains historical price coverage.

## Validation

Run:

```cmd
flutter analyze
flutter test
flutter build web
py -m unittest discover -s backend\tests
scripts\00631l_release_check.cmd
git diff --check
```
