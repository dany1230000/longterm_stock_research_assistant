# v5.86 Public Status Language

## Scope

v5.86 cleans up remaining English operational status labels in the 00631L app.

Updated user-facing labels include:

- backend connection status
- backend release status
- public static release status
- public deployment persistence status
- backend-disconnected fallback guidance

The underlying source-status values are unchanged. Machine-readable labels such
as `static_public_data`, `mock`, and `error` still remain in the data model where
they are used for routing and diagnostics.

## Why

The mobile app should read like a production ETF research room, not a debug
panel. The status page now keeps the same operational details but presents them
with clearer Chinese labels.

## Validation

The existing widget and repository tests cover the changed labels and fallback
state mapping.
