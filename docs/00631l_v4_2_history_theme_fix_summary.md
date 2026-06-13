# 00631L lab v4.2 history range and theme fix summary

## Completed

- History/backtest page defaults to the latest one-year range.
- Start and end date controls are visible on the history page.
- Quick range controls support latest 1 year, latest 3 years, and all data.
- Price history charts, interval metrics, and the current-range table use the selected date range.
- Light/dark mode is shown as a visible `日間` / `夜間` control.
- The 00631L market shell rebuilds directly when the theme preference changes.

## Notes

- The fix does not change backend data sources.
- Historical performance still uses split-adjusted prices.
- The page continues to show data status labels and the non-advice disclaimer where relevant.
