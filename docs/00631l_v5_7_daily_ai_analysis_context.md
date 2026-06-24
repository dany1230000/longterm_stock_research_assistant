# 00631L v5.7 Daily AI Analysis Context

Release tag: `00631l-lab-v5.7-daily-ai-analysis-context`

## What Changed

- Strengthened the backend rule-based AI summary so it reads more like a daily data briefing.
- Added explicit bullets for:
  - current official holdings date,
  - latest intraday NAV time,
  - latest market price / estimated NAV / premium-discount deviation,
  - intraday premium-discount range,
  - holdings exposure context,
  - data risk across holdings, intraday, price history, and integrity.
- Kept the same `/api/etf/00631l/analysis/summary` response contract.

## Guardrails

- The AI source remains `rule_based`.
- No external LLM key is required.
- Output describes data status, content structure, price deviation, and program actions only.
- It is not investment guidance.

## Validation

Run:

```cmd
flutter analyze
flutter test
flutter build web
py -m unittest discover -s backend\tests
scripts\00631l_release_check.cmd
git diff --check
```
