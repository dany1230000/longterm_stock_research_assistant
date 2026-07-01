# 00631L lab v9.59 - mobile design hierarchy

## Goal

This release tightens the mobile-first information hierarchy of the ETF
research room. The focus is layout, scan speed, and page-specific structure,
not new data sources or trading features.

## Changes

- Restores a compact `今日摘要` strip on the overview first screen.
- Keeps the overview chart visible while adding a concise official exposure
  block below it on phone width.
- Moves history start/end date controls above the chart, so users do not need
  to open an advanced panel before adjusting the range.
- Keeps technical source details inside advanced sections.
- Keeps the bottom navigation as the only main navigation.

## Scope

- No new live TX source.
- No trading instruction wording.
- No parser or backend behavior change.
- Static public and live proxy modes keep their existing labels.
