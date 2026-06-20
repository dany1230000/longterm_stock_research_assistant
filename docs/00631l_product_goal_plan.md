# 00631L / ETF 研究室產品目標規劃

Date: 2026-06-20

## 目前完成狀態

- 00631L 正二研究室已是公開 PWA，GitHub Pages root 可直接開啟。
- Render backend 可提供 live proxy：Yuanta Basic、Yuanta holdings、TWSE intraday NAV、TAIFEX TX quote。
- static public data 可在沒有 backend 時提供歷史價格與回測資料。
- 00631L 2026 分割已用調整價處理，歷史績效與回測使用 `adjustedClose`。
- ETF catalog 與多檔 ETF 歷史資料已建立基礎，可做搜尋與比較。
- 持倉追蹤是 local-only，不需要登入，不上傳個人資料。
- AI 摘要目前是 rule-based，只描述資料狀態、歷史變化與程式操作。

## 主要問題

1. 首頁第一眼仍需要更清楚：市價、資料時間、折溢價、走勢、內容物重點要更快讀懂。
2. 歷史圖表需要更好的日期標示與點擊資訊。
3. ETF 搜尋與比較要從固定比較改成使用者可選。
4. 資料正確性要持續放在第一順位：分割、coverage、live/static/cached/stale/mock/error 必須清楚標示。
5. AI 分析要更像每日資料解讀，而不是一般描述文字。

## 產品目標

最終產品是「ETF 研究室」，00631L 是第一個完整研究室。

使用者每天打開手機應該能快速知道：

- 今天 live backend 是否正常。
- intraday NAV 與折溢價資料時間是否可靠。
- 官方 holdings 是哪一天的每日快照。
- TX、台積電、股票、期貨、現金/保證金比例如何變化。
- 歷史價格、NAV、報酬、回撤與回測結果使用哪個資料來源。
- 目前選取 ETF 的歷史資料是否完整。
- 本機持倉資料是否只存在本機。
- 下一步需要做的程式操作，例如更新資料、檢查 backend、重新匯出 CSV。

## 下一階段路線

### v4.16 首頁與圖表可讀性

- 首頁走勢改為近一年。
- 圖表下方加入日期標示。
- 點擊圖表可顯示日期與數值。
- 新增本文件與工作計畫。

### v4.17 資料正確性面板

- 將分割調整、raw/adjusted price、coverage、row count、latest date 放到更清楚的位置。
- 針對 00631L 與其他 ETF 分別顯示資料完整度。
- 不把 static history 說成 live intraday。

### v4.18 ETF 搜尋與切換

- 左上 ETF 按鈕成為主要搜尋入口。
- 搜尋後整頁切換到該 ETF 的歷史、回測、持倉與 AI context。
- 00631L official holdings 只在 00631L context 顯示。

### v4.19 自選 ETF 比較

- 比較清單由使用者選擇。
- 保留同類型比較入口，但不強迫每檔都跟 00631L 比。

### v4.20 回測與持倉精簡

- 回測預設一年，保留日期可調。
- 手機版縮短輸入表單長度。
- 持倉頁保留 local-only、JSON 匯出、清除資料。

### v4.21 AI 每日資料解讀

- AI 摘要改成「今日資料狀態、價格偏離、內容物變化、歷史風險、程式操作」。
- 不輸出操作方向或未來預測。

### v5.0 App Store 準備版

- PWA 維持正式使用版本。
- Android/iOS 只做 frontend shell。
- live data 仍依賴 public backend。
- 補齊 app icon、privacy policy、network permission、release signing 文件。

## 原則

- 不把 fallback 說成 official。
- 不把 static history 說成 live intraday。
- 不用假資料補空洞。
- 不在 UI 提供操作方向。
- 每一版都要可測試、可 build、可回復。
