# LongTerm Stock Research Assistant

中長線股票研究助理是一個 Flutter Web MVP，定位為研究與教育用途的股票研究工具。第一版以本地模擬資料呈現財報趨勢、估值區間、風險提醒、條件篩選、策略回測與研究日記流程。

## 執行方式

```bash
flutter create . --platforms=web
flutter pub get
dart format .
flutter analyze
flutter test
flutter run -d chrome
```

## 目前功能

- 首頁 Dashboard：今日研究摘要、需要注意的觀察清單、估值偏高清單、營收轉強清單、自選股列表。
- 個股詳情頁：總覽、財務、估值、風險、筆記五個分段。
- 條件篩選頁：以 ROE、營收 YoY、PE、殖利率、體質分數與 200 日均線整理條件篩選結果。
- 策略回測頁：以模擬歷史資料呈現策略條件摘要、統計指標、年度報酬表與 0050 比較。
- 研究日記頁：新增研究紀錄，資料暫存於 memory repository。
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
