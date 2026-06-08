# LongTerm Stock Research Assistant

## 00631L lab v1.0 completed

Release status: completed on 2026-06-08. Release summary: `docs/00631l_v1_release_summary.md`. Release checklist: `docs/00631l_release_checklist.md`.

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

Local backend env:

```powershell
cd C:\dev\longterm_stock_research_assistant
Copy-Item backend\.env.example backend\.env
```

Start backend:

```powershell
.\backend\run_dev.ps1
```

Start frontend live proxy:

```powershell
flutter run -d chrome --dart-define=USE_00631L_LIVE_PROXY=true --dart-define=00631L_PROXY_BASE_URL=http://127.0.0.1:8000
```

Manual smoke:

```powershell
py backend\scripts\smoke_00631l_live.py
```

The smoke script prints an `[overall]` block with `PASS`, `WARN`, or `FAIL`. A freshness warning after market close is a manual-review warning, not an automatic app test failure.

Release checklist:

```text
docs/00631l_release_checklist.md
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
