# 00631L v9.2 Search Loading State

Date: 2026-06-29

## Goal

Make the left-top ETF search sheet truthful while the static ETF catalog is
lazy-loaded.

## What Changed

- When the catalog request is still running, the search sheet shows
  `ETF 目錄載入中，請稍候。`
- If the catalog request fails and no loaded catalog exists, the sheet shows a
  clear `ETF 目錄載入失敗` state.
- The empty-result message is now reserved for real empty searches instead of
  being reused for deferred catalog loading.

## Result

The first public screen can stay lightweight, while the search workflow remains
clear on mobile when the full ETF catalog is fetched on demand.

## Validation

- Widget tests cover lazy catalog loading, success, and error states.
- Static-public source labels remain separate from live intraday NAV.
