# 00631L lab v5.45 brief public release wait

v5.45 makes public Pages release waiting shorter for daily use.

## Changes

- `--summary-only` now prints a brief `attemptSummary` instead of every polling
  attempt.
- The brief summary keeps:
  - first sampled public release marker
  - latest sampled public release marker
  - sample count
  - release SHA transition count
- `--include-attempts` can be added when debugging each compact polling sample.

## Daily Command

```cmd
scripts\00631l_wait_public_release_marker.cmd --expected-sha <commit> --summary-only
```

## Debug Command

```cmd
scripts\00631l_wait_public_release_marker.cmd --expected-sha <commit> --summary-only --include-attempts
```

The command still checks the public static bundle only. Live intraday NAV still
requires the public backend.
