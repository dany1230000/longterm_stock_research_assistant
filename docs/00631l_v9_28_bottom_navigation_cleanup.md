# 00631L lab v9.28 bottom navigation cleanup

v9.28 keeps the bottom navigation focused on the primary app pages.

## What changed

- Added a stable `00631l-bottom-nav` key for regression coverage.
- Confirmed the bottom navigation no longer contains an `ETF` tab.
- Removed the unused internal ETF bottom-navigation section.
- ETF search and target switching remain available through the top-left symbol
  button.

## Bottom navigation pages

- 總覽
- 歷史回測
- 持倉
- AI
- 我的

## Scope

This is a navigation cleanup only. It does not change ETF data sources,
historical calculations, backtest behavior, or live backend behavior.
