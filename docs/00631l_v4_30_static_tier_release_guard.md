# 00631L v4.30 static tier release guard

v4.30 adds a release-check guard for static-public ETF history coverage tiers.

## Changes

- `scripts\00631l_release_check.cmd` now checks the `static_public_data` summary line.
- If static ETF history is ready but tier metadata is unavailable, release check fails instead of silently accepting the missing status detail.
- Static data without ETF history remains allowed to report unavailable tiers when `etfReady=0`.
- The guard protects the maintenance log output added in v4.28 and the legacy fallback added in v4.29.

## Why

ETF comparison and search readiness depend on clear coverage labels. The release
check should catch regressions where the data exists but the status summary no
longer exposes long-term/recent/unavailable/error tier counts.

## Scope

- No data import behavior changed.
- No generated static data is committed.
- The guard is a validation improvement only.
