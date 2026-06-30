# 00631L lab v9.45 - marker-first Pages wait

Date: 2026-06-30

## Goal

Avoid noisy GitHub API rate-limit output during post-push public deployment
verification.

## Change

`scripts\00631l_wait_pages_deploy.cmd` now defaults to `public-marker` mode.

That mode checks the public GitHub Pages `release.json` marker and does not
call the GitHub Actions API. It is the preferred post-push check:

```cmd
scripts\00631l_wait_pages_deploy.cmd --expected-sha <commit-sha>
```

The older workflow API behavior is still available when needed:

```cmd
scripts\00631l_wait_pages_deploy.cmd --mode github-api --expected-sha <commit-sha>
```

## Why

The public release marker proves that the phone PWA is serving the expected
static bundle. It is also less noisy than unauthenticated GitHub API polling.

## Validation

Release check still runs `scripts\00631l_wait_pages_deploy.cmd --dry-run`; the
dry run now reports `mode=public-marker`.
