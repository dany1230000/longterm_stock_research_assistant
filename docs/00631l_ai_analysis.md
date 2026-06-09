# 00631L AI 分析摘要

`00631L 正二研究室` 的 AI 分析摘要目前是 rule-based，不會呼叫外部 LLM，也不需要 API key。

## 目前來源

- `source: rule_based`
- backend endpoint: `GET /api/etf/00631l/analysis/summary`
- frontend 區塊：`AI 分析摘要`

## 輸入資料

rule-based analysis 讀取已存在的資料狀態：

- official holdings latest snapshot
- holdings 7/30 日變化
- intraday NAV history
- premium / discount 狀態
- daily readiness
- data integrity
- daily report / export / backup 狀態

## 輸出內容

endpoint 回傳：

- `source`
- `generatedAt`
- `dataTime`
- `readinessLevel`
- `bullets`
- `actionItems`
- `sourceStatuses`
- `disclaimer: 非買賣建議`

畫面會顯示 3–6 條摘要與需要的程式操作，例如：

- 請先執行 `scripts\00631l_daily_cycle.cmd`
- 請檢查 `backend\.env`
- 請重新執行 release check
- 請確認 intraday NAV 資料時間

## 資料更新頻率

- official holdings / ratio 是每日快照，不是盤中即時資料。
- intraday NAV / 折溢價來自 TWSE all_etf.txt，backend 與 env 正常時約 15–30 秒更新。
- TX live 尚未接入，目前只顯示 mock/fallback。

## 外部 LLM placeholder

backend 保留 `AnalysisProvider` 介面：

- `RuleBasedAnalysisProvider`
- `ExternalLlmAnalysisProvider` placeholder

預設只使用 rule-based。未來若要接外部 LLM，只能透過本機 `.env` 明確啟用，且不能把 key 寫入 repo。

## 邊界

AI 分析只描述資料狀態、內容物變化、折溢價偏離與資料風險。它不是交易訊號，也不提供投資操作建議。
