# 00631L lab v9.23 position source chips

Date: 2026-06-30

## What changed

- The position account summary now shows market source, history source, and data time as compact chips.
- The previous long source sentence was removed from the first-screen position card.
- The local-only position workflow and JSON export / clear controls are unchanged.

## Why

The position page needs to be readable on a phone. Source provenance still matters, but it should not take over the first screen.

## Verification

- Widget coverage checks `00631l-position-source-chip-strip`.
- The strip must contain market source, history source, and data time labels.
- Existing local-only position controls and forbidden wording checks remain active.
