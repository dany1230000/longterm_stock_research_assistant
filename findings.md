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
