# 00631L 盤中資料更新時間

00631L 正二研究室把資料分成三種更新頻率，畫面會分別標示來源與資料時間。

## 官方每日內容物

- 來源：元大 00631L ratio / holdings。
- 更新型態：每日官方快照。
- 用途：股票、期貨、現金、保證金與基金資產結構。
- 注意：這不是盤中即時內容物，盤中不會假裝內容物每 15 秒改變。

## 盤中 NAV / 折溢價

- 來源：TWSE `all_etf.txt`，或 backend 設定的 Yuanta INAV fallback。
- TWSE 一般交易時間：台北時間 09:00 到 13:30。
- 盤中：app 依 `userDelay` 或至少約 15 秒刷新市價、預估淨值、折溢價與資料時間。
- 13:30 後：app 會標示收盤確認或盤後資料，保留最後資料時間。
- 週末或非交易時段：app 會標示休市資料或資料不可用。

目前只內建週末判斷，沒有完整台灣假日行事曆。請以畫面上的 `dataTime` 與官方來源為準。

## TX live

TX live 由 backend 連 TAIFEX MIS quote stream，使用自動解析的月份合約。非交易時段或來源失敗時會顯示 unavailable / stale / cached / mock，不會把 fallback 標示成 official。

## 前端自動刷新

- live proxy 模式：盤中優先刷新 intraday NAV；完整資料低頻刷新。
- static public 模式：提供歷史與回測；不提供 live intraday NAV。
- mock default 模式：只供離線與 fallback 顯示，不代表 official。
