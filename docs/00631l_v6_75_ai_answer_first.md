# 00631L lab v6.75 AI answer-first layout

v6.75 makes the AI page more direct on phone screens.

## What changed

- The AI tab now opens with the daily rule-based interpretation and concise
  summary bullets.
- Program actions remain visible near the top, limited to app/data maintenance
  actions.
- Source grids, generated-time metadata, matrix detail, and data-completeness
  notes are now inside an advanced detail panel.
- The existing rule-based analysis engine and data inputs are unchanged.

## Why

The previous AI tab showed a broad status grid before the written
interpretation. On a phone, that made the page feel like another status dump
instead of a daily analysis page.

## Scope

This is a presentation-only change. It does not add external LLM calls and does
not change:

- official holdings parsing,
- intraday NAV handling,
- historical calculations,
- backtest formulas,
- position tracking,
- selected ETF behavior.

All visible text remains descriptive and non-instructional.
