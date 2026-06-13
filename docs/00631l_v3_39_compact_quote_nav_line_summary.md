# 00631L lab v3.39 compact quote NAV line summary

Completed: 2026-06-13

## Scope

v3.39 reduces the mobile quote header height.

## Changes

- Replaces separate NAV chips with one compact quote metadata line.
- Keeps market price, premium/discount state, estimated NAV, previous NAV, and
  data time visible on the overview.
- Removes decorative quote fact chip widgets that were not needed for the first
  screen.

## Notes

The change is visual only. It does not change data sources, live backend
behavior, or historical calculations.
