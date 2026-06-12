# 00631L lab v3.16 overview first screen summary

完成日期：2026-06-12

## 完成範圍

- 總覽頁第一屏改成更適合手機閱讀的「今日快覽」。
- 移除總覽第一屏原本像表格的資料狀態列表，改成四張資料模式卡：
  - `DAY`：官方每日內容物快照。
  - `LIVE`：盤中 NAV 與折溢價狀態。
  - `HIS`：歷史價格 rows 與 coverage。
  - `AI`：rule-based AI 摘要狀態。
- 詳細資料覆蓋、診斷、daily cycle、export、backup 等維護資訊仍保留在下方區塊與設定頁。

## 資料說明

- official holdings 仍是每日官方資料，不是盤中即時內容物。
- live intraday NAV 仍需要 backend；static-public 模式不提供盤中即時資料。
- static-public 歷史資料仍可支援歷史與回測。
- TX live 仍未接入。

## 驗收重點

- 總覽頁第一屏更短、更像股票 app 首頁。
- 資料來源狀態仍清楚標示，不把 fallback 或 mock 標示成 official。
- 文案只描述資料狀態與價格偏離，不提供投資建議。
