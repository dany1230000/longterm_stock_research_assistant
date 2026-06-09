# 00631L 正二研究室 deployment notes

本文件整理未來搬到其他電腦、固定服務或簡單 web hosting 時需要注意的事項。範圍只包含 00631L 正二研究室與 backend proxy，不包含 TX live 或任何交易功能。

## 1. 本機開發模式

建議流程：

```cmd
cd C:\dev\longterm_stock_research_assistant
scripts\00631l_check_env.cmd
scripts\00631l_start_backend.cmd
```

另開終端：

```cmd
scripts\00631l_start_frontend_live.cmd
```

Flutter live proxy mode 使用：

```text
USE_00631L_LIVE_PROXY=true
00631L_PROXY_BASE_URL=http://127.0.0.1:8000
```

直接頁面：

```text
/#/00631l-lab
```

## 2. Flutter web build 輸出

產生 web build：

```cmd
flutter build web
```

輸出位置：

```text
build\web
```

`build\` 是產物，不要提交到 git。

Flutter web build 是靜態前端。若只把 `build\web` 放到 GitHub Pages 或其他靜態服務，live data 仍需要可連線的 backend proxy。沒有 backend 時，頁面只能顯示 mock、stale、unavailable 或 cached 狀態，不能把這些狀態標示為 official。

frontend live proxy mode 需設定 backend URL：

```cmd
flutter run -d chrome --dart-define=USE_00631L_LIVE_PROXY=true --dart-define=00631L_PROXY_BASE_URL=http://127.0.0.1:8000
```

公開前端 build 使用：

```cmd
set PUBLIC_BACKEND_URL=https://your-backend.example.com
scripts\00631l_build_web_public.cmd
```

手機 LAN 模式請用：

```cmd
scripts\00631l_lan_info.cmd
scripts\00631l_start_backend_lan.cmd
scripts\00631l_start_frontend_lan.cmd
```

手機 URL 會是：

```text
http://<LAN-IP>:8080/#/00631l-lab
```

## 3. backend proxy 需求

live data 需要 backend proxy，原因是：

- Flutter Web 直接抓官方頁面可能遇到 CORS。
- backend 統一解析 Yuanta Basic、Yuanta ratio、TWSE intraday NAV 與 Yuanta INAV fallback。
- backend 負責 cache、本機 history、CSV export、daily cycle status 與 operations/status。

啟動 backend：

```cmd
scripts\00631l_start_backend.cmd
```

等同於：

```cmd
py -m uvicorn backend.app.main:app --reload --host 127.0.0.1 --port 8000
```

公開 server 可使用 production-like 指令：

```cmd
py -m uvicorn backend.app.main:app --host 0.0.0.0 --port 8000
```

Docker 範例：

```cmd
docker build -f backend\Dockerfile -t 00631l-lab-backend .
docker run --rm -p 8000:8000 --env-file backend\.env -v 00631l-data:/data 00631l-lab-backend
```

## 4. `.env` 設定

從範本建立：

```cmd
copy backend\.env.example backend\.env
```

至少確認：

```text
PUBLIC_API_BASE_URL=https://your-backend.example.com
ALLOWED_ORIGINS=https://your-frontend.example.com
TWSE_00631L_INTRADAY_NAV_URL=https://mis.twse.com.tw/stock/data/all_etf.txt
00631L_INTRADAY_NAV_SOURCE=auto
00631L_DATA_DIR=/data
00631L_DATA_PERSISTENCE_MODE=persistent
00631L_PROFILE_CACHE_SECONDS=86400
00631L_HOLDINGS_CACHE_SECONDS=600
00631L_INTRADAY_NAV_CACHE_SECONDS=15
```

`backend\.env` 是本機設定，不要提交到 git。

## 5. data folder 持久化

需要保存：

```text
backend\data\
backend\exports\
backend\backups\
```

這些目錄包含：

- holdings history JSONL
- intraday NAV history JSONL
- daily cycle status JSON
- CSV export
- local backup zip

若搬到新機器，先備份再搬移。v1.36 提供 restore dry-run，可先檢查備份 zip 與 manifest 是否可讀；實際還原仍需解壓到臨時資料夾，比對後再手動複製需要的檔案，避免覆蓋現有 history。

## 6. exports/backups 忽略規則

`backend\exports\` 與 `backend\backups\` 是本機輸出。它們應保留在 `.gitignore` 中，不要提交產出檔。

需要匯出資料時使用：

```cmd
scripts\00631l_export_history.cmd
```

需要本機備份時使用：

```cmd
scripts\00631l_backup_data.cmd
```

檢查最近備份是否可讀：

```cmd
scripts\00631l_restore_dry_run.cmd
```

## 7. GitHub Pages 限制

GitHub Pages 可以放 Flutter web 靜態前端，但不能執行 FastAPI backend。

因此：

- mock/fallback mode 可以只靠前端開啟。
- live data、history accumulation、CSV export、daily cycle 與 operations/status 仍需要 backend proxy。
- 若前端部署在 GitHub Pages，`00631L_PROXY_BASE_URL` 必須指到可連線的 backend。

## 8. 家用主機或 VPS 注意事項

若 backend 放到家用主機或 VPS，需處理：

- backend port 與防火牆規則
- frontend 到 backend 的 CORS 設定
- `.env` 與 cache 秒數
- `backend\data\` 的持久化與備份
- `backend\exports\` 與 `backend\backups\` 的磁碟空間
- daily cycle 是否手動執行或另由作業系統排程執行

若沒有 HTTPS 或固定網域，瀏覽器可能限制部分存取情境。先以本機模式確認資料鏈正常，再考慮固定部署。

更多公開部署細節見 `docs\00631l_public_deployment.md`。PWA 使用方式見 `docs\00631l_pwa_usage.md`。未來 Android / iOS 路線見 `docs\00631l_app_store_path.md`。

## 9. 明確未包含

- TX live
- 所有正二
- 推播通知
- 自動交易
- 投資或交易建議

本研究室只整理資料來源、內容物歷史、折溢價狀態與本機操作狀態。
