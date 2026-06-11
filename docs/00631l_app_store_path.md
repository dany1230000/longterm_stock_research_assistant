# 00631L future App Store path

## v3.3 note

目前建議順序仍是：

1. 先用 GitHub Pages static PWA。
2. 再部署 public FastAPI backend。
3. 等 public backend 穩定後，再評估 Android / iOS app shell。

Android / iOS app 只會是 Flutter frontend shell。live data 仍需要 public backend：

- `/health`
- `/ready`
- `/api/etf/00631l/operations/status`
- `/api/etf/00631l/intraday-nav`
- `/api/etf/00631l/holdings`

上架前仍需另外準備：

- app icon
- app name
- privacy policy
- network permission
- Android signing
- iOS signing and provisioning
- developer account
- backend uptime
- public backend URL
- 清楚標示非投資建議

本 repo 不包含 store credential、cloud token、DNS 權限或上架流程自動化。

現階段建議先使用 PWA。未來若要做 Android / iOS app，可以把 Flutter 專案包成 mobile app，但 live data 仍需要公開 backend。

## 核心觀念

- Android / iOS app 主要是 frontend shell。
- official holdings、intraday NAV、history、report、export、backup 狀態仍由 backend 提供。
- backend 需要公開 URL、CORS 設定、persistent data volume 與 uptime。

## 需要另外準備

- app icon
- app name
- privacy policy
- network permission
- store developer account
- Android release signing
- iOS signing and provisioning
- backend uptime monitoring
- public backend URL for production builds

## 不包含的範圍

- 不接 TX live。
- 不擴大到所有正二。
- 不做投資建議。
- 不做通知。
- 不做自動交易。

## 建議順序

1. 先完成 public backend。
2. 部署 Flutter Web / PWA。
3. 觀察手機日常使用是否穩定。
4. 再評估 Android / iOS app packaging。
