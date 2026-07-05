# v15.96 overview AI readout

This release makes the phone overview AI line read like a daily interpretation
instead of a compact debug label string.

## What changed

- The overview AI line now combines intraday data time, premium/discount state,
  daily holdings date, TX / 2330 exposure, and history row count.
- The line remains short enough for the phone first screen and keeps detailed
  analysis on the AI tab.
- The wording stays descriptive: it explains data state and price deviation, and
  continues to show that it is not investment advice.

## Guardrails

- No TX live behavior changed.
- No broker, order, or trading action feature was added.
- Mock/static/live labels remain truthful.
- A widget test now checks that the overview AI line reads as an interpretation
  with data time, premium/discount, holdings, and history context.
