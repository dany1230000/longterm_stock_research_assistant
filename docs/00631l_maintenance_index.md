# 00631L maintenance document index

This index reduces duplicate lookup paths for the semi-automated maintenance workflow.

## Daily Operation

- Daily usage: `docs\00631l_daily_usage.md`
- Daily report guide: `docs\00631l_daily_report_guide.md`
- Troubleshooting: `docs\00631l_troubleshooting.md`

## Maintenance Scripts

- Environment check: `scripts\00631l_check_env.cmd`
- Deployment bootstrap: `scripts\00631l_bootstrap_deploy.cmd`
- Daily cycle: `scripts\00631l_daily_cycle.cmd`
- Scheduled daily cycle wrapper: `scripts\00631l_daily_cycle_scheduled.cmd`
- CSV export: `scripts\00631l_export_history.cmd`
- Daily report generation: `scripts\00631l_generate_daily_report.cmd`
- Data integrity check: `scripts\00631l_check_integrity.cmd`
- Local backup with rotation: `scripts\00631l_backup_data.cmd --retention-count 30`
- Restore dry-run: `scripts\00631l_restore_dry_run.cmd`
- Release check: `scripts\00631l_release_check.cmd`

## Setup And Deployment

- Scheduler setup: `docs\00631l_scheduler_setup.md`
- Deployment notes: `docs\00631l_deployment_notes.md`
- Release checklist: `docs\00631l_release_checklist.md`
- Maintenance release summary: `docs\00631l_v1_40_maintenance_summary.md`
- Backend disconnected state: `docs\00631l_v1_43_release_summary.md`

## Script Output Convention

Maintenance scripts should print detailed JSON or step output, then end with a compact summary line when practical:

```text
[summary] overallStatus=PASS warnings=0 failures=0
```

`WARN` is acceptable for local setup or off-hours freshness states when `failures=0`. `FAIL` requires review of the failed step, `errorMessage`, or `failures` list.

## Scope Boundary

The maintenance workflow keeps 00631L data collection, history, exports, reports, backups, and local validation usable. It does not connect TX live, expand beyond 00631L, add notifications, or provide investment guidance.
