# 00631L lab v1.43 release summary

Completed on 2026-06-09.

## Scope

v1.43 improves the frontend state shown when live proxy mode is enabled but the backend is not reachable.

## Changes

- `Cached00631LRepository` now preserves a backend connection error in operations status while keeping mock/fallback data visible.
- `/00631l-lab` shows `backend disconnected`, `backend reachable`, `backend unavailable`, or `mock fallback` in the daily data status area.
- The operations guidance now tells the user to start `scripts\00631l_start_backend.cmd` and reopen `/#/00631l-lab` when the backend is disconnected.
- Widget and repository tests cover the disconnected backend fallback path.

## Behavior

- Backend down: page remains usable with mock/fallback data and explicit `backend disconnected` status.
- Backend up: operations/status metadata continues to show live proxy/cached source labels.
- Default mock mode remains unchanged.

## Limits

- No TX live source was added.
- No scope expansion beyond 00631L was added.
- No notifications or investment guidance were added.

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
