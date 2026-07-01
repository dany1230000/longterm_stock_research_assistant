# 00631L lab v9.61 - theme toggle clarity

## Goal

The day/night control should read like an action, not an ambiguous current
state. Users should know what happens when they tap it.

## Changes

- Light mode now shows `切換夜間`.
- Dark mode now shows `切換日間`.
- The icon follows the action: moon for switching to night, sun for switching
  to day.
- Widget tests still verify that the market palette actually changes.

## Scope

- No palette redesign.
- No data behavior change.
- No generated output committed.
