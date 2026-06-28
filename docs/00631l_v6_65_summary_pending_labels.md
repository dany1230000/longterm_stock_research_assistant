# 00631L lab v6.65 summary pending labels

v6.65 localizes background-pending labels in the overview summary row.

## What changed

- DAY pending state uses `同步中`.
- LIVE pending state uses `連線中`.
- HIS pending state uses `檢查中`.
- Final source labels such as `error`, `unavailable`, and mode labels remain
  truthful.
- Widget tests cover the fast-start intraday pending state.

## Why

The mobile first screen previously mixed product UI with debug-like loading
labels such as `syncing` and `checking`. Short localized labels are easier to
scan while preserving the underlying source state.

## Scope

This is a wording-only UI change. It does not change:

- source fetch timing,
- fallback order,
- holdings parsing,
- intraday NAV parsing,
- price history,
- backtest formulas,
- position tracking,
- AI analysis.
