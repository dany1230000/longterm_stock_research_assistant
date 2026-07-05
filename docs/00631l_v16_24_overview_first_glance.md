# 00631L v16.24 Overview First Glance

This release reduces the phone overview first screen so the page reads more like
a compact market app.

## Scope

- The overview still leads with quote, premium/discount status, and the one-year
  chart.
- The former mobile AI plus holdings mini block is replaced by a thin
  first-glance strip.
- The first-glance strip shows `AI`, `TX`, `2330`, and `CASH` values together.
- Full holdings details and full AI interpretation remain available lower on the
  page and in their dedicated tabs.

## What Did Not Change

- No data source changed.
- No TX live integration was added.
- No investment recommendation text was added.
- Static public and live proxy mode labels remain truthful.

## Validation

Targeted tests:

```powershell
flutter test test\etf_00631l_widget_test.dart --plain-name "overview phone first screen keeps market order"
flutter test test\etf_00631l_widget_test.dart --plain-name "overview first glance uses compact status chips"
```
