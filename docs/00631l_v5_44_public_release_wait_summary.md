# 00631L lab v5.44 public release wait summary

v5.44 makes the public Pages release-marker wait command easier to use after
pushes.

## Changes

- `scripts\00631l_wait_public_release_marker.cmd` now supports
  `--summary-only`.
- Summary mode keeps the top-level status, release tag, commit SHA, row count,
  coverage, warnings, failures, and a compact attempt summary.
- Summary mode omits the full sampled public Pages payloads, so daily logs stay
  readable.
- `scripts\00631l_release_check.cmd` uses summary mode for its dry-run check.

## Usage

```cmd
scripts\00631l_wait_public_release_marker.cmd --expected-sha <commit> --summary-only
```

Use the command without `--summary-only` only when debugging the full public
Pages check payload. From v5.45 onward, add `--include-attempts` when you want
every compact polling attempt in summary mode.

## Status Rules

- `PASS`: public Pages is serving the expected release marker.
- `WARN`: public Pages is reachable but still serving an older release marker.
- `FAIL`: public Pages or static data validation failed.

This check only verifies the public static bundle. Live intraday NAV still
depends on the public backend.
