# 00631L v9.94 AI first screen readability

## Scope

This release tightens the AI page first screen for the mobile PWA.

## Changes

- Replaces the long first-screen AI stack with a compact headline panel.
- Keeps the first screen focused on:
  - today's conclusion
  - official holdings date
  - intraday NAV time
  - historical row count
  - the primary program action
- Moves detailed conclusion cards, decision tiles, readouts, and fact rows into
  the `AI 資料細節` expansion.
- Keeps the AI source as rule-based and keeps the disclaimer visible.

## Product Rule

The AI page describes data status, data time, historical coverage, and program
actions only. It remains non-advisory and does not describe future outcomes.

## Validation

- Widget tests guard that the first screen shows the compact headline and that
  detailed AI panels stay inside the expansion.
- The forbidden wording scan remains part of release validation.
