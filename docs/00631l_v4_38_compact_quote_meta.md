# ETF research room v4.38 compact quote meta

v4.38 trims the first-screen quote metadata.

## What Changed

- The top quote card now keeps only the most important first-screen metadata: estimated NAV, market session/data time, and history row count.
- Less urgent fields such as previous NAV and frontend mode remain available in detail/status sections instead of occupying the first quote strip.
- A widget test now verifies that the quote metadata strip stays focused.

## Why

The first screen should be readable on a phone without forcing users to parse operational details before the main quote and chart.

## Scope

- UI layout and widget test only.
- Does not change data sources, historical calculations, TX live, or investment guidance.
