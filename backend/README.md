# 00631L live proxy backend

Minimal FastAPI proxy for the 00631L lab.

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

## Environment variables

See `backend/.env.example` for the deployable template.

- `TWSE_00631L_INTRADAY_NAV_URL`: verified TWSE feed, currently `https://mis.twse.com.tw/stock/data/all_etf.txt`.
- `YUANTA_00631L_INTRADAY_NAV_URL`: verified Yuanta INAV fallback URL from the Yuanta INAV page network request.
- `00631L_INTRADAY_NAV_SOURCE`: `twse`, `yuanta`, or `auto`.
- `00631L_PROFILE_CACHE_SECONDS`: default `86400`.
- `00631L_HOLDINGS_CACHE_SECONDS`: default `600`.
- `00631L_INTRADAY_NAV_CACHE_SECONDS`: default `15`.
- `00631L_HOLDINGS_HISTORY_PATH`: local JSONL path for daily holdings history, default `backend/data/00631l_holdings_history.jsonl`.
- `00631L_INTRADAY_NAV_HISTORY_PATH`: local JSONL path for intraday NAV history, default `backend/data/00631l_intraday_nav_history.jsonl`.
- `00631L_BACKUP_DIR`: local backup output directory, default `backend/backups`.

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

Yuanta Basic and Yuanta ratio are daily official sources. Intraday NAV is only market price, estimated NAV, premium/discount, and data time. TX remains mock/fallback in v1.0.

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

## v1.10 operations status

Endpoint:

```text
GET /api/etf/00631l/operations/status
```

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

The file is local operational state and is ignored by git. `operations/status` reads it when present. If the file does not exist, the endpoint reports `dailyCycle.sourceStatus: unavailable` and `overallStatus: missing`.

## v1.18 release check

Run the full local release check:

```cmd
scripts\00631l_release_check.cmd
```

The wrapper runs env check, Flutter analyze/test/build, backend tests, daily cycle, export, live smoke, forbidden wording scan, and `git diff --check`. It returns exit code `1` only for failures. WARN is used for expected local/off-hours conditions such as missing local `.env` while fallback mode is still operational.

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
