# ETF 研究室 App Store 路線

本文件說明如何把目前的 `ETF 研究室 · 00631L 正二研究室` 從 PWA 推進到 Android / iOS app。現階段不包含券商登入、自動交易、推播或投資建議。

## 目前狀態

- PWA 已可公開使用。
- GitHub Pages root URL 會直接開啟 00631L 研究室。
- static public data 可提供歷史資料與回測。
- live intraday NAV 與最新 official holdings 需要 public backend。
- repo 目前尚未加入 Android / iOS 原生 scaffold。

## 上架前必備

### 共通

- app name：`ETF 研究室`
- 第一個研究室：`00631L 正二研究室`
- app icon 與啟動畫面
- privacy policy URL
- support URL
- store screenshots
- no investment-advice wording review
- public backend URL
- backend persistent data volume
- crash-free smoke test
- release checklist pass

### Android

- 建立 Flutter Android scaffold。
- 設定 package id。
- 設定 app label 與 icon。
- 建立 release signing key。
- 設定 Play Console app 資料。
- 產生 AAB release build。
- 測試 PWA 同等功能：overview、history/backtest、position、AI、settings。

### iOS

- 需要 macOS 與 Xcode。
- 需要 Apple Developer account。
- 建立 bundle id。
- 設定 signing / provisioning。
- 準備 App Store Connect app record。
- 產生 archive 並送 TestFlight。
- 測試 network permission、PWA 同等功能與 iOS 字級。

## Backend 需求

Android / iOS app 仍只是 Flutter frontend shell。live data 仍需要 public backend：

- `/health`
- `/ready`
- `/api/etf/00631l/operations/status`
- `/api/etf/00631l/intraday-nav`
- `/api/etf/00631l/holdings`
- `/api/etf/00631l/history/status`
- `/api/etf/00631l/analysis/summary`

正式上架前請確認：

- backend URL 使用 HTTPS。
- CORS 允許正式 frontend origin。
- data dir 掛載 persistent volume。
- `.env` 沒有 commit。
- Render / VPS / Docker 的 uptime 與 restart 行為可接受。

## 建議路線

1. 先維持 PWA 作為公開版本。
2. 完成 Android scaffold 與 release build。
3. 補齊 privacy policy、support page 與 screenshots。
4. 以 Android internal testing 驗證手機流程。
5. 再處理 iOS，因為 iOS 需要 macOS、Xcode 與 Apple Developer。

## 本版不做

- 不接 TX live。
- 不擴大到所有正二。
- 不做券商登入。
- 不做自動交易。
- 不提供投資建議。
