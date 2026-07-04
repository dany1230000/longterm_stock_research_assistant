# 00631L v15.78 AI Compact Decision Rail

## Scope

v15.78 improves the phone AI page first screen so it reads more like daily ETF
data interpretation instead of a long status dump.

## Changes

- Adds a compact three-column AI rail on phone width: `資料`, `偏離`, and `操作`.
- Keeps full AI detail collapsed while showing the key daily interpretation
  before the expansion panel.
- Shortens program actions to app-operation labels such as `daily cycle`,
  `.env`, or `檢查後端`.

## Notes

- AI remains rule-based and does not call an external LLM.
- The output describes data state and price deviation only; it is not
  investment guidance.
