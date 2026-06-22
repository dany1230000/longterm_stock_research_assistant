# ETF research room v4.45 selected quote source label

Date: 2026-06-22

## Scope

v4.45 makes the selected ETF quote source label more accurate.

## Changes

- The overview quote header now distinguishes live 00631L intraday quote, TWSE catalog quote, and historical close fallback.
- If a selected ETF has no catalog market price and the app uses local price history instead, the caption shows `市價 · 歷史收盤`.
- If catalog market price is available, the caption remains `市價 · catalog`.
- The change is label and source interpretation only. It does not change price-history data, official holdings, backtest calculations, TX data, or local position storage.

## Verification

- Widget coverage checks the catalog quote path for 0050.
- Widget coverage checks a catalog-without-quote fixture and verifies the historical-close fallback label.
- Existing no-advice wording checks still run through release check.
