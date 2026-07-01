# 00631L lab v9.87 AI action density

## Goal

Make the AI page first screen feel more like a daily app briefing by showing the
primary program action before technical detail panels.

## Changes

- Moved the `程式操作` block above the AI detail expansion panel.
- Kept the daily conclusion and source disclaimer visible on the first screen.
- Changed the daily AI decision tiles to two columns on normal phone widths.
- Kept longer source, matrix, and data-integrity details behind expansion.

## Validation

- Widget tests verify the primary program action appears before AI details.
- Existing tests still cover the AI detail expansion, fact row, rule-based
  source, and no-trading-action wording scan.
