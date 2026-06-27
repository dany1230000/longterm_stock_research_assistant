# 00631L lab v5.90 Pages maintenance split

## Scope

v5.90 separates normal GitHub Pages publishing from ETF history maintenance.

Push builds now do the minimum needed for a public app release:

- export strict 00631L static data
- merge committed ETF history seeds
- build Flutter web

ETF history refresh is reserved for maintenance paths:

- weekday scheduled Pages workflow
- manual workflow dispatch with `refresh_etf_histories=true`
- manual workflow dispatch with `full_etf_refresh=true`
- local `scripts\00631l_build_pages_static.cmd --refresh-etf-history`
- local `scripts\00631l_build_pages_static.cmd --full-etf-refresh`

## Why

The public app should publish quickly after UI or code changes. Broad ETF
history upkeep is slower and belongs in scheduled/manual maintenance, where
partial official-source gaps can be reviewed without delaying every release.

## Local commands

Fast Pages build:

```cmd
scripts\00631l_build_pages_static.cmd
```

Selected ETF refresh before build:

```cmd
scripts\00631l_build_pages_static.cmd --refresh-etf-history
```

Broad recent refresh before build:

```cmd
scripts\00631l_build_pages_static.cmd --full-etf-refresh
```

## Data behavior

- 00631L static price history still uses strict coverage checks.
- Other ETF histories come from committed seeds unless a maintenance refresh is
  explicitly requested.
- Missing ETF histories stay visible as data gaps; they are not replaced by
  fallback rows.
