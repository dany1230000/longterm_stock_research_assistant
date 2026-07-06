# 00631L v16.62 Comparison Selection

This polish pass makes ETF comparison behave and read as a user-selected
comparison set instead of a fixed 00631L benchmark view.

- Phone comparison header now says `ETF 自選比較` and uses the `自選` badge.
- The header shows the current date range, filter, and comparable ETF count.
- The default filter label is `常用`; users can still apply peer presets,
  keep only the current ETF, clear the set, or manually select 1-5 ETFs.
- Summary text continues to state `不設基準`, so comparison output is not
  presented as a fixed benchmark recommendation.

This is a layout and wording change only. It does not change data sourcing,
historical return calculation, or backtest behavior.
