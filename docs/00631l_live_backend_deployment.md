# 00631L live backend deployment

Current Render backend:

```text
https://longterm-stock-research-assistant.onrender.com
```

Current frontend origin:

```text
https://dany1230000.github.io
```

這份文件說明如何把 FastAPI backend 部署成公開 API，讓 GitHub Pages / PWA 可以取得 live 資料。

## 最短路線

1. 準備一台可公開連線的 server、VPS、Render、Railway、Fly.io 或等價平台。
2. 複製 `backend\.env.example` 成平台 env 設定。
3. 設定 `PUBLIC_API_BASE_URL` 為公開 backend URL。
4. 設定 `ALLOWED_ORIGINS=https://dany1230000.github.io`。
5. 掛載 persistent volume 到 `/data/00631l`。
6. 設定 `00631L_DATA_DIR=/data/00631l`。
7. 設定 `00631L_DATA_PERSISTENCE_MODE=persistent`。
8. 部署 `backend\Dockerfile`。
9. 用 `/health` 和 `/ready` 檢查狀態。
10. 用 public backend URL 重新 build frontend。

Frontend live build:

```cmd
set PUBLIC_BACKEND_URL=https://your-backend.example.com
scripts\00631l_build_web_public.cmd
```

這個 build 會同時啟用 `live_proxy` 與 `static_public`。live backend 可用時走 API；backend 暫時不可用時，歷史與回測仍可讀 GitHub Pages static JSON。

## 必要 env

```env
PUBLIC_API_BASE_URL=https://your-backend.example.com
ALLOWED_ORIGINS=https://dany1230000.github.io
TWSE_00631L_INTRADAY_NAV_URL=https://mis.twse.com.tw/stock/data/all_etf.txt
00631L_INTRADAY_NAV_SOURCE=auto
00631L_DATA_DIR=/data/00631l
ETF_PRICE_HISTORY_DIR=/data/00631l/etf_price_history
00631L_DATA_PERSISTENCE_MODE=persistent
00631L_HOLDINGS_HISTORY_PATH=/data/00631l/00631l_holdings_history.jsonl
00631L_INTRADAY_NAV_HISTORY_PATH=/data/00631l/00631l_intraday_nav_history.jsonl
00631L_PRICE_HISTORY_PATH=/data/00631l/00631l_price_history.jsonl
ETF_PRICE_HISTORY_DIR=/data/00631l/etf_price_history
00631L_HISTORY_EXPORT_DIR=/data/00631l/exports
00631L_BACKUP_DIR=/data/00631l/backups
00631L_REPORT_DIR=/data/00631l/reports
```

`ALLOWED_ORIGINS` 只填 origin，不填路徑。GitHub Pages 專案頁的 origin 是 `https://dany1230000.github.io`。

## Docker / VPS

Production run:

```cmd
docker build -f backend\Dockerfile -t 00631l-lab-backend .
docker run --rm -p 8000:8000 --env-file backend\.env -v 00631l-data:/data/00631l 00631l-lab-backend
```

Docker Compose 範本：

```cmd
docker compose -f deploy\docker-compose.yml up -d --build
```

反向代理範本：

- `deploy\Caddyfile`
- `deploy\nginx.example.conf`

正式公開建議使用 HTTPS。Caddy 可以自動處理 TLS；nginx 通常搭配平台 TLS 或 certbot。

## Render / Railway / Fly.io

Render blueprint 範本在 `deploy\render.yaml`。

注意：

- Render/Railway/Fly 都需要在平台設定 env。
- data folder 必須掛 persistent disk / volume。
- 沒有 persistent volume 時只能算 transient mode，重啟後本機 history/report/export/backup 可能消失。
- repo 不包含 cloud token、DNS 權限或平台帳號。

## Readiness

公開部署後先檢查：

```text
GET /health
GET /ready
GET /api/etf/00631l/operations/status
```

`/ready` 會檢查：

- public API URL
- CORS origins
- data dir 是否可寫
- persistence mode
- TWSE intraday NAV URL
- TWSE price history URL template
- live source connectivity

網路暫時失敗會以 WARN 表示，不會讓 backend crash。data dir 不可寫或 URL 格式錯誤才是 FAIL。

## 常見問題

### CORS blocked

確認 `ALLOWED_ORIGINS` 包含前端 origin，例如：

```env
ALLOWED_ORIGINS=https://dany1230000.github.io
```

不要填 `/#/00631l-lab`，那不是 origin。

### backend disconnected

前端會先顯示 `backend disconnected`，再使用 static history fallback。請檢查：

- `/health`
- `/ready`
- backend URL 是否和 frontend build 的 `00631L_PROXY_BASE_URL` 一致
- server 防火牆與 HTTPS

### data dir not writable

確認 volume 掛載到 `/data/00631l`，且 container user 可以寫入。

### no persistent volume

operations/status 會顯示 persistence WARN。這不會阻止 app 開啟，但 history/report/export/backup 不適合長期保存。

### intraday unavailable

確認：

- `TWSE_00631L_INTRADAY_NAV_URL`
- backend 可連外
- 目前是否非交易時段

### official source timeout

重新跑 `/ready` 或 smoke script。若 static mode 仍有資料，PWA 仍可看歷史與回測；live intraday 需等 backend source 恢復。

## 範圍限制

目前仍只做 00631L。不接 TX live，不擴大到所有正二，不做投資建議，不做自動交易。
