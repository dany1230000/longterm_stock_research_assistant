# 00631L Lab v5.66 ETF Import Progress

v5.66 adds visible progress lines to long ETF history imports.

Broad static-public ETF import can take several minutes because it checks the
committed TWSE ETF seed catalog. Before this release, the command could look
idle until the final summary appeared. The import CLI now supports:

```cmd
--progress-every 25
```

Progress lines go to stderr and look like:

```text
[progress] etf_price_history_import 25/343 code=00636
```

The JSON summary on stdout remains compact when `--summary-only` is enabled.

## What Changed

- `backend/scripts/import_etf_price_history.py` supports `--progress-every`.
- GitHub Pages workflow prints progress during selected and broad ETF import.
- `scripts\00631l_build_pages_static.cmd` prints progress during selected and
  broad ETF import.
- Tests cover progress interval behavior and pipeline flags.
