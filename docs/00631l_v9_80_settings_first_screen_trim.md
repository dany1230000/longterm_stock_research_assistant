# 00631L lab v9.80 settings first screen trim

## Goal

Make the bottom-right `我的` page feel like a normal app account/settings page
instead of a system diagnostics page.

## Changes

- Removed the duplicate `我的` header card.
- Kept a single compact summary at the top with account, current ETF, local
  storage, and data mode.
- Moved version drift and deployment diagnostics behind `進階維護診斷`.
- Kept ETF data library, app store preparation, data mode, and maintenance
  panels available as expandable sections.

## Validation

- Widget tests verify the first screen shows user-facing account/preferences
  content.
- Deployment drift appears only after expanding advanced maintenance diagnostics.
- Forbidden trading wording scan remains part of the release check.
