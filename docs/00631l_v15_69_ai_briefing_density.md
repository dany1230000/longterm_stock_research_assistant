# 00631L v15.69 AI briefing density

This release tightens the phone AI analysis first screen.

## Changed

- Reduced compact AI briefing hero padding.
- Reduced compact headline panel padding and vertical gaps.
- Reduced compact fact pill and primary action padding.
- Reduced compact insight line padding.
- Tightened widget guards for AI hero, fact row, and compact insight height.

## Design intent

The AI page should open as a short daily readout: source, data status, main
program action, and one compact interpretation line. Full analysis remains in
the existing detail expansion.

## Verification

- `flutter test test\etf_00631l_widget_test.dart --name "AI phone first screen keeps long details collapsed"`
- `scripts\00631l_mobile_layout_check.cmd`
