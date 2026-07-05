# 00631L v16.27 AI Insight Readability

This release improves the phone AI page first screen.

## What Changed

- The compact "today insight" line can now use two lines on phones.
- The AI page still keeps detailed status and source checks behind the advanced
  detail panel.
- The first screen remains focused on daily interpretation, data timing,
  premium/discount context, and program actions.

## Guardrails

- The analysis source remains rule-based.
- No external LLM key or account is required.
- The wording remains data-state oriented and non-advisory.

## Validation

- Widget coverage asserts the compact AI insight text is present.
- Widget coverage keeps the phone insight card under 72 px.
