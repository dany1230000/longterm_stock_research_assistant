# 00631L v16.28 Overview Chart Density

This release tightens the phone overview first screen.

## What Changed

- The overview chart remains visible by default.
- The compact phone chart height is reduced from 64 px to 56 px.
- Empty chart space is reduced from 50 px to 44 px.
- The first-screen density guard now keeps the market stack at or below 366 px.

## Guardrails

- The chart is not folded or hidden.
- Touch detail, date labels, and one-year context remain visible.
- No data source or calculation behavior changed.

## Validation

- Widget coverage verifies the overview order: quote, chart, dates, touch
  detail, compact daily summary, bottom navigation.
- Widget coverage verifies the compact chart height stays at or below 56 px.
