# 00631L Lab v5.18 AI Today Snapshot

## Scope

v5.18 makes the AI page start with an immediate daily data interpretation panel.
The existing rule-based AI details remain available below it.

## What Changed

- Adds a `今日 AI 資料解讀` panel at the top of the AI page.
- Shows official holdings date and intraday NAV data time.
- Shows premium/discount status from the existing rule-based assessment.
- Shows price history row count, coverage, and latest close.
- Shows backend/readiness/source status in one line.
- Shows one program-operation action item.

## User Impact

The AI page now reads like a daily data status summary instead of a long
maintenance report. It remains rule-based and does not call an external LLM.

This panel does not provide investment guidance.

## Validation

- `flutter analyze`
- `flutter test`
- `flutter build web`
- `py -m unittest discover -s backend\tests`
- `scripts\00631l_release_check.cmd`
- `git diff --check`
