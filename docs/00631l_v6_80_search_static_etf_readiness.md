# 00631L lab v6.80 search static ETF readiness

v6.80 fixes the ETF search sheet data-readiness summary during fast startup.

## What changed

- Fast startup now merges static-public ETF library readiness metadata when the
  live backend does not provide ETF-wide history counts yet.
- The left-top ETF search sheet can show the same static-public readiness
  counts used by the settings data-library panel.
- Live backend operations data is still preferred when it is more complete than
  the static fallback.

## Why

The public static data export already had classified ETF history coverage, but
the search sheet could initially fall back to catalog item flags and show a much
lower completion rate. That made the ETF database look incomplete even when the
static-public index was available.

## Validation

- Repository test covers fast startup merging static ETF readiness metadata.
- Full release validation should still pass with only accepted release-check
  warnings and no failures.
