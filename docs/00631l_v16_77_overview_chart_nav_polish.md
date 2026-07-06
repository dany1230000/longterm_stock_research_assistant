# 00631L v16.77 overview chart and navigation polish

This release continues the mobile-first UI cleanup for the standalone ETF app.

## Changes

- The combined history and backtest bottom tab is labeled `歷測`, making the
  combined purpose clearer in a compact five-tab layout.
- The phone overview chart is taller, so the one-year movement reads as a
  primary panel on the home screen instead of a small decoration.
- Existing chart date labels and touch detail remain available.

## Scope

- No new data source.
- No change to backtest calculations.
- No investment guidance.

## Validation

- Widget tests cover the updated tab label and the taller overview chart.
- Full release validation still includes Flutter, backend, release check,
  smoke, forbidden wording scan, and git diff checks.
