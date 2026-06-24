# 00631L v5.6 Position Account Summary

Release tag: `00631l-lab-v5.6-position-account-summary`

## What Changed

- Added a compact account-style summary strip to the position page.
- The position page now shows the selected ETF, estimated market value, unrealized PnL, and local data state before the input form.
- Reduced low-value status badges in the input block while keeping local-only, no-login, and no-upload labels visible.
- Kept JSON export, local save, and local clear controls unchanged.

## Data Notes

- Position data remains browser-local and is not uploaded.
- Market value uses the current available quote for the selected ETF.
- The section is for position tracking display only and is not investment guidance.

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
