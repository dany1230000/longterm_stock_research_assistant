# 00631L v15.73 position empty-card density

This release tightens the phone position input card when no local position has
been saved yet.

## Changed

- Reduced compact empty-position card padding.
- Reduced gaps between the card title, helper line, input row, and save action.
- Added a widget height guard for the compact empty-position input card.

## Design intent

The position page should open like an account input screen: shares and average
cost are the primary controls, while export and clear tools stay hidden until a
local position exists.

## Verification

- `flutter test test\etf_00631l_widget_test.dart --name "empty position starts with input card on phone width|position phone values keep summary first without duplicate grid|position section saves local-only data controls"`
- `scripts\00631l_mobile_layout_check.cmd`
