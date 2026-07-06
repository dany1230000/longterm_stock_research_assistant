# 00631L v16.78 AI compact program label

This release keeps the AI tab focused on data interpretation and app-side
checks.

## Changes

- The compact phone AI decision rail uses `程式` instead of a generic action
  label.
- The compact primary action row uses the same `程式` label so the first screen
  reads as a program check, not an investment action.

## Scope

- No external LLM integration.
- No new data source.
- No investment guidance.
- Full AI details still remain in the expandable section.

## Validation

- Widget tests check the compact AI first screen labels.
- The forbidden wording scan remains part of release validation.
