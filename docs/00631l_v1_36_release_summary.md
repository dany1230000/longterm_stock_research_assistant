# 00631L lab v1.36 restore dry-run summary

v1.36 adds a read-only restore dry-run for local 00631L backup archives.

## Scope

- Added `scripts\00631l_restore_dry_run.cmd`.
- Added `backend\scripts\restore_00631l_dry_run.py`.
- Added `backend\app\restore_dry_run.py`.
- Added backend unit tests for readable backups, missing backups, and invalid backup archives.
- Added `00631L_RESTORE_DRY_RUN_STATUS_PATH` for the latest local dry-run result.

## Behavior

The dry-run reads the latest `00631l_local_data_backup_*.zip` under `backend\backups\` unless a specific `--backup-path` is provided. It validates `backup_manifest.json` and confirms included archive entries can be read.

It does not copy files back into `backend\data\` or `backend\exports\`.

## Status Rules

- `PASS`: backup manifest and included entries are readable.
- `WARN`: no backup exists, or the manifest records missing source files.
- `FAIL`: the archive is unreadable, the manifest is missing, or an included entry is missing.

## Validation

Run:

```cmd
scripts\00631l_restore_dry_run.cmd
flutter analyze
flutter test
flutter build web
py -m unittest discover -s backend\tests
scripts\00631l_release_check.cmd
git diff --check
```

This release does not connect TX live, expand beyond 00631L, add notification features, or add investment guidance.
