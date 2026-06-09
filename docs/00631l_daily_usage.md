# 00631L 正二研究室日常使用手冊

本文件說明如何每天用同一套本機流程檢查 00631L 資料。這個研究室只整理資料來源、內容物歷史、折溢價狀態與本機操作狀態，不提供操作建議。

## 第一次安裝

1. 確認 repo 位置：

```cmd
cd C:\dev\longterm_stock_research_assistant
```

2. 確認 Flutter SDK 使用乾淨路徑：

```cmd
where flutter
where dart
```

建議 PATH 最前面是：

```text
C:\src\flutter-clean\bin
```

3. 安裝 backend 套件：

```cmd
py -m pip install -r backend\requirements.txt
```

4. 建立本機 env：

```cmd
copy backend\.env.example backend\.env
```

`backend\.env` 是本機設定檔，不要提交到 git。

5. 檢查本機環境：

```cmd
scripts\00631l_check_env.cmd
```

若顯示 missing `.env`，先依上面的方式複製範本。若顯示 intraday URL 未設定，app 仍可用 mock/fallback 啟動，但盤中即時淨值來源會顯示 unavailable。

## 最簡單日常入口

在專案根目錄執行：

```cmd
scripts\00631l_open_lab.cmd
```

這個 helper 會先跑環境檢查，確認 backend 是否已在 `http://127.0.0.1:8000/health` 回應，並列出 backend、daily cycle、Flutter live proxy 與 `/#/00631l-lab` 的直接開啟方式。它不會把 server 藏在背景執行。

## 每天啟動 backend

在專案根目錄執行：

```cmd
scripts\00631l_start_backend.cmd
```

等 backend 顯示 uvicorn 啟動後，可用另一個終端確認：

```powershell
Invoke-RestMethod http://127.0.0.1:8000/health
Invoke-RestMethod http://127.0.0.1:8000/api/etf/00631l/operations/status
```

## 每天啟動 Flutter live proxy

backend 啟動後，在另一個終端執行：

```cmd
scripts\00631l_start_frontend_live.cmd
```

等 Chrome 開啟後進入：

```text
/#/00631l-lab
```

app 外殼仍叫「中長線研究助理」。若先看到 Dashboard，請點首頁的「00631L 正二研究室」入口，或在瀏覽器網址後方直接使用 `/#/00631l-lab`。

如果 backend 暫時不可用，頁面應顯示 mock/error/fallback 狀態，而不是空白頁。

## 每天跑 daily cycle

daily cycle 會執行 collect、CSV export 與 live smoke：

```cmd
scripts\00631l_daily_cycle.cmd
```

完成後會寫入本機狀態檔：

```text
backend\data\00631l_daily_cycle_status.json
```

這是本機操作狀態，不會提交到 git。`/api/etf/00631l/operations/status` 會讀取最近一次結果。

## operations/status 怎麼看

開啟：

```text
http://127.0.0.1:8000/api/etf/00631l/operations/status
```

重點欄位：

- `sourceStatus`: local operation 狀態。
- `latestHoldingsTradeDate`: 最近一筆 holdings history 的官方內容物日期。
- `latestIntradayDataTime`: 最近一筆 intraday NAV 樣本時間。
- `holdingsHistoryCount`: 本機每日 holdings 筆數。
- `intradaySampleCount`: 本機 intraday NAV 樣本數。
- `exportStatus`: CSV 匯出狀態。
- `dailyCycle`: 最近一次 daily cycle 結果。
- `statusSummary`: app 顯示今日資料狀態用的摘要。

## holdings history 怎麼看

Flutter 頁面 `/00631l-lab` 會顯示每日內容物歷史。主要欄位：

- TX 權重。
- 台積電權重。
- 股票資產比例。
- 期貨資產比例。
- 現金與保證金比例。
- 每單位淨值。
- 發行單位數。
- day-over-day change。
- first-to-latest change。

如果尚未累積 history，頁面會顯示尚無歷史紀錄，不會把 mock 當成 official history。

## 手機瀏覽器使用

手機寬度下，summary、operations status 與 holdings history 摘要會改成單欄卡片，表格保留橫向捲動。sourceStatus 與 sourceContract 會以短 chip 顯示，避免擠壓主要數字。

若表格欄位較多，請左右滑動表格區塊；這不代表資料缺失。

## 加到桌面或手機主畫面

Flutter web build 會使用 `web/manifest.json`。manifest 目前以「00631L 正二研究室」作為 app 名稱，安裝後預設開啟 `/#/00631l-lab`。

瀏覽器安裝方式依平台不同：

- Chrome/Edge 桌面：開啟 web app 後使用瀏覽器選單的安裝 app 或建立捷徑。
- Android Chrome：開啟 web app 後使用加入主畫面。
- iOS Safari：使用分享選單加入主畫面。

安裝到桌面或主畫面只處理前端入口。live data 仍需要 backend proxy 正常啟動。

## CSV 匯出

手動匯出：

```cmd
scripts\00631l_export_history.cmd
```

輸出位置：

```text
backend\exports\00631l_holdings_history_summary.csv
backend\exports\00631l_intraday_nav_history.csv
backend\exports\00631l_history_export_metadata.json
```

`backend\exports\` 是本機輸出目錄，不要提交到 git。

## smoke WARN 怎麼判斷

手動 smoke：

```cmd
py backend\scripts\smoke_00631l_live.py
```

結果意義：

- `PASS`: 必要來源可抓取並可解析。
- `WARN`: 來源可解析，但資料新鮮度或本機設定需要人工確認。盤後、夜間、週末或 `.env` 未設定 intraday URL 時常見。
- `FAIL`: 必要來源抓取或解析失敗，需要先看 `errorMessage`。

盤後 freshness WARN 不代表 app 測試失敗。若 `failures` 為空，可繼續日常檢查。

## backend down 怎麼處理

1. 確認 backend 是否在跑：

```powershell
Invoke-RestMethod http://127.0.0.1:8000/health
```

2. 若連不上，重新啟動：

```cmd
scripts\00631l_start_backend.cmd
```

3. 若仍失敗，跑環境檢查：

```cmd
scripts\00631l_check_env.cmd
```

Flutter 頁面不應因 backend down 變成空白頁；應顯示 error/fallback/mock 狀態。

## .env 怎麼設定

基本範本在：

```text
backend\.env.example
```

常用設定：

```text
TWSE_00631L_INTRADAY_NAV_URL=https://mis.twse.com.tw/stock/data/all_etf.txt
YUANTA_00631L_INTRADAY_NAV_URL=
00631L_INTRADAY_NAV_SOURCE=auto
00631L_PROFILE_CACHE_SECONDS=86400
00631L_HOLDINGS_CACHE_SECONDS=600
00631L_INTRADAY_NAV_CACHE_SECONDS=15
```

Yuanta INAV fallback URL 若需要更新，請從 Yuanta INAV 頁面 network request 重新驗證，不要使用不明來源。

## 備份本機資料

手動備份：

```cmd
scripts\00631l_backup_data.cmd
```

輸出位置：

```text
backend\backups\
```

備份 zip 會包含目前存在的 holdings history、intraday NAV history、daily cycle status 與 export metadata。`backend\backups\` 是本機備份目錄，不要提交到 git。
v1.35 起，backup 會自動保留最近 N 份 `00631l_local_data_backup_*.zip`，預設 30 份。可用 `--retention-count` 調整：

```cmd
scripts\00631l_backup_data.cmd --retention-count 30
```

## local retention

保留策略檢查與清理：

```cmd
scripts\00631l_apply_retention.cmd --report-retention-count 30
```

只檢查、不刪除 report：

```cmd
scripts\00631l_apply_retention.cmd --dry-run --report-retention-count 30
```

保留規則：

- holdings 與 intraday JSONL history 是長期本機紀錄，預設完整保留。
- daily Markdown report 會依 `00631L_REPORT_RETENTION_COUNT` 保留最近 N 份。
- CSV export 使用固定目前檔名，retention helper 只回報狀態，不建立額外 archive。

v1.36 提供 restore dry-run，只讀取備份 zip 並檢查 manifest 與檔案項目是否可讀，不會覆蓋任何本機資料：

```cmd
scripts\00631l_restore_dry_run.cmd
```

v1.46 起，backup manifest 會記錄每個檔案的 SHA256，restore dry-run 會驗證 archive entry 是否符合 checksum，並在 summary 顯示 `entriesVerified`。

若 dry-run 顯示 PASS，代表備份檔結構可讀；若顯示 WARN，通常是目前沒有備份或備份內記錄了部分來源檔缺少；若顯示 FAIL，請先查看 `errorMessage`。真正需要還原時，仍請先解壓到臨時資料夾，比對檔案內容與日期，再手動複製需要的檔案回 `backend\data\` 或 `backend\exports\`，避免覆蓋較新的 history。

## 資料目錄健康狀態

`scripts\00631l_check_env.cmd` 會確認：

- `backend\data`
- `backend\exports`
- `backend\backups`

檢查內容包含目錄是否存在、是否可寫入、是否已有 holdings history、export metadata 與 backup zip。剛安裝還沒有 backup 或 history 時會顯示 WARN，不是 FAIL。

`/00631l-lab` 的 operations/status 也會顯示 data、exports、backups 的簡短狀態。

## 下一步操作提示

`/00631l-lab` 的「今日資料狀態」會顯示「下一步操作提示」。提示只包含 app 操作，例如執行 daily cycle、參考 `.env.example`、檢查 TWSE URL 設定或交易時段、建立 CSV export、建立 local backup、檢查資料目錄。

這些提示只描述本機流程與資料狀態，不是價格判斷或操作建議。

## official / cached / mock / fallback

- `official`: backend 成功從官方來源抓取並解析。
- `cached`: 使用 backend cache 或本機已保存資料。
- `mock`: app 預設示範資料，只用來讓頁面可啟動。
- `fallback`: live source 不可用時的降級流程，必須明確標示。
- `stale`: 資料時間可能過期，需以官方資料時間為準。
- `error`: 抓取、連線或解析失敗。

mock/fallback 不可標成 official。

## 官方每日內容物與盤中即時淨值的差異

Yuanta ratio 是官方每日內容物快照，代表該日揭露的基金內容物與資產結構。它不是盤中即時變動的內容物。

TWSE/Yuanta intraday NAV 是盤中估算資料，只用於市價、預估淨值、折溢價與資料時間觀察。

## 為什麼沒有 TX live

目前 TX 仍保留 mock/fallback，因為 v1.0 到 v1.20 的產品範圍先把 00631L 官方內容物、intraday NAV、history、export 與日常操作流程做穩。TX live 需要另行確認官方來源、CORS、更新頻率與測試策略。

## 為什麼沒有買賣建議

本研究室定位是資料透明化工具，只描述來源狀態、內容物變化、折溢價偏離與資料新鮮度。所有提示都是資料狀態提示，不構成任何操作建議。

## 每日建議流程

```cmd
cd C:\dev\longterm_stock_research_assistant
scripts\00631l_open_lab.cmd
scripts\00631l_check_env.cmd
scripts\00631l_start_backend.cmd
```

另開終端：

```cmd
cd C:\dev\longterm_stock_research_assistant
scripts\00631l_daily_cycle.cmd
scripts\00631l_start_frontend_live.cmd
```

需要 release 前完整驗收時：

```cmd
scripts\00631l_release_check.cmd
```

若要用 Windows Task Scheduler 半自動執行 daily cycle，請先看：

```text
docs/00631l_scheduler_setup.md
```

daily cycle 也會輸出本機 Markdown 日報：

```text
backend\reports\
```

需要手動重新產生日報時：

```cmd
scripts\00631l_generate_daily_report.cmd
```

`/00631l-lab` 的「今日資料狀態」會顯示最近日報是否存在、日報 `overallStatus`、生成時間與 WARN/FAIL 數量。

日報閱讀說明：

```text
docs\00631l_daily_report_guide.md
```

維護文件索引：

```text
docs\00631l_maintenance_index.md
```

日報的 WARN 代表需要人工查看資料時間、source status 或本機設定，不代表資料一定錯誤。FAIL 則代表至少一個必要檢查沒有完成，請先看 `failures`、`errorMessage` 與失敗步驟，再依 troubleshooting 文件排查。

資料完整性檢查：

```cmd
scripts\00631l_check_integrity.cmd
```

檢查結果會寫到：

```text
backend\data\00631l_integrity_status.json
```

duplicate key 與必要欄位缺值是 FAIL；日期缺口與 sourceStatus 異常是 WARN。

常見問題可先看：

```text
docs/00631l_troubleshooting.md
```

部署到其他電腦或固定服務前，請先看：

```text
docs/00631l_deployment_notes.md
```
