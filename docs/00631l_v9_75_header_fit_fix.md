# ETF lab v9.75 header fit fix

v9.75 fixes a mobile header fit regression introduced while making the symbol
search entry more obvious.

## What changed

- The top-left symbol pill keeps the larger code, search icon, and down arrow.
- The extra text inside the pill was removed so the `ETF 研究室` title can fit
  on phone width.
- The existing search sheet and ETF switching behavior are unchanged.

## Verification

- Widget tests confirm the pill still exposes search and down-arrow icons and
  opens the ETF/stock search sheet.
- Public screenshot verification should show the title without truncation.
