# ETF lab v9.74 symbol search affordance

v9.74 makes the top-left symbol control look and behave more like a clear
search entry.

## What changed

- The top-left symbol pill is slightly larger.
- The pill now shows the selected code, a search icon, a short `搜尋` label, and
  a down arrow.
- The existing ETF/stock search sheet is unchanged, so selecting an ETF still
  switches the visible ETF context for quote, history, backtest, position, and
  AI sections where data is available.

## Why

Users should understand that the code pill is an action, not just a label. This
keeps the app header compact while making ETF switching discoverable on phone
screens.

## Verification

- Widget tests confirm the pill exposes the `搜尋` label and still opens the
  ETF/stock search sheet.
- No new data source or investment interpretation is included.
