# 00631L v14.0 overview chart density

## Goal

Keep the home chart visible while making the first screen feel more like a
compact market app quote board.

## Changes

- The overview market stack uses slightly tighter padding and vertical gaps on
  phones.
- The one-year sparkline remains expanded, but its compact height is reduced.
- The compact chart axis labels use `起 / 中 / 迄`; the touch detail still shows
  the full selected date and value.

## Validation

- Updated phone-width overview tests to enforce the smaller chart height.
- Added checks that the compact date labels remain visible on the chart axis.
