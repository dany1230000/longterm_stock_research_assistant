# 00631L v16.75 Position Privacy Strip

This release clarifies the position page privacy model.

## Changes

- Adds a compact phone strip for saved positions: local-only, no login, no upload.
- Localizes the desktop position note to Chinese.
- Keeps position storage in browser local storage.
- Keeps JSON export and clear actions unchanged.

## Scope

- No account login, broker connection, cloud sync, or external upload was added.
- No data source or price calculation behavior changed.

## Validation

- Widget tests verify the compact privacy strip appears only after a local position exists.
- Existing position tests still verify input density and local-only controls.
