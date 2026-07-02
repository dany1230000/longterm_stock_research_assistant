# 00631L v11.2 first-load refresh budget

## Goal

Keep the public mobile first screen responsive when live proxy data is slow or
unavailable.

## Change

- Live-core warmup retries are now limited to 2 attempts.
- Warmup retry interval is now 8 seconds.
- After those attempts, the app returns to the normal market-session refresh
  interval instead of repeatedly reloading profile, holdings, NAV, TX fallback,
  and static preview data.

## Expected behavior

- Public static mode still renders history/backtest data without a backend.
- Live proxy mode still has a short chance to replace static fallback data.
- If the public backend is unavailable, the app keeps static/mock fallback
  labels truthful and stops aggressive startup refreshes.

## Verification

- Widget test guards the retry limit and interval.
- The public first screen keeps the same information architecture: quote,
  premium/discount, one-year chart, holdings digest, AI badge, and bottom
  navigation.
