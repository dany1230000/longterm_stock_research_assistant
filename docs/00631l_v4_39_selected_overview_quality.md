# ETF research room v4.39 selected overview quality

v4.39 makes the overview data-quality card follow the ETF chosen from the top-left selector.

## What Changed

- The overview page now shows the current selected ETF code inside the data-quality card.
- Data-quality labels use user-facing wording for coverage and data source instead of compact debug-style labels.
- Switching from 00631L to another ETF keeps the selected ETF coverage, row count, source status, and price field visible before entering history/backtest.

## Why

Users need to confirm which ETF data is being inspected, especially after searching and switching symbols. The overview should not look like it is still showing 00631L metadata when another ETF is selected.

## Scope

- UI wording and widget coverage only.
- Does not change data import, split-adjustment calculations, TX live, or investment guidance.
