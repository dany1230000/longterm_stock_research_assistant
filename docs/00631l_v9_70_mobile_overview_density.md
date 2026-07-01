# 00631L lab v9.70 mobile overview density

v9.70 tightens the mobile overview without changing data sources or investment
logic.

## Changes

- The one-year chart remains visible on the overview first screen.
- Official exposure switches to a compact stock / futures / cash row on phone
  width, while wider screens keep the progress-bar layout.
- The official holdings digest uses shorter app-style copy so the page reads
  more like a quote app and less like a maintenance report.

## Data behavior

- Official holdings still come from the daily Yuanta snapshot.
- Intraday NAV still comes from the configured live backend when available.
- Static public history and mock fallback labels remain unchanged.
