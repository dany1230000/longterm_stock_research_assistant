# 00631L lab v9.44 - public console guard

Date: 2026-06-30

## Goal

Catch public PWA runtime errors before a release is considered healthy.

## Added Check

`scripts\00631l_check_public_console.cmd`

The script opens the public GitHub Pages app at phone width, waits for the first
screen, and reads browser console output through Playwright CLI.

It passes only when the console reports:

```text
Errors: 0, Warnings: 0
```

If `npx.cmd` is not available, the script prints a WARN and exits without
blocking local validation.

## Release Check

`scripts\00631l_release_check.cmd` now includes `public_console` after the
first-load network budget check.
