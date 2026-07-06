# 00631L lab v16.50 phone first-screen audit

This release performs a small cross-tab phone density pass.

## Changes

- Compact section gaps are aligned across overview, history/backtest, backtest,
  and AI surfaces.
- The density regression test now guards the thinner AI fact row and compact
  history date panel.
- Existing tab-specific first-screen guards remain in place for overview,
  position, AI, history/backtest, and settings.

## Scope

- No data-source, calculation, history, backtest, position storage, or AI
  provider changes.
- No new ETF scope and no additional live source integration.

## Validation

- The phone first-screen density guard now checks the history date panel and the
  AI readout against the current compact layout.
