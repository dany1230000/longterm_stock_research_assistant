# 00631L lab v6.28 AI daily briefing hero

v6.28 makes the AI page start with a compact daily interpretation card.

## What changed

- The AI page now opens with a `今日 AI 判讀` card.
- The card groups holdings date, intraday NAV time, source status, TX weight,
  TSMC weight, premium-discount context, and the first program action.
- The card explicitly states `rule_based` and `非買賣建議`.
- Existing detailed AI/status panels remain available below the new daily
  briefing card.

## Scope

- UI hierarchy and wording only.
- No live TX change.
- No new investment guidance.
- No historical price, backtest, holdings, or source-label calculation changes.

## Validation

Run:

```cmd
dart format --set-exit-if-changed .
flutter analyze
flutter test
flutter build web
py -m unittest discover -s backend\tests
scripts\00631l_release_check.cmd
git diff --check
```
