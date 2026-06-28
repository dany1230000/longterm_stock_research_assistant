# 00631L lab v6.96 intraday previous-day label

v6.96 fixes the first-screen intraday time label before market open.

## What changed

- `IntradayMarketSession` now detects a pre-open screen that is still showing a
  previous trading day's TWSE intraday NAV data.
- The quote card can show `前一交易日` instead of implying the same data is
  today's pre-open state.
- Weekend closed-market labeling remains unchanged.

## Why

On the public PWA, a Monday pre-open check can still use Friday 13:31 TWSE NAV
data. Showing that as a generic pre-open state makes the homepage harder to
read. The user should see that the value is the previous trading day's last
available intraday NAV snapshot.

## Scope

- No source endpoint changes.
- No static history row changes.
- No TX live changes.
- No investment guidance.
