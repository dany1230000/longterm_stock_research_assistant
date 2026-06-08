# 00631L Lab v1.18 Release Summary

Date: 2026-06-09

## Scope

v1.18 adds one-command release validation.

Added:

- `scripts/00631l_release_check.cmd`
- `backend/scripts/release_check_00631l.py`

The release check runs:

- env check
- Flutter analyze
- Flutter test
- Flutter web build
- backend tests
- daily cycle
- history export
- live smoke
- forbidden wording scan
- git diff check

Output:

- `overallStatus`: `PASS`, `WARN`, or `FAIL`
- `failures`
- `warnings`
- `nextAction`
- per-step status and command tails

WARN is acceptable for expected local or off-hours data freshness states, including missing local `.env` when fallback mode remains operational.

## Boundaries

This release does not connect TX live, expand beyond 00631L, add notification features, or add trading advice. The release check is validation automation only.

## Validation

Required validation:

```cmd
scripts\00631l_release_check.cmd
```
