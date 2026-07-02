# 00631L v13.7 loading shell density

## Goal

Reduce the visual weight of the first loading screen so public PWA startup feels
closer to a market app and less like a debug wait page.

## Changes

- The loading shell uses tighter outer padding.
- The status strip text is shorter and describes the public/static/backend
  loading path.
- The quote skeleton and section skeleton use smaller bars and less vertical
  spacing.

## Validation

- Updated loading-shell widget tests for the new copy.
- Added height guards for the quote skeleton and section skeleton.
