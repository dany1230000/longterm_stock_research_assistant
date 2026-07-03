# 00631L v15.68 position account strip

This release tightens the phone position page when a local position is entered.

## Changed

- Reduced compact padding in the position account strip.
- Reduced the compact gap before the account metric row.
- Tightened the phone account strip height guard from 104px to 100px.

## Design intent

The position page should read like an account snapshot first: market value,
unrealized result, cost, and allocation stay above edit and tool controls.
Export and clear actions remain available under the existing tools panel.

## Verification

- `flutter test test\etf_00631l_widget_test.dart --name "position phone values keep summary first without duplicate grid"`
- `scripts\00631l_mobile_layout_check.cmd`
