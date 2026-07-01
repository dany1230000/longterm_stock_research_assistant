# 00631L lab v9.71 live warm-up retry

v9.71 improves the public app path when the live backend is slow or cold.

## Changes

- The overview still renders a static/public first screen quickly.
- If live holdings or intraday NAV are missing, the app retries the fast live
  core data up to 15 times on the short retry interval.
- The retry stops as soon as both official/cached holdings and intraday NAV are
  available.

## Why

GitHub Pages can render before the public backend finishes waking up. The longer
warm-up window lets the app replace fallback values with live core data sooner,
without blocking the initial screen.
