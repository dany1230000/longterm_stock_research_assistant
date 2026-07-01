# 00631L lab v10.1 position account compact

Release tag: `00631l-lab-v10.1-position-account-compact`

## Goal

Make the `持倉` page read more like a compact account screen on mobile.

## Changes

- The first card now groups market value, unrealized P/L, cost, and position
  weight together.
- Quote source and data time are visible as compact chips.
- Full quote/history source details stay behind `更多資料來源`.
- The input form remains focused on shares and average cost first; optional
  fields stay in the advanced panel.

## Unchanged

- Position data is still saved only in the browser.
- No backend upload was added.
- Position calculations, JSON export, and clear behavior were not changed.
- This page remains a data display and estimate surface, not investment advice.
