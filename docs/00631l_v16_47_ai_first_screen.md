# 00631L lab v16.47 AI first screen

This release tightens the phone AI tab first screen.

## Changes

- The AI tab now leads with the daily interpretation headline, the main program
  action, and a compact daily readout.
- Source/readiness metadata remains visible, but it no longer appears before the
  interpretation on compact phone layouts.
- The three first-screen facts now render as a thin single-row readout on phone
  width instead of taller mini cards.

## Scope

- No data-source, holdings, intraday NAV, history, backtest, or position
  calculation changes.
- AI remains rule-based and descriptive.
- The screen continues to state that the output is not investment guidance.

## Validation

- Widget coverage checks that compact AI metadata appears after the daily
  decision readout and that the fact row stays thin on phone width.
