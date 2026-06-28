# 00631L lab v6.79 settings compact summary

v6.79 shortens the account/settings first screen.

## What changed

- The old settings overview grid was replaced with a compact summary card.
- The card keeps the important account state, selected ETF, data mode, release
  version, and daily status in short badges.
- Detailed backend, persistence, report, export, backup, and ETF library
  diagnostics remain available below the first screen.

## Why

The settings page should feel like an app account page first. Detailed
maintenance diagnostics are still useful, but they should not consume the
entire first mobile screen.

## Scope

This is a layout/readability change only. It does not change data collection,
ETF history eligibility, live backend behavior, or local-only position storage.
