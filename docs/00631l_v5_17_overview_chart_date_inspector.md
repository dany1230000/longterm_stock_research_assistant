# 00631L Lab v5.17 Overview Chart Date Inspector

## Scope

v5.17 improves the mobile home chart. The overview chart still defaults to a
recent one-year window, but it now includes a compact date inspector below the
chart.

## What Changed

- The overview sparkline keeps clear bottom date labels.
- The chart now tracks the selected point from touch interactions.
- The default detail shows the latest visible date and value.
- Touching or dragging the chart updates the detail row with the selected date.
- The chart maps rendered spots to their exact source history rows, so skipped
  invalid values do not shift the tooltip date.

## User Impact

Users can read the latest date/value at a glance and inspect a specific chart
point on mobile. This is a data display improvement only; it does not add any
investment guidance.

## Validation

- `flutter analyze`
- `flutter test`
- `flutter build web`
- `py -m unittest discover -s backend\tests`
- `scripts\00631l_release_check.cmd`
- `git diff --check`
