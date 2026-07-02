# 00631L v15.7 History Range Summary Density

This release tightens the phone history and backtest date-range summary.

## What Changed

- Phone date-range summary no longer shows the long `start - end` range inside narrow metric chips.
- Compact mode prioritizes short status chips such as row count, strategy, or sample count.
- Start and end dates remain visible in the date-control cards.

## Product Boundary

- No date filtering calculation change.
- No backtest engine change.
- No history source change.
- This is a phone layout density improvement only.

## Validation

Run the normal release checks:

```cmd
flutter analyze
flutter test
flutter build web
py -m unittest discover -s backend\tests
scripts\00631l_release_check.cmd
git diff --check
```
