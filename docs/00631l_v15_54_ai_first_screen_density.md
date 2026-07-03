# 00631L v15.54 AI first screen density

This release tightens the phone AI analysis first screen.

## Changed

- The compact AI insight now reads like a short market status line:
  TX weight, 2330 weight, premium/discount status, and history row count.
- Long premium/discount explanation stays available in the expanded detail
  panel instead of filling the phone first screen.
- Widget coverage checks the compact AI insight height on phone width.

## Design intent

The AI tab should open with the current day's conclusion and one clear program
action. Detailed source explanations remain available, but they should not make
the first screen feel like a report dump.

## Verification

- `flutter test test\etf_00631l_widget_test.dart --name "AI phone first screen keeps long details collapsed"`
- `flutter test test\etf_00631l_widget_test.dart --name "AI and settings sections render clean status wording"`
- Full release validation remains required before tagging.
