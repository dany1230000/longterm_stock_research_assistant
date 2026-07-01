# 00631L lab v9.64 compact daily summary

v9.64 reduces first-screen height on phones by simplifying the daily summary
strip.

## Changes

- Removed the extra `今日摘要` header row from the overview summary strip.
- Kept the three core summary chips: official contents, intraday NAV, and price
  history.
- Added a phone-width widget guard so the summary strip remains compact.

## Scope

- No data source, parser, repository, or chart calculation behavior changed.
- The frontend mode remains visible in the quote/status area; it is not repeated
  inside the summary strip.
