# 00631L Lab v1.23 Release Summary

Date: 2026-06-09

## Scope

v1.23 prepares basic web app metadata for the 00631L lab.

Updated:

- `web/manifest.json`
- `web/index.html`
- Daily usage documentation

The manifest now uses:

- app name: `00631L 正二研究室`
- short name: `00631L Lab`
- start URL: `./#/00631l-lab`
- theme color: `#0F766E`

## Boundaries

This release does not add tracking, service worker hacks, TX live data, all-product expansion, notification features, or trading advice.

Live data still requires the backend proxy.

## Validation

Required validation:

```cmd
flutter analyze
flutter test
flutter build web
py -m unittest discover -s backend\tests
scripts\00631l_release_check.cmd
git diff --check
```
