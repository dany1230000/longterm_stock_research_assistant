# 00631L v16.46 Settings Status Labels

v16.46 makes the account/settings and maintenance panels read more like a
product screen.

## Changed

- Settings status pills now use product labels for backend, holdings, intraday,
  price history, backtest, position, and daily cycle states.
- Raw status strings remain in models and parsers; only the UI presentation
  changed.

## Scope

This is a UI wording change. It does not change backend status endpoints,
official data parsing, static history, live NAV, backtest calculations, or
position storage.
