# 00631L lab v9.21 history range details

Date: 2026-06-30

## What changed

- The history/backtest date controls now expose a compact range mode plus separate start and end date labels.
- History charts now show date and value as distinct touch-detail fields, so phone users can read the selected point without relying on a long combined sentence.
- Mini chart height was adjusted so the date axis and touch detail fit on narrow screens without overflow.

## Why

The history page already defaulted to the latest one-year range and supported custom dates, but the selected range and chart point details were too easy to miss on mobile. This release makes the active range and chart detail explicit while preserving the compact layout.

## Verification

- Widget coverage checks the history page exposes range mode, start date, and end date fields.
- Widget coverage checks chart touch detail exposes separate date and value fields.
- Phone-width history range coverage still verifies the layout wraps instead of overflowing.
