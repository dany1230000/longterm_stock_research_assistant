# 00631L v11.4 mobile overview trim

## Goal

Make the public phone first screen more focused.

## Change

- On phone width, the overview page no longer renders the secondary
  `更多資料` expansion card.
- Desktop/tablet width still keeps the expansion card for source details,
  comparison context, and maintenance diagnostics.
- The phone first screen now prioritizes quote, one-year chart, data time, and
  official holdings digest.

## Expected behavior

- Mobile users see the primary market and holdings context without an extra
  low-priority card.
- Detailed status remains available from the dedicated pages and wider layouts.
- No data-source labels are changed or hidden falsely.

## Verification

- Phone-width widget tests assert the secondary expansion is absent.
- Desktop-width tests still cover the expansion behavior.
