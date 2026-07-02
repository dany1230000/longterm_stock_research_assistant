# 00631L v14.4 History Holdings Density

This release tightens the history/backtest page.

## What Changed

- Holdings history remains available on the history page.
- The TX, TSMC, exposure, NAV, and 30-row holdings history details now live under `內容物歷史`.
- The first history/backtest screen stays focused on date range, price chart, chart touch detail, and backtest context.

## Product Boundary

- No data-source change.
- No holdings calculation change.
- No backtest calculation change.
- The content is still data interpretation only, not investment guidance.

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
