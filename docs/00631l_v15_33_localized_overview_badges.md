# 00631L lab v15.33 localized overview badges

This release removes raw backend-style wording from the overview fallback UI.

## Changes

- Holdings unavailable badges now use app-facing labels such as `錯誤` or
  `不可用` instead of raw status strings.
- The change is limited to display text; source status values remain unchanged
  in models and repositories.

## Validation

- Widget coverage verifies the compact unavailable holdings row no longer
  renders raw `error` text.
- Release check still scans forbidden wording and validates source labels.
