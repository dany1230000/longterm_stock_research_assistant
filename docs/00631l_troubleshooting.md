# 00631L 正二研究室錯誤排除指南

本文件只處理本機啟動、資料來源、匯出與日常操作問題。00631L 正二研究室不提供操作建議，也不包含 TX live。

## 1. 打開後看到「中長線研究助理」不是 00631L

這是正常的。app 外殼仍保留原本名稱與 Dashboard。

處理方式：

```text
/#/00631l-lab
```

也可以在 Dashboard 點選「00631L 正二研究室」入口。

## 2. backend 卡在 Uvicorn running 是否正常

正常。`scripts\00631l_start_backend.cmd` 會啟動 FastAPI backend，終端機會停在 uvicorn 執行畫面。

確認方式：

```powershell
Invoke-RestMethod http://127.0.0.1:8000/health
```

停止 backend 時，在該終端機按 `Ctrl+C`。

## 3. `backend\.env does not exist` 是什麼意思

代表尚未建立本機 backend 設定檔。這通常是 WARN，不一定會讓 app 無法啟動。

建立方式：

```cmd
copy backend\.env.example backend\.env
```

`backend\.env` 是本機檔案，不要提交到 git。

## 4. intraday NAV unavailable 怎麼辦

先確認 `.env` 是否有設定：

```text
TWSE_00631L_INTRADAY_NAV_URL=https://mis.twse.com.tw/stock/data/all_etf.txt
00631L_INTRADAY_NAV_SOURCE=auto
```

若非交易時段或官方來源暫時無回應，頁面可能顯示 unavailable。這時 app 應保留 mock/error/fallback 狀態，不會把 fallback 標成 official。

## 5. smoke WARN 怎麼判斷

`py backend\scripts\smoke_00631l_live.py` 與 `scripts\00631l_release_check.cmd` 可能在盤後或本機 `.env` 未設定時顯示 WARN。

判斷方式：

- `failures` 是空陣列：通常可接受。
- `Yuanta Basic` 與 `Yuanta ratio` 是 official：官方每日資料來源正常。
- `intraday NAV` 是 unavailable：檢查 TWSE URL、交易時段與網路狀態。

## 6. Flutter path 不對怎麼辦

執行：

```cmd
where flutter
where dart
scripts\00631l_check_env.cmd
```

建議 PATH 最前面使用：

```text
C:\src\flutter-clean\bin
```

不要停用 Windows 安全性政策。若是公司或學校裝置，需由管理者允許官方 Flutter SDK。

## 7. build web 失敗怎麼辦

先執行：

```cmd
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build web
```

若仍失敗，保留完整錯誤輸出，再看是否是 Flutter SDK、套件解析、測試失敗或 web build 問題。

## 8. backend port 8000 被占用怎麼辦

先確認是否已有 backend 在跑：

```powershell
Invoke-RestMethod http://127.0.0.1:8000/health
```

若回應正常，可以直接使用既有 backend。若不是本專案 backend，請先關閉占用該 port 的程式，或手動用其他 port 啟動 backend 並同步調整 Flutter live proxy base URL。

## 9. CSV export 找不到怎麼辦

執行：

```cmd
scripts\00631l_export_history.cmd
```

輸出位置：

```text
backend\exports\
```

若仍沒有檔案，先確認 holdings history 是否存在。

## 10. history 沒資料怎麼辦

先跑一次 daily cycle：

```cmd
scripts\00631l_daily_cycle.cmd
```

也可以單獨收集 snapshot：

```cmd
scripts\00631l_collect_snapshot.cmd --samples 1
```

如果官方 Yuanta ratio 來源暫時無法抓取，history endpoint 會回傳 unavailable 或 error，不會使用 mock 資料偽裝成 official history。

## 快速檢查順序

```cmd
scripts\00631l_open_lab.cmd
scripts\00631l_check_env.cmd
scripts\00631l_daily_cycle.cmd
scripts\00631l_release_check.cmd
```

若 release check 只有可接受 WARN 且 `failures` 為空，通常代表本機日常流程可繼續使用。
