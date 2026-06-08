# 00631L Lab v1.6 Daily Runbook

Date: 2026-06-08

Scope: daily operation, validation, and deployment flow for the single-product 00631L lab. This version does not connect TX live, expand to other leveraged ETFs, or add trading advice.

## One-Time Local Setup

Use the clean Flutter SDK:

```powershell
$env:PATH="C:\src\flutter-clean\bin;$env:PATH"
flutter --version
```

Create local backend env:

```powershell
cd C:\dev\longterm_stock_research_assistant
Copy-Item backend\.env.example backend\.env
```

Keep `backend\.env` local. Do not commit it.

## Daily Backend Start

```powershell
cd C:\dev\longterm_stock_research_assistant
.\backend\run_dev.ps1
```

The script loads `backend\.env` if present, then starts FastAPI at `http://127.0.0.1:8000`.

## Daily Smoke

Run in a second PowerShell window:

```powershell
cd C:\dev\longterm_stock_research_assistant
.\scripts\00631l_daily_smoke.ps1
```

If local PowerShell script execution is disabled, use the CMD wrapper:

```cmd
scripts\00631l_daily_smoke.cmd
```

The wrapper loads `backend\.env` before calling `backend\scripts\smoke_00631l_live.py`.

Expected result:

- `PASS`: live sources parsed and freshness checks look current.
- `WARN`: data parsed but freshness needs manual review, common after market close or on weekends.
- `FAIL`: a required live source did not fetch or parse.

Do not treat mock or fallback data as official.

## Daily Collection

Use the collector when the goal is to persist official snapshots into local JSONL history, not just inspect source freshness.

One-command daily cycle:

```cmd
scripts\00631l_daily_cycle.cmd
```

The daily cycle runs collection, CSV export, and live smoke in that order.

One-shot collection:

```cmd
scripts\00631l_collect_snapshot.cmd --samples 1
```

Intraday premium/discount accumulation:

```cmd
scripts\00631l_collect_snapshot.cmd --skip-profile --skip-holdings --samples 20 --interval-seconds 15
```

The collector stores only successful official holdings and intraday NAV payloads through the backend service. It does not mark mock, unavailable, or error data as official.

## History Export

Export local JSONL history to CSV:

```cmd
scripts\00631l_export_history.cmd
```

The default output folder is `backend\exports`, which is ignored by git. Use this for local backup or offline review.

Task Scheduler can call the same CMD wrapper from:

```text
C:\dev\longterm_stock_research_assistant
```

Use `--samples 1` for daily holdings collection. Use repeated intraday samples only during periods when intraday NAV is expected to update.

## Frontend Live Proxy

```powershell
flutter run -d chrome --dart-define=USE_00631L_LIVE_PROXY=true --dart-define=00631L_PROXY_BASE_URL=http://127.0.0.1:8000
```

Open:

```text
http://127.0.0.1:<flutter-port>/#/00631l-lab
```

Check:

- profile is `official`, `proxy`, or `cached` when backend is healthy.
- holdings are `official`, `proxy`, or `cached` when backend is healthy.
- intraday NAV shows `sourceContract: twse_a_k_json` when TWSE succeeds.
- Yuanta fallback shows `sourceContract: yuanta_inav` and is not labeled as TWSE.
- backend down still leaves a visible mock/error fallback, not a blank page.
- TX remains mock/fallback by design.

## Full Release Validation

```powershell
cd C:\dev\longterm_stock_research_assistant
.\scripts\00631l_release_validate.ps1
```

If local PowerShell script execution is disabled:

```cmd
scripts\00631l_release_validate.cmd
```

The wrapper runs:

- `flutter analyze`
- `flutter test`
- `flutter build web`
- `py -m unittest discover -s backend\tests`
- `.\scripts\00631l_daily_smoke.ps1`
- `git diff --check`

Use `-SkipSmoke` only when network access is intentionally unavailable; document that skipped smoke in the release notes.

For the CMD wrapper, use `--skip-smoke` for the same explicit network-unavailable case.

## Web Build Deployment

Local web build:

```powershell
flutter build web
```

GitHub Pages project build:

```powershell
flutter build web --base-href="/longterm_stock_research_assistant/"
```

The built static app still needs a reachable backend proxy for live official data. Without the proxy, the app must stay in mock/fallback mode and label that state clearly.

## History Data

The backend stores local JSONL history under paths from `backend\.env`:

- `00631L_HOLDINGS_HISTORY_PATH`
- `00631L_INTRADAY_NAV_HISTORY_PATH`

These files are local operational data. Do not commit them unless a future release creates explicit anonymized fixtures.

## Source Boundary

Official daily holdings are daily snapshots from Yuanta ratio. Intraday NAV is only market price, estimated NAV, premium/discount, and timestamps. The status summary describes data health and deviation degree only; it is not trading advice.
