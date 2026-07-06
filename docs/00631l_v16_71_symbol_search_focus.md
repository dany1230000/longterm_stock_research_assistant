# 00631L v16.71 Symbol Search Focus

This release makes the top-left symbol search feel more like an app search entry.

## Changes

- The symbol search sheet now owns a `FocusNode`.
- The search field requests focus after the sheet opens, so phone users can type immediately.
- Widget coverage verifies that the search field is focused after tapping the top-left symbol pill.
- No search ranking, ETF data, price history, or comparison behavior changed.

## Validation

- The compact phone symbol search test now checks immediate input readiness.
- Release check and forbidden wording scan remain required before tagging.
