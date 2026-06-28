# 00631L lab v6.82 search database detail labels

v6.82 cleans up the ETF search sheet database detail panel.

## What changed

- Replaced internal English labels in the expanded database detail panel:
  - `catalog` -> `ETF 清單`
  - `catalog source` -> `清單來源`
  - `history source` -> `歷史來源`
  - `long-term` -> `長期資料`
  - `recent` -> `近期資料`
- The panel now explains that it shows ETF catalog, imported history status,
  and coverage category details.

## Why

The search sheet is a user-facing ETF selector. It should not read like a debug
dump when users expand the database status details.

## Validation

- Widget coverage verifies the expanded search database detail panel uses the
  new labels.
