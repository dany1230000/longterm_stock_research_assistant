# 00631L lab v15.22 overview first-screen guard

This release adds a phone-first layout guard for the overview page.

## Changes

- Compact overview spacing is slightly tighter on phone width.
- Widget coverage now checks that the market stack, AI glance, holdings digest,
  and bottom navigation fit as a coherent first screen.
- The overview still keeps advanced data outside the phone first screen.

## Validation

- The phone overview test measures actual widget positions and heights.
- No repository, parser, backend, data-source, or analysis behavior changed.
