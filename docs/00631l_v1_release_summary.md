# 00631L Lab v1.0 Release Summary

Completion date: 2026-06-08

## Completed Scope

- Added the single-product `00631L 正二研究室` MVP.
- Integrated Yuanta 00631L Basic information through the backend proxy.
- Integrated Yuanta 00631L daily holdings ratio through the backend proxy.
- Integrated TWSE intraday NAV through the backend proxy.
- Added Yuanta INAV as a verified fallback source.
- Kept the frontend default in mock mode.
- Added live proxy mode through Flutter `--dart-define`.
- Preserved mock/cache/error fallback behavior so the page does not go blank when live sources fail.
- Kept TX quote as mock/fallback by design.
- Kept the page free of investment buy/sell advice.
- Kept scope limited to 00631L only.

## Live Data Sources

- Yuanta Basic information:
  `https://www.yuantaetfs.com/product/detail/00631L/Basic_information`
- Yuanta daily holdings ratio:
  `https://www.yuantaetfs.com/product/detail/00631L/ratio`
- TWSE intraday NAV:
  `https://mis.twse.com.tw/stock/data/all_etf.txt`
  - `sourceContract: twse_a_k_json`
- Yuanta INAV fallback:
  - `sourceContract: yuanta_inav`
  - The verified URL is documented in `backend/.env.example`.

## Fallback Data Sources

- Frontend default mode: `Mock00631LRepository`.
- Live proxy failure path: `Cached00631LRepository`, then mock fallback if no cached data is available.
- Backend cache:
  - profile: `00631L_PROFILE_CACHE_SECONDS=86400`
  - holdings: `00631L_HOLDINGS_CACHE_SECONDS=600`
  - intraday NAV: `00631L_INTRADAY_NAV_CACHE_SECONDS=15`
- TX quote: mock/fallback only.

## Not Included

- TX live data.
- All leveraged ETF expansion.
- Premium/discount alert features.
- Buy/sell advice or investment recommendations.
- Any attempt to present mock/fallback data as official.

## After v1.0 Note

The next small UI layer may show premium/discount status color and text on `/00631l-lab`. That status should remain a price-deviation hint based on intraday NAV `premiumDiscountPct`; stale, unavailable, error, or mock data should not be presented as an official judgment.

## Validation Results

- `flutter analyze`: PASS.
- `flutter test`: PASS, 25 tests.
- `flutter build web`: PASS.
- `py -m unittest discover -s backend\tests`: PASS, 10 tests OK.
- `py backend\scripts\smoke_00631l_live.py`: PASS/WARN acceptable; WARN only because intraday freshness was checked after market close.
- `git diff --check`: PASS.

## Start Backend

```powershell
cd C:\dev\longterm_stock_research_assistant
.\backend\run_dev.ps1
```

Equivalent direct command:

```powershell
py -m uvicorn backend.app.main:app --reload --host 127.0.0.1 --port 8000
```

## Start Frontend Live Proxy

```powershell
flutter run -d chrome --dart-define=USE_00631L_LIVE_PROXY=true --dart-define=00631L_PROXY_BASE_URL=http://127.0.0.1:8000
```

Direct route:

```text
http://127.0.0.1:<flutter-port>/#/00631l-lab
```

## Smoke Script

```powershell
py backend\scripts\smoke_00631l_live.py
```

The smoke script is manual. It is not part of the default unit test suite because live network freshness can vary during market close, weekends, or source maintenance.
