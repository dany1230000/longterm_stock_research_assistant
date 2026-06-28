# 00631L lab v6.18 Pages release tag polling

v6.18 changes the GitHub Pages release metadata fix from tag-ref deployment to
main-branch deployment with tag polling.

## What changed

- Pages deployment stays on the `main` workflow path.
- The workflow waits briefly for a matching `00631l-lab-v*` tag on `HEAD`.
- If the tag appears, static export receives:
  - `00631L_BACKEND_RELEASE_TAG`
  - `00631L_BACKEND_APP_VERSION`
- If no tag appears, static export uses `untagged-<git-sha>` instead of stale
  default metadata.

## Why this matters

GitHub Pages environments may reject tag-ref deployments. Polling for the tag in
the main workflow matches the local release flow, where the commit is pushed
first and the annotated tag follows shortly after.
