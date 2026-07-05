# 00631L v16.26 Position Input Density

This release tightens the empty-position screen on phones.

## What Changed

- The phone position page now keeps the first action focused on two inputs:
  shares and average cost.
- The repeated local-only sentence is hidden in the compact phone card.
- The save action uses a shorter phone label so the card stays below the
  fold sooner.
- The existing local-only storage behavior is unchanged.

## Guardrails

- Position data remains browser-local.
- No broker account, external account, or cloud upload is added.
- This is a layout change only. It does not change calculations or data
  sources.

## Validation

- Widget coverage asserts the compact phone card stays at or below 160 px.
- Widget coverage asserts the phone card uses the short save label and does not
  reintroduce the repeated local-only sentence.
