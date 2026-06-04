# LongTerm Stock Research Assistant

中長線股票研究助理是一個 Flutter Web MVP，定位為研究與教育用途的股票研究工具。v0.2 以本地模擬資料呈現財報趨勢、估值區間、風險提醒、條件篩選、策略研究、ETF 比較、投資組合風險與輔助研究筆記流程。

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

## 下一步

- 建立資料授權清單與資料欄位規格。
- 設計 API-backed repository，但保留 mock repository。
- 補充更多 widget 測試與視覺回歸檢查。
- 規劃研究提醒、ETF 比較、投資組合風險分析與 AI 摘要。
