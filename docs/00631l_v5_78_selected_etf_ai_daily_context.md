# 00631L lab v5.78 selected ETF AI daily context

This release improves rule-based AI wording for non-00631L selected ETFs.

## What changed

- Selected ETF AI now describes the latest close relative to the previous loaded price point.
- The summary explicitly distinguishes historical close data from intraday live data.
- The one-year range position is now shown in Chinese instead of an English debug phrase.
- Widget tests cover the selected ETF AI context and non-intraday wording.

## Scope

- No external LLM is enabled.
- No TX live behavior was changed.
- No investment guidance was added.
