# 00631L live proxy backend

Minimal FastAPI proxy for the 00631L lab.

Health endpoint:

```text
GET /health
```

The response includes backend version, 00631L-only scope, live-source configuration flags, local-state readiness, and key endpoint paths. It does not fetch live Yuanta or TWSE data.

Readiness endpoint:

```text
GET /ready
```

`/ready` checks public API URL, CORS origins, data directory write access, persistent data mode, TWSE URL configuration, and live source connectivity. Missing public deployment values are WARN in local mode. An unwritable data directory or invalid URL format is FAIL.

Production deployment helpers:

```cmd
scripts\00631l_backend_prod_check.cmd
scripts\00631l_backend_docker_check.cmd
scripts\00631l_remote_maintenance.cmd --dry-run
docker compose -f deploy\docker-compose.yml up -d --build
```

Full live backend deployment guide: `docs\00631l_live_backend_deployment.md`.

Remote public backend maintenance:

```cmd
scripts\00631l_remote_maintenance.cmd --mode all
```

GitHub Actions can run the same checks through `.github/workflows/00631l_backend_maintenance.yml`. The workflow wakes the public backend, checks readiness, collects intraday status, updates official price history, and verifies status endpoints. Details: `docs\00631l_remote_maintenance.md`.

## v1.0 local setup

Create a local env file:

```powershell
cd C:\dev\longterm_stock_research_assistant
Copy-Item backend\.env.example backend\.env
```

`backend/.env` is ignored by git. Do not put secrets or local tokens in tracked files.

Start the backend:

```powershell
.\backend\run_dev.ps1
```

CMD wrapper:

```cmd
scripts\00631l_start_backend.cmd
```

Equivalent command:

```powershell
py -m uvicorn backend.app.main:app --reload --host 127.0.0.1 --port 8000
```

Production-like command:

```powershell
py -m uvicorn backend.app.main:app --host 0.0.0.0 --port 8000
```

Docker:

```cmd
docker build -f backend\Dockerfile -t 00631l-lab-backend .
docker run --rm -p 8000:8000 --env-file backend\.env -v 00631l-data:/data/00631l 00631l-lab-backend
```

Frontend live proxy mode:

```powershell
flutter run -d chrome --dart-define=USE_00631L_LIVE_PROXY=true --dart-define=00631L_PROXY_BASE_URL=http://127.0.0.1:8000
```

CMD wrapper:

```cmd
scripts\00631l_start_frontend_live.cmd
```

Local environment check:

```cmd
scripts\00631l_check_env.cmd
```

Daily open helper:

```cmd
scripts\00631l_open_lab.cmd
```

Release checklist: `docs/00631l_release_checklist.md`.

Daily usage guide: `docs/00631l_daily_usage.md`.

Daily report guide: `docs/00631l_daily_report_guide.md`.

Maintenance index: `docs/00631l_maintenance_index.md`.

Maintenance release summary: `docs/00631l_v1_40_maintenance_summary.md`.

Deployment bootstrap: `scripts\00631l_bootstrap_deploy.cmd`.

Main documentation map: `docs\00631l_docs_index.md`.

## Environment variables

See `backend/.env.example` for the deployable template.

- `PUBLIC_API_BASE_URL`: public backend URL shown in health/status metadata.
- `ALLOWED_ORIGINS`: comma-separated frontend origins allowed by CORS.
- `00631L_DATA_DIR`: base data directory for JSONL/status data.
- `00631L_DATA_PERSISTENCE_MODE`: `local`, `persistent`, or `transient`; public deployments should use `persistent`.
- `TWSE_00631L_INTRADAY_NAV_URL`: verified TWSE feed, currently `https://mis.twse.com.tw/stock/data/all_etf.txt`.
- `YUANTA_00631L_INTRADAY_NAV_URL`: verified Yuanta INAV fallback URL from the Yuanta INAV page network request.
- `00631L_INTRADAY_NAV_SOURCE`: `twse`, `yuanta`, or `auto`.
- `00631L_PROFILE_CACHE_SECONDS`: default `86400`.
- `00631L_HOLDINGS_CACHE_SECONDS`: default `600`.
- `00631L_INTRADAY_NAV_CACHE_SECONDS`: default `15`.
- `00631L_TX_QUOTE_CACHE_SECONDS`: default `15`.
- `TAIFEX_TX_SOCKJS_URL`: TAIFEX MIS quote stream root, default `https://mis.taifex.com.tw/futures/rt`.
- `TAIFEX_TX_FUTURES_SYMBOL`: default `TXF-P`.
- `TAIFEX_TX_SPOT_SYMBOL`: default `TXF-S`.
- `00631L_HOLDINGS_HISTORY_PATH`: local JSONL path for daily holdings history, default `backend/data/00631l_holdings_history.jsonl`.
- `00631L_INTRADAY_NAV_HISTORY_PATH`: local JSONL path for intraday NAV history, default `backend/data/00631l_intraday_nav_history.jsonl`.
- `ETF_CATALOG_PATH`: local normalized TWSE all-ETF catalog JSON path, default `backend/data/twse_etf_catalog.json`.
- `00631L_BACKUP_DIR`: local backup output directory, default `backend/backups`.
- `00631L_BACKUP_RETENTION_COUNT`: number of local backup archives to keep, default `30`.
- `00631L_REPORT_DIR`: local daily Markdown report directory, default `backend/reports`.
- `00631L_REPORT_RETENTION_COUNT`: number of daily Markdown report files to keep, default `30`.
- `00631L_EXPORT_RETENTION_COUNT`: policy count for fixed CSV export outputs, default `30`.
- `00631L_INTEGRITY_STATUS_PATH`: local data integrity check result, default `backend/data/00631l_integrity_status.json`.
- `00631L_RESTORE_DRY_RUN_STATUS_PATH`: latest restore dry-run result, default `backend/data/00631l_restore_dry_run_status.json`.

`auto` tries TWSE first and then Yuanta. If neither URL is configured, intraday NAV returns `sourceStatus: unavailable` and does not return mock data as official data.

## Response metadata

All three 00631L endpoints include:

- `sourceStatus`
- `sourceContract` (`twse_a_k_json`, `yuanta_inav`, or `null` when not applicable)
- `sourceUrl`
- `fetchedAt`
- `sourceUpdatedAt`
- `dataTime`
- `isStale`
- `errorMessage`

Yuanta Basic and Yuanta ratio are daily official sources. Intraday NAV is market price, estimated NAV, premium/discount, and data time. TAIFEX TX quote is exposed separately at `/api/etf/00631l/tx-quote`; off-hours can return unavailable or stale. TWSE all-ETF catalog can be imported for future ETF-room work and is not treated as 00631L official holdings.

Manual live smoke:

```powershell
cd C:\dev\longterm_stock_research_assistant
.\scripts\00631l_daily_smoke.ps1
```

The wrapper loads `backend\.env` and then calls `backend\scripts\smoke_00631l_live.py`. The smoke script is not part of the default unit test suite. It performs network checks against Yuanta and the optional intraday NAV URL, so failures should be reviewed manually instead of breaking CI.

Smoke output includes an `[overall]` block:

- `PASS`: sources parsed and freshness checks are within expected bounds.
- `WARN`: sources parsed, but freshness should be reviewed manually. This is common after market close, overnight, or on weekends.
- `FAIL`: a required source failed to fetch or parse.

The script prints Basic/ratio/intraday `sourceStatus`, intraday `sourceContract`, cache status, market price, estimated NAV, premium/discount, `dataTime`, and `fetchedAt`.

```powershell
cd C:\dev\longterm_stock_research_assistant
py -m pip install -r backend\requirements.txt
py -m uvicorn backend.app.main:app --reload --host 127.0.0.1 --port 8000
```

The intraday NAV endpoint needs a configured TWSE and/or Yuanta JSON URL:

```powershell
$env:TWSE_00631L_INTRADAY_NAV_URL="https://mis.twse.com.tw/stock/data/all_etf.txt"
$env:YUANTA_00631L_INTRADAY_NAV_URL="https://etfapi.yuantaetfs.com/ectranslation/api/trans?APIType=ETFBackstage&CompanyName=YUANTAFUNDS&PageName=%2FtradeInfo%2FINav%2FAsia_ETF&DeviceId=00000000-0000-4000-8000-000000000631&FuncId=ETFNAV%2FGetINAV_Data&AppName=ETF&Device=4&Platform=ETF"
${env:00631L_INTRADAY_NAV_SOURCE}="auto"
```

Source mode:

- `twse`: only parse the TWSE a-k aggregate feed (`sourceContract: twse_a_k_json`).
- `yuanta`: only parse Yuanta's INAV API (`sourceContract: yuanta_inav`).
- `auto`: try TWSE first, then Yuanta.

If no intraday URL is configured, `/api/etf/00631l/intraday-nav` returns
`sourceStatus: unavailable` instead of mock data.

Yuanta Basic and ratio pages were verified live on 2026-06-08. TWSE `all_etf.txt` and Yuanta INAV were also smoke-tested for 00631L intraday NAV. The live smoke script is manual because network/API changes should not fail unit test CI.

## v1.2 holdings history

When `/api/etf/00631l/holdings` successfully fetches and parses an official Yuanta ratio snapshot, the backend saves one local JSONL history record per `tradeDate`. Repeated fetches for the same `tradeDate` and `sourceHash` are skipped; if the same `tradeDate` has a new `sourceHash`, the local record is replaced.

History endpoints:

```text
GET /api/etf/00631l/holdings/history?limit=30
GET /api/etf/00631l/holdings/history/summary?limit=30
```

The full history endpoint returns stored daily snapshots. The summary endpoint returns the trend fields used by the Flutter page: TX weight, TSMC weight, stock asset %, futures asset %, cash and margin %, NAV, fund net asset value, and outstanding units.

If no history file exists yet, the endpoints return `sourceStatus: unavailable` with an empty `items` list. They do not return mock data as official history.

## v1.4 intraday NAV history

When `/api/etf/00631l/intraday-nav` successfully fetches an official TWSE or Yuanta intraday NAV sample, the backend saves it to local JSONL. Repeated samples with the same `sourceContract` and `dataTime` are skipped.

Endpoints:

```text
GET /api/etf/00631l/intraday-nav/history?date=YYYY-MM-DD&limit=500
GET /api/etf/00631l/intraday-nav/history/summary?date=YYYY-MM-DD
```

The summary endpoint returns the sample count, highest premium, lowest discount, average premium/discount, first data time, last data time, latest market price, and latest estimated NAV.

If no intraday history exists yet, the endpoints return `sourceStatus: unavailable` with an empty `items` list. They do not fabricate official intraday history from mock data.

## v4.1 TX quote and ETF catalog

TX quote endpoint:

```text
GET /api/etf/00631l/tx-quote
```

The endpoint uses the TAIFEX MIS quote stream with `sourceContract: taifex_sockjs_quote`. It reports TXF-P price, TXF-S weighted-index reference, basis points, basis percent, data time, and clear unavailable/error metadata. TAIFEX can omit a last price outside active sessions, so the backend does not convert that into mock official data.

TWSE ETF catalog endpoints:

```text
GET /api/etf/catalog
GET /api/etf/catalog/status
POST /api/etf/catalog/import
```

Manual import:

```cmd
scripts\00631l_import_etf_catalog.cmd
scripts\00631l_import_etf_catalog.cmd --status-only
```

The catalog is normalized from TWSE `all_etf.txt` and saved under `ETF_CATALOG_PATH`. It is local operational data and should not be committed.

## v1.10 operations status

Endpoint:

```text
GET /api/etf/00631l/operations/status
```

AI analysis summary:

```text
GET /api/etf/00631l/analysis/summary
```

The analysis endpoint uses `source: rule_based` by default. It reads local operations/history/report/export/backup/integrity state and returns bullets, actionItems, sourceStatuses, and `disclaimer: 非買賣建議`. External LLM support is only a disabled placeholder and requires a future explicit release before any `.env` key is used.

This endpoint reads local configuration and local JSONL history summaries. It does not fetch Yuanta or TWSE live sources. It reports intraday source mode, whether TWSE/Yuanta intraday URLs are configured, latest holdings history trade date, intraday NAV sample count, latest intraday data time, and collector commands.

If there is no local history, the endpoint returns `sourceStatus: unavailable`; it does not return mock data as official operational state.

## v1.14 data freshness summary

`/api/etf/00631l/operations/status` also reports:

- latest holdings history trade date
- latest intraday NAV data time
- holdings history and intraday sample counts
- CSV export availability and latest export file time
- local env readiness and missing required keys
- latest daily cycle status file when present
- a compact `statusSummary` object for frontend rendering

This endpoint still reads only local state and configuration. It does not fetch live Yuanta or TWSE sources and does not mark missing local state as official data.

## v1.15 daily cycle status

`scripts\00631l_daily_cycle.cmd` calls `backend\scripts\run_00631l_daily_cycle.py`.

The runner executes collect, export, and live smoke, then writes the latest result to:

```text
backend/data/00631l_daily_cycle_status.json
```

## v1.45 retention policy

Apply local retention:

```cmd
scripts\00631l_apply_retention.cmd --report-retention-count 30
```

Dry-run without deleting report files:

```cmd
scripts\00631l_apply_retention.cmd --dry-run --report-retention-count 30
```

The policy is intentionally conservative:

- Holdings and intraday JSONL history are retained as the long-term local record.
- Daily Markdown reports under `backend/reports/` are pruned by retention count.
- CSV exports use fixed current filenames under `backend/exports/`, so they are reported but not archived by the retention helper.

## v1.46 backup checksum

`scripts\00631l_backup_data.cmd` writes SHA256 metadata for every included file in `backup_manifest.json` and reports the generated zip archive SHA256.

`scripts\00631l_restore_dry_run.cmd` reads the latest backup, verifies archive entries against manifest SHA256 values, and reports `entriesVerified`. It still does not overwrite local data.

## v1.47 deployment precheck

Run a lightweight deployment readiness check:

```cmd
scripts\00631l_deploy_precheck.cmd
```

The release check now runs deployment precheck and retention dry-run before finishing. Deployment precheck validates local scripts, web metadata, backend env templates, and local data directories. Missing optional local `.env` is WARN, not FAIL.

The file is local operational state and is ignored by git. `operations/status` reads it when present. If the file does not exist, the endpoint reports `dailyCycle.sourceStatus: unavailable` and `overallStatus: missing`.

## v1.18 release check

Run the full local release check:

```cmd
scripts\00631l_release_check.cmd
```

The wrapper runs env check, Flutter analyze/test/build, backend tests, daily cycle, export, report generation, data integrity, backup rotation, restore dry-run, live smoke, forbidden wording scan, and `git diff --check`. It also checks required maintenance docs/scripts such as scheduler setup and restore dry-run. It returns exit code `1` only for failures. WARN is used for expected local/off-hours conditions such as missing local `.env` while fallback mode is still operational.

## v1.24 local data backup

Create a local backup archive:

```cmd
scripts\00631l_backup_data.cmd
```

The archive is written under ignored local storage:

```text
backend/backups/
```

Included when present:

- holdings history JSONL
- intraday NAV history JSONL
- latest daily cycle status JSON
- CSV export metadata JSON

Restore is a manual review flow in v1.24. Unzip to a temporary folder, compare file dates and contents, then copy selected files back to `backend/data/` or `backend/exports/` only after review.

v1.35 adds rotation for files matching `00631l_local_data_backup_*.zip`. The default retention is 30 archives and can be changed with:

```cmd
scripts\00631l_backup_data.cmd --retention-count 30
```

## v1.36 restore dry-run

Validate the latest local backup archive without restoring it:

```cmd
scripts\00631l_restore_dry_run.cmd
```

The dry-run reads `backup_manifest.json`, checks that every included archive entry is present and readable, then writes a local status file under ignored `backend/data/`. It never copies files back into `backend/data/` or `backend/exports/`.

You can point it at a specific archive:

```cmd
scripts\00631l_restore_dry_run.cmd --backup-path backend\backups\00631l_local_data_backup_YYYYMMDD_HHMMSSZ.zip
```

## v1.25 data directory health

`scripts\00631l_check_env.cmd` checks:

- `backend/data`
- `backend/exports`
- `backend/backups`

Each directory is created when missing and tested for local write access. Missing holdings history, export metadata, or backup archives are reported as WARN so a fresh install remains usable.

`/api/etf/00631l/operations/status` also reports `dataDirectoryHealth`, `backup`, and `config.backupDirReady`. The Flutter page shows backup and directory readiness in the operations/status area.

## v1.19 daily usage guide

Daily operation is documented in:

```text
docs/00631l_daily_usage.md
```

The guide covers first setup, backend startup, Flutter live proxy startup, daily cycle, operations/status review, holdings history, CSV export, smoke WARN review, backend-down recovery, `.env` setup, and source status definitions. It keeps the scope limited to data status and does not change backend behavior.

## v1.26 open lab helper

```cmd
scripts\00631l_open_lab.cmd
```

The helper runs the local environment check, probes backend health, and prints the exact backend, daily cycle, Flutter live proxy, and direct `/#/00631l-lab` route commands. It does not hide backend or Flutter server processes in the background.

## v1.32 daily report

`scripts\00631l_daily_cycle.cmd` generates a local Markdown report after collect, export, and smoke complete. The report is written under ignored `backend\reports\`.

Manual report generation:

```cmd
scripts\00631l_generate_daily_report.cmd
```

`/api/etf/00631l/operations/status` reports latest daily report metadata under the `report` key.

## v1.34 data integrity check

```cmd
scripts\00631l_check_integrity.cmd
```

The checker reads local holdings and intraday JSONL history, then writes:

```text
backend\data\00631l_integrity_status.json
```

Duplicate keys and missing required fields are FAIL. Weekday gaps and abnormal source statuses are WARN.

## v1.13 local startup checks

Environment check:

```cmd
scripts\00631l_check_env.cmd
```

The check confirms the clean Flutter SDK path, Flutter/Dart/Python availability, backend dependencies, local `.env` presence, intraday NAV URL configuration, and local data/export directory readiness. A missing `backend\.env` is a warning because mock/fallback mode remains usable.

Startup wrappers:

```cmd
scripts\00631l_start_backend.cmd
scripts\00631l_start_frontend_live.cmd
```

## v1.11 CSV history export

Export local JSONL history stores to CSV:

```cmd
scripts\00631l_export_history.cmd
```

Default output directory:

```text
backend/exports/
```

Generated files:

- `00631l_holdings_history_summary.csv`
- `00631l_intraday_nav_history.csv`
- `00631l_history_export_metadata.json`

Holdings CSV fields include `tradeDate`, `navPerUnit`, `fundNetAssetValue`, `outstandingUnits`, `txWeightPct`, `tsmcWeightPct`, `stockExposurePct`, `futuresExposurePct`, `cashAndMarginPct`, `sourceStatus`, `sourceUrl`, `fetchedAt`, and `sourceHash`.

The metadata JSON includes `exportedAt`, row counts, source history range, and output paths. `operations/status` reports the latest export file and metadata when available.

`backend/exports/` is ignored by git. The exporter only reads local JSONL history; it does not fetch live sources and does not fabricate official history.

## v1.7 snapshot collector

The collector uses the same backend service as the API endpoints. It fetches profile, holdings, and intraday NAV, then relies on the service to save successful official holdings and intraday NAV payloads into the configured local JSONL history stores.

Manual one-shot collection:

```cmd
scripts\00631l_collect_snapshot.cmd --samples 1
```

Direct Python command:

```powershell
py backend\scripts\collect_00631l_snapshot.py --samples 1
```

Collect repeated intraday NAV samples:

```cmd
scripts\00631l_collect_snapshot.cmd --skip-profile --skip-holdings --samples 20 --interval-seconds 15
```

The collector exits with code `1` only when a required source fails. Holdings are required because they are the daily official snapshot source. Intraday NAV unavailable/error is reported as `WARN` so off-hours or missing URL checks do not break local operation.

## v1.6 daily workflow

Daily runbook:

```text
docs/00631l_v1_6_daily_runbook.md
```

Use `.\backend\run_dev.ps1` for local backend startup. Use `.\scripts\00631l_daily_smoke.ps1` for daily live source observation.

If local PowerShell script execution is disabled, use `scripts\00631l_daily_smoke.cmd` for smoke observation and `scripts\00631l_release_validate.cmd` for the full validation sequence.
