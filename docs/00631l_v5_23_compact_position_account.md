# 00631L Lab v5.23 Compact Position Account

## Completed Scope

- The position page keeps the account-style local summary at the top.
- Detailed market value, cost, unrealized PnL, and allocation estimates now live
  in an expandable estimate detail block.
- The input card keeps the core controls visible: shares, average cost, optional
  assets, optional fees, note, local save, JSON export, and local clear.
- Local-only wording remains visible and clear.

## Data Behavior

- Position data remains browser-local.
- No login is required.
- No position data is sent to the backend.
- The estimate uses the currently available selected ETF market/close value and
  its data time.

## Boundaries

- This page is an account-state view, not an action workflow.
- The release does not add broker integration, automated actions, or investment
  guidance.
