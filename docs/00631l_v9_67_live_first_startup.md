# 00631L lab v9.67 live-first startup

v9.67 fixes the public first screen data priority. When GitHub Pages is built
with both live proxy and static public data, the app now waits for the live
backend during the short startup timeout before showing static fallback data.

## Changes

- Fast startup starts static fallback in parallel, but live backend data wins
  when it responds inside the configured timeout.
- Static public data still appears when the backend is cold, unavailable, or
  slower than the startup timeout.
- The overview page stays on fast core data and does not request heavy full-data
  endpoints before the user opens detail sections.
- A repository test covers both paths: live-first startup and timeout fallback.

## Runtime behavior

- Public Pages can show official holdings and TWSE intraday NAV on the first
  overview screen when the Render backend is healthy.
- If the public backend is unavailable, historical data and backtest remain
  available from static public data.
- Static data is not treated as live intraday data.
