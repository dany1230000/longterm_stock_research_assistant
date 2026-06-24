# 00631L lab v5.36 Pages deploy wait helper

## Scope

v5.36 adds a wait helper for GitHub Pages deployment. After pushing a release,
the maintainer can wait for the latest `deploy_web.yml` workflow run for the
current commit and confirm that the public PWA smoke check passes.

## Changes

- Added `scripts\00631l_wait_pages_deploy.cmd`.
- Added `backend/scripts/wait_pages_deploy_00631l.py`.
- Added release-check dry-run coverage for the wait helper.
- Added backend tests for completed, still-running, retry-to-success, and dry-run
  outcomes.
- Updated backend release metadata to `00631l-lab-v5.36-pages-deploy-wait`.

## Usage

After pushing `main` and the release tag, run:

```cmd
scripts\00631l_wait_pages_deploy.cmd
```

The command polls the public GitHub Actions workflow status and the public PWA
smoke check. It returns PASS only when the expected commit has a completed,
successful Pages workflow and the public app smoke check passes.

Use `--dry-run` for release-check validation without waiting.

## Validation

Run:

```cmd
scripts\00631l_wait_pages_deploy.cmd --dry-run
flutter analyze
flutter test
flutter build web
py -m unittest discover -s backend\tests
scripts\00631l_release_check.cmd
git diff --check
```
