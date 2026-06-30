# 00631L lab v9.57 - post-deploy resolved warnings

## Goal

v9.56 correctly refreshed public data after a deploy, but the final command could
still report `WARN` because the first deploy-wait sample saw stale data or the
maintenance preflight reported a temporary operational warning. v9.57 keeps
those early signals visible while making the final result match the repaired
data state.

## Behavior

`scripts\00631l_public_post_deploy_refresh.cmd` now returns `PASS` when:

- the release marker matches the expected backend release,
- there are no hard failures,
- final public/local/static freshness is `PASS`, and
- remaining warnings came from deploy wait, remote maintenance, or targeted gap
  batch preflight steps that were resolved by the final freshness check.

Resolved warnings move to:

```json
summary.resolvedWarnings
```

If gap discovery itself fails, or final freshness is not `PASS`, the command
still returns `WARN` or `FAIL`.

## Why it matters

The daily maintenance flow can now distinguish between:

- data still needing attention, and
- data already repaired during the post-deploy refresh command.

This keeps the public backend check shorter and easier to act on without hiding
the original deploy-time condition.
