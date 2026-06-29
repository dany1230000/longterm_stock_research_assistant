# 00631L lab v9.18 custom comparison basket

Date: 2026-06-29

## What changed

- The ETF comparison panel now has an explicit custom-basket summary.
- The summary lists the ETFs currently selected by the user.
- The comparison chart continues to normalize each selected ETF over the shared date range.
- The panel states that there is no fixed comparison baseline.

## Why

Users should be able to compare any selected ETF group without the app silently anchoring the view to 00631L. The same-type quick action remains available, but it is no longer implied as the default comparison set.

## Verification

- Widget coverage confirms the comparison summary is visible.
- Selecting 0050 alone keeps the summary on 0050 and does not add 00631L.
- The existing forbidden wording scan remains part of the release check.
