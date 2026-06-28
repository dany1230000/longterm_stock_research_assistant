# 00631L lab v6.85 ETF gap reason labels

## What changed

- User-facing ETF gap reason labels now use readable Chinese wording.
- Raw API/model keys such as `official_empty`, `source_error`, and `not_saved`
  remain unchanged for data contracts and tests.
- The settings gap-detail panel now shows labels such as:
  - `官方無資料`
  - `來源錯誤`
  - `尚未匯入`
  - `資料不足`
  - `驗證異常`

## Data rules

- This is a UI wording change only.
- Missing ETF histories are still not used for history, backtest, comparison,
  or analysis calculations.
- Static public data and live proxy source labels remain truthful.
