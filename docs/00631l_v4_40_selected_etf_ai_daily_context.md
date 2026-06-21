# ETF research room v4.40 selected ETF AI daily context

v4.40 makes the selected ETF AI page describe the latest loaded daily data.

## What Changed

- When the top-left selector switches to another ETF, the AI page now shows latest trading date, latest close, daily change, drawdown, row count, source status, and coverage.
- The rule-based summary adds a daily-data sentence before longer coverage and performance context.
- Widget coverage verifies the selected ETF AI page is no longer a generic description.

## Why

The AI page should explain the data currently on screen. For non-00631L ETFs, the app must avoid implying that 00631L holdings or live intraday NAV applies to the selected symbol.

## Scope

- Rule-based UI summary only.
- No external LLM key, no new data source, no TX live change, and no investment guidance.
