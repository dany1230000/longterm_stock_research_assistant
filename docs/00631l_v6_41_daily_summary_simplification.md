# 00631L v6.41 daily summary simplification

## Goal

Make the overview `今日摘要` strip easier to scan on phone screens.

## What Changed

- The strip now focuses on three daily readiness signals:
  - official daily holdings date
  - intraday NAV time
  - static history coverage
- Removed duplicate P/D and AI chips from this strip because premium/discount is
  already in the quote card and AI has its own page.
- Intraday source captions now show user-facing labels such as `TWSE` or
  `Yuanta` instead of raw source-contract IDs.

## Validation

- Widget coverage verifies the fast-start summary avoids transient error text,
  no longer renders the removed P/D chip, and hides raw source-contract text.
- Source-contract details remain available in deeper status views.
