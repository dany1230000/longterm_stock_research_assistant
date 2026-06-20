# 00631L v4.16 home chart and product goal summary

Date: 2026-06-20

## Scope

This release starts the next product-planning track and improves the homepage chart readability.

## Changes

- Added a product goal plan at `docs/00631l_product_goal_plan.md`.
- Added repo-level working plan files: `task_plan.md`, `findings.md`, and `progress.md`.
- Changed the overview price chart from a short 60-row window to an approximately one-year window.
- Added bottom date labels to the overview price chart.
- Enabled chart touch tooltips so a selected point shows date and price.
- Updated widget tests to expect the new homepage chart label.

## Product Direction

The app direction is `ETF 研究室`, with 00631L as the first complete research room. The next work should prioritize data correctness, first-screen clarity, ETF selection, user-selected comparison, backtest usability, local position tracking, and rule-based daily data interpretation.

## Boundaries

This release does not add broker integration, notifications, automatic order flows, or unsupported data claims. Static history, live proxy data, cached data, stale data, and fallback data remain separate status concepts.
