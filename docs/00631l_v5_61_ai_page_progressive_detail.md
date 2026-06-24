# 00631L lab v5.61 AI page progressive detail

Release tag: `00631l-lab-v5.61-ai-page-progressive-detail`

## What changed

The AI page now opens with a short daily interpretation and three compact cards:

- daily data state
- intraday NAV and price deviation state
- data risk and maintenance notes

The detailed interpretation matrix, source-status panel, complete report, and
integrity notes are still available, but they are grouped under `進階 AI 明細`.
This keeps the first mobile screen focused while preserving the full audit trail.

## Boundaries

- AI remains `rule_based`.
- The page describes data state, holdings changes, price deviation, and program
  actions only.
- TX live data is not expanded.
- Fallback and static data are not labeled as live official data.

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
