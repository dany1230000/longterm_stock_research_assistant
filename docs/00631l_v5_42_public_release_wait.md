# 00631L lab v5.42 public release marker wait

v5.42 adds a public-only wait command for GitHub Pages deployments. It checks
the `00631l-static-data/release.json` marker served by Pages and does not call
the GitHub Actions API.

## Command

```cmd
scripts\00631l_wait_public_release_marker.cmd --expected-sha <commit>
```

Useful options:

```cmd
scripts\00631l_wait_public_release_marker.cmd --attempts 20 --interval-seconds 15
scripts\00631l_wait_public_release_marker.cmd --dry-run
```

## Status Rules

- `PASS`: public Pages is serving the expected release marker.
- `WARN`: public Pages is usable but still serving a previous release marker.
- `FAIL`: the public app or static data smoke check failed.

This is intended for post-push validation when the GitHub API is rate-limited.
