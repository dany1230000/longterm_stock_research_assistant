# ETF research room v4.42 position source context

v4.42 makes the position page show selected ETF and data-source context more clearly.

## What Changed

- The position input area now labels the current selected ETF explicitly.
- Quote source and historical price source are separated as行情來源 and歷史來源.
- Widget coverage verifies the position page follows the ETF selected from the top-left selector.

## Why

Position tracking is local-only and does not connect to a brokerage account. The page should clearly show which ETF is being estimated and which data sources drive quote and history context.

## Scope

- UI wording and widget coverage only.
- No login, no broker connection, no external account sync, and no investment guidance.
