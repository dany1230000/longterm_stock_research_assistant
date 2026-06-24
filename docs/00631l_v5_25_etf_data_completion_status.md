# 00631L lab v5.25 ETF data completion status

## Scope

v5.25 moves the ETF data completion summary from Settings into the left-top ETF search and switch sheet. The user can now see whether ETF catalog rows and imported price histories are ready before searching or switching ETFs.

## UI changes

- The left-top ETF search sheet now shows an `ETF 資料補齊` strip near the top.
- The block shows catalog count, history ready count, completion ratio, long-term coverage count, recent coverage count, remaining gap, and data time.
- Settings still keeps the same readiness summary for maintenance context.

## Data behavior

- No source contract changed.
- No mock data is promoted to official.
- Static-public, live-proxy, cached, and mock status labels remain visible.
- A missing history gap means the ETF is not ready for comparison or backtest until verified history rows are imported.

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

Warnings are acceptable only when `failures=[]` and the warning is from expected local/live freshness conditions.
