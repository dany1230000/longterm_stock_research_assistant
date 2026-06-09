# 00631L lab v2.0 final daily tool summary

Completed on 2026-06-09.

## Product Goal

v2.0 treats the 00631L lab as a daily-use research room inside the existing long-term stock research assistant shell. The goal is that a user can open the app, enter `/#/00631l-lab`, and quickly understand official data freshness, intraday NAV status, holdings history completeness, local maintenance state, and the next program operation to run when something is missing.

This release remains a data transparency tool. It describes source status, holdings structure, premium/discount state, local reports, exports, backups, and maintenance checks. It is not investment guidance.

## Daily-Use Entry Points

- App route: `/#/00631l-lab`
- Daily helper: `scripts\00631l_open_lab.cmd`
- Backend startup: `scripts\00631l_start_backend.cmd`
- Frontend live proxy: `scripts\00631l_start_frontend_live.cmd`
- Daily cycle: `scripts\00631l_daily_cycle.cmd`
- Release check: `scripts\00631l_release_check.cmd`

The app shell name remains the long-term stock research assistant. The dashboard contains a clear `00631L 正二研究室` entry, and the helper scripts print the direct lab route.

## Live Sources

- Yuanta 00631L Basic information through backend proxy.
- Yuanta 00631L ratio daily holdings through backend proxy.
- TWSE intraday NAV through `https://mis.twse.com.tw/stock/data/all_etf.txt`, `sourceContract: twse_a_k_json`.
- Yuanta INAV as official fallback when configured, `sourceContract: yuanta_inav`.

## Fallback And Local Sources

- Default frontend mode remains mock/fallback and is labeled as such.
- Backend disconnected state keeps the page readable and explicitly shows fallback/error status.
- Local holdings history is stored as ignored JSONL under `backend\data`.
- Intraday NAV samples are stored as ignored JSONL under `backend\data`.
- Daily reports are Markdown files under ignored `backend\reports`.
- CSV exports are under ignored `backend\exports`.
- Backups are under ignored `backend\backups` and include manifest checksums.

Mock, fallback, unavailable, stale, cached, and error states are never displayed as official.

## Frontend Completion

The `/00631l-lab` page now gives a daily-use overview before detailed tables:

- Summary cards for market price, estimated NAV, premium/discount, official holdings date, fund NAV, NAV per unit, outstanding units, last update, and source status.
- `00631L 狀態總結` for source freshness, holdings changes, intraday NAV status, and non-advice data notes.
- `今日資料狀態` with a `每日可用狀態` panel that summarizes backend, official holdings, intraday NAV, daily cycle, report, CSV export, backup, and local state.
- `折溢價狀態` as a price-deviation hint only.
- `每日內容物歷史` with recent 7-row summary, 30-row table, day-over-day change, and first-to-latest change.
- `盤中折溢價歷史` with latest local intraday samples and source contract.
- Operations guidance for app maintenance actions such as running daily cycle, export, backup, report generation, or env checks.

Desktop and mobile layouts remain readable. Wide tables keep horizontal scrolling where needed, while summary/status areas collapse into compact cards.

## Backend And Maintenance Completion

- `/health` exposes deployment-friendly backend health metadata.
- `/api/etf/00631l/operations/status` exposes local data, history, report, export, backup, restore dry-run, retention, env, and source configuration state.
- Daily cycle records local run status and generates a Markdown report.
- Export produces CSV files and export metadata.
- Backup rotation prevents unbounded backup folder growth.
- Restore dry-run verifies backup readability and checksum data without overwriting local data.
- Integrity checks cover history duplicates, missing fields, weekday gaps, and abnormal source status.
- Release check covers env, Flutter validation, backend tests, daily cycle, export, smoke, integrity, backup, restore dry-run, retention, docs index, forbidden wording scan, and git diff check.

## Daily Routine

1. Open a terminal in the repo:

```cmd
cd C:\dev\longterm_stock_research_assistant
```

2. Check the daily helper:

```cmd
scripts\00631l_open_lab.cmd
```

3. Start backend in a dedicated terminal:

```cmd
scripts\00631l_start_backend.cmd
```

4. Run daily cycle after backend is ready:

```cmd
scripts\00631l_daily_cycle.cmd
```

5. Start Flutter live proxy in another terminal:

```cmd
scripts\00631l_start_frontend_live.cmd
```

6. Open:

```text
/#/00631l-lab
```

## Documents To Start With

- Main index: `docs\00631l_docs_index.md`
- Daily usage: `docs\00631l_daily_usage.md`
- Troubleshooting: `docs\00631l_troubleshooting.md`
- Maintenance index: `docs\00631l_maintenance_index.md`
- Deployment notes: `docs\00631l_deployment_notes.md`

## Final Validation

The final validation set is:

```cmd
flutter analyze
flutter test
flutter build web
py -m unittest discover -s backend\tests
scripts\00631l_release_check.cmd
git diff --check
```

Release check WARN is acceptable only when `failures=[]` and the WARN is from expected live-source timing or local optional state.

## Explicitly Not Included

- TX live source.
- All-leveraged-ETF expansion.
- Notifications.
- Automated trading.
- Investment guidance.
- Commit of `.env`, build output, logs, local data, exports, backups, reports, cache, or debug output.

## Status

v2.0 can be treated as the formal daily-use completion release for the 00631L lab, subject to official source availability and local backend operation.
