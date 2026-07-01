# 00631L lab v9.66 live overview refresh

v9.66 lets the public overview page upgrade from static fallback to live backend
data after the fast first screen renders.

## Changes

- Live-proxy builds now load full backend data even while the user stays on the
  overview tab.
- The fast first screen can still render from static public data while the
  backend is cold.
- Periodic refresh also checks the full live backend in live-proxy mode.
- A widget-level logic test guards that live-proxy mode loads full data after
  fast data is ready.

## Runtime behavior

- If the Render backend responds, holdings and intraday NAV can replace the
  static fallback on the overview page.
- If the backend is unavailable, static price history and backtest data remain
  visible.
