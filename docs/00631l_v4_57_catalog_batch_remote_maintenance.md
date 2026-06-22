# 00631L lab v4.57 catalog-batch remote ETF history maintenance

v4.57 lets the public backend update ETF price history from the cached ETF
catalog in controlled batches.

## Why

The default remote maintenance basket covers selected representative ETFs. Static
public data can contain many more catalog ETFs, so the public backend may have a
lower ETF ready count than GitHub Pages static data.

## Backend Endpoint

`POST /api/etf/history/update` now supports:

- `fromCatalog=true`
- `limit=<batch-size>`
- `offset=<batch-offset>`
- `startDate=yyyy-mm-dd`
- `endDate=yyyy-mm-dd`

If `codes=` is supplied, explicit codes still take priority. Without `codes` and
without `fromCatalog=true`, the default representative ETF basket remains
unchanged.

## Remote Command

```cmd
scripts\00631l_remote_maintenance.cmd --mode daily --etf-from-catalog --etf-limit 50 --etf-offset 0 --soft-fail
```

Run the next batch by increasing `--etf-offset`:

```cmd
scripts\00631l_remote_maintenance.cmd --mode daily --etf-from-catalog --etf-limit 50 --etf-offset 50 --soft-fail
```

This is still an operational data-maintenance command only. It does not change
investment logic.
