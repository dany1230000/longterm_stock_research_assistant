# 00631L v5.8 AI Page Briefing Cards

Release tag: `00631l-lab-v5.8-ai-page-briefing-cards`

## Scope

v5.8 improves the mobile AI analysis page presentation without changing the
backend analysis contract or data calculations.

## Changes

- Replaced the oversized AI page header with compact briefing cards.
- The first screen now highlights:
  - daily data status
  - intraday premium/discount context
  - data-risk context
- Kept the full rule-based report in an expandable detail section.
- Kept `rule_based` as the default analysis source.
- Kept the non-advisory disclaimer visible.

## Data Behavior

- No new live data source was added.
- No TX live behavior changed.
- No ETF scope expansion was added in this release.
- The UI still labels live proxy, static public, and fallback states explicitly.

## Validation

- Widget coverage checks the three AI briefing cards by stable keys.
- Backend health metadata is updated to v5.8.
- Release check requires this summary file.
