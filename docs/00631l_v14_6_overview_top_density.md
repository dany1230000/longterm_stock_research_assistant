# 00631L v14.6 Overview Top Density

This release tightens the top of the mobile overview page.

## What Changed

- The top market bar is shorter, so the quote and chart start higher on phone screens.
- The top-left symbol search pill keeps the same search affordance with less vertical padding.
- The compact premium/discount box uses a tighter width and smaller value text.
- The overview one-year chart stays visible by default, but uses a shorter compact height.
- The overview AI glance keeps the same one-line summary and program action with less padding.

## Product Boundary

- No data-source change.
- No analysis or backtest calculation change.
- No TX live source change.
- This is a layout polish release only.

## Validation

Run the normal release checks:

```cmd
flutter analyze
flutter test
flutter build web
py -m unittest discover -s backend\tests
scripts\00631l_release_check.cmd
git diff --check
```
