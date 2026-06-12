# 00631L lab v3.14 holdings coverage summary

完成日期：2026-06-12

## 完成內容

- 內容物頁新增「內容物歷史覆蓋」區塊。
- backend `operations/status` 會帶出 data integrity 狀態。
- frontend 會顯示：
  - official holdings 當日快照日期。
  - holdings history 累積筆數。
  - integrity overall status。
  - holdings history 缺日數與日期預覽。
- 設定頁與總覽頁沿用同一套 coverage 判斷。

## 資料補齊狀態

- 價格歷史：可用 static-public data，支援歷史與回測。
- 內容物歷史：只從本 app daily cycle 開始累積；官方 ratio 是每日快照。
- 缺日提示：來自 `scripts\00631l_check_integrity.cmd` 的本機資料完整性檢查。
- 盤中 NAV：仍需要 live backend。
- TX live：仍未接入，只使用官方 holdings 裡的 TX 權重。

## 使用方式

每天使用前可執行：

```cmd
scripts\00631l_daily_cycle.cmd
scripts\00631l_check_integrity.cmd
```

若 holdings history 顯示缺日，代表本機目前沒有那幾個交易日的 official ratio snapshot。此 app 不會用 mock 或推算資料補成 official。

本版不接 TX live、不擴大 ETF 範圍、不新增投資建議。
