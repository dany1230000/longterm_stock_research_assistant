# 00631L lab v6.72 settings data-mode caption

v6.72 keeps the settings first screen focused on what the user can do, while
still preserving backend diagnostics below the fold.

## What changed

- The settings data-mode card now uses a first-screen caption that explains
  static data remains available when the backend is unavailable or reports an
  error.
- Detailed backend status remains in advanced diagnostics.
- Widget coverage verifies backend errors are not shown as the first-screen
  data-mode caption.

## Scope

This is presentation-only. It does not change:

- backend status calculation,
- source-status labels,
- static/live fallback order,
- historical data or backtest data,
- position storage,
- AI analysis output.
