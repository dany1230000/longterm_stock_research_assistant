# 00631L v11.3 static fallback cache reuse

## Goal

Reduce repeated public first-screen requests after the app has already loaded
static fallback data.

## Change

- `Cached00631LRepository` now reuses in-memory static fallback data during
  later fast live refreshes.
- If live backend data arrives but still lacks price-history readiness fields,
  cached static history/status fills that gap without another static JSON read.
- If the live backend is slow or unavailable, the existing fallback path remains
  available and labels stay truthful.

## Expected behavior

- First public load can still race live proxy and static data for fast display.
- Later live warmup attempts should not re-fetch static `price_preview`,
  `status`, or `release` files when cached copies already exist.
- Static public mode remains valid for history and backtest while live intraday
  NAV still depends on the backend.

## Verification

- Repository test verifies the second fast refresh reuses cached static fallback
  paths instead of making new static client requests.
