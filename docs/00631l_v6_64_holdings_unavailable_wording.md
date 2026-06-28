# 00631L lab v6.64 holdings unavailable wording

v6.64 polishes the overview holdings-unavailable card.

## What changed

- The unavailable holdings card now says `官方內容物暫不可用`.
- Supporting text says the data source has not returned a usable snapshot and
  that zero-value holdings are hidden.
- The right-side badge shows the source status, such as `error`, instead of a
  placeholder trade date.
- Widget tests verify the new unavailable wording.

## Why

The public mobile screen previously showed technical text such as `live backend`
and `official holdings`. It also showed a placeholder date even when the
snapshot was not usable. That made the state harder to read.

## Scope

This is a UI wording change only. It does not change:

- Yuanta holdings parsing,
- source-status decisions,
- price history,
- intraday NAV,
- backtest,
- position tracking,
- AI analysis.
