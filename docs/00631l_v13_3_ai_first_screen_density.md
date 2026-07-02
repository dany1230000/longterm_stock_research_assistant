# 00631L v13.3 AI first-screen density

## Goal

Make the AI page feel more like a daily briefing on phones. The first screen
should answer what matters now, then keep deeper diagnostics in the expandable
detail area.

## Changes

- Phone width now hides the first-screen AI bullet list and long conclusion
  card.
- The first AI screen keeps the headline, source/readiness badges, primary
  program action, and advanced detail entry.
- The conclusion card is still available inside the AI detail expansion on
  compact width.
- Wider layouts continue to show the richer AI briefing before the detail
  expansion.

## Validation

- Added a widget test for compact phone AI layout.
- Existing AI detail and compact fact-row widget tests still cover the expanded
  diagnostics.
- No investment guidance or trading-action wording was added.
