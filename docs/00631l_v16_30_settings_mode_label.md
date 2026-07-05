# 00631L v16.30 Settings Mode Label

This patch keeps the account/settings tab focused on everyday use.

Changes:

- The first settings card now shows friendly mode labels such as `Live 連線`,
  `公開靜態模式`, or `示範模式`.
- Compact phone copy now describes what the user can do instead of exposing
  internal mode names.
- Technical source labels remain available in the advanced settings panels.

Scope:

- No data fetching changes.
- No TX live changes.
- No investment guidance.

Validation:

- Widget coverage checks the compact settings first screen does not expose
  `mock_default` or `static_public`.
