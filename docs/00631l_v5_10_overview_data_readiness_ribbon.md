# 00631L v5.10 Overview Data Readiness Ribbon

Release tag: `00631l-lab-v5.10-overview-data-readiness-ribbon`

## Scope

v5.10 makes data readiness more visible on the overview page without adding
new data sources or changing calculations.

## Changes

- The overview `資料正確性` ribbon now includes:
  - selected ETF code
  - price field
  - split-adjustment status
  - loaded row count
  - coverage type
  - ETF history readiness count versus catalog count
- This keeps data completeness visible near the quote and chart instead of
  hiding it only under settings.

## Data Behavior

- No parser behavior changed.
- No split-adjustment logic changed.
- No TX live behavior changed.
- Multi-ETF history readiness still reflects imported/cache data only.

## Validation

- Widget coverage verifies the new `覆蓋型態` and `ETF歷史` labels.
- Backend health metadata is updated to v5.10.
- Release check requires this summary file.
