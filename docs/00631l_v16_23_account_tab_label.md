# 00631L v16.23 Account Tab Label

This release makes the bottom-right app entry read more like a user-facing
account and preferences area.

## Scope

- Bottom navigation label changes from `設定` to `帳戶`.
- Bottom navigation icon changes from a generic settings icon to a person
  outline.
- The settings first-screen heading changes from `設定` to `帳戶`.
- Advanced technical diagnostics remain inside the existing `進階設定` panel.

## What Did Not Change

- No settings behavior changed.
- No account login or external account integration was added.
- No position data upload was added.
- No TX live integration was added.
- No investment recommendation text was added.

## Validation

Targeted tests:

```powershell
flutter test test\etf_00631l_widget_test.dart --plain-name "00631L lab renders stock-app style quote header"
flutter test test\widget_test.dart --plain-name "root opens standalone 00631L app"
```
