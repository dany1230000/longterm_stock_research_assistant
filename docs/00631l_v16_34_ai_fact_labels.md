# 00631L v16.34 AI fact labels

This release makes the AI first-screen fact row read more like the rest of the
mobile app.

## What changed

- `DAY` is now shown as `日`.
- `LIVE` is now shown as `盤`.
- `曝險` stays unchanged because it is already clear.
- The detail text still explains the source: official daily holdings and
  intraday NAV.

## Why

The AI page should explain the current data in user-facing language. Technical
short labels are still useful internally, but the phone first screen should not
look like a debug panel.

This is only wording and layout polish. It does not change data source priority,
history calculations, intraday NAV, holdings parsing, backtest behavior, or
position tracking.
