# 00631L v15.67 settings preference density

This release tightens the phone settings first screen.

## Changed

- Increased the compact settings preference card aspect ratio.
- Reduced compact preference card padding.
- Reduced compact preference icon size and vertical gap.
- Tightened the widget guard for the settings preference grid height.

## Design intent

The settings tab should read like account and app preferences first. Technical
diagnostics remain available under existing advanced panels, but they should not
dominate the phone first screen.

## Verification

- `flutter test test\etf_00631l_widget_test.dart --name "settings first screen keeps technical diagnostics advanced"`
- `scripts\00631l_mobile_layout_check.cmd`
