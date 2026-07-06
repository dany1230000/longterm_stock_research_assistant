# 00631L v16.76 top bar and ribbon polish

This release keeps the mobile-first ETF app structure but tightens the first
screen wording.

## Changes

- The top app bar keeps the left symbol search button and makes `ETF 研究室`
  slightly more prominent without increasing the bar height.
- On compact widths, the subtitle includes the current frontend data mode, such
  as `公開靜態`, `Live 後端`, or `示範`.
- The overview data ribbon now uses user-facing labels:
  `日 / 盤中 / 歷史 / 模式`.

## Scope

- No new data source.
- No TX live connection.
- No investment guidance.
- Existing static, live proxy, and mock fallback labels remain truthful.

## Validation

- Widget coverage checks the compact top bar, the symbol search button, and the
  localized overview ribbon labels.
- The forbidden wording scan remains part of the release check.
