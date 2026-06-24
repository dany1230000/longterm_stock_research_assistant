# 00631L v5.71 Static Warning Cleanup

Date: 2026-06-24

## Scope

v5.71 cleans up static public data output after the broad ETF price seed release.

The static export no longer treats normal seed merges or catalog-wide missing
ETF histories as individual warnings. Those details are now summarized as
structured fields:

- `etfPriceHistoryReadyCount`
- `etfPriceHistoryMissingCount`
- `etfPriceHistoryCoverageTierCounts`
- `etfPriceHistorySeedMerge`
- `noteCount`
- `notesSample`

## Why This Matters

The public Pages build now covers the full TWSE ETF catalog. Some catalog items
still do not have a validated price-history file. That is a data coverage fact,
not a separate warning for every symbol.

Warnings are now reserved for conditions that need attention, such as source
failures, stale 00631L coverage, missing seed directories, or strict export
failures.

## Expected Daily Output

For a normal static export run, the concise summary should look like:

```text
[summary] overallStatus=PASS rows=2835 coverage=2014-10-31..2026-06-24 etfReady=230 etfRows=345 etfCatalogRows=345 etfMissing=115 tiers=long_term:8,recent:222,unavailable:115,error:0
```

Normal update details move to `notesSample`, for example update mode, saved
rows, catalog row count, and all-catalog resolution.

## Data Semantics

- `etfReady`: ETF histories with at least two validated rows.
- `etfMissing`: catalog symbols that are visible in the readiness index but do
  not yet have a usable static history.
- `unavailable`: shown in tier counts for catalog entries without usable
  history.
- `warnings`: reserved for source, coverage, seed, or strict export issues.

## Validation

Run:

```cmd
flutter analyze
flutter test
flutter build web
py -m unittest discover -s backend\tests
scripts\00631l_release_check.cmd
scripts\00631l_build_pages_static.cmd
git diff --check
```

The public Pages marker should still point to the latest pushed release before
calling the release complete.
