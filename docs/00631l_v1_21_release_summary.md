# 00631L Lab v1.21 Release Summary

Date: 2026-06-09

## Scope

v1.21 improves the entry experience without changing the app shell.

Added:

- A dedicated Dashboard entry card for `00631L 正二研究室`.
- A direct route hint in `scripts/00631l_start_frontend_live.cmd`.
- Daily usage documentation that explains the app shell name and `/00631l-lab` route.

## Boundaries

The original app dashboard remains in place. This release does not connect TX live, expand beyond 00631L, add notification features, or add trading advice.

## Validation

Required validation:

```cmd
flutter analyze
flutter test
flutter build web
py -m unittest discover -s backend\tests
scripts\00631l_release_check.cmd
git diff --check
```
