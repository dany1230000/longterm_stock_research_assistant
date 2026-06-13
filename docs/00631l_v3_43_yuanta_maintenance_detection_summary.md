# 00631L lab v3.43 Yuanta maintenance detection summary

Completed: 2026-06-13

## Scope

v3.43 improves data reliability when Yuanta's official 00631L pages return a
site maintenance page instead of the expected Basic or ratio content.

## Changes

- Detects Yuanta maintenance pages in the profile and holdings parsers.
- Marks those responses as `sourceStatus=unavailable` with
  `sourceContract=yuanta_maintenance`.
- Prevents maintenance pages from being cached as usable official data.
- Keeps holdings usable through the latest local JSONL history snapshot when
  the live ratio page is unavailable.
- Updates live smoke assessment so recognizable Yuanta maintenance is a WARN
  condition when cached holdings and TWSE intraday NAV remain usable.

## Data Behavior

- Yuanta Basic and ratio are still official daily sources when the pages are
  serving normal content.
- During Yuanta maintenance, profile is marked unavailable and holdings use
  cached local history if available.
- TWSE intraday NAV continues to be evaluated separately.
- Cached local history is never labeled as official.

## Validation

- Parser tests cover Yuanta maintenance responses for profile and holdings.
- Smoke assessment tests cover profile maintenance as WARN with no failures.
