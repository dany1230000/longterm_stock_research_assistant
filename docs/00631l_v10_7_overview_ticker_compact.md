# 00631L lab v10.7 overview ticker compact

## Goal

Make the overview first screen feel tighter on phones without removing the
quote, premium/discount state, daily data status, or one-year chart.

## Changes

- Reduced embedded quote padding inside the overview market stack.
- Reduced daily data ticker item width.
- Reduced daily ticker separator height.
- Kept the one-year chart visible without adding another card.

## Data Rules

- No data source, parsing, or calculation logic changed.
- The daily holdings row remains an official daily snapshot, not intraday data.
- Intraday NAV still depends on live backend availability.
- Static and fallback status labels remain truthful.

## Verification

- `flutter test test\etf_00631l_widget_test.dart --plain-name "00631L lab remains readable on phone width"`
- Full release validation remains required before tagging.
