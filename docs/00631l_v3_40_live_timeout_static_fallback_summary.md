# 00631L lab v3.40 live timeout static fallback summary

Completed: 2026-06-13

## Scope

v3.40 improves public PWA cold-start behavior when the live backend is slow or
waking up.

## Changes

- Adds a full-data primary timeout inside `Cached00631LRepository`.
- Adds `00631L_PROXY_TIMEOUT_MS` as a Dart define for public live proxy builds.
- Defaults public proxy timeout to 3000 ms, so the app can fall back to static
  public history instead of waiting for a long backend timeout.
- Keeps the existing fast first-screen fallback behavior.

## Usage

```cmd
flutter build web --dart-define=USE_00631L_LIVE_PROXY=true --dart-define=USE_00631L_STATIC_DATA=true --dart-define=00631L_PROXY_BASE_URL=https://your-backend.example.com --dart-define=00631L_PROXY_TIMEOUT_MS=3000
```

## Notes

Static fallback is not live intraday data. It only keeps historical data and
backtest screens usable while the backend is disconnected or warming up.
