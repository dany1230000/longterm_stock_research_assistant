# 00631L Lab v5.20 ETF Room Readiness Panel

## Scope

v5.20 adds a Settings checklist that summarizes whether the app is ready for
daily ETF research use.

## What Changed

- Adds `ETF 研究室完成度` near the top of Settings.
- Summarizes public PWA availability and live backend dependency.
- Summarizes 00631L holdings, price history, and intraday status.
- Summarizes multi-ETF price-history readiness.
- Shows the active symbol readiness state.
- Confirms position data is local-only and AI analysis is rule-based.

## User Impact

Users can open Settings and quickly see which parts of the ETF research room are
ready, which parts depend on backend/data freshness, and which program operation
to run next.

This checklist describes app/data state only.

## Validation

- `flutter analyze`
- `flutter test`
- `flutter build web`
- `py -m unittest discover -s backend\tests`
- `scripts\00631l_release_check.cmd`
- `git diff --check`
