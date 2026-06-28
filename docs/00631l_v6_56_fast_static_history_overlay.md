# 00631L v6.56 fast static history overlay

v6.56 improves the public first-screen startup state.

When live proxy mode returns a fast payload before full details are ready, price history can still be marked `deferred`. The app now overlays the existing GitHub Pages static public price history for the fast first screen so the overview chart and history row count can appear immediately.

This does not change source truth:

- Intraday NAV still requires the live backend.
- Official holdings remain daily snapshots.
- Static public history is labeled as static history, not live intraday data.
- Full live details still replace or supplement the fast screen when they finish loading.

Verification:

- Repository test covers fast-start static price-history overlay.
- Full Flutter/backend validation remains required before release.
