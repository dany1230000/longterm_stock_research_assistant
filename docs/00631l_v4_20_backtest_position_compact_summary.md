# 00631L v4.20 backtest and position compact summary

Date: 2026-06-21

## Scope

This release makes the backtest and local position pages easier to scan on mobile.

## Changes

- Backtest now shows a compact status row for date range, strategy, sample count, and cost parameter.
- Position tracking now shows a compact status row for local-only storage, no login, no upload, source status, and market price.
- Widget tests cover the new compact status rows.

## Notes

Backtest results describe historical data only. Position tracking remains local-only in the browser and does not send personal position data to an external service.
