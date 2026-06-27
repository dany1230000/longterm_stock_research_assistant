# 00631L lab v6.4 runtime catalog probe

v6.4 changes the public Pages ETF price-history probe to use a runtime ETF
catalog before missing-only imports.

## What Changed

- GitHub Pages imports the current TWSE ETF catalog into
  `backend\data\etf_catalog.json` before ETF history imports.
- If the live catalog import fails, the workflow copies the committed seed
  catalog as a fallback.
- Missing-only imports and probe batches use the runtime catalog path.
- Local Pages build mirrors the same behavior when refresh/probe flags are used.

## Why

After v6.3, only two public ETF history gaps remained unclassified:

- `009823`
- `009824`

They appeared in the public static catalog but not in the committed seed catalog
used by the import/probe step. The probe therefore never selected them.

Using the runtime catalog closes that selection gap while retaining the seed
fallback for source outages.

## Boundary

This only changes which ETF symbols are selected for official TWSE STOCK_DAY
checks. It does not create price rows when the official source has no rows.
