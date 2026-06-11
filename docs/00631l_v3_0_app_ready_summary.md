# 00631L lab v3.0 app-ready summary

Completion date: 2026-06-11

## Completed Scope

- Mobile-first `/00631l-lab` layout with stock-app style quote header.
- Light and dark theme toggle with saved preference.
- Section navigation: overview, holdings, history, backtest, position, AI analysis, and system status.
- Official Yuanta profile and holdings ratio through backend proxy.
- Official TWSE intraday NAV with Yuanta INAV fallback.
- Local holdings history and intraday NAV history from daily cycle.
- TWSE price history cache for long-range performance and backtest.
- Historical performance metrics and compact trend charts.
- Backtest engine for one-time and monthly contribution history calculations.
- Local-only position tracking with JSON export and clear controls.
- Rule-based AI summary covering data status, holdings, history, reports, export, backup, and program actions.
- Public deployment-ready frontend/backend settings from the v2.2 release remain supported.

## Live And Local Sources

- Daily holdings ratio: official Yuanta daily snapshot, not intraday.
- Intraday NAV: official TWSE `all_etf.txt` when backend is connected and env is configured.
- Price history: official TWSE STOCK_DAY cache after running `scripts\00631l_update_price_history.cmd`.
- Holdings history: local backend JSONL accumulated after collection starts.
- Position tracking: browser local storage only.
- TX quote: still mock/fallback by design.

## App Sections

- Overview: data update frequency, source status, and core snapshot.
- Holdings: asset allocation, stock lines, futures lines, and cash/margin lines.
- History: price history coverage, performance, price trend, and holdings history.
- Backtest: historical calculation form and result cards.
- Position: local holding calculator.
- AI analysis: rule-based non-advice summary.
- System status: backend, official sources, history, reports, export, backup, deployment, and persistent storage.

## Validation

Required validation before release:

```cmd
flutter analyze
flutter test
flutter build web
py -m unittest discover -s backend\tests
scripts\00631l_release_check.cmd
scripts\00631l_check_public_config.cmd
scripts\00631l_update_price_history.cmd --status-only
git diff --check
```

`scripts\00631l_release_check.cmd` may return WARN for off-hours freshness or missing public deployment env as long as `failures=[]`.

## Not Included

- TX live.
- All-leveraged-ETF expansion.
- Notifications.
- Automated trading.
- Investment guidance.
- App store release.

## Public Deployment Remaining Work

To make the app available from anywhere, provide:

- A public backend host.
- A public frontend static host.
- HTTPS domain or platform URL.
- Persistent backend volume for `backend/data`, reports, exports, and backups.
- Production `.env` values, especially `PUBLIC_API_BASE_URL`, `ALLOWED_ORIGINS`, and data persistence mode.

The codebase is prepared for this flow, but it does not include cloud credentials or a deployed public server.
