# 00631L v16.35 loading source labels

This release polishes the first loading screen.

## What changed

- The loading source strip now uses `歷`, `盤`, and `解讀`.
- The old `HIS` and `LIVE` labels no longer appear on the first loading screen.
- The value text still explains what is loading: public history, backend check,
  and analysis summary.

## Why

When the public app is waking up the backend, the first screen should still feel
like a finished product. Short Chinese labels keep the loading state compact
without exposing internal source codes as the primary UI.
