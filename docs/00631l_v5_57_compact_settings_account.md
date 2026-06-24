# 00631L lab v5.57 compact settings/account

Release tag: `00631l-lab-v5.57-compact-settings-account`

v5.57 makes the bottom-right settings page easier to use as an app account and
preferences area.

## What changed

- The first settings screen now focuses on daily-use items:
  - account requirement
  - local-only position storage
  - theme preference
  - selected ETF
  - frontend data mode
- ETF data-library readiness and comparison capability moved into a compact
  `ETF 資料與比較能力` expander.
- App store preparation remains available, but it is no longer part of the
  first visible block.
- Backend, reports, export, backup, public deployment, and data-path diagnostics
  remain in `進階維護診斷`.

## Boundaries

- This release does not change data sources.
- It does not add TX live behavior.
- It does not expand the app into full all-ETF research pages.
- It does not add trading guidance. The UI remains a data-status and research
  tool.

## Validation

Run:

```cmd
flutter analyze
flutter test
flutter build web
py -m unittest discover -s backend\tests
scripts\00631l_release_check.cmd
git diff --check
```
