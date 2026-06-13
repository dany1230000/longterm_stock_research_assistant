# ETF 研究室上架計畫

目標是把目前公開 PWA 推進成可送審的 Android / iOS app。此計畫只處理產品、技術與商店準備，不包含交易、通知或投資建議。

## Product Scope

- App brand：`ETF 研究室`
- First room：`00631L 正二研究室`
- Core tabs：總覽、歷史回測、持倉、AI、設定
- Default data mode：static public + live backend fallback
- Local position data：browser/app local-only
- AI：rule-based by default

## Phase 1：Store Foundation

- PWA metadata 改為 ETF 研究室品牌。
- 保留 00631L 正二研究室為第一個完整研究室。
- 設定頁顯示上架準備狀態。
- 回測工具直接顯示於歷史回測頁。
- 補齊 App Store / Play Store 上架清單。

## Phase 2：Android Shell

- 新增 Android scaffold。
- 設定 package id、app label、icon、adaptive icon。
- 建立 release signing 文件。
- 產生 internal testing AAB。
- 驗證 public backend / static fallback / local position。

## Phase 3：Store Materials

- 建立 privacy policy。
- 建立 support page。
- 準備 screenshots。
- 撰寫 store description。
- 檢查所有使用者可見文案不包含交易指令。

## Phase 4：iOS Shell

- 在 macOS + Xcode 環境新增 iOS scaffold。
- 設定 bundle id、signing、capabilities。
- 建立 TestFlight build。
- 檢查 Safari/PWA 與 iOS app 行為差異。

## Phase 5：Release Governance

- release check 必須通過。
- backend public readiness 必須可檢查。
- data persistence 必須有明確狀態。
- static fallback 必須可用。
- 所有測試與 build 必須通過。

## External Inputs Needed Later

- Google Play Console account。
- Apple Developer account。
- Android release signing policy。
- iOS signing / provisioning。
- privacy policy public URL。
- support public URL。
- final app icon / screenshots。
