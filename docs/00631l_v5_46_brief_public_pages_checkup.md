# 00631L lab v5.46 brief public Pages checkup

v5.46 makes the public phone-app checkup shorter for daily use.

## Changes

- `scripts\00631l_public_pages_checkup.cmd` now supports `--summary-only`.
- Summary mode keeps:
  - public URL
  - static row count and coverage
  - release marker version, tag, and commit SHA
  - public Pages smoke status
  - GitHub Pages workflow status when checked
  - warnings, failures, and action items
- Summary mode omits the full nested public Pages and workflow payloads.
- `scripts\00631l_release_check.cmd` now uses this compact checkup mode.

## Daily Command

```cmd
scripts\00631l_public_pages_checkup.cmd --skip-github-api --summary-only
```

Run without `--summary-only` only when debugging the full public smoke or
workflow payload.
