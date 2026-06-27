# 00631L lab v6.5 public catalog universe

v6.5 separates current ETF catalog count from retained ETF history index count
in the public static-data checker.

## What Changed

- `scripts\00631l_check_public_static_data.cmd` now reports:
  - `etfPriceHistoryOutOfCatalogCount`
- The compact summary prints `etfOutOfCatalog`.
- A history index larger than the current catalog snapshot is no longer WARN by
  itself.
- WARN is kept when out-of-catalog rows still include unclassified gaps.

## Why

After v6.4, all ETF history gaps were classified, but the public checker still
warned because the history index retained 345 symbols while the current catalog
snapshot had 343. Retaining classified out-of-catalog symbols is useful history
evidence, not a data failure.

## Boundary

This is a status interpretation change only. It does not remove historical
files, change ETF rows, or mark unavailable histories as ready.
