# 00631L lab v15.23 history range control density

This release tightens the phone history/backtest range controls.

## Changes

- Compact range panels use less vertical padding.
- Phone range titles use a smaller type style than desktop.
- The history range widget test now uses a stricter height guard.

## Validation

- The focused phone history/backtest layout test checks the range control
  height directly.
- No historical data, backtest calculation, repository, parser, or backend
  behavior changed.
