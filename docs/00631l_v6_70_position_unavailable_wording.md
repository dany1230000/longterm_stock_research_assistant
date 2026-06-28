# 00631L lab v6.70 position unavailable wording

v6.70 replaces raw English fallback text in the local position account summary.

## What changed

- The unrealized result percentage now shows a localized unavailable label when
  the percentage cannot be calculated.
- The local position account summary remains compact and phone-readable.
- Widget tests verify the localized unavailable state is rendered.

## Why

After v6.69 fixed the metric layout, the position summary still displayed raw
`unavailable` text in the phone UI. This release keeps the state readable for
daily users.

## Scope

This is wording-only. It does not change:

- local-only storage,
- position calculations,
- JSON export or clear actions,
- quote source labels,
- backtest,
- AI analysis.
