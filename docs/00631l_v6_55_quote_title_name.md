# 00631L v6.55 quote title name

v6.55 cleans up the quote header title.

## What changed

- If 00631L price history only reports the code as its name, the quote header now falls back to `元大台灣50正2`.
- The quote header no longer renders `00631L 00631L`.

## Data behavior

- This is a display fallback only.
- Price, NAV, history, holdings, and calculation behavior are unchanged.
- Selected non-00631L ETFs still use their own imported history or catalog names.

## Validation focus

- Widget coverage verifies the duplicated quote title is gone and the 00631L display name is shown.
