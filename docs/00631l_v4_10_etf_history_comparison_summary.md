# 00631L lab v4.10 ETF history comparison summary

v4.10 turns the imported ETF price histories into a visible comparison block inside the history/backtest page.

## Completed

- Added a frontend comparison provider that loads the selected ETF plus the prepared comparison set:
  - `00631L`
  - `0050`
  - `006208`
  - `00878`
  - `00919`
- The history/backtest page now shows an `ETF 歷史比較` section.
- The comparison uses the selected ETF's latest one-year window by default.
- The comparison table shows:
  - code
  - name
  - period return
  - annualized return
  - max drawdown
  - annualized volatility
  - latest close
  - row count
  - source status
- The top-left ETF selector remains the main ETF entry. The bottom navigation does not add a separate ETF tab.

## Data Boundaries

- Comparison data is historical price data from proxy/static/mock repositories.
- `00631L` holdings and intraday NAV remain 00631L-specific.
- Static public mode can compare imported ETF histories without a live backend.
- Live intraday data still requires the backend proxy.
- Comparison output is historical observation only and is not a future forecast.

## Validation

- Widget tests cover selecting `0050` and rendering the ETF history comparison block.
- Release check includes this summary file.
