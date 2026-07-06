# 00631L lab v9.44 - public console guard

Date: 2026-06-30

## Goal

Catch public PWA runtime errors before a release is considered healthy.

## Added Check

`scripts\00631l_check_public_console.cmd`

The script now delegates to a non-interactive Python smoke check. It fetches
the public GitHub Pages app and required Flutter/PWA entry assets without
opening a visible browser window.

It passes only when the root page is reachable, contains the 00631L app marker,
and the required public assets respond successfully.

## Release Check

`scripts\00631l_release_check.cmd` now includes `public_console` after the
first-load network budget check.
