# 00631L lab v6.7 public gap release guard

v6.7 makes the public static-data release check enforce that the ETF history
library has no unclassified gaps.

## What Changed

- `scripts\00631l_release_check.cmd` now runs the public static-data check with
  `--max-unclassified-gap 0`.
- Public data can still report classified unavailable histories such as
  `official_empty` or `source_error`.
- A returned `not_saved` gap becomes a release-check warning and must be
  investigated with the missing ETF probe flow.
- The static public regression guard still fails same-release local regressions,
  but if the local ignored static export is simply older than the public Pages
  export it reports a warning and tells the maintainer to regenerate static
  data before deployment.

## Meaning

The app does not pretend every ETF has usable history. The release guard only
requires that missing histories are classified, so daily maintenance can explain
why a symbol is not ready.
