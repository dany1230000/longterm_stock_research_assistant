# 00631L live proxy

## v1.0 deployment settings

Tracked template:

```text
backend/.env.example
```

Local setup:

```powershell
cd C:\dev\longterm_stock_research_assistant
Copy-Item backend\.env.example backend\.env
.\backend\run_dev.ps1
```

Frontend live proxy:

```powershell
flutter run -d chrome --dart-define=USE_00631L_LIVE_PROXY=true --dart-define=00631L_PROXY_BASE_URL=http://127.0.0.1:8000
```

Important env vars:

- `TWSE_00631L_INTRADAY_NAV_URL=https://mis.twse.com.tw/stock/data/all_etf.txt`
- `YUANTA_00631L_INTRADAY_NAV_URL=<verified Yuanta INAV URL from backend/.env.example>`
- `00631L_INTRADAY_NAV_SOURCE=auto`
- `00631L_PROFILE_CACHE_SECONDS=86400`
- `00631L_HOLDINGS_CACHE_SECONDS=600`
- `00631L_INTRADAY_NAV_CACHE_SECONDS=15`
- `00631L_TX_QUOTE_CACHE_SECONDS=15`
- `TAIFEX_TX_SOCKJS_URL=https://mis.taifex.com.tw/futures/rt`
- `TAIFEX_TX_FUTURES_SYMBOL=TXF-P`
- `TAIFEX_TX_SPOT_SYMBOL=TXF-S`
- `ETF_CATALOG_PATH=<local data dir>\twse_etf_catalog.json`

`sourceContract` definitions:

- `twse_a_k_json`: TWSE a-k feed selected from `a1[].msgArray` for `a == "00631L"`.
- `yuanta_inav`: Yuanta INAV API contract. It is never labeled as TWSE.
- `null`: endpoint metadata field is present but not applicable, such as profile or holdings.

Fallback rules:

- TWSE succeeds: return official/cached intraday NAV with `sourceContract: twse_a_k_json`.
- TWSE fails and Yuanta succeeds in `auto`: return official/cached intraday NAV with `sourceContract: yuanta_inav`.
- No configured URL or no live/cached intraday data: return `sourceStatus: unavailable` or `error`.
- Frontend live proxy failure: use cached data or mock fallback, clearly labeled; never present fallback as official.
- TAIFEX TX quote is fetched through `/api/etf/00631l/tx-quote` when backend is available. Non-session or source failures return unavailable/error metadata.
- TWSE all-ETF catalog can be imported for future ETF-room expansion. It is not labeled as 00631L official holdings.

Daily holdings are official daily snapshots. Intraday NAV is only market price, estimated NAV, premium/discount, and timestamps.

Premium/discount status on the Flutter page uses normalized intraday NAV fields:

- `premiumDiscountPct` is a percentage-point value such as `0.75` for `+0.75%`.
- `sourceStatus` must be official/proxy/cached and not stale before the page presents a status judgment.
- `mock`, `error`, and `unavailable` stay clearly labeled as unavailable/fallback states.
- The status text is only a price-deviation hint and is not investment advice.

Smoke script:

```powershell
.\scripts\00631l_daily_smoke.ps1
```

The wrapper loads `backend\.env` and then calls `backend\scripts\smoke_00631l_live.py`. The `[overall]` block reports `PASS`, `WARN`, or `FAIL`. Freshness older than 60 seconds is a `WARN` for manual review and is expected outside regular trading hours. The live smoke remains manual and is not part of the default unit test suite.

v1.6 daily runbook:

```text
docs/00631l_v1_6_daily_runbook.md
```

If local PowerShell script execution is disabled, use the CMD wrappers:

```cmd
scripts\00631l_daily_smoke.cmd
scripts\00631l_release_validate.cmd
```

## Intraday NAV source update - 2026-06-08

Verified sources:

- TWSE official market site aggregate a-k feed:
  `https://mis.twse.com.tw/stock/data/all_etf.txt`
  - Contract: `twse_a_k_json`
  - Shape: top-level `a1[]`, each issuer group has `msgArray`, `refURL`, `userDelay`, `rtMessage`, and `rtCode`.
  - 00631L was found in the Yuanta issuer group with fields `a-k`.
  - Suitable for backend proxy use. Flutter Web should still read it through the proxy to avoid CORS/runtime fragility.
- Yuanta INAV official API used by the Yuanta INAV page:
  `https://etfapi.yuantaetfs.com/ectranslation/api/trans?...FuncId=ETFNAV/GetINAV_Data...`
  - Contract: `yuanta_inav`
  - Requires the same query parameter shape used by Yuanta's Nuxt app, including `APIType=ETFBackstage`, `CompanyName=YUANTAFUNDS`, `FuncId=ETFNAV/GetINAV_Data`, `AppName=ETF`, `Device=4`, `Platform=ETF`, and a UUID-like `DeviceId`.
  - Contains 00631L `NOW_PRICE`, `NOW_NAV`, `NAV`, `NAV_DATE`, `UPDATE_T`, and `iOS_UNIT`.

Backend env vars:

```powershell
$env:TWSE_00631L_INTRADAY_NAV_URL="https://mis.twse.com.tw/stock/data/all_etf.txt"
$env:YUANTA_00631L_INTRADAY_NAV_URL="https://etfapi.yuantaetfs.com/ectranslation/api/trans?APIType=ETFBackstage&CompanyName=YUANTAFUNDS&PageName=%2FtradeInfo%2FINav%2FAsia_ETF&DeviceId=00000000-0000-4000-8000-000000000631&FuncId=ETFNAV%2FGetINAV_Data&AppName=ETF&Device=4&Platform=ETF"
${env:00631L_INTRADAY_NAV_SOURCE}="auto"
```

Source mode:

- `twse`: use only `TWSE_00631L_INTRADAY_NAV_URL`.
- `yuanta`: use only `YUANTA_00631L_INTRADAY_NAV_URL`.
- `auto`: try TWSE first, then Yuanta.
- If no intraday URL is configured, `/api/etf/00631l/intraday-nav` returns `sourceStatus: unavailable`.

Do not confuse official daily holdings with intraday estimated NAV. Yuanta ratio holdings are daily snapshots. Intraday data is limited to market price, estimated NAV, premium/discount, and timestamps.

## Live smoke validation - 2026-06-08

Manual smoke command:

```powershell
cd C:\dev\longterm_stock_research_assistant
py backend\scripts\smoke_00631l_live.py
```

Latest local smoke result:

- Yuanta Basic information URL: `https://www.yuantaetfs.com/product/detail/00631L/Basic_information`
  - HTTP 200.
  - Parsed as `sourceStatus: official`.
  - Parsed fund name, tracking index, setup/listing dates, dividend flag, RR level, management fee, and custodian fee.
- Yuanta holdings ratio URL: `https://www.yuantaetfs.com/product/detail/00631L/ratio`
  - HTTP 200.
  - Parsed as `sourceStatus: official`.
  - Parsed `tradeDate`, fund NAV, NAV per unit, outstanding units, asset values, 5 cash/non-product lines, 1 stock line, and 1 futures line.
- Intraday NAV:
  - TWSE `all_etf.txt` has been verified for 00631L a-k fields.
  - Endpoint returns `sourceStatus: unavailable` only when no intraday URL env var is configured.

The backend uses Python `urllib` first. On this Windows/Python 3.14 environment, Yuanta TLS validation can fail with a certificate chain compatibility error; the proxy then falls back to the system `curl.exe` without disabling TLS verification. Do not use `curl -k` or disable certificate checks.

## Intraday NAV URL finding

TWSE's official ETF NAV integration document defines the JSON shape and `a-k` mapping. The TWSE market-site aggregate feed was verified at `https://mis.twse.com.tw/stock/data/all_etf.txt`; it wraps issuer groups in top-level `a1[]` and each issuer group contains `msgArray`.

Verified references:

- TWSE integration format: `msgArray`, fields `a` through `k`, `userDelay`, `rtMessage`, and `rtCode`.
- Yuanta INAV page: `https://www.yuantaetfs.com/tradeInfo/INav/Asia_ETF`.

Yuanta's INAV page is an official page and its Nuxt app calls Yuanta's `ETFNAV/GetINAV_Data` API. That API uses `sourceContract: yuanta_inav`, not the TWSE `msgArray` contract.

## Local CORS

The backend allows local Flutter development origins with:

```text
http://localhost:<port>
http://127.0.0.1:<port>
```

This is for Flutter Chrome/web-server dynamic ports only. It does not allow arbitrary remote origins.

## Frontend live proxy smoke

Backend:

```powershell
py -m uvicorn backend.app.main:app --host 127.0.0.1 --port 8000
```

Flutter live mode:

```powershell
flutter run -d chrome --dart-define=USE_00631L_LIVE_PROXY=true --dart-define=00631L_PROXY_BASE_URL=http://127.0.0.1:8000
```

Use `/#/00631l-lab` for direct web navigation because this app currently uses hash routing.

Observed smoke behavior:

- Backend up with intraday env configured: page renders `00631L`, `proxy`, `official`, live Yuanta holdings, and intraday NAV with `sourceContract`.
- Backend down after reload: page renders `00631L` and `mock` fallback instead of a blank page.
- The fallback is explicitly labeled mock/fallback and is not presented as official data.

本頁說明 00631L 正二研究室的 live proxy 第一版。它只服務 `00631L`，不是全市場正二，也不是所有槓桿 ETF。

## Why

Flutter Web 直接抓元大投信官方頁或 TWSE/Yuanta 即時 JSON 時，可能遇到 CORS、TLS、header 或來源格式變動問題。proxy 的用途是：

- 由 backend 抓官方來源。
- 在 backend 做 parser、timeout、cache、錯誤分類。
- 回傳 normalized JSON 給 Flutter app。
- 在 live 失敗時清楚標示 `sourceStatus: error`、`unavailable` 或 `cached`，不把 mock 偽裝成 official。

## Endpoints

```text
GET /health
GET /api/etf/00631l/profile
GET /api/etf/00631l/holdings
GET /api/etf/00631l/intraday-nav
GET /api/etf/00631l/tx-quote
GET /api/etf/00631l/operations/status
GET /api/etf/catalog
GET /api/etf/catalog/status
POST /api/etf/catalog/import
```

`/api/etf/00631l/operations/status` only reads local config and JSONL history summaries for collection status. It does not trigger live source fetch.

`/api/etf/00631l/tx-quote` reads TAIFEX MIS quote data. It returns TXF-P quote fields, TXF-S weighted-index reference fields, computed basis, source metadata, and unavailable/error state when TAIFEX has no active last price.

`/api/etf/catalog/import` imports TWSE `all_etf.txt` into local `ETF_CATALOG_PATH`. This creates an all-ETF catalog for future research-room expansion, not a replacement for 00631L holdings.

`/api/etf/00631l/holdings` 是官方每日內容物快照，不是盤中即時內容物。盤中即時的是市價、預估淨值與折溢價。

`/api/etf/00631l/intraday-nav` 讀取 TWSE/Yuanta ETF 即時淨值 JSON，篩選 `00631L`，mapping `a-k` 欄位：

```text
a symbol
b name
c outstandingUnits
d outstandingUnitsDelta
e marketPrice
f estimatedNav
g estimatedPremiumDiscountPct
h previousBusinessDayNav
i dataDate
j dataTime
k targetType
```

TWSE `all_etf.txt` 已確認可用於 00631L a-k JSON；但為了保留安全 fallback，intraday endpoint 只有在設定 `TWSE_00631L_INTRADAY_NAV_URL` 或 `YUANTA_00631L_INTRADAY_NAV_URL` 後才抓 live。

## Response Metadata

每個資料 response 都包含：

- `sourceStatus`: `official`、`cached`、`mock`、`error`、`unavailable`
- `sourceContract`: `twse_a_k_json`、`yuanta_inav` 或 `null`
- `sourceUrl`
- `fetchedAt`
- `sourceUpdatedAt` 或 `dataTime`
- `isStale`
- `errorMessage`

前端收到 proxy 的 `official` 會顯示為 `proxy`，表示資料是經由本機 backend 轉接而來。

## Cache

- profile: 24 小時
- holdings: 10 分鐘 (`00631L_HOLDINGS_CACHE_SECONDS=600`)
- intraday-nav: 15 秒

若 live 抓取失敗且已有快取，backend 回 `sourceStatus: cached` 並帶 `errorMessage`。若沒有快取，holdings 回 `sourceStatus: error`，intraday nav 回 `sourceStatus: unavailable` 或 `error`。

## Run Backend

```powershell
cd C:\dev\longterm_stock_research_assistant
py -m pip install -r backend\requirements.txt
py -m uvicorn backend.app.main:app --reload --host 127.0.0.1 --port 8000
```

設定 intraday NAV URL：

```powershell
$env:TWSE_00631L_INTRADAY_NAV_URL="https://mis.twse.com.tw/stock/data/all_etf.txt"
${env:00631L_INTRADAY_NAV_SOURCE}="auto"
```

## Enable Frontend Proxy

預設 app 使用 mock，不會自動打 live proxy。

```powershell
flutter run -d chrome --dart-define=USE_00631L_LIVE_PROXY=true --dart-define=00631L_PROXY_BASE_URL=http://localhost:8000
flutter build web --dart-define=USE_00631L_LIVE_PROXY=true --dart-define=00631L_PROXY_BASE_URL=http://localhost:8000
```

如果 backend 斷線，前端會透過 `Cached00631LRepository` 回到 mock fallback 或顯示 error/unavailable 狀態，不會讓整頁空白。

## Tests

```powershell
py -m unittest discover -s backend\tests
flutter test
```

目前 backend parser tests 可用 Python stdlib 執行。endpoint tests 需要安裝 `backend\requirements.txt` 中的 FastAPI/TestClient 相關套件。
## v1.2 holdings history endpoints

The live proxy stores successful Yuanta 00631L ratio official snapshots in a local JSONL file. The default path is `backend/data/00631l_holdings_history.jsonl`, configurable with `00631L_HOLDINGS_HISTORY_PATH`.

Endpoints:

```text
GET /api/etf/00631l/holdings/history?limit=30
GET /api/etf/00631l/holdings/history/summary?limit=30
```

The history endpoint returns full stored snapshots. The summary endpoint is intended for the Flutter table and includes `tradeDate`, `txWeightPct`, `tsmcWeightPct`, `stockExposurePct`, `futuresExposurePct`, `cashAndMarginPct`, `navPerUnit`, `fundNetAssetValue`, and `outstandingUnits`.

The backend does not synthesize official history from mock data. If no records exist, the response uses `sourceStatus: unavailable` and an empty `items` list.

## v1.3 holdings change notices

The frontend computes holdings change notices from the history summary response. The backend does not need a new endpoint for v1.3.

The app compares the latest two official history rows and flags data-state changes when TX weight, TSMC weight, cash/margin ratio, futures asset ratio, or combined stock/futures exposure crosses the configured thresholds. If there are fewer than two history rows, the app shows that history is still insufficient.

These notices are not trading advice and must not be treated as trading instructions. They are intended to make daily official holdings changes easier to audit.

## v1.4 intraday NAV history endpoints

The backend stores official intraday NAV samples in local JSONL when `/api/etf/00631l/intraday-nav` succeeds. The default path is `backend/data/00631l_intraday_nav_history.jsonl`, configurable with `00631L_INTRADAY_NAV_HISTORY_PATH`.

Endpoints:

```text
GET /api/etf/00631l/intraday-nav/history?date=YYYY-MM-DD&limit=500
GET /api/etf/00631l/intraday-nav/history/summary?date=YYYY-MM-DD
```

The summary endpoint returns today's sample count, highest premium, lowest discount, average premium/discount, first and last data times, latest market price, and latest estimated NAV.

The backend does not fabricate official intraday history from mock, cached, error, or unavailable responses.

## v1.5 status summary

The status summary is computed in the Flutter model layer. No new backend endpoint is required.

It combines:

- Yuanta holdings freshness.
- Intraday NAV availability and `sourceContract`.
- Premium/discount assessment.
- Holdings change notice state.
- Intraday NAV history sample state.

The summary is a data-health description only. It is not a trading strategy and does not provide trading instructions.
