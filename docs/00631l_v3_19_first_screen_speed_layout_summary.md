# 00631L lab v3.19 first-screen speed and layout summary

完成日期：2026-06-12

## 完成範圍

- 首頁 loading 改為 app shell + skeleton card，避免初次載入時只看到空白轉圈。
- 00631L lab 資料讀取改為並行取得，降低 profile、holdings、intraday、history、AI 與 operations 依序等待的體感時間。
- 上方導覽壓縮為單行情境列，手機寬度會隱藏 mode badge，避免 390px 畫面溢出。
- 總覽行情卡改為 compact quote card，先顯示市價、折溢價、資料時間、預估淨值、官方 NAV 與發行單位。
- 低頻資料來源與更多資料狀態改為預設收合，首頁首屏優先保留行情、今日快覽、核心比較與內容物變化。

## 範圍限制

- 沒有新增資料來源。
- 沒有接 TX live。
- 沒有擴大到所有正二。
- 沒有新增投資建議。

## 驗收重點

- root 頁載入時先出現 00631L app skeleton，而不是單一 spinner。
- 手機首屏不再出現重複導覽或過大的 hero card。
- `flutter analyze`、`flutter test`、web build、backend tests 與 release check 維持可通過。
