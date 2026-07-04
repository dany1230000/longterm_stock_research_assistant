# 00631L v15.79 Position Account Grid

## Scope

v15.79 improves the phone position page so saved holdings read more like an
account summary in a stock app.

## Changes

- Phone saved-position metrics now use a fixed 2x2 grid instead of a horizontal
  scroller.
- The compact position account card hides the extra explanatory line after a
  position is entered, keeping cost, market value, unrealized P/L, and weight
  together.
- Widget coverage now guards that the phone position metrics stay visible
  without horizontal scrolling.

## Notes

- Position data remains local-only in the browser.
- No broker login, sync, or external upload behavior was added.
