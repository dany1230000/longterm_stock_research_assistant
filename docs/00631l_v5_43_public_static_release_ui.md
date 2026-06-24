# 00631L lab v5.43 public static release UI

v5.43 surfaces the GitHub Pages static release marker inside the PWA.

## Changes

- Static repository now reads `00631l-static-data/release.json`.
- Operations status carries:
  - static release app version
  - release tag
  - commit SHA
  - build time
- Settings shows `public static release` when static public data is active.

This helps mobile users confirm which public static bundle is currently served
without opening command-line tools. Live intraday NAV still requires a backend.
