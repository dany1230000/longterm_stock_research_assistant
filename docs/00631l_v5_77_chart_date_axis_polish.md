# 00631L lab v5.77 chart date axis polish

This release improves chart readability on phone screens.

## What changed

- Chart bottom-axis date ticks now use full `yyyy/MM/dd` labels instead of split `yyyy` and `MM/dd` lines.
- Existing touch details remain available: tapping a chart shows the exact date and value.
- Tests now accept repeated full-date labels because the same date may appear in both the axis tick and the range strip.

## Scope

- No data source changes.
- No TX live changes.
- No investment guidance.
