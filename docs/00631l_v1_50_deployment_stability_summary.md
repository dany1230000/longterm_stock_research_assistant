# 00631L lab v1.50 deployment stability summary

Completed on 2026-06-09.

## Release Goal

v1.50 closes the deployment and data reliability release line from v1.41 to v1.50. The goal is a stable local/deployable 00631L lab workflow with clearer health checks, safer backups, retention policy, and maintainable docs.

## Completed Scope

- Deployment bootstrap: `scripts\00631l_bootstrap_deploy.cmd`
- Backend health/status metadata: `/health` and `/api/etf/00631l/operations/status`
- Frontend backend disconnected state: `/00631l-lab`
- Latest daily report UI: `/00631l-lab`
- Local retention policy: `scripts\00631l_apply_retention.cmd`
- Backup checksum: `scripts\00631l_backup_data.cmd`
- Restore dry-run checksum verification: `scripts\00631l_restore_dry_run.cmd`
- Deployment precheck: `scripts\00631l_deploy_precheck.cmd`
- Release check with deployment precheck and retention dry-run: `scripts\00631l_release_check.cmd`
- Documentation index: `docs\00631l_docs_index.md`
- Documentation index test coverage: `backend\tests\test_documentation_index.py`

## Data Reliability

- Official Yuanta Basic and ratio sources remain live through backend proxy.
- TWSE intraday NAV remains live through `sourceContract: twse_a_k_json`.
- Yuanta INAV remains fallback through `sourceContract: yuanta_inav`.
- Local JSONL history remains the long-term local record and is not pruned automatically.
- Daily Markdown reports can be pruned by retention count.
- CSV exports use fixed current filenames and are included in backup metadata.
- Backup manifests include per-file SHA256.
- Restore dry-run verifies archive entries and does not overwrite local data.

## Daily Commands

Start from the docs index:

```cmd
type docs\00631l_docs_index.md
```

Precheck deployment:

```cmd
scripts\00631l_deploy_precheck.cmd
```

Run daily cycle:

```cmd
scripts\00631l_daily_cycle.cmd
```

Open lab helper:

```cmd
scripts\00631l_open_lab.cmd
```

Release validation:

```cmd
scripts\00631l_release_check.cmd
```

## Validation

Final v1.50 validation should run:

```cmd
flutter analyze
flutter test
flutter build web
py -m unittest discover -s backend\tests
scripts\00631l_release_check.cmd
git diff --check
```

## Explicitly Not Included

- TX live source.
- All-leveraged-ETF expansion.
- Notifications.
- Automated trading.
- Investment guidance.
- Commit of local `.env`, build output, reports, exports, backups, cache, or logs.

## Status

v1.50 can be treated as the stable deployment and data reliability checkpoint for the 00631L lab, subject to live source availability and local backend operation.
