# 00631L lab v6.60 quote premium source guard

v6.60 keeps the quote-card premium/discount display tied to the correct data
source.

## What changed

- For 00631L, the quote-card premium/discount box now uses only intraday NAV
  premium/discount data.
- If intraday NAV is unavailable, the quote-card premium/discount value shows
  `unavailable`.
- Non-00631L selected ETF quote cards can still use catalog premium/discount
  data, because those cards are explicitly catalog/history context.
- The premium box has a stable widget key so source behavior is testable.

## Why

The public first screen can be in a mixed state: static history is available,
but live intraday NAV may still be unavailable. The quote-card premium/discount
value must not mix catalog/static reference values with live intraday labels.

## Scope

This is a display-source guard only. It does not change:

- TWSE intraday NAV parsing,
- Yuanta official holdings parsing,
- ETF catalog import,
- price history calculations,
- backtest formulas,
- local position tracking,
- AI summary logic.
