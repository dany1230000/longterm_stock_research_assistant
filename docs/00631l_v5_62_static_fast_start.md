# 00631L lab v5.62 static fast start

Release tag: `00631l-lab-v5.62-static-fast-start`

## What changed

Public static mode now has a dedicated fast-start data path. The first screen
can use static official price history, operations status, ETF catalog metadata,
and the rule-based summary without waiting for the full live backend path.

## Data labels

- price history: `static_official` when `price_history.json` is available
- operations status: `static_public_data`
- holdings history: `backend_required`
- intraday NAV: `backend_required`
- TX quote: `static_public_backend_required_tx_quote`

This prevents public PWA startup from showing mock holdings or TX data as if it
were live.

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
