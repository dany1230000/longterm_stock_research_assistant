# 00631L 遠端日常維護

本文件說明如何讓公開 backend 在不開本機電腦的情況下維持日常檢查。

## 目的

00631L 正二研究室目前有兩種公開資料模式：

- `live_proxy`：前端連到公開 FastAPI backend，取得 holdings、intraday NAV、AI 摘要與系統狀態。
- `static_public`：GitHub Pages 內建靜態歷史資料，backend 暫時不可用時仍可看歷史與回測。

遠端日常維護的目標是定時喚醒公開 backend，並執行資料狀態檢查。

## GitHub Actions

workflow：

```text
.github/workflows/00631l_backend_maintenance.yml
```

預設 public backend：

```text
https://longterm-stock-research-assistant.onrender.com
```

可選設定：

```text
PUBLIC_BACKEND_URL
```

如果 GitHub repository secret 有設定 `PUBLIC_BACKEND_URL`，workflow 會使用 secret。沒有設定時會使用 Render 預設網址。

## 排程

目前排程：

- 台灣交易日上午盤中：每 15 分鐘執行 `intraday` mode。
- 台灣交易日收盤後：執行 `daily` mode。

GitHub Actions 使用 UTC cron，因此文件中的時間以 workflow 設定為準。

## 執行內容

`intraday` mode：

- `/health`
- `/ready`
- `/api/etf/00631l/intraday-nav`
- `/api/etf/00631l/operations/status`
- `/api/etf/00631l/analysis/summary`

`daily` mode：

- `/health`
- `/ready`
- `/api/etf/00631l/holdings`
- `POST /api/etf/00631l/history/update`
- `/api/etf/00631l/history/status`
- `/api/etf/00631l/history/performance`

`all` mode 會執行以上全部。

## Price history 分段更新

`POST /api/etf/00631l/history/update` 由 remote maintenance script 分段呼叫，避免公開平台因單次全量更新太久而回 502。

- 如果 backend 尚未有完整上市日 coverage，script 會從 `2014-10-31` 起依年度分段補資料。
- 如果 backend 已有完整 coverage，script 只補最近 45 天。
- 每個分段仍使用官方 TWSE STOCK_DAY 來源。
- 分段結果會彙總成 `savedRows`、`chunkCount`、`coverageStart`、`coverageEnd`。

## 本機手動執行

Dry-run，不連線：

```cmd
scripts\00631l_remote_maintenance.cmd --dry-run
```

檢查公開 backend：

```cmd
scripts\00631l_remote_maintenance.cmd --mode all
```

只跑盤中資料檢查：

```cmd
scripts\00631l_remote_maintenance.cmd --mode intraday
```

只跑每日資料更新：

```cmd
scripts\00631l_remote_maintenance.cmd --mode daily
```

指定 backend：

```cmd
scripts\00631l_remote_maintenance.cmd --base-url https://your-backend.example.com --mode all
```

## PASS / WARN / FAIL

- `PASS`：backend 可連，主要 endpoint 正常。
- `WARN`：資料時間、交易時段、sourceStatus 或歷史資料狀態需要注意，但不一定代表故障。
- `FAIL`：backend HTTP 錯誤、endpoint 無法回應，或 readiness 回報失敗。

盤後 intraday freshness WARN 可以接受。請以資料時間與官方來源為準。

## 注意

- 遠端維護不會提供投資建議。
- 遠端維護不會執行任何交易功能。
- 若 Render free instance cold start，第一次檢查可能較慢。
- 若 public backend 沒有 persistent volume，history、report、export、backup 可能隨重啟消失。
## v4.53 multi-ETF history maintenance

Daily remote maintenance now also calls:

```text
POST /api/etf/history/update
GET /api/etf/history/status
```

This is separate from the 00631L listing-history update. It keeps the selected ETF basket history cache warm on the public backend, while v4.52 seed fallback remains available when a persistent volume is empty.

Log fields to watch:

- `readyCount`
- `rowCount`
- `coverageTierCounts`
- `validationFailureCount`
- `validationWarningCount`
- `sourceUpdatedAt`

If `readyCount` is 0 or validation failures are present, the remote maintenance script returns `WARN` with `failures=[]` unless the endpoint itself fails.

## v4.59 transient retry

Use retry flags when the public backend is deployed on a platform that can briefly return `502`, `503`, or `504` during cold starts or load transitions:

```cmd
scripts\00631l_remote_maintenance.cmd --mode daily --etf-from-catalog --etf-limit 50 --etf-offset 0 --retry-count 2 --retry-delay-seconds 3 --soft-fail
```

Retry applies to read-only `GET` checks. Update `POST` calls are not blindly repeated. If an update completes but the follow-up status check is temporarily unavailable, the script reports `WARN` with `postCheckHttpStatus` instead of hiding the successful update behind a hard failure.
