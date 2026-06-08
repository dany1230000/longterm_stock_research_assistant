# 00631L Lab v1.5 Release Summary

Date: 2026-06-08

## Scope

v1.5 adds a non-advice data status summary to `/00631l-lab`.

The summary combines:

- Official holdings freshness.
- Holdings `sourceStatus`.
- Intraday NAV availability and `sourceContract`.
- Premium/discount state.
- Holdings change notice state.
- Intraday premium/discount history state.

## UX

The new section is titled `00631L 狀態總結` and appears near the top of the lab page. It shows a compact status label and short explanatory lines.

The final line explicitly states that the summary only describes data status and deviation degree, and is not trading advice.

## Boundaries

This release does not connect TX live, does not expand to all leveraged ETFs, does not add push notifications, and does not add trading signals.

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
