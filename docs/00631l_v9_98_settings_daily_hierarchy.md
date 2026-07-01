# 00631L v9.98 settings daily hierarchy

## Scope

This release tightens the `我的` page hierarchy.

## Changes

- Keeps daily-use settings first: account, appearance, selected ETF, and local
  position state.
- Keeps ETF data capability, data mode, and maintenance diagnostics before App
  Store planning.
- Moves `App 上架準備` to the bottom of the settings page while keeping the
  original details available.

## Product Rule

The `我的` page should behave like an app settings/account page first. Store
release planning is useful, but it should not compete with daily-use controls.

## Validation

- Widget tests guard the new ordering.
- Full release validation keeps tests, build, release check, and forbidden
  wording scan in the loop.
