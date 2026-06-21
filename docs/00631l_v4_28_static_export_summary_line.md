# 00631L v4.28 static export summary line

v4.28 makes the static-public data command easier to read in scheduler,
GitHub Actions, and local maintenance logs.

## Changes

- Added a shared `build_static_export_summary_line()` helper for static export CLI output.
- `scripts\00631l_export_static_data.cmd --status-only` now prints ETF price-history readiness in its final `[summary]` line.
- The summary includes 00631L row count, coverage range, ETF history ready count, ETF history row count, and coverage tier counts.
- If older static data does not contain tier counts, the summary prints `tiers=not_available` instead of inferring zeros.
- Full JSON output remains available above the compact summary for debugging.

Example compact line:

```text
[summary] overallStatus=PASS rows=2827 coverage=2014-10-31..2026-06-11 etfReady=228 etfRows=55000 tiers=long_term:8,recent:220,unavailable:0,error:0
```

## Scope

- No data source behavior changed.
- No generated static data is committed.
- This is a maintenance/log readability improvement only.
