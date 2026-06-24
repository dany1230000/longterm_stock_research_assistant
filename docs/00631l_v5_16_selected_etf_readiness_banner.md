# 00631L Lab v5.16 Selected ETF Readiness Banner

## Scope

v5.16 improves the ETF switch experience after using the top-left symbol search.
When the active symbol is not 00631L, the overview screen now shows a compact
readiness banner before the chart and metrics.

## What Changed

- Shows whether the selected ETF has imported price history.
- Distinguishes `history ready` from `catalog-only`.
- Shows the loaded row count and coverage range when history is available.
- Shows a clear data gap message when only catalog fields are available.
- Keeps 00631L official holdings and live intraday NAV clearly scoped to 00631L.

## User Impact

The first screen after switching ETF now explains what data is usable:

- `history ready`: history, backtest, and comparison can use imported price data.
- `catalog-only`: only catalog fields are available until price history is imported.

The banner is a data-readiness notice only. It does not provide investment
guidance.

## Validation

- `flutter analyze`
- `flutter test`
- `flutter build web`
- `py -m unittest discover -s backend\tests`
- `scripts\00631l_release_check.cmd`
- `git diff --check`
