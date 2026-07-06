# 00631L v16.60 Mobile Design Contract

This release freezes the current mobile information architecture before the
next design pass.

## Rules

- The public app opens directly into the ETF research room.
- The bottom navigation is the only primary navigation on phone width.
- The bottom navigation keeps five entries: overview, history/backtest,
  position, AI, and account/settings.
- The old bottom ETF tab stays removed. ETF selection lives in the top-left
  symbol/search control.
- Overview is the only page with a quote-style hero.
- History/backtest, position, AI, and account/settings start with their own
  purpose-specific content.
- Technical diagnostics stay behind settings or expansion panels.
- User-visible analysis remains non-advisory and describes data state only.

## Validation

- Widget tests guard the bottom navigation labels and compact first screens.
- Release validation now uses a non-interactive public-page smoke check for the
  public console step, so it does not need to open a visible browser window.
