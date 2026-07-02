# 00631L v12.0 overview holdings inline

## Goal

Make the overview first screen read like one compact market page instead of a
stack of repeated cards.

## Change

- The official holdings digest now sits inside the overview market stack.
- The separate holdings digest card below the quote/chart stack was removed.
- The digest still shows the key holdings context: official daily date, TX,
  TSMC, and stock/futures/cash exposure.

## Expected behavior

- The overview groups quote, chart, data time, and official daily holdings
  context together.
- Content remains non-advisory and source labels stay truthful.
- Full holdings detail remains in the holdings section.

## Verification

- Widget tests assert the holdings digest renders inside the overview market
  stack on phone width.
- Existing release checks keep forbidden wording and build validation in place.
