# 00631L future App Store path

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
