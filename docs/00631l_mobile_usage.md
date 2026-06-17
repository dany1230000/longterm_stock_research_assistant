# 00631L 手機使用方式

## v3.0 mobile modes

There are two supported phone paths:

1. Public deployment: phone opens `https://your-frontend.example.com/#/00631l-lab` from anywhere, and the frontend calls a public backend API.
2. LAN mode: phone and computer are on the same Wi-Fi, and the phone opens `http://<LAN-IP>:<frontend-port>/#/00631l-lab`.

Public deployment is the correct path for daily use outside the home or office network. LAN mode is still useful for local testing.

本文件說明如何用手機開啟 `00631L 正二研究室`。目前支援 LAN 模式；公開部署後，手機可用公開網址開啟。

## 先確認資料更新頻率

- official holdings / ratio：元大每日揭露資料，是每日快照，不是盤中即時內容物。
- intraday NAV / 折溢價：TWSE `all_etf.txt` 可準即時更新，約 15–30 秒；需要 backend 可連線且 `.env` 設定正確。
- TX live：backend 可連 TAIFEX 時顯示自動月份合約與加權指數；fallback 不會標示為 official。

## LAN 手機模式

電腦與手機必須在同一個 Wi-Fi 或 LAN。

1. 在電腦開 repo：

```cmd
cd C:\dev\longterm_stock_research_assistant
```

2. 查看 LAN IP 與手機 URL：

```cmd
scripts\00631l_lan_info.cmd
```

3. 啟動 backend LAN 模式：

```cmd
scripts\00631l_start_backend_lan.cmd
```

這會把 backend 綁到 `0.0.0.0:8000`。Uvicorn 停在 running 是正常的，請保持這個終端開著。

4. 在另一個終端啟動 Flutter web-server LAN 模式：

```cmd
scripts\00631l_start_frontend_lan.cmd
```

5. 手機瀏覽器開啟 script 顯示的 URL：

```text
http://<LAN-IP>:8080/#/00631l-lab
```

## Windows 防火牆

第一次使用時，Windows 可能詢問是否允許 Python 或 Flutter web-server 通過防火牆。若手機無法連線，請確認：

- 手機與電腦在同一個 Wi-Fi。
- backend 已使用 `0.0.0.0` 啟動。
- Flutter web-server 已使用 `0.0.0.0` 啟動。
- Windows 防火牆允許 Python 與 Flutter web-server 在目前網路存取。

不要關閉整個安全性設定；只針對本機開發工具做可回復的允許。

## 公開網址 / PWA 模式

若要讓手機在任何地方開啟，需要：

- Flutter Web 前端部署到公開網址。
- FastAPI backend 部署到公開 server。
- frontend build 時指定公開 backend：

```cmd
set PUBLIC_BACKEND_URL=https://your-backend.example.com
scripts\00631l_build_web_public.cmd
```

手機開：

```text
https://your-frontend.example.com/#/00631l-lab
```

也可以用手機瀏覽器加到主畫面。PWA 只是前端入口；live data 仍需要 backend 可連線。詳細步驟見：

- `docs\00631l_public_deployment.md`
- `docs\00631l_pwa_usage.md`

## 手機畫面怎麼看

進入 `/#/00631l-lab` 後先看：

- `AI 分析摘要`
- `今日資料狀態`
- `資料更新頻率`
- `折溢價狀態`
- `每日內容物歷史`
- `盤中折溢價歷史`

若顯示 mock、unavailable、stale 或 error，請依畫面上的程式操作提示處理，例如檢查 `.env`、啟動 backend、執行 daily cycle 或確認 intraday NAV 資料時間。

所有摘要都只描述資料狀態與價格偏離，非買賣建議。
