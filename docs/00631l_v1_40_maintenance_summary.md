# 00631L lab v1.40 semi-automated maintenance summary

v1.40 closes the v1.31-v1.40 maintenance release line. The 00631L lab is now ready for semi-automated daily maintenance on a local Windows machine.

## Completed Scope

- Windows Task Scheduler preparation for daily cycle.
- Local daily Markdown reports.
- Frontend operations/status report visibility.
- Local data integrity checks.
- Backup rotation.
- Restore dry-run.
- Daily report user guide.
- Strengthened release check.
- Maintenance document index.
- Consistent script summary output for key maintenance scripts.

## Live Data Sources

- Yuanta 00631L Basic information: official via backend proxy.
- Yuanta 00631L ratio holdings: official via backend proxy.
- TWSE ETF intraday NAV aggregate feed: official when configured.
- Yuanta INAV: verified fallback when configured.

## Local State And Outputs

Ignored local paths:

```text
backend\data\
backend\exports\
backend\backups\
backend\reports\
```

These hold local history, CSV exports, backup archives, daily cycle status, integrity status, restore dry-run status, and Markdown reports.

## Daily Maintenance Commands

Environment check:

```cmd
scripts\00631l_check_env.cmd
```

Daily cycle:

```cmd
scripts\00631l_daily_cycle.cmd
```

Daily report:

```cmd
scripts\00631l_generate_daily_report.cmd
```

CSV export:

```cmd
scripts\00631l_export_history.cmd
```

Integrity check:

```cmd
scripts\00631l_check_integrity.cmd
```

Backup with rotation:

```cmd
scripts\00631l_backup_data.cmd --retention-count 30
```

Restore dry-run:

```cmd
scripts\00631l_restore_dry_run.cmd
```

Release check:

```cmd
scripts\00631l_release_check.cmd
```

## Maintenance Documents

- `docs\00631l_maintenance_index.md`
- `docs\00631l_daily_usage.md`
- `docs\00631l_daily_report_guide.md`
- `docs\00631l_scheduler_setup.md`
- `docs\00631l_troubleshooting.md`
- `docs\00631l_deployment_notes.md`
- `docs\00631l_release_checklist.md`

## Validation

Final validation for this release line:

```cmd
flutter analyze
flutter test
flutter build web
py -m unittest discover -s backend\tests
scripts\00631l_release_check.cmd
git diff --check
```

PASS is ideal. WARN is acceptable when `failures=[]` and the warning is caused by local setup or off-hours freshness state.

## Explicitly Not Included

- TX live data connection.
- Expansion beyond 00631L.
- Notification features.
- Investment guidance.
- Automated trading.

## Release Boundary

This release focuses on local maintenance reliability: scheduled daily cycle preparation, report generation, integrity checking, backup validation, release checking, and user documentation. It does not change the investment analysis scope.
