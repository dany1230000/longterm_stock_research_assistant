# 00631L lab v9.33 chart position guard

v9.33 adds a stricter first-screen chart-position regression guard.

## What changed

- The phone-width widget test now requires the overview chart bottom to stay
  within `500px`.
- This locks in the compact quote/header work from v9.31 and v9.32.
- No user-facing UI logic changed in this version.

## Scope

This is a regression-test hardening update only. It does not change data
fetching, static exports, holdings, price calculations, or backtest behavior.
