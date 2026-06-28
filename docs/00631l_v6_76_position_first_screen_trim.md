# 00631L lab v6.76 position first-screen trim

v6.76 makes the position page shorter and more direct on phone screens.

## What changed

- The redundant local-position page title card is hidden on the position tab.
- The page now starts with the account summary, local actions, and input card.
- Save, JSON export, clear, and local-only behavior are unchanged.

## Why

The position tab already has a dedicated account summary and local-only labels.
The extra page title repeated that context and pushed the input fields farther
down the phone screen.

## Scope

This is a presentation-only change. It does not change:

- position calculations,
- browser local storage,
- JSON export,
- selected ETF switching,
- market-price fallback behavior.
