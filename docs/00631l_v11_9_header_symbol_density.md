# 00631L v11.9 header symbol density

## Goal

Make the top-left ETF selector and app title feel more like the primary entry
point on phone screens.

## Change

- The market top bar is slightly taller, with a larger `ETF` room title.
- The top-left ETF code/search pill is larger and easier to tap.
- Widget coverage locks the top bar height and selector touch target.

## Expected behavior

- Users can recognize the ETF selector as the place to switch symbols.
- The bottom navigation remains the only primary page navigation.
- No data logic, TX live source, or advisory wording is added.

## Verification

- Widget tests assert the top bar height and selector size.
- Existing release checks continue to scan for forbidden trading wording.
