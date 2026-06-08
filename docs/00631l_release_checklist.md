# 00631L Lab v1.0 Release Checklist

Scope: 00631L only. Do not connect TX live, expand to all leveraged ETFs, add trading alerts, or add buy/sell advice during this release check.

## Environment

- Confirm Flutter SDK path starts with `C:\src\flutter-clean\bin`.
- Copy `backend\.env.example` to `backend\.env` for local live proxy validation.
- Confirm `backend\.env` does not contain secrets or local tokens.
- Confirm intraday source mode is `00631L_INTRADAY_NAV_SOURCE=auto`.

## Backend

```powershell
cd C:\dev\longterm_stock_research_assistant
.\backend\run_dev.ps1
```

Equivalent direct command:

```powershell
py -m uvicorn backend.app.main:app --reload --host 127.0.0.1 --port 8000
```

Check:

- `GET /health` returns `status: ok`.
- `GET /api/etf/00631l/profile` returns Yuanta profile metadata with `sourceStatus: official` or `cached`.
- `GET /api/etf/00631l/holdings` returns Yuanta daily holdings with `sourceStatus: official` or `cached`.
- `GET /api/etf/00631l/intraday-nav` returns TWSE intraday NAV with `sourceStatus: official` or `cached`.
- `sourceContract` is `twse_a_k_json` when TWSE succeeds.
- If TWSE fails and Yuanta succeeds, `sourceContract` is `yuanta_inav`; do not label it as TWSE.
- If no live or cached intraday data is available, endpoint returns `sourceStatus: unavailable` or `error`, not mock.
- Holdings history trend chart renders from official/cached local history; it is hidden behind the existing empty-history state when no history exists.
- Intraday premium/discount trend chart renders only from stored intraday NAV history; it is hidden behind the existing empty-history state when no intraday history exists.
- `GET /api/etf/00631l/operations/status` returns local collection status without triggering live source fetch.

## Frontend Live Proxy

```powershell
flutter run -d chrome --dart-define=USE_00631L_LIVE_PROXY=true --dart-define=00631L_PROXY_BASE_URL=http://127.0.0.1:8000
```

Open:

```text
http://127.0.0.1:<flutter-port>/#/00631l-lab
```

Check `/00631l-lab`:

- Profile data is official/proxy/cached, not mock when backend is healthy.
- Holdings data is official/proxy/cached, not mock when backend is healthy.
- Intraday NAV is official or cached during live proxy mode.
- `sourceContract` displays `twse_a_k_json` for TWSE data.
- Yuanta fallback displays `yuanta_inav` and is not presented as TWSE.
- If backend is down, the page shows mock/error fallback and does not become blank.
- TX remains mock/fallback.
- The page does not provide buy/sell advice.

## Validation Commands

```powershell
flutter analyze
flutter test
flutter build web
py -m unittest discover -s backend\tests
py backend\scripts\smoke_00631l_live.py
```

Equivalent v1.6 wrapper:

```powershell
.\scripts\00631l_release_validate.ps1
```

Daily smoke wrapper that loads `backend\.env`:

```powershell
.\scripts\00631l_daily_smoke.ps1
```

Daily history collector:

```cmd
scripts\00631l_collect_snapshot.cmd --samples 1
```

If local PowerShell script execution is disabled:

```cmd
scripts\00631l_release_validate.cmd
scripts\00631l_daily_smoke.cmd
```

Smoke script notes:

- Intraday freshness older than 60 seconds is a `WARN`, not an automatic `FAIL`.
- Holdings trade date not matching the latest expected trading day is a `WARN`, not an automatic `FAIL`.
- Weekend, night, or market-closed checks may warn because intraday data is not actively updating.

## v1.6 Daily Operation

Use `docs/00631l_v1_6_daily_runbook.md` for the daily backend, frontend live proxy, smoke observation, and web build flow.
