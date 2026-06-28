# 00631L lab v6.90 - static catalog completeness guard

## Goal

Keep the public static ETF catalog complete when the live TWSE catalog source
temporarily fails or returns fewer rows during a Pages build.

## Root Cause

The v6.89 public static check showed:

- ETF catalog rows: 343
- ETF price-history index rows: 347
- Out-of-catalog rows: 4
- Manifest warning: TWSE all-ETF catalog fetch returned HTTP 502

The history index still had the fuller ETF universe, but the catalog snapshot
was reduced by the failed live catalog update.

## Changes

- Static export now merges the committed ETF catalog seed into the runtime
  catalog payload by ETF code.
- Live/local catalog rows are kept first; seed-only codes are appended.
- Public static data check now warns whenever history contains symbols outside
  the catalog snapshot, even if missing-gap reasons are already classified.

## Boundaries

- No price-history rows are fabricated.
- Existing ETF gap reasons and price-history validation remain unchanged.
- This only preserves known catalog symbols so catalog, comparison, and
  readiness counts share the same universe.

## Validation

- Targeted backend tests cover catalog seed merge and out-of-catalog warnings.
- Static export smoke after the change produced `etfCatalogRows=347`,
  `etfRows=347`, and `etfOutOfCatalog=0`.
- Full validation passed: Flutter analyze/test/build, backend tests, release
  check with acceptable WARN-only output and `failures=0`, and
  `git diff --check`.
