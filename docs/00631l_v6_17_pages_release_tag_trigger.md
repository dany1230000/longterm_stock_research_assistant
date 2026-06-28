# 00631L lab v6.17 Pages release tag trigger

v6.17 fixes public static release metadata when a `main` push starts before the
matching release tag is visible to GitHub Actions.

## What changed

- GitHub Pages deployment now also runs on `00631l-lab-v*` tag pushes.
- Tag-triggered Pages builds inject:
  - `00631L_BACKEND_RELEASE_TAG`
  - `00631L_BACKEND_APP_VERSION`
- Static export no longer falls back to an old configured release tag when no
  exact tag is available.
- Untagged static exports use `untagged-<git-sha>` instead of a stale release
  label.

## Why this matters

The public release marker should describe the deployed app build. A stale tag
can make public checks look current by SHA while showing an older release name.
The tag-triggered workflow lets the final release tag publish the correct
metadata after the commit and tag are both pushed.
