# AGENTS.md

本專案是 `LongTerm Stock Research Assistant`，目前只針對 Flutter Web MVP 開發。

## 產品定位

- App 是中長線股票研究助理，不是投顧工具。
- 目前只使用本地模擬資料。
- 所有分析語氣必須是研究參考、觀察清單、條件篩選結果、歷史統計或風險提醒。
- 不要加入交易指令、價格承諾、收益承諾或煽動式文案。

## 技術規範

- Flutter / Dart。
- Riverpod 管理狀態與 provider。
- go_router 管理路由。
- fl_chart 用於趨勢圖。
- 維持 `models`、`repositories`、`services`、`features`、`shared` 分層。
- Screen 只處理畫面與互動，資料取得透過 provider。
- 新資料來源需先新增 repository implementation，不要讓 screen 直接依賴 API client。

## 平台限制

- 目前只處理 Web。
- 不新增 Android、iOS、Windows 平台設定。
- 不新增登入、訂閱制或後端。
- 不接真實股市 API，除非使用者明確要求並已確認資料授權。

## 驗證指令

```bash
flutter pub get
dart format .
flutter analyze
flutter test
flutter run -d chrome
```
