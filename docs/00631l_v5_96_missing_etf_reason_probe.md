# 00631L lab v5.96 missing ETF reason probe

v5.96 adds a small maintenance flow for classifying remaining ETF price-history
gaps.

## What Changed

- `scripts\00631l_probe_missing_etf_reasons.cmd` probes a limited batch of
  missing ETF histories through the existing TWSE STOCK_DAY importer.
- The backend ETF price-history index now reports `attemptedCount`.
- Static export, operations status, public static-data check, and Flutter
  operations status now preserve the attempted count.
- The system page shows how many ETF gaps have real import-attempt evidence.

## How To Use

Run:

```cmd
scripts\00631l_probe_missing_etf_reasons.cmd
```

The default batch is 20 missing ETF codes. Extra arguments are passed through to
`backend\scripts\import_etf_price_history.py`, so a wider run can use:

```cmd
scripts\00631l_probe_missing_etf_reasons.cmd --limit 50
```

The command may save official rows when they are available. If a symbol returns
no rows or source errors, the attempt is stored in local backend data so the gap
reason can move away from plain `not_saved`.

## Data Boundary

Attempt evidence is local runtime state under the backend data directory. It is
not committed to git. Static public output includes only generated summaries and
should be regenerated through the normal static export / Pages workflow.

This is a data maintenance feature. It does not add ETF guidance, alerts, or
trading instructions.
