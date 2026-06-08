# 00631L Lab v1.22 Release Summary

Date: 2026-06-09

## Scope

v1.22 improves phone-width readability for `/00631l-lab`.

Updated:

- Summary cards switch to one column on compact screens.
- Operations/status cards switch to one column on compact screens.
- Holdings history summary cards switch to one column on compact screens.
- Command blocks can wrap vertically on narrow screens.
- Data tables keep horizontal scrolling with a stable minimum width.
- Widget test covers phone-width rendering.

## Boundaries

This release changes only UI readability and documentation. It does not add analysis logic, connect TX live, expand beyond 00631L, add notification features, or add trading advice.

## Validation

Required validation:

```cmd
flutter analyze
flutter test
flutter build web
py -m unittest discover -s backend\tests
scripts\00631l_release_check.cmd
git diff --check
```
