# 00631L 正二研究室

## 00631L lab status

00631L lab v3.2 is a standalone 00631L PWA. The public root URL opens the 00631L app directly, without first showing the old general research dashboard.

Public root URL:

```text
https://dany1230000.github.io/longterm_stock_research_assistant/
```

Compatibility route:

```text
https://dany1230000.github.io/longterm_stock_research_assistant/#/00631l-lab
```

Start from `docs/00631l_docs_index.md`, `docs/00631l_v3_2_standalone_pwa_summary.md`, or `docs/00631l_v3_3_live_public_summary.md`.

Daily helper:

```cmd
scripts\00631l_open_lab.cmd
```

Local direct route:

```text
/
```

The old general research screens remain available as internal routes for development, but the product experience is now 00631L-only.

Mobile LAN helper:

```cmd
scripts\00631l_lan_info.cmd
scripts\00631l_start_backend_lan.cmd
scripts\00631l_start_frontend_lan.cmd
```

Public deployment helpers:

```cmd
scripts\00631l_check_public_config.cmd
scripts\00631l_backend_prod_check.cmd
scripts\00631l_backend_docker_check.cmd
scripts\00631l_export_static_data.cmd --status-only
scripts\00631l_export_static_data.cmd --update
set PUBLIC_BACKEND_URL=https://your-backend.example.com
scripts\00631l_build_web_public.cmd
scripts\00631l_build_pages_static.cmd
```

v3.3 live-public ready status:

- GitHub Pages static mode remains usable without a backend.
- A public FastAPI backend can be deployed with `backend\Dockerfile` or `deploy\docker-compose.yml`.
- Public backend readiness is exposed at `/ready`.
- Production data should be mounted at `/data/00631l` with `00631L_DATA_PERSISTENCE_MODE=persistent`.
- Public frontend builds can enable both live proxy and static fallback through `scripts\00631l_build_web_public.cmd`.
- Live intraday NAV requires the public backend; static mode is not live intraday data.

v3.4 live backend URL:

```text
https://longterm-stock-research-assistant.onrender.com
```

GitHub Pages builds now use this backend URL by default and keep static history fallback.

Rule-based AI analysis is available at `/api/etf/00631l/analysis/summary` and on `/00631l-lab`. It does not call an external LLM by default and does not require an API key.

Price history and historical backtest:

```cmd
scripts\00631l_update_price_history.cmd --status-only
scripts\00631l_update_price_history.cmd
```

Guides:

- `docs\00631l_data_sources_freshness.md`
- `docs\00631l_backtest_guide.md`
- `docs\00631l_position_tracking.md`

Current source timing:

- Yuanta holdings ratio is an official daily snapshot, not an intraday holdings feed.
- TWSE intraday NAV is the fast-updating market price, estimated NAV, premium/discount, and data-time source.
- TWSE price history is cached locally after running the update script.
- Static public mode reads `00631l-static-data` generated from official TWSE price history.
- TX live remains out of scope and is still mock/fallback by design.

## 00631L lab v1.0 completed

Release status: completed on 2026-06-08. Release summary: `docs/00631l_v1_release_summary.md`. Release checklist: `docs/00631l_release_checklist.md`.

Main 00631L documentation entry: `docs/00631l_docs_index.md`.

The 00631L lab remains a single-product MVP. It does not connect TX live, does not expand to all leveraged ETFs, and does not provide buy/sell advice.

Default mode is mock/fallback. Live proxy mode requires:

```powershell
flutter run -d chrome --dart-define=USE_00631L_LIVE_PROXY=true --dart-define=00631L_PROXY_BASE_URL=http://127.0.0.1:8000
```

v1.0 live sources:

- Yuanta 00631L Basic information: live official through backend proxy.
- Yuanta 00631L holdings ratio: live official daily snapshot through backend proxy.
- TWSE intraday NAV: live official through `https://mis.twse.com.tw/stock/data/all_etf.txt`, `sourceContract: twse_a_k_json`.
- Yuanta INAV: verified official fallback, `sourceContract: yuanta_inav`.
- TX quote: still mock/fallback.
- Premium/discount status: shown as a price-deviation hint only, based on intraday NAV `premiumDiscountPct`, and not shown as official when data is stale or unavailable.
- Holdings history v1.2: backend stores official Yuanta ratio snapshots locally by `tradeDate` in JSONL and exposes `/api/etf/00631l/holdings/history` plus `/summary`; default mock mode shows no official history.
- Holdings change notices v1.3: compares the latest two official holdings history rows and shows data-status reminders for TX, TSMC, cash/margin, and exposure changes. These reminders are not trading advice.
- Intraday premium/discount history v1.4: backend stores official intraday NAV samples locally and the app shows today's highest, lowest, and average premium/discount. This is not a trading signal.
- Status summary v1.5: combines official holdings freshness, intraday NAV status, premium/discount state, holdings change notices, and intraday history into a non-advice data health summary.
- Daily workflow v1.6: `docs/00631l_v1_6_daily_runbook.md` documents backend startup, live proxy mode, smoke checks, and web build flow. `scripts/00631l_release_validate.ps1` runs the release validation sequence.
- Daily collector v1.7: `backend/scripts/collect_00631l_snapshot.py` and `scripts/00631l_collect_snapshot.cmd` collect official holdings and intraday NAV samples into local JSONL history without requiring the Flutter page to be open.
- Holdings trend v1.8: the daily holdings history section shows a simple trend chart for TX weight, TSMC weight, and cash/margin weight, while keeping the table as the source-of-truth detail view.
- Intraday premium trend v1.9: the intraday premium/discount history section shows a simple premiumDiscountPct trend chart with a 0% reference line, using only stored official intraday NAV history.
- Operations status v1.10: backend exposes local collector/history readiness at `/api/etf/00631l/operations/status`, and the lab page shows whether holdings history, intraday samples, and intraday NAV URLs are configured.
- History export v1.11: `scripts/00631l_export_history.cmd` exports local holdings and intraday JSONL history into CSV files under `backend/exports/` for backup or offline review.
- Daily cycle v1.12: `scripts/00631l_daily_cycle.cmd` runs collect, export, and live smoke in one command.
- Local startup checks v1.13: `scripts/00631l_check_env.cmd`, `scripts/00631l_start_backend.cmd`, and `scripts/00631l_start_frontend_live.cmd` provide one-command local environment, backend, and live proxy startup flows.
- Data freshness summary v1.14: `/api/etf/00631l/operations/status` reports local history, intraday samples, export availability, env readiness, and latest daily cycle state; `/00631l-lab` shows a compact "今日資料狀態" section.
- Daily cycle status v1.15: `scripts/00631l_daily_cycle.cmd` records the latest run result to local ignored state at `backend/data/00631l_daily_cycle_status.json`.
- Holdings history polish v1.16: `/00631l-lab` adds a recent 7-row holdings summary plus day-over-day and first-to-latest change columns for key official holdings history metrics.
- CSV export v1.17: history export includes exposure columns, source metadata, row counts, source history range, and `00631l_history_export_metadata.json`.
- Release check v1.18: `scripts/00631l_release_check.cmd` runs env check, Flutter validation, backend tests, daily cycle, export, smoke, wording scan, and git diff check in one command.
- Daily usage v1.19: `docs/00631l_daily_usage.md` gives the daily startup, collection, export, status review, and fallback interpretation flow.
- Final daily-use release v1.20: `docs/00631l_v1_20_final_summary.md` summarizes the completed daily-use scope, live/fallback sources, scripts, endpoints, tests, and limitations.
- Entry experience v1.21: Dashboard now has a clear `00631L 正二研究室` entry and the live frontend startup script prints the direct `/#/00631l-lab` route.
- Mobile layout v1.22: `/00631l-lab` uses compact one-column cards and horizontal tables on phone-width screens.
- Web app metadata v1.23: Flutter web manifest and HTML metadata now present the app as `00631L 正二研究室` and start at `/#/00631l-lab` when installed.
- Local data backup v1.24: `scripts/00631l_backup_data.cmd` writes local history/status/export metadata backups under ignored `backend/backups/`.
- Data directory health v1.25: environment check and operations/status report local `backend/data`, `backend/exports`, and `backend/backups` readiness.
- Open lab helper v1.26: `scripts/00631l_open_lab.cmd` runs the local environment check, reports backend reachability, and prints the backend, daily cycle, live frontend, and direct `/#/00631l-lab` route commands.
- Troubleshooting v1.27: `docs/00631l_troubleshooting.md` covers common local startup, backend, intraday NAV, smoke WARN, Flutter path, CSV export, and history data issues.
- Operations guidance v1.28: `/00631l-lab` shows app operation next steps for daily cycle, `.env`, intraday NAV availability, CSV export, backup, and data directory checks.
- Deployment notes v1.29: `docs/00631l_deployment_notes.md` documents local mode, Flutter web build output, backend proxy needs, `.env`, data persistence, GitHub Pages limits, and home server/VPS considerations.
- Daily experience release v1.30: `docs/00631l_v1_30_daily_experience_summary.md` summarizes direct entry, mobile layout, PWA metadata, backup, data health, helper scripts, troubleshooting, deployment notes, and operations guidance.
- Scheduler prep v1.31: `scripts/00631l_daily_cycle_scheduled.cmd` and `docs/00631l_scheduler_setup.md` prepare Windows Task Scheduler usage for daily cycle runs.
- Daily report v1.32: daily cycle now writes a local Markdown report under ignored `backend/reports/`; `scripts/00631l_generate_daily_report.cmd` can regenerate it manually.
- Operations report UI v1.33: `/api/etf/00631l/operations/status` and `/00631l-lab` show latest daily report availability, overallStatus, generatedAt, and WARN/FAIL counts.
- Data integrity v1.34: `scripts/00631l_check_integrity.cmd` checks local holdings/intraday JSONL for duplicate keys, missing required fields, weekday gaps, and abnormal source statuses.
- Backup rotation v1.35: `scripts/00631l_backup_data.cmd` keeps the latest configured number of local backup archives, default 30.
- Restore dry-run v1.36: `scripts/00631l_restore_dry_run.cmd` verifies the latest local backup archive can be read without overwriting any data.
- Daily report guide v1.37: `docs/00631l_daily_report_guide.md` explains how to read Markdown reports, WARN states, FAIL states, source status, and local report files.
- Release check v1.38: `scripts\00631l_release_check.cmd` now also checks scheduler artifacts, report generation, integrity, backup rotation, and restore dry-run.
- Maintenance stability v1.39: `docs/00631l_maintenance_index.md` consolidates maintenance docs and key scripts now use a compact `[summary] overallStatus=...` line.
- Maintenance release v1.40: `docs/00631l_v1_40_maintenance_summary.md` summarizes the semi-automated daily maintenance release line.
- Deployment bootstrap v1.41: `scripts\00631l_bootstrap_deploy.cmd` prepares dependencies, `.env`, local directories, and environment checks before deployment or first use.
- Backend health v1.42: `/health` and operations/status now expose deployment-friendly backend health, source configuration, and local-state readiness metadata.
- Backend disconnected state v1.43: live proxy fallback now keeps `/00631l-lab` readable while explicitly showing `backend disconnected` and mock/fallback status.
- Daily report UI v1.44: `/00631l-lab` now shows the latest local daily report status, generated time, WARN/FAIL counts, and report path.
- Retention policy v1.45: `scripts\00631l_apply_retention.cmd` prunes old daily report Markdown files, reports fixed CSV export retention state, and keeps JSONL history as the long-term local record.
- Backup checksum v1.46: local backup manifests include SHA256 per included file, and restore dry-run verifies archive entries before any manual restore workflow.
- Release check v1.47: `scripts\00631l_release_check.cmd` now includes deployment precheck and retention dry-run coverage.
- Documentation index v1.48: `docs\00631l_docs_index.md` is the main entry point for daily use, troubleshooting, maintenance, deployment, and release-summary routing.
- Stability patch v1.49: backend tests verify that local paths in `docs\00631l_docs_index.md` exist, and release check requires the docs index.
- Deployment stability release v1.50: `docs\00631l_v1_50_deployment_stability_summary.md` summarizes the stable deployment and data reliability checkpoint.
- Mobile + AI v2.1: `docs\00631l_mobile_usage.md` explains LAN phone usage, and `docs\00631l_ai_analysis.md` explains rule-based AI analysis. holdings/ratio remains a daily official snapshot; intraday NAV is the 15–30 second live/cached source; TX live remains mock/fallback.
- Public deploy-ready v2.2: `backend\Dockerfile`, `scripts\00631l_check_public_config.cmd`, `scripts\00631l_build_web_public.cmd`, `docs\00631l_public_deployment.md`, and `docs\00631l_pwa_usage.md` prepare the lab for a public Flutter Web frontend plus public FastAPI backend. Local LAN mode remains available.
- Static-public v3.1: GitHub Pages can serve generated 00631L price history and backtest data without a live backend.
- Standalone PWA v3.2: the public root URL opens `00631L 正二研究室` directly; `/#/00631l-lab` remains compatible.
- Live-public ready v3.3: backend deployment package, `/ready`, persistent volume guidance, deploy templates, and live-to-static frontend fallback are complete.

Local backend env:

```powershell
cd C:\dev\longterm_stock_research_assistant
Copy-Item backend\.env.example backend\.env
```

Start backend:

```powershell
.\backend\run_dev.ps1
```

CMD wrapper:

```cmd
scripts\00631l_start_backend.cmd
```

Start frontend live proxy:

```powershell
flutter run -d chrome --dart-define=USE_00631L_LIVE_PROXY=true --dart-define=00631L_PROXY_BASE_URL=http://127.0.0.1:8000
```

CMD wrapper:

```cmd
scripts\00631l_start_frontend_live.cmd
```

Check local environment:

```cmd
scripts\00631l_check_env.cmd
```

Manual smoke:

```powershell
.\scripts\00631l_daily_smoke.ps1
```

Holdings history is populated by calling the backend holdings endpoint after the backend is running:

```powershell
Invoke-RestMethod http://127.0.0.1:8000/api/etf/00631l/holdings
Invoke-RestMethod http://127.0.0.1:8000/api/etf/00631l/holdings/history/summary?limit=30
```

Daily collector:

```cmd
scripts\00631l_collect_snapshot.cmd --samples 1
```

For intraday observation, run repeated samples with an interval at least as long as the configured intraday NAV cache seconds:

```cmd
scripts\00631l_collect_snapshot.cmd --skip-profile --skip-holdings --samples 20 --interval-seconds 15
```

Export local history:

```cmd
scripts\00631l_export_history.cmd
```

Back up local 00631L data:

```cmd
scripts\00631l_backup_data.cmd
```

Open the 00631L lab daily helper:

```cmd
scripts\00631l_open_lab.cmd
```

Run the daily cycle:

```cmd
scripts\00631l_daily_cycle.cmd
```

The smoke script prints an `[overall]` block with `PASS`, `WARN`, or `FAIL`. A freshness warning after market close is a manual-review warning, not an automatic app test failure.

Release checklist:

```text
docs/00631l_release_checklist.md
```

Daily usage guide:

```text
docs/00631l_daily_usage.md
```

Daily report guide:

```text
docs/00631l_daily_report_guide.md
```

Maintenance index:

```text
docs/00631l_maintenance_index.md
```

Maintenance release summary:

```text
docs/00631l_v1_40_maintenance_summary.md
```

Deployment bootstrap:

```cmd
scripts\00631l_bootstrap_deploy.cmd
```

Troubleshooting guide:

```text
docs/00631l_troubleshooting.md
```

Deployment notes:

```text
docs/00631l_deployment_notes.md
```

Daily experience release summary:

```text
docs/00631l_v1_30_daily_experience_summary.md
```

Windows Task Scheduler setup:

```text
docs/00631l_scheduler_setup.md
```

Generate the latest local daily report:

```cmd
scripts\00631l_generate_daily_report.cmd
```

Check local history integrity:

```cmd
scripts\00631l_check_integrity.cmd
```

Backup with rotation:

```cmd
scripts\00631l_backup_data.cmd --retention-count 30
```

Restore dry-run:

```cmd
scripts\00631l_restore_dry_run.cmd
```

Final v1.20 summary:

```text
docs/00631l_v1_20_final_summary.md
```

Full local validation wrapper:

```powershell
.\scripts\00631l_release_validate.ps1
```

If PowerShell script execution is disabled locally, use:

```cmd
scripts\00631l_release_validate.cmd
```

Official daily holdings are daily snapshots. Intraday NAV is only market price, estimated NAV, premium/discount, and timestamps. If live proxy or intraday URLs are unavailable, the app must show `mock`, `cached`, `unavailable`, or `error` state clearly and must not label fallback data as official.

## 00631L live smoke - 2026-06-08

The 00631L lab remains a single-product MVP. Do not treat mock data as official data.

Manual backend live smoke:

```powershell
cd C:\dev\longterm_stock_research_assistant
py backend\scripts\smoke_00631l_live.py
```

Run backend proxy:

```powershell
py -m uvicorn backend.app.main:app --host 127.0.0.1 --port 8000
```

Optional intraday NAV live proxy env:

```powershell
$env:TWSE_00631L_INTRADAY_NAV_URL="https://mis.twse.com.tw/stock/data/all_etf.txt"
$env:YUANTA_00631L_INTRADAY_NAV_URL="https://etfapi.yuantaetfs.com/ectranslation/api/trans?APIType=ETFBackstage&CompanyName=YUANTAFUNDS&PageName=%2FtradeInfo%2FINav%2FAsia_ETF&DeviceId=00000000-0000-4000-8000-000000000631&FuncId=ETFNAV%2FGetINAV_Data&AppName=ETF&Device=4&Platform=ETF"
${env:00631L_INTRADAY_NAV_SOURCE}="auto"
${env:00631L_PROFILE_CACHE_SECONDS}="86400"
${env:00631L_HOLDINGS_CACHE_SECONDS}="600"
${env:00631L_INTRADAY_NAV_CACHE_SECONDS}="15"
```

Run Flutter with live proxy:

```powershell
flutter run -d chrome --dart-define=USE_00631L_LIVE_PROXY=true --dart-define=00631L_PROXY_BASE_URL=http://127.0.0.1:8000
```

Direct web route:

```text
http://127.0.0.1:<flutter-port>/#/00631l-lab
```

Current source status:

- Yuanta 00631L Basic information: verified live through backend proxy.
- Yuanta 00631L holdings ratio: verified live through backend proxy.
- Intraday NAV: verified via TWSE official `all_etf.txt` aggregate a-k feed when `TWSE_00631L_INTRADAY_NAV_URL` is configured. Yuanta INAV is also supported as `sourceContract: yuanta_inav` fallback.
- TX quote: still mock/fallback.

Official daily holdings are not intraday live holdings. Intraday data should only be used for market price, estimated NAV, and premium/discount observation.

## 00631L live proxy validation notes

`00631L 正二研究室` 預設仍使用 mock/fallback，不會把 mock 偽裝成官方資料。若要使用 live proxy，先啟動 backend：

```powershell
py -m pip install -r backend\requirements.txt
py -m uvicorn backend.app.main:app --reload --host 127.0.0.1 --port 8000
```

再以 dart define 啟用前端 proxy：

```powershell
flutter run -d chrome --dart-define=USE_00631L_LIVE_PROXY=true --dart-define=00631L_PROXY_BASE_URL=http://localhost:8000
```

官方每日內容物是每日快照；盤中即時資料是市價、預估淨值與折溢價。live proxy 是為了解決 Flutter Web CORS 與來源格式處理問題。更多細節見 `docs/00631l_lab.md`、`docs/00631l_live_proxy.md`、`docs/windows_flutter_policy_block.md`。

Flutter SDK policy block has been resolved locally by using the clean official SDK at `C:\src\flutter-clean`. Current validation commands pass: `flutter analyze`, `flutter test`, `flutter build web`, and `py -m unittest discover -s backend\tests`. Historical Windows policy details remain in `docs/windows_flutter_policy_block.md`.

中長線股票研究助理是一個 Flutter Web MVP，定位為研究與教育用途的股票研究工具。v0.2 以本地模擬資料呈現財報趨勢、估值區間、風險提醒、條件篩選、策略研究、ETF 比較、投資組合風險與輔助研究筆記流程。

## Flutter Test Runner Note

This Flutter app uses `flutter_test`; the primary app test command is:

```powershell
flutter test
```

`dart test` is not the main validation command for this repo because the project does not currently define a pure Dart `package:test` test runner. Do not treat `dart test` package-not-found output as an app test failure unless a future change intentionally adds `package:test` tests.

## GitHub Pages Demo

公開 Demo：

```text
https://dany1230000.github.io/longterm_stock_research_assistant/
```

## Demo 狀態

- 目前是 Web MVP Demo 版本。
- 目前使用本地模擬資料，不串接真實股市 API。
- 內容僅供研究與教育用途，不構成投資建議、買賣建議或收益保證。
- 目前沒有登入、後端、訂閱制或永久資料儲存。

## 本機開發方式

```bash
flutter pub get
dart format .
flutter analyze
flutter test
flutter run -d chrome
```

## Web Build 方式

一般本機 build：

```bash
flutter build web
```

GitHub Pages project page build：

```bash
flutter build web --base-href="/longterm_stock_research_assistant/"
```

`build/web` 是部署產物。

## 主要功能

- 研究工作台：今日研究摘要、觀察清單、估值偏高觀察清單、營收轉強觀察清單、風險升高觀察清單、產業分布與快速入口。
- 個股詳情頁：總覽、財務、估值、營收、籌碼 / 觀察資料、風險、研究筆記七個分段。
- 條件篩選頁：以 ROE、營收 YoY、PE、PB、殖利率、分數、風險程度、產業與長期均線整理條件篩選結果，並支援 preset。
- 策略研究頁：以模擬歷史資料呈現多策略統計、年度報酬表、權益曲線、回撤曲線與 0050 比較。
- 投資組合頁：持股總覽、持股清單、產業集中度、曝險、風險提醒與情境模擬。
- ETF 比較頁：兩檔 ETF mock 比較、持股、產業曝險與重疊率提醒。
- 00631L 正二研究室：單一 00631L MVP，整理元大官方每日內容物、TWSE 即時淨值格式資料、TX 期貨觀察與基礎分析摘要；目前預設使用明確標示的 mock/fallback。
- 提醒中心：營收、估值、風險、ETF、投資組合與 mock 事件提醒。
- 研究筆記頁：作為輔助頁保留，支援觀察紀錄新增、編輯、刪除與篩選，資料暫存於 memory repository。
- 設定頁：免責聲明、資料來源、授權提醒、版本資訊與未來功能 placeholder。

## 專案架構

```text
lib/
  main.dart
  app.dart
  router.dart
  theme/
  models/
  repositories/
  services/
  features/
    dashboard/
    stock_detail/
    screener/
    backtest/
    portfolio_risk/
    etf_compare/
    leveraged_etf_lab/
    alerts/
    journal/
    settings/
  shared/
    widgets/
    utils/
test/
docs/
```

## 技術選擇

- Flutter / Dart
- Riverpod
- go_router
- fl_chart
- 本地 mock repository

## 產品語氣

App 文案必須維持研究參考、觀察清單、條件篩選結果、歷史統計與風險提醒語氣。不得使用交易指令、價格承諾、收益承諾或煽動式文案。

## 00631L 正二研究室

詳細設計與資料限制見 `docs/00631l_lab.md`。此頁只針對 00631L，不擴大成全市場正二或所有槓桿 ETF。官方每日內容物與盤中估算資料分開標示；若 live source 被 CORS 阻擋，需透過 backend/proxy 接入，不能把 mock 資料偽裝成官方即時資料。

## 下一步

- 建立資料授權清單與資料欄位規格。
- 設計 API-backed repository，但保留 mock repository。
- 補充更多 widget 測試與視覺回歸檢查。
- 規劃研究提醒、ETF 比較、投資組合風險分析與 AI 摘要。
