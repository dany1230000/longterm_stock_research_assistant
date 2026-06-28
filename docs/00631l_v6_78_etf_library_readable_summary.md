# 00631L lab v6.78 ETF library readable summary

v6.78 makes the ETF data-library status easier to read in the app.

## What changed

- The settings ETF data-library panel now shows a readable summary before the
  detailed metrics.
- The summary shows how many ETF histories are usable, how many are not yet
  usable, and whether the remaining gaps are classified.
- Classified reasons are grouped as official empty data, source error, and
  unclassified.

## Why

The backend and public static checks already had correct gap metadata, but the
app still exposed too much raw maintenance detail. The new summary keeps the
same data truth while making the first reading clearer.

## Scope

This is a UI/readability change only. It does not infer missing histories, does
not change ETF eligibility for history/backtest/comparison, and does not alter
official source parsing.
