# 00631L lab v6.36 compact quote header

v6.36 reduces duplicate information at the top of the overview screen.

## Updated

- The 00631L overview quote header no longer repeats the NAV/session/history meta strip.
- The same daily context now lives in the compact `今日摘要` strip added in v6.35.
- Non-00631L selected ETF contexts can still use the quote meta strip because they do not have the 00631L daily summary.
- Widget coverage verifies that the 00631L overview hides the duplicate quote meta strip.

## Scope

- No data source, calculation, history, backtest, or AI-provider changes.
- Static public, live proxy, and mock labels remain truthful.
- Intraday NAV and official daily holdings remain separate data concepts.
