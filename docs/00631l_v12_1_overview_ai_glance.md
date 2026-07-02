# 00631L v12.1 overview AI glance

## Goal

Use the empty lower half of the phone overview for one compact interpretation
layer instead of leaving the first screen visually unfinished.

## Change

- Added a compact AI glance card to the overview.
- The card shows one rule-based summary line, one program action line, source,
  and data time.
- Mock/fallback wording is softened on the overview so the first screen reads
  like a finished app instead of a debug page.

## Expected behavior

- Full AI detail remains in the AI tab.
- The overview AI card stays short and fits before the bottom navigation on
  phone width.
- The content remains non-advisory.

## Verification

- Widget tests assert the overview AI card is visible on phone width and stays
  under the height guard.
- Widget tests assert fallback wording does not leak into the fast first screen.
