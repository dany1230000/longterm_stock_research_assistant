# 00631L historical backtest guide

The backtest section uses saved 00631L split-adjusted historical closing prices. It is a history calculator, not a future forecast.

## Data Requirement

Run the price history update before using the backtest section:

```cmd
scripts\00631l_update_price_history.cmd
```

Check local coverage without calling the network:

```cmd
scripts\00631l_update_price_history.cmd --status-only
```

The app shows coverage start, coverage end, row count, and whether the local cache is complete from the listing date. If the cache is empty, the backtest section shows an unavailable state.

TWSE raw OHLC is preserved in the price history cache. Return, drawdown, charts, CSV export, and backtest calculations use `adjustedClose`. The 2026 00631L split is normalized with a 1/22 adjustment before 2026-03-31.

## Supported Backtest Inputs

- One-time historical allocation.
- Monthly contribution.
- Start date and end date.
- Initial amount.
- Monthly amount.
- Monthly contribution day.
- Fee rate, default `0`.
- Split-adjusted closing price basis.

## Results

- Ending value.
- Total invested.
- Total return.
- Annualized return.
- Maximum drawdown.
- Annualized volatility.
- Best and worst observed day in the saved data.
- Equity curve.
- Drawdown curve.

## Safety Boundary

The section always shows:

```text
回測不代表未來表現，非買賣建議。
```

It does not select parameters, optimize schedules, forecast future values, or provide operational suggestions about the ETF.
