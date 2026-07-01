# 00631L lab v9.86 position first screen density

## Goal

Make the position page easier to scan on mobile by keeping the first screen
focused on the account estimate instead of long setup text.

## Changes

- Changed the position card title to the selected ETF code plus `持倉`.
- Reduced the input status row to a compact line with local-only storage and
  quote source.
- Kept the main metrics focused on market value, unrealized P/L, and position
  weight.
- Shortened the empty-state copy while preserving the local-only data notice.

## Validation

- Widget tests verify the compact position card, local-only controls, source
  chips, and phone-width metric layout.
- Position calculations, storage, JSON export, and clear behavior were not
  changed.
