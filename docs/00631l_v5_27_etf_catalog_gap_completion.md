# 00631L lab v5.27 ETF catalog gap completion

## Scope

v5.27 fixes the ETF data completion denominator. The UI now compares imported ETF price histories against the broader ETF catalog count when catalog metadata is available.

## Why

The previous completion display could show `228 / 228` when 228 ETF histories were imported, even if the catalog contained more ETF rows. That was too optimistic for a data-completion question.

## Behavior

- Completion total uses the largest available count from loaded catalog rows, operations catalog rows, history-index rows, and ready-history rows.
- Left-top ETF search shows the full catalog/statistics gap before switching ETFs.
- Settings and the ETF room readiness panel use the same denominator.
- No source label changes. Mock, cached, static, and official labels remain explicit.

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
