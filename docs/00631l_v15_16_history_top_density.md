# 00631L lab v15.16 history top density

This release tightens the phone history/backtest first screen.

## Changes

- The compact history top strip now shows only date, close, and row count in
  the first metric row.
- Source status stays visible in the right-side badge.
- Lower-frequency source and adjustment details remain available in the
  history quality section instead of taking first-screen space.

## Validation

- Widget coverage verifies the phone top strip stays short and no longer uses a
  combined date / price metric.
- No data source, parser, backtest, or position behavior changed.
