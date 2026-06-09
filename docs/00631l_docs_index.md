# 00631L documentation index

This is the main entry point for 00631L lab documentation.

## Start Here

- Daily usage: `docs\00631l_daily_usage.md`
- Troubleshooting: `docs\00631l_troubleshooting.md`
- Maintenance index: `docs\00631l_maintenance_index.md`
- Deployment notes: `docs\00631l_deployment_notes.md`

## Daily Operation

- Open lab helper: `scripts\00631l_open_lab.cmd`
- Backend startup: `scripts\00631l_start_backend.cmd`
- Frontend live proxy: `scripts\00631l_start_frontend_live.cmd`
- Daily cycle: `scripts\00631l_daily_cycle.cmd`
- Release check: `scripts\00631l_release_check.cmd`

## Data And Reports

- Daily report guide: `docs\00631l_daily_report_guide.md`
- Holdings and intraday source notes: `docs\00631l_lab.md`
- Live proxy details: `docs\00631l_live_proxy.md`
- CSV export: `scripts\00631l_export_history.cmd`
- Retention policy: `scripts\00631l_apply_retention.cmd --dry-run --report-retention-count 30`
- Backup: `scripts\00631l_backup_data.cmd --retention-count 30`
- Restore dry-run: `scripts\00631l_restore_dry_run.cmd`

## Setup And Deployment

- Backend README: `backend\README.md`
- Env template: `backend\.env.example`
- Deployment bootstrap: `scripts\00631l_bootstrap_deploy.cmd`
- Deployment precheck: `scripts\00631l_deploy_precheck.cmd`
- Scheduler setup: `docs\00631l_scheduler_setup.md`

## Release Summaries

Release summaries remain available for audit history. For daily use, prefer the start-here docs above.

- Daily-use release: `docs\00631l_v1_20_final_summary.md`
- Daily experience release: `docs\00631l_v1_30_daily_experience_summary.md`
- Maintenance release: `docs\00631l_v1_40_maintenance_summary.md`
- Deployment stability release: `docs\00631l_v1_50_deployment_stability_summary.md`

## Scope Boundary

This project remains scoped to 00631L. TX live, all-leveraged-ETF expansion, notifications, automated trading, and investment guidance are outside the current scope.
