# ETF Research Room Findings

## 2026-06-20

- The correct repo is `C:\dev\longterm_stock_research_assistant`; do not edit `C:\新增資料夾`.
- Current HEAD before v4.16 work: `3d441e6` (`00631l-lab-v4.15-tx-stale-status`).
- The public backend now marks old TAIFEX TX quotes as `stale` when `isStale=true`.
- The homepage sparkline used a short recent window and disabled chart touch behavior. This made the date context too weak for a stock-app style first screen.
- Existing comparison chart code already has `LineTouchData` and date-axis logic that can be reused for the homepage chart.
- ETF price-history gap details are maintenance/status evidence only. The app
  should show them in settings for data-quality inspection, but unavailable gap
  rows must stay out of history, backtest, comparison, and AI performance data.
- v6.13 reason filters do not change the underlying ETF history eligibility.
  They only narrow the visible maintenance rows in the settings panel.
- v6.25 Playwright inspection found the first visible oversized loading card is
  the pre-Flutter `web/index.html` shell. Improving the public perceived load
  requires changing that HTML shell, not only Flutter loading widgets.
- v6.55 public mobile inspection found that live-proxy fast startup could show
  the overview trend card as `unavailable` even while GitHub Pages static
  history was ready. The fix belongs in repository-level fast-data merging so
  widgets keep truthful source labels without duplicating fallback logic.
- v6.56 public mobile inspection confirmed the chart is visible from static
  history, but also revealed an invalid holdings snapshot could still render
  a digest with zero/unavailable values. Holdings digest needs its own usable
  snapshot guard.
- v6.57 public mobile inspection showed the 00631L quote card title can still
  truncate because it uses the long fund registration name. The quote card
  should use the short product name while preserving the full name elsewhere.
- v6.58 public mobile inspection confirmed the short quote title fits, but the
  background-refresh banner still consumes first-screen space even when quote,
  chart, and official holdings context are already visible.
- v6.59 public mobile inspection confirmed the banner is gone, but the quote
  premium/discount box can still show a catalog/static reference value while
  the same card says intraday data is unavailable. The 00631L quote card should
  use intraday NAV premium/discount only.
- v6.60 public mobile inspection confirmed the premium source guard, and showed
  the DAY/LIVE/HIS row still uses generic syncing/checking text even when date
  and time values are already available.
