# 00631L Lab v5.65 Concise Static Pages Build

v5.65 makes GitHub Pages and local static build logs shorter.

The v5.64 seed-catalog import fixed ETF coverage, but a full local build printed
thousands of lines of per-symbol JSON. That made daily validation hard to scan.
The import and export CLIs now support compact normal-run output through
`--summary-only`.

## What Changed

- Selected ETF import in GitHub Actions uses `--summary-only`.
- Broad seed-catalog import in GitHub Actions uses `--summary-only`.
- Static export in GitHub Actions uses `--summary-only`.
- `scripts\00631l_build_pages_static.cmd` uses compact output for all import
  and export steps.
- Tests cover compact import/export payloads and the Pages pipeline flags.

## Expected Output

The scripts still print one JSON summary and one `[summary]` line. They keep:

- status
- row count
- ETF ready count
- coverage
- warning count
- failure count
- a small sample of warnings or items

They no longer print every ETF item in normal Pages build logs.
