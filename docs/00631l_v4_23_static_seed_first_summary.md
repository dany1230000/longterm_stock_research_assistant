# 00631L lab v4.23 Static Seed-First Export

Date: 2026-06-21

## Scope

v4.23 hardens GitHub Pages static-public builds. CI runners usually do not have `backend/data`, so static export must load committed seed history before deciding the incremental update start date.

## Changes

- Added `_prepare_price_history_update_start` for static export.
- Static export now merges the 00631L seed before incremental update when no local cache exists.
- `--start-date` and `--full-refresh` still override the default behavior.
- Added a unit test for the CI-like empty-cache plus seed case.

## Result

- Static export update remains incremental by default.
- Pages builds can start from committed seed data and fetch only the latest cached month instead of attempting a full 2014-present refresh.
- Generated `web\00631l-static-data` files remain ignored.
