# 00631L v16.37 overview date axis

This release improves the phone overview chart date axis.

## What changed

- Phone width now renders chart axis dates as `yy/MM/dd`.
- Wider layouts keep the full `yyyy/MM/dd` date format.
- The chart touch detail still shows the full date and value.

## Why

The overview chart should stay visible and readable on a phone. Shorter date
labels let the three axis cells show larger text without overlapping or looking
like a debug readout.
