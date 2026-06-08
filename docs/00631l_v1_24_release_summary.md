# 00631L Lab v1.24 Release Summary

Date: 2026-06-09

## Scope

v1.24 adds local data backup for 00631L operational state.

Added:

- `backend/app/data_backup.py`
- `backend/scripts/backup_00631l_data.py`
- `scripts/00631l_backup_data.cmd`
- `backend/tests/test_data_backup.py`

Updated:

- `.gitignore` ignores `backend/backups/`.
- `backend/.env.example` includes `00631L_BACKUP_DIR`.
- Docs explain backup and manual restore review.

Backup includes files when present:

- holdings history JSONL
- intraday NAV history JSONL
- daily cycle status JSON
- CSV export metadata JSON

## Boundaries

This release does not add restore automation, connect TX live, expand beyond 00631L, add notification features, or add trading advice.

## Validation

Required validation:

```cmd
scripts\00631l_backup_data.cmd
flutter analyze
flutter test
flutter build web
py -m unittest discover -s backend\tests
scripts\00631l_release_check.cmd
git diff --check
```
