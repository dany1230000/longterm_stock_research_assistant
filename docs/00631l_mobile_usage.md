# 00631L 手機使用方式

本文件說明如何用手機在同一個 Wi-Fi 開啟 `00631L 正二研究室`。

## 先確認資料更新頻率

- official holdings / ratio：元大每日揭露資料，是每日快照，不是盤中即時內容物。
- intraday NAV / 折溢價：TWSE `all_etf.txt` 可準即時更新，約 15–30 秒；需要 backend 可連線且 `.env` 設定正確。
- TX live：目前尚未接入，只保留 mock/fallback 顯示，不會標示為 official。

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
