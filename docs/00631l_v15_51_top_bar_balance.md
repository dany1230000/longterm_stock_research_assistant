# 00631L v15.51 top bar balance

This release adjusts the phone app header proportions.

## Changed

- Increased the top bar height slightly so `ETF 研究室` reads as the app title.
- Enlarged the left-top symbol button so it behaves like the primary ETF search and switch entry.
- Added a stable widget key for the top title so layout tests can protect the header.
- Kept the bottom navigation unchanged: overview, history, position, AI, and settings.

## Design intent

The top bar should explain where the user is and make symbol switching obvious without adding another navigation row.

## Verification

- `flutter test test\etf_00631l_widget_test.dart --name "00631L lab renders stock-app style quote header"`
- `flutter test test\etf_00631l_widget_test.dart --name "00631L lab remains readable on phone width"`
- Full release validation remains required before tagging.
