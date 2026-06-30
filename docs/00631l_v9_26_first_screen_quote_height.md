# 00631L lab v9.26 first-screen quote height

## Scope

v9.26 keeps the mobile overview first screen compact. The quote header should
show the selected ETF, price, premium/discount state, readiness chips, and still
leave room for the one-year chart.

## Changes

- Added a stable `00631l-main-quote-header` key for the actual quote card.
- Added a phone-width widget guard that keeps the quote card height within
  168 px in the stock-app layout test.
- Reduced quote card padding and readiness-strip spacing without removing data.

## Why

The app should not open with a large repeated hero card. The overview can keep
the key quote context, but the chart and history context must remain visible
early on the page.

## Verification

- Widget test checks the main quote card exists and stays compact.
- Existing first-screen tests still verify the one-year chart is visible.
