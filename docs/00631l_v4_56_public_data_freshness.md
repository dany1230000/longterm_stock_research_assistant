# 00631L lab v4.56 public data freshness comparison

v4.56 adds a read-only freshness comparison for deployed public backend data.

## Goal

The app can now compare three public-use data surfaces:

- public backend: `https://longterm-stock-research-assistant.onrender.com`
- local backend cache / seed-merged price history
- GitHub Pages static export under `web\00631l-static-data`

This catches cases where the mobile app can connect to the backend, but the
deployed backend history is older than local or static data.

## Command

```cmd
scripts\00631l_compare_public_freshness.cmd --soft-fail
```

Dry-run mode is used by release check:

```cmd
scripts\00631l_compare_public_freshness.cmd --dry-run
```

## Status Rules

- `PASS`: public backend, local history, and static public data are aligned.
- `WARN`: public backend history is behind local/static data, ETF ready counts are
  lower than static data, or a non-critical source is missing.
- `FAIL`: public backend status check itself fails.

Warnings include program actions such as running remote maintenance. The command
does not mutate data.

## Why This Matters

GitHub Pages static mode can show history/backtest even if the live backend is
behind. v4.56 makes that gap explicit so daily maintenance can keep the public
backend and static data synchronized.

This remains a data-quality check only. It is not investment guidance.
