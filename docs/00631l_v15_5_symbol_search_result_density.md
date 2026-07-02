# 00631L v15.5 Symbol Search Result Density

This release tightens the left-top symbol search result list on phones.

## What Changed

- Phone width search rows use smaller padding and a compact code badge.
- ETF code, name, readiness badge, and price remain visible in the main row.
- Extra capability details still open from the detail toggle, but no longer dominate the default row.

## Product Boundary

- No ETF catalog source change.
- No historical data calculation change.
- No selected ETF switching behavior change.
- This is a phone layout density improvement only.

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
