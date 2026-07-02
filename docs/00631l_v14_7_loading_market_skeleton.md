# 00631L v14.7 Loading Market Skeleton

This release improves the mobile loading state so the public app does not feel like an empty waiting screen.

## What Changed

- The loading quote card now mirrors the real market stack shape.
- Loading state shows a quote area, premium/discount box, chart skeleton, date chips, and compact data ribbon placeholders.
- The bottom navigation and top symbol selector remain visible while data is loading.
- The loading view still avoids claiming official, live, or static data before the repository returns it.

## Product Boundary

- No data-source change.
- No static or live backend behavior change.
- No analysis or backtest calculation change.
- This is a perceived-performance and layout polish release only.

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
