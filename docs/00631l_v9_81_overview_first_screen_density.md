# 00631L lab v9.81 overview first screen density

## Goal

Make the overview first screen easier to scan on mobile without hiding the main
chart.

## Changes

- Shortened the daily status label from `官方內容物` to `內容物`.
- Reduced spacing in the overview daily status strip.
- Tightened widget tests so the summary strip stays compact and the chart stays
  visible earlier in the first screen.

## Validation

- Widget tests enforce compact first-screen height.
- Existing chart, holdings digest, static data, and live fallback behavior remain
  unchanged.
