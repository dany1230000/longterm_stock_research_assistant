# 00631L lab v3.3 live-public ready summary

完成日期：2026-06-11

## 完成範圍

v3.3 把 standalone PWA 往公開 live backend 部署推進。GitHub Pages static mode 保留，public backend 可部署後，frontend 可優先使用 live proxy，失敗時保留 static history fallback。

## 新增能力

- `/ready` backend readiness endpoint。
- production `.env.example` 欄位整理。
- backend Dockerfile 使用 `/data/00631l` persistent data root。
- Docker Compose production 範本。
- Caddy / nginx reverse proxy 範本。
- Render blueprint 範本。
- production backend config check。
- Docker build/run readiness smoke check。
- frontend live proxy to static-public fallback。
- UI 顯示 frontend mode、backend API URL、API check time、static rows 與 generated time。

## Backend readiness

`GET /ready` 會回傳：

- `overallStatus`: PASS / WARN / FAIL
- public API URL
- allowed origins
- data dir
- persistence mode
- data dir writable check
- live source connectivity check
- warnings / failures

local 或尚未設定 public backend URL 時可以是 WARN。data dir 不可寫或 URL 格式錯誤才是 FAIL。

## Public frontend mode

Production frontend build:

```cmd
set PUBLIC_BACKEND_URL=https://your-backend.example.com
scripts\00631l_build_web_public.cmd
```

此 build 會啟用：

- `USE_00631L_LIVE_PROXY=true`
- `00631L_PROXY_BASE_URL=https://your-backend.example.com`
- `USE_00631L_STATIC_DATA=true`
- `00631L_STATIC_DATA_BASE_URL=00631l-static-data`

優先順序：

1. `live_proxy`
2. `static_public`
3. `mock_default`

## Persistent data

Public backend 需掛載 persistent volume：

```text
/data/00631l
```

保存項目：

- holdings history
- intraday NAV history
- price history
- daily cycle status
- integrity status
- reports
- exports
- backups

這些資料不可 commit 到 repo。

## Static fallback

GitHub Pages static mode 仍可使用：

```cmd
scripts\00631l_export_static_data.cmd --update
scripts\00631l_build_pages_static.cmd
```

Static mode 可看歷史與回測。live intraday NAV 和 official holdings daily collection 仍需要 backend。

## 尚未實際部署

本 repo 不包含 cloud token、DNS 權限、server SSH 或部署平台帳號。本版完成 deploy-ready；真正公開 backend 還需要使用者提供：

- server / cloud platform
- public backend URL
- DNS 或平台 URL
- persistent volume
- 平台 env 設定

## 範圍限制

仍不接 TX live、不擴大到所有正二、不做通知、不做自動交易、不提供投資建議。
