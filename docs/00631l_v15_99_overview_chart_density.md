# 00631L v15.99 Overview Chart Density

v15.99 makes the phone overview market stack shorter without hiding the chart.

## What changed

- The phone overview chart remains expanded on the first screen, but its height
  is reduced from 72px to 68px.
- The chart date axis and touch detail are allowed to sit flush together on
  phone width, removing unused vertical gap.
- The phone chart touch detail uses a lightweight date/value row instead of a
  full bordered detail card.
- Widget tests now guard the smaller market stack height and the compact
  chart-first order.

## Scope

- No data-source changes.
- No TX live integration.
- No advice wording or transaction actions.
- Desktop chart detail keeps the fuller bordered layout.
