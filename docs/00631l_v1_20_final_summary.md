# 00631L Lab v1.20 Final Daily-Use Summary

Date: 2026-06-09

## Final Scope

v1.20 closes the current 00631L lab daily-use release line. The project is now a single-product 00631L research dashboard with backend proxy, local history accumulation, CSV export, operational status, daily cycle, release check, and daily usage documentation.

The app remains focused on data transparency:

- official Yuanta 00631L profile data
- official Yuanta 00631L daily holdings snapshot
- official TWSE intraday NAV feed
- verified Yuanta INAV fallback
- local holdings history
- local intraday NAV history
- premium/discount status as a price-deviation hint
- source status display for official, cached, mock, fallback, stale, unavailable, and error states
- operations/status display
- local daily cycle result
- CSV export for offline review

## Live Sources

- Yuanta 00631L Basic information page, through backend proxy.
- Yuanta 00631L ratio page, through backend proxy.
- TWSE ETF intraday NAV aggregate feed:

```text
https://mis.twse.com.tw/stock/data/all_etf.txt
```

The TWSE contract is:

```text
twse_a_k_json
```

## Fallback Sources

- Yuanta INAV backend source contract:

```text
yuanta_inav
```

- Flutter default mock mode for local startup without backend.
- Cached backend responses and local JSONL history where applicable.

mock/fallback data is clearly labeled and is not presented as official.

## Scripts

Daily startup and operation:

```cmd
scripts\00631l_check_env.cmd
scripts\00631l_start_backend.cmd
scripts\00631l_start_frontend_live.cmd
scripts\00631l_collect_snapshot.cmd
scripts\00631l_daily_cycle.cmd
scripts\00631l_export_history.cmd
```

Smoke and release validation:

```cmd
scripts\00631l_daily_smoke.cmd
scripts\00631l_release_check.cmd
```

Backend helpers:

```cmd
py backend\scripts\smoke_00631l_live.py
py backend\scripts\collect_00631l_snapshot.py
py backend\scripts\export_00631l_history.py
py backend\scripts\run_00631l_daily_cycle.py
py backend\scripts\release_check_00631l.py
```

## Backend Endpoints

```text
GET /health
GET /api/etf/00631l/profile
GET /api/etf/00631l/holdings
GET /api/etf/00631l/intraday-nav
GET /api/etf/00631l/holdings/history
GET /api/etf/00631l/holdings/history/summary
GET /api/etf/00631l/intraday-nav/history
GET /api/etf/00631l/intraday-nav/history/summary
GET /api/etf/00631l/operations/status
```

## Frontend Pages

- `/00631l-lab`: 00631L 正二研究室.

The page shows profile, daily holdings, asset structure, stock/futures/cash lines, intraday NAV, premium/discount status, holdings history, intraday history, data-status summary, and operations status.

## Tests

Primary release validation:

```cmd
scripts\00631l_release_check.cmd
```

The release check runs:

- environment check
- Flutter analyze
- Flutter test
- Flutter web build
- backend unit tests
- daily cycle
- CSV export
- live smoke
- forbidden wording scan
- git diff check

Expected WARN cases:

- missing local `backend\.env` when fallback mode remains usable
- off-hours intraday freshness review
- intraday URL unavailable in local scripts while required official daily holdings still parse

## Daily Usage

The daily-use runbook is:

```text
docs/00631l_daily_usage.md
```

Recommended daily flow:

```cmd
cd C:\dev\longterm_stock_research_assistant
scripts\00631l_check_env.cmd
scripts\00631l_start_backend.cmd
```

Open a second terminal:

```cmd
cd C:\dev\longterm_stock_research_assistant
scripts\00631l_daily_cycle.cmd
scripts\00631l_start_frontend_live.cmd
```

Release check:

```cmd
scripts\00631l_release_check.cmd
```

## Known Limitations

These are intentionally not included in this release:

- TX live data
- all leveraged ETF expansion
- trading advice
- notification features
- automated trading

The current release describes data status, source freshness, holdings changes, and premium/discount deviation only.

## Final Validation

Run:

```cmd
scripts\00631l_release_check.cmd
```

The release is considered acceptable when the result is `PASS`, or `WARN` with no failures and only expected local/off-hours warnings.
