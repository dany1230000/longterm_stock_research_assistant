# 00631L lab v5.88 fast Pages static build

## Scope

v5.88 shortens the GitHub Pages publish path without changing ETF price-history
truth labels.

The Pages workflow now uses two refresh modes:

- push builds: import the core ETF list, run the missing-only ETF batch, then
  export static data
- weekday schedule or manual dispatch with `full_etf_refresh=true`: also run the
  broad all-catalog recent ETF refresh

This keeps normal app releases faster while preserving a separate full refresh
path for maintenance.

## Local command

The local Pages build script is fast by default:

```cmd
scripts\00631l_build_pages_static.cmd
```

Run the broader maintenance refresh only when needed:

```cmd
scripts\00631l_build_pages_static.cmd --full-etf-refresh
```

## Data behavior

- Static 00631L history still requires strict coverage checks before export.
- ETF histories that are not present remain visible as explicit gaps.
- The app continues to show `static_public`, `live_proxy`, or fallback status
  based on the actual source.
- Missing ETF histories should be filled with:

```cmd
scripts\00631l_import_missing_etf_batch.cmd
scripts\00631l_export_static_data.cmd --status-only
```

## Validation

`backend\tests\test_static_pages_pipeline.py` locks the workflow behavior:

- full all-catalog refresh is schedule/manual only
- local full refresh requires `--full-etf-refresh`
- missing-only batch still runs in the Pages path
