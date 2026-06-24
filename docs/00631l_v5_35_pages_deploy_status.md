# 00631L lab v5.35 Pages deploy status check

## Scope

v5.35 adds a GitHub Pages deployment-status check. It complements the v5.34
public Pages smoke check by looking at the GitHub Pages settings and the latest
`deploy_web.yml` workflow run through the public GitHub API.

## Changes

- Added `scripts\00631l_check_pages_deploy.cmd`.
- Added `backend/scripts/check_pages_deploy_status_00631l.py`.
- Added Pages deployment status to `scripts\00631l_release_check.cmd`.
- Added backend tests for success, workflow warning, strict workflow failure,
  and GitHub API unavailable states.
- Updated backend release metadata to `00631l-lab-v5.35-pages-deploy-status`.

## Operational Notes

The script is intentionally conservative:

- GitHub API or network unavailability is WARN, not FAIL.
- A failed latest workflow run is WARN by default, because local release checks
  may be running before a new push has deployed.
- Use `--strict-workflow` when checking a finished public deployment and you
  want a failed workflow conclusion to return FAIL.
- The public Pages smoke check still fails when the deployed app payload or
  static data contract is invalid.

## Validation

Run:

```cmd
scripts\00631l_check_pages_deploy.cmd
flutter analyze
flutter test
flutter build web
py -m unittest discover -s backend\tests
scripts\00631l_release_check.cmd
git diff --check
```
