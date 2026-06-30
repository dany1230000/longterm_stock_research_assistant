# 00631L lab v9.43 - public first-load network guard

Date: 2026-06-30

## Goal

Prevent public mobile first load from regressing into heavy background requests.

## Added Check

`scripts\00631l_check_public_first_load_network.cmd`

The script opens the public GitHub Pages app at phone width and inspects the
first few seconds of network requests. It fails if the overview immediately
requests deferred heavy data such as:

- `/api/etf/00631l/history/price`
- `/api/etf/catalog`
- `/api/etf/00631l/operations/status`
- `/api/etf/00631l/analysis/summary`
- `price_history.json`
- `etf_catalog.json`
- `etf_price_history_index.json`

Expected first-load data remains:

- live core quote / holdings / intraday endpoints when available
- `price_preview.json`
- `status.json`
- `release.json`

## Release Check

`scripts\00631l_release_check.cmd` now includes the public first-load network
guard. If Node / `npx.cmd` is unavailable, the guard prints a WARN and exits
without blocking local validation.
