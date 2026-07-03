# 00631L lab v15.25 symbol search result density

This release tightens the phone ETF search result rows.

## Changes

- Compact search rows use less padding.
- Code badges and the expandable detail entry are shorter on phone width.
- Widget coverage now uses a stricter row-height guard for ETF search results.

## Validation

- The focused phone symbol-search test verifies row height and expandable
  details.
- Search ranking, catalog loading, ETF switching, and data-source behavior are
  unchanged.
