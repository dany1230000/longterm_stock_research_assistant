# 00631L v7.0 Loading Skeleton Labels

## Scope

This release cleans up the first loading state. The loading metric skeleton no
longer shows `LIVE / DAY / HIS / AI` as the first visible labels.

## Behavior

- Loading metric labels are now `盤中`, `內容物`, `歷史`, and `分析`.
- The bottom navigation still keeps `AI` as a tab label.
- This change does not affect repository selection, static data, live proxy, or
  backend behavior.

## Validation

- Widget coverage confirms the loading grid uses the user-facing labels.
- The same coverage confirms the old technical labels are absent inside the
  loading metric grid.
