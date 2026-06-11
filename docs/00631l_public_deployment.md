# 00631L public deployment

## v3.0 public app-ready note

The codebase is ready for a public frontend plus public backend deployment, but this repository does not include cloud credentials, DNS ownership, TLS certificates, or a running server.

Minimum public setup:

1. Deploy the FastAPI backend with `backend\Dockerfile` or a production Python service.
2. Mount a persistent data volume for backend local state.
3. Set `PUBLIC_API_BASE_URL` to the backend public URL.
4. Set `ALLOWED_ORIGINS` to the frontend public origin.
5. Build Flutter Web with `USE_00631L_LIVE_PROXY=true` and `00631L_PROXY_BASE_URL=https://your-backend.example.com`.
6. Host `build\web` on static hosting.
7. Open `https://your-frontend.example.com/#/00631l-lab` on mobile.

Without a public backend, the PWA can still load, but live data sections will show mock, stale, unavailable, or error states instead of official live data.

本文件說明如何把 00631L 正二研究室部署成公開可連線工具。這不是綁定特定 cloud 平台的教學，也不需要把 token 或 secret 放進 repo。

## 架構

- Flutter Web / PWA 是靜態前端。
- FastAPI backend 是 live data proxy。
- 手機瀏覽器開公開前端網址，再由前端呼叫公開 backend API。
- live data、history、report、export、backup 都需要 backend。
- 只放 GitHub Pages 或純靜態 hosting 時，沒有 backend 就只能顯示 mock、cached、stale、unavailable 或 error。

## Backend env

在公開 server 設定環境變數，不要 commit `.env`：

```env
PUBLIC_API_BASE_URL=https://your-backend.example.com
ALLOWED_ORIGINS=https://your-frontend.example.com
TWSE_00631L_INTRADAY_NAV_URL=https://mis.twse.com.tw/stock/data/all_etf.txt
YUANTA_00631L_INTRADAY_NAV_URL=
00631L_INTRADAY_NAV_SOURCE=auto
00631L_DATA_DIR=/data
00631L_DATA_PERSISTENCE_MODE=persistent
```

`ALLOWED_ORIGINS` 是逗號分隔清單。公開部署請填明確前端 origin，不要用 wildcard。

## Backend run

本機 production-like 指令：

```cmd
py -m uvicorn backend.app.main:app --host 0.0.0.0 --port 8000
```

Docker build 範例：

```cmd
docker build -f backend\Dockerfile -t 00631l-lab-backend .
docker run --rm -p 8000:8000 --env-file backend\.env -v 00631l-data:/data 00631l-lab-backend
```

部署平台 health check 可用：

```text
/health
```

## Frontend build

公開前端 build 時指定 backend URL：

```cmd
flutter build web --dart-define=USE_00631L_LIVE_PROXY=true --dart-define=00631L_PROXY_BASE_URL=https://your-backend.example.com
```

或用 helper：

```cmd
set PUBLIC_BACKEND_URL=https://your-backend.example.com
scripts\00631l_build_web_public.cmd
```

完成後部署 `build\web` 到靜態 hosting。手機開：

```text
https://your-frontend.example.com/#/00631l-lab
```

## Persistent data

公開部署必須把 backend data 掛到 persistent volume。至少要保存：

- holdings history JSONL
- intraday NAV history JSONL
- daily cycle status
- integrity status
- reports
- exports
- backups

如果 `00631L_DATA_PERSISTENCE_MODE` 不是 `persistent`，operations/status 會顯示 warning。這代表資料可能只是本機或暫存狀態，不適合長期公開服務。

## CORS

backend 會讀 `ALLOWED_ORIGINS`。公開部署請只允許前端網域，例如：

```env
ALLOWED_ORIGINS=https://00631l.example.com
```

本機或 LAN 模式未設定 `ALLOWED_ORIGINS` 時，backend 保留 localhost / private LAN fallback。

## 檢查

```cmd
scripts\00631l_check_public_config.cmd
scripts\00631l_release_check.cmd
```

缺公開 backend URL 時會 WARN，不會 FAIL。URL 格式錯誤、wildcard CORS、或本機資料產物被 git 追蹤會 FAIL。

## 範圍限制

- 只服務 00631L。
- TX live 尚未接入。
- 不提供投資建議。
- 不包含通知、自動下單或 app store 上架流程。
