# 00631L v16.36 top bar density

This release trims the app top bar so the first screen reaches market data
faster.

## What changed

- Top bar height changed from 58 px to 52 px.
- The `ETF 研究室` title changed from 24 px to 22 px.
- The left symbol search pill keeps its tap target and remains the primary way
  to switch ETF symbols.

## Why

The top bar should identify the app and provide symbol search, but it should not
compete with price, NAV, premium/discount, and chart content. This is layout
polish only; data fetching, calculations, and source labels are unchanged.
