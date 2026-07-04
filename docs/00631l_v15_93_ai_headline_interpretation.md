# 00631L v15.93 AI Headline Interpretation

## Scope

This release makes the AI tab first screen read more like a daily data
interpretation instead of a raw status list.

## Changes

- The AI headline now mentions readiness, premium/discount context, primary TX
  and TSMC exposure, and source-time caution in one sentence.
- The compact fact label HOLD was renamed to 曝險.
- The AI tab still uses rule-based analysis and still avoids investment
  instructions.
- No backend, parser, live source, holdings, history, or backtest behavior
  changed.

## Validation

- Widget coverage verifies the AI first-screen facts use the new 曝險 label.
- Full release validation remains required before tagging this release.
