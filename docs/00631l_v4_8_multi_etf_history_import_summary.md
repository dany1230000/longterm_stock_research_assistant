# 00631L lab v4.8 multi-ETF history import summary

v4.8 adds the first verified data pipeline for importing other ETF price
history. It is a backend/data foundation for future ETF comparison.

## Completed

- Added `backend/app/etf_price_history.py`.
- Added `scripts\00631l_import_etf_price_history.cmd`.
- Added backend endpoints:
  - `GET /api/etf/history/status`
  - `GET /api/etf/history/price?code=0050`
  - `POST /api/etf/history/update?codes=0050,006208,00878`
- Stores each ETF in ignored local files under `backend/data/etf_price_history`.
- Uses TWSE `STOCK_DAY` with the requested ETF code.
- Does not apply the 00631L split adjustment to other ETFs.

## Daily Use

Default import set:

```cmd
scripts\00631l_import_etf_price_history.cmd
```

Specific codes:

```cmd
scripts\00631l_import_etf_price_history.cmd --codes 0050,006208,00878 --start-date 2019-01-01
```

Catalog-driven sample:

```cmd
scripts\00631l_import_etf_price_history.cmd --from-catalog --limit 20 --start-date 2024-01-01
```

Status:

```cmd
scripts\00631l_import_etf_price_history.cmd --status-only
```

## Limits

- This release imports selected ETF price history only.
- It does not add a full ETF comparison UI yet.
- It does not infer missing history.
- It does not change 00631L holdings or intraday NAV logic.
