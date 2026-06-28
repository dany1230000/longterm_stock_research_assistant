# 00631L v6.43 overview summary grid fit

v6.43 fixes the phone-width overview summary row.

## What changed

- The overview `DAY / LIVE / HIS` summary now uses a fixed three-column grid.
- `LIVE` shows the latest intraday time instead of a full date-time string.
- `HIS` shows row count and coverage years instead of a long coverage range.
- The summary keeps the frontend mode badge in the header.

## Why

The public mobile view showed the third `HIS` chip partially off screen. The
summary is now designed to fit a 390px phone width without horizontal scrolling.

## Data rules

- `DAY` remains the official daily holdings snapshot date.
- `LIVE` remains intraday NAV status from the configured live backend when available.
- `HIS` remains static/public historical price data coverage.
- Static history is not presented as live intraday data.
