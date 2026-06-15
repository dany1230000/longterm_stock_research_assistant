# 00631L lab v4.11 ETF comparison basket summary

v4.11 expands the static/proxy ETF comparison basket and adds group filters to the history/backtest comparison view.

## Completed

- Expanded the default ETF history import basket:
  - `00631L`
  - `0050`
  - `0056`
  - `006208`
  - `00692`
  - `00713`
  - `00757`
  - `00850`
  - `00878`
  - `00881`
  - `00919`
  - `00922`
  - `00923`
  - `00929`
  - `00940`
- GitHub Pages static build imports the expanded basket before exporting static data.
- Mock fallback now includes the same representative ETF catalog and price history profiles.
- The ETF history comparison view now has filters:
  - representative
  - market-cap style
  - dividend style
  - tech theme
  - all imported

## Data Boundaries

- The basket is a practical representative set, not the full TWSE ETF universe.
- Static public mode can compare imported price histories without a live backend.
- Official holdings and intraday NAV remain 00631L-specific unless a future release adds verified sources for each ETF.
- Historical comparison describes past data only.

## Validation

- Widget tests cover selecting `0050`, rendering the comparison panel, and switching to the dividend filter.
- Release check includes this summary file.
