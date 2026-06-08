# 00631L Lab v1.3 Release Summary

Date: 2026-06-08

## Scope

v1.3 adds non-advice holdings change notices to `/00631l-lab`.

The app compares the latest two official holdings history rows from v1.2 and displays data-status reminders for notable changes in:

- TX weight.
- TSMC weight.
- Cash and margin ratio.
- Futures asset ratio.
- Combined stock and futures exposure.
- Official holdings freshness.

This release does not connect TX live, does not expand to all leveraged ETFs, and does not add trading strategy behavior.

## Thresholds

- TX weight change: 5 percentage points.
- TSMC weight change: 2 percentage points.
- Cash and margin increase: 5 percentage points.
- Futures asset ratio change: 10 percentage points.
- Combined stock and futures exposure outside 180%-220%.
- Official holdings older than 1 business day.

## UX

The new section is titled `內容物變化提醒`. It shows one or more status cards. Each message ends with a non-advice reminder and includes source/history status context.

If there are fewer than two official history rows, the app reports that history is still insufficient instead of creating a synthetic comparison.

## Validation

Run before release:

```powershell
flutter analyze
flutter test
flutter build web
py -m unittest discover -s backend\tests
py backend\scripts\smoke_00631l_live.py
git diff --check
```
