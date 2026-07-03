# 00631L v15.63 mobile check coverage

This release broadens the focused mobile layout check.

## Changed

- `scripts\00631l_mobile_layout_check.cmd` now includes the stock-app quote
  header test.
- The same script also verifies the overview holdings digest tape with `TX`,
  `2330`, and `CASH`.

## Design intent

Recent homepage density work should stay protected by the fast mobile QA script,
not only by the full Flutter test suite.

## Verification

- `scripts\00631l_mobile_layout_check.cmd`
- `scripts\00631l_release_check.cmd`
