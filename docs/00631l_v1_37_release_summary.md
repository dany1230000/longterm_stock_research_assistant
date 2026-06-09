# 00631L lab v1.37 daily report documentation summary

v1.37 adds user-facing documentation for daily Markdown reports.

## Added

- `docs\00631l_daily_report_guide.md`
- README link to the report guide
- daily usage references for report reading, WARN review, and FAIL review

## Scope

This release only documents how to read local report files and how to review WARN/FAIL states. It does not change backend parsing, live data fetching, frontend behavior, TX live, or the 00631L-only product scope.

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
