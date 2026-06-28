# 00631L lab v6.13 gap detail filters

v6.13 makes ETF price-history gap details easier to inspect in the app.

## What changed

- Added reason filter chips to the settings `ETF gap details` panel.
- The filter can show all rows or focus on a single gap reason such as
  `official_empty` or `source_error`.
- Added a filtered count so the panel shows how many rows match the selected
  reason.
- Added widget coverage for the reason-filter interaction.

## Data boundary

The panel remains a maintenance view.

Unavailable ETF rows are not used as price history, backtest input,
comparison data, or AI performance context. They are displayed only to explain
which symbols still lack verified historical data and why.

## Usage

Open:

```text
Settings / ETF data and comparison capability / ETF gap details
```

Choose a reason chip to inspect that maintenance bucket. Choose `all` to return
to the full detail list.
