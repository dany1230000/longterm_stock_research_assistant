# 00631L lab v5.92 release static guard

## Scope

v5.92 makes the static public regression guard part of normal release
validation, not only a deployment workflow guard.

`scripts\00631l_release_check.cmd` now runs:

```cmd
scripts\00631l_guard_static_public_regression.cmd
```

without `--dry-run`.

## Behavior

The release check fails if the local static export that would be published is
older or smaller than the current GitHub Pages static data:

- older `coverageEnd`
- lower row count on the same coverage date
- lower ETF ready count

This keeps local validation aligned with the Pages deployment guard.

If GitHub Pages status cannot be fetched, the guard reports WARN rather than
blocking unrelated local validation.
