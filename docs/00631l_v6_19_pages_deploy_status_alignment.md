# 00631L lab v6.19 Pages deploy status alignment

v6.19 aligns the local Pages deployment checker with the v6.18 release metadata
flow.

## What changed

- `scripts\00631l_check_pages_deploy.cmd` now passes the expected git SHA into
  the public Pages smoke check.
- The deploy checker includes public `release.json` metadata in its summary.
- If the latest workflow run is stale or cancelled but the public release marker
  already matches the expected HEAD, the workflow warning is downgraded to pass.
- If the public marker does not match the expected HEAD, the checker still
  reports a warning.

## Why this matters

GitHub Pages deployment status can lag behind the actual published static data
when release tags are pushed immediately after the main branch. The public
`release.json` marker is the user-visible deployment signal, so it should be the
deciding signal for release validation once it matches the expected commit.
