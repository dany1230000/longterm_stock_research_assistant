# 00631L v6.54 background refresh banner

v6.54 shortens the first-screen background refresh banner.

## What changed

- The fast first screen now says `背景更新中，已先顯示可用資料。`
- The fallback/error banner is shorter and still tells the user that fallback data is retained.
- The quote card, chart, summary row, and data source labels are unchanged.

## Data behavior

- This is a presentation-only change.
- No parser, repository, or calculation behavior changed.
- The app still keeps live/static/fallback labels truthful.

## Validation focus

- Widget coverage verifies the fast first screen uses the compact background-refresh wording.
