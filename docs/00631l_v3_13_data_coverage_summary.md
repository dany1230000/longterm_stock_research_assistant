# 00631L lab v3.13 data coverage summary

完成日期：2026-06-12

## 完成內容

- 總覽頁新增「資料覆蓋狀態」，直接回答目前資料補齊到哪裡。
- 設定頁的「資料完整度」改用同一組 coverage 判斷，避免總覽與設定說法不一致。
- 四種資料分開標示：
  - 價格歷史：顯示 rows、coverage、source status、是否從上市日起完整。
  - 內容物歷史：顯示 latest snapshot、history count，並標示 official ratio 是每日快照。
  - 盤中 NAV / 折溢價：顯示 dataTime，並標示需要 live backend 與 TWSE all_etf.txt。
  - TX live：明確標示尚未接 live quote，只使用 official holdings 裡的 TX 權重。

## 資料補齊邊界

- 歷史價格與回測資料可透過 static-public data 在公開 PWA 使用。
- 官方 holdings history 只從本 app daily cycle 開始保存；不補假過去內容物。
- 盤中 NAV / 折溢價不是 static data，公開頁若沒有 backend 會顯示 unavailable 或 fallback。
- TX live 仍未接入；目前只顯示官方每日 holdings 中的 TX 權重。

## 使用者可見狀態

- `static_public`：公開靜態資料模式，可看歷史與回測。
- `live_proxy`：前端連到 backend，可抓 holdings、intraday NAV、operations、AI summary。
- `mock_default`：開發或 fallback 模式，不偽裝成 official。
- `unavailable / stale / error`：資料不可用、過期或錯誤時明確顯示原因與程式操作。

## 驗收範圍

- Flutter widget test 覆蓋資料覆蓋狀態與設定頁資料完整度。
- release check 要求本文件存在。
- forbidden wording scan 維持通過。

本版只整理資料覆蓋狀態與文案，不接 TX live、不擴大 ETF 範圍、不新增投資建議。
