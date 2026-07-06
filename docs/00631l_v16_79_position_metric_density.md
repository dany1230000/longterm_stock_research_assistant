# 00631L v16.79 position metric density

This release continues the phone-first account and position layout cleanup.

## Changes

- The saved-position metric row is shorter on phone widths.
- Metric tiles are slightly narrower so 市值、未實現損益、成本、部位比例 stay
  in one horizontal strip.
- The local-only privacy wording remains visible for saved positions.

## Scope

- No account login.
- No cloud sync for personal position data.
- No investment guidance.

## Validation

- Widget tests guard the compact position metric grid height.
- Existing local-only position tests remain in place.
