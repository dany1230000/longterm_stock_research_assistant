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

Equivalent command:

```powershell
py -m uvicorn backend.app.main:app --reload --host 127.0.0.1 --port 8000
```

Frontend live proxy mode:

```powershell
flutter run -d chrome --dart-define=USE_00631L_LIVE_PROXY=true --dart-define=00631L_PROXY_BASE_URL=http://127.0.0.1:8000
```

Release checklist: `docs/00631l_release_checklist.md`.

## Environment variables

See `backend/.env.example` for the deployable template.

- `TWSE_00631L_INTRADAY_NAV_URL`: verified TWSE feed, currently `https://mis.twse.com.tw/stock/data/all_etf.txt`.
- `YUANTA_00631L_INTRADAY_NAV_URL`: verified Yuanta INAV fallback URL from the Yuanta INAV page network request.
- `00631L_INTRADAY_NAV_SOURCE`: `twse`, `yuanta`, or `auto`.
- `00631L_PROFILE_CACHE_SECONDS`: default `86400`.
- `00631L_HOLDINGS_CACHE_SECONDS`: default `600`.
- `00631L_INTRADAY_NAV_CACHE_SECONDS`: default `15`.

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
py backend\scripts\smoke_00631l_live.py
```

The smoke script is not part of the default unit test suite. It performs network checks against Yuanta and the optional intraday NAV URL, so failures should be reviewed manually instead of breaking CI.

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
