# 00631L lab v3.26 user-facing status labels summary

Completed date: 2026-06-13

## Scope

v3.26 makes the top app chrome and overview first screen read less like debug output.

## Changes

- First-screen frontend mode labels now use short user-facing text such as `公開靜態`, `Live 後端`, and `Mock 預設`.
- Quote-board NAV status uses short labels such as `官方`, `快取`, `過期`, `錯誤`, and `暫無`.
- The overview metrics now use `筆` and `盤中資料暫無` instead of `rows` and `live unavailable`.
- Technical source contracts and raw state labels remain available in deeper data-source and settings diagnostics.

## Boundaries

- No parser, live data source, history, backtest, position, or AI logic changed.
- TX live remains intentionally not connected.
- This remains a 00631L-only app and the wording remains non-advisory.
