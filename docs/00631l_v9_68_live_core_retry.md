# 00631L lab v9.68 live core retry

v9.68 improves the public mobile first screen when the Render backend is slow
for the first request.

## Changes

- If the first live-proxy fast request falls back to static public data, the app
  retries live core data with a short interval.
- The short retry is capped at three attempts before returning to the normal
  refresh interval.
- The overview page still avoids heavy full-data endpoints on first load.
- Tests cover the retry decision, live-first startup, and static timeout
  fallback.

## Runtime behavior

- Public Pages can recover from a slow backend response without waiting for the
  normal 15-second refresh interval.
- Static public history remains visible while live data is unavailable.
- Static data is not labeled as live intraday data.
