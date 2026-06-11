# 00631L lab v3.12 navigation and settings summary

v3.12 simplifies the mobile app navigation after user review.

## What Changed

- Bottom navigation now has six user-facing sections:
  - 總覽
  - 內容物
  - 歷史回測
  - 持倉
  - AI 分析
  - 設定
- 歷史 and 回測 are merged because they both depend on the same historical price dataset.
- The former system status page is no longer a primary bottom-navigation page.
- 設定 now contains:
  - 帳戶與隱私
  - 資料完整度
  - 進階診斷
- 進階診斷 keeps backend, report, export, backup, and deployment checks available without making them the main user experience.

## Data Completeness

- Price history is available from static/official history data and shows row count plus coverage range.
- Holdings history is not backfilled from the past unless official history is available; it accumulates from saved daily official snapshots.
- Intraday NAV is live only when the backend can reach TWSE/Yuanta intraday sources.
- TX live quote remains not connected by design. The app only displays TX weight from official holdings snapshots.

## Boundaries

- No TX live integration was added.
- No all-leveraged-ETF expansion was added.
- No notification, broker login, automated trading, or investment guidance was added.
- Static/public data remains labeled separately from live intraday data.
