# 00631L lab v1.45 release summary

Completed on 2026-06-09.

## Scope

v1.45 adds a conservative retention policy for local history, reports, and CSV exports.

## Changes

- Added `backend/app/retention_policy.py`.
- Added `backend/scripts/apply_00631l_retention.py`.
- Added `scripts/00631l_apply_retention.cmd`.
- Added backend tests for report pruning and dry-run behavior.
- Added `.env.example` settings:
  - `00631L_REPORT_RETENTION_COUNT=30`
  - `00631L_EXPORT_RETENTION_COUNT=30`
- Updated user docs with the local retention command.

## Policy

- Holdings and intraday JSONL history are retained as the long-term local record.
- Daily Markdown reports under `backend/reports/` are pruned by retention count.
- CSV exports under `backend/exports/` use fixed current filenames, so the retention helper reports their status instead of pruning archives.

## Commands

Apply report retention:

```cmd
scripts\00631l_apply_retention.cmd --report-retention-count 30
```

Dry-run:

```cmd
scripts\00631l_apply_retention.cmd --dry-run --report-retention-count 30
```

## Limits

- No TX live source was added.
- No notifications were added.
- No investment guidance was added.
- The helper does not automatically delete JSONL history.

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
