# 00631L v16.31 Overview Ribbon Labels

This patch makes the phone overview status ribbon read more like app UI and
less like an internal debug strip.

Changes:

- `DAY` becomes `日`.
- `NAV` becomes `盤`.
- `HIS` becomes `歷`.
- `MODE` becomes `模式`.

The values still show the same underlying data:

- official daily holdings date,
- intraday NAV time or status,
- historical row count,
- current frontend mode.

Scope:

- No data source changes.
- No TX live changes.
- No investment guidance.
