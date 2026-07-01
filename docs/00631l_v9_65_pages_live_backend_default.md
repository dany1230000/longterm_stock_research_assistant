# 00631L lab v9.65 Pages live-backend default

v9.65 makes local and GitHub Pages static builds default to the public Render
backend while keeping static public data as fallback.

## Changes

- `scripts\00631l_build_pages_static.cmd` now builds with:
  - `USE_00631L_LIVE_PROXY=true`
  - `00631L_PROXY_BASE_URL=https://longterm-stock-research-assistant.onrender.com`
  - `USE_00631L_STATIC_DATA=true`
- The GitHub Pages workflow already has the same public backend fallback when a
  secret/variable is not configured.
- A metadata test now guards that Pages builds include both live proxy and static
  fallback settings.

## Runtime behavior

- Public PWA first tries the Render backend for live holdings, intraday NAV,
  operations status, and AI summary.
- If the backend is cold or unavailable, the app should still show static public
  history and backtest data.
