# v5.85 Public Static Release Match

## Scope

v5.85 extends the public static data checker with optional release matching:

```cmd
scripts\00631l_check_public_static_data.cmd --expected-release-tag 00631l-lab-v5.84-public-static-check
scripts\00631l_check_public_static_data.cmd --expected-sha cccc52b
scripts\00631l_check_public_static_data.cmd --expected-release-tag 00631l-lab-v5.84-public-static-check --strict-release
```

## Behavior

- Without expected values, the checker only verifies that public static data is
  reachable and structurally healthy.
- With `--expected-release-tag` or `--expected-sha`, mismatches are reported as
  `WARN` by default. This is useful while GitHub Pages is still deploying.
- With `--strict-release`, mismatches become `FAIL`. Use this after the Pages
  workflow should have completed.

## Why

The public phone app can be healthy while still serving the previous static
bundle for a few minutes after a push. Expected release checks make that state
explicit without confusing it with missing data.

## Example Post-Push Check

```cmd
scripts\00631l_check_public_static_data.cmd --expected-sha cccc52b --strict-release
```

Static public data supports public history and backtest usage. Live intraday NAV
still requires the public backend.
