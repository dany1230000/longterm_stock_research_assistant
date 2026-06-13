# 00631L lab v4.6 header symbol search summary

## Scope

v4.6 improves the top app bar and adds a symbol search entry point. It does not add full stock detail pages, all-ETF research rooms, investment guidance, notifications, or automated trading.

## Completed

- Increased the top app bar height and visual weight.
- Split the title into `ETF 研究室` and `00631L 正二研究室` for clearer hierarchy.
- Made the left `00631L ▼` pill tappable.
- Added an ETF / stock-code search bottom sheet.
- Search uses the existing ETF catalog for now.
- If the user searches a stock code that is not in the catalog, the app clearly says the stock data source is not connected yet.
- Added widget tests for the top symbol search entry.

## Data Boundary

The current search sheet is an entry point. It does not create official detail pages for every ETF or stock. Additional verified data sources are needed before expanding to full stock or ETF research pages.
