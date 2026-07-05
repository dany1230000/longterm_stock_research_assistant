# 00631L v16.20 Phone Density Regression

This release adds a cross-tab mobile layout guard for the 00631L app shell.

## Scope

- Keeps the overview market stack compact on a 390px phone viewport.
- Keeps the AI daily briefing hero and first-screen fact row compact.
- Keeps the position account strip and metric row compact after local values are entered.
- Keeps the settings quick summary and preference row compact.
- Keeps the bottom navigation as the only primary app navigation.

## What Did Not Change

- No data source behavior changed.
- No parser behavior changed.
- No static public export behavior changed.
- No TX live integration was added.
- No investment recommendation text was added.

## Validation

Targeted test:

```powershell
flutter test test\etf_00631l_widget_test.dart --plain-name "phone first-screen density guard covers main app tabs"
```

Full validation remains:

```powershell
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build web
py -m unittest discover -s backend\tests
py backend\scripts\check_public_config_00631l.py
py backend\scripts\check_public_static_data_00631l.py
git diff --check
```
