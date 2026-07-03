# 00631L v15.52 history date controls

This release tightens the phone history/backtest date controls.

## Changed

- The compact `最近 1 年 / 最近 3 年 / 全部資料` chips now fit in one phone row.
- Start and end date controls use less vertical padding on phone width.
- The history range widget test now checks that all range chips stay inside the visible panel.

## Design intent

The history page should show date range, chart, and backtest context together without forcing the user to scroll past a tall control panel.

## Verification

- `flutter test test\etf_00631l_widget_test.dart --name "history range context wraps on phone width"`
- Full release validation remains required before tagging.
