# 00631L v15.71 bottom navigation guard

This release tightens and guards the phone bottom navigation.

## Changed

- Reduced the bottom navigation fixed height from 60px to 56px.
- Reduced icon container size and vertical spacing.
- Added stable label keys for each bottom navigation item.
- Tightened widget guards so the bottom navigation remains the five core app
  sections and does not reintroduce an ETF switch tab.

## Design intent

ETF switching belongs in the left-top symbol search button. The bottom
navigation should stay focused on the main app sections: overview,
history/backtest, position, AI, and settings.

## Verification

- `flutter test test\etf_00631l_widget_test.dart --name "00631L lab renders stock-app style quote header|00631L lab remains readable on phone width|phone tabs open distinct first-screen content"`
- `scripts\00631l_mobile_layout_check.cmd`
