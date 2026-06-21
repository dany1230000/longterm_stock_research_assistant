# 00631L lab v4.27 static status tier fallback

Completed: 2026-06-21

## Scope

- `static_export_status()` now reads `etf_price_history_index.json` when `manifest.json` does not include `etfPriceHistoryCoverageTierCounts`.
- This keeps existing static public folders readable after upgrading the backend code.
- The behavior is covered by a backend unit test.

## Notes

This does not modify generated static data. The next static export will write tier counts into the manifest directly; older exports can still expose the same counts if the index file has them.
