# 00631L lab v5.58 compact home glance

Release tag: `00631l-lab-v5.58-compact-home-glance`

v5.58 reduces the amount of operational detail shown on the overview first
screen.

## What changed

- The overview now prioritizes:
  - quote header
  - core data
  - visible one-year price chart
  - official holdings highlights
- Update-time chips and data-quality diagnostics moved into `更多資料`.
- The chart remains visible without opening a panel.
- The page still keeps source and data-quality details available for audit, but
  they no longer compete with the first-screen information hierarchy.

## Boundaries

- No data-source behavior changed.
- No TX live behavior changed.
- No new ETF research pages were added.
- No trading guidance was added.

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
