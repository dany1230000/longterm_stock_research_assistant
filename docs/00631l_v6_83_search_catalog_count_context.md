# 00631L lab v6.83 search catalog count context

v6.83 clarifies the count labels in the expanded ETF search database detail.

## What changed

- `ETF 清單` is now `目前清單`.
- `統計母數` remains the full denominator used by the data readiness summary.

## Why

The public static export can have a full data-readiness denominator that is
larger than the currently loaded or focused ETF list. The labels now make that
distinction explicit instead of presenting two similar count names.

## Validation

- Widget coverage verifies the expanded ETF search database detail panel uses
  the new count label.
