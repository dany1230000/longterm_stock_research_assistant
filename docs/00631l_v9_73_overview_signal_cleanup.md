# 00631L lab v9.73 overview signal cleanup

v9.73 tightens the mobile overview first screen.

## What changed

- The one-year chart remains expanded on the overview page.
- On phone width, the chart panel no longer repeats the compact stock/futures/cash
  exposure row.
- Official holdings exposure remains available in the dedicated holdings digest
  immediately below the chart.
- Desktop width still keeps the chart and exposure block side by side.

## Why

The previous mobile overview showed the same daily exposure idea twice: once
inside the chart panel and again in the holdings digest. Removing the duplicate
row keeps the first screen closer to a stock-app quote page while preserving the
daily official holdings context.

## Verification

- Widget tests cover the phone layout and holdings digest.
- No data source, TX live source, or investment interpretation changed in this
  version.
