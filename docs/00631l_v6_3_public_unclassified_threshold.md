# 00631L lab v6.3 public unclassified gap threshold

v6.3 adds an optional public static-data check threshold for remaining
unclassified ETF gaps.

## What Changed

`scripts\00631l_check_public_static_data.cmd` now accepts:

```cmd
scripts\00631l_check_public_static_data.cmd --max-unclassified-gap 0
```

When the public static data still has more unclassified ETF gaps than the target,
the command returns WARN with `failures=[]`.

## Why

After v6.2, the public static export showed only two remaining `not_saved` ETF
history gaps. A direct threshold makes it easy to confirm when the public
maintenance pipeline has classified all catalog gaps.

## Boundary

This is a maintenance check only. It does not change historical price rows or
mark unavailable ETF data as ready.
