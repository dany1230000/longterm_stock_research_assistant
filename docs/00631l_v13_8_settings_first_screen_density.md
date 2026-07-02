# 00631L v13.8 settings first-screen density

## Goal

Make the `我的` page feel like a user settings page instead of a system
diagnostics page on phones.

## Changes

- The first screen now focuses on account, appearance, selected ETF, and
  local-position preferences.
- ETF database readiness, comparison capability, gap details, backend
  diagnostics, and app-store preparation now live under `進階設定`.
- The preference cards remain in a compact two-column phone layout without text
  overflow.

## Validation

- Updated settings widget tests so technical diagnostics are only visible after
  expanding `進階設定`.
- Kept backend-error copy user-facing and short on the first screen.
