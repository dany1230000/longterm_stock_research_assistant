# 00631L lab v5.68 compact static output

Date: 2026-06-24

## Scope

v5.68 keeps the v5.67 static coverage guard and reduces daily maintenance output noise.

## Changes

- `--summary-only` ETF import output now keeps only 5 sample rows by default.
- Import sample rows keep only operational fields: code, source status, coverage end, row count, saved rows, validation status, and error message.
- Long warning and failure text is truncated in compact output.
- Static export compact output also truncates long warning and failure text.

## Unchanged

- Full JSON output is still available by omitting `--summary-only`.
- Static public mode still exports official/cached source labels truthfully.
- Live intraday NAV still requires backend connectivity.
- No TX live, all-ETF expansion logic, notification, or investment instruction is added.

## Validation

Run:

```cmd
flutter analyze
flutter test
flutter build web
py -m unittest discover -s backend\tests
scripts\00631l_release_check.cmd
scripts\00631l_build_pages_static.cmd
git diff --check
```
