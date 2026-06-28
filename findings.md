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
- v6.61 public mobile inspection confirmed summary labels improved when values
  are available, but invalid holdings snapshots can still render a 0% official
  exposure strip beside the price chart.
- v6.62 public mobile inspection confirmed the zero-value exposure strip is
  gone. The next visible issue is that DAY/LIVE summary chips can still show
  background-sync wording even when a specific source already reports
  error/unavailable.
- v6.63 public mobile inspection confirmed the DAY chip now shows
  unavailable/error. The holdings-status card still used technical
  `live backend` / `official holdings` wording and showed a placeholder date
  for an unusable snapshot.
- v6.64 public mobile inspection confirmed holdings-unavailable wording is now
  product-facing. Remaining first-screen polish: pending summary values still
  used English loading words that read like debug state.
- v6.65 public mobile inspection confirmed live data can populate the first
  screen cleanly. The chart panel still showed a long official-exposure strip
  under the chart on phone width, duplicating the holdings digest and clipping
  the right-side cash text.
- v6.66 public mobile inspection confirmed the exposure strip is gone. The
  next largest mobile issue is the history/backtest first screen: date controls
  and duplicated `00631L` badges appear before the user reaches the chart.
- v6.67 public mobile inspection confirmed chart-first ordering, but the
  history/backtest page still spends too much height on top summary tiles and
  data-quality details before the chart is fully visible.
- v6.69 public position-page inspection confirmed the account metric layout now
  fits, but the unrealized result still displayed raw `unavailable` text for a
  missing percentage.
- v6.70 settings-page public inspection showed the account tab still surfaced
  backend persistence warnings and readiness labels on the first screen. The
  diagnostics are useful, but they should live below the account/preferences
  summary unless the user opens advanced status.
- v6.71 public settings-page inspection confirmed the first-screen diagnostics
  moved down, but the data-mode tile still used the backend error label as a
  caption. That caption should describe static-data availability on the first
  screen and leave backend error details in advanced diagnostics.
- v6.72 public history/backtest inspection showed the chart still had duplicate
  in-chart x-axis dates plus the below-chart date strip. On phone width, the
  in-chart dates crowd the y-axis labels, so the below-chart strip should be
  the single range context.
- v6.73 public history/backtest inspection confirmed the duplicate chart-axis
  dates are gone, but the current-range context cards could still truncate on
  phone width. Adding phone-width widget coverage also exposed compact mini
  chart cards that were too short for the date strip and touch detail.
- v6.74 AI-page public inspection showed the page had a strong daily
  interpretation card, but then immediately repeated a broad status quick-view
  before the written summary. The AI tab should be answer-first, with source
  grids and matrices behind advanced detail.
- v6.75 position-page review showed the first card repeated local-only context
  already shown by the account summary and action bar. Removing that title card
  brings account status and input controls higher on phone screens.
- v6.76 data status review showed local ETF price-history status could report
  completionGap=116 while gapReasonCounts only explained 20 rows. The remaining
  96 rows are catalog-only symbols without local history rows and should be
  classified as `not_saved`, not left implicit.
- Position-page mobile inspection shows the account summary's horizontal fixed
  metric strip clips the `未實現損益` tile on phone width.

- v6.77 public static-data verification confirms every missing ETF history is now classified: public data has 231 usable histories out of 347 catalog rows, with 96 official-empty and 20 source-error gaps, and no unclassified gap.
- v6.78 settings review showed the app already had the correct gap counts but needed a plain-language summary before the detailed maintenance metrics.

- v6.79 public settings inspection showed the account/settings first screen was still too tall because the overview grid consumed most of the phone viewport. A compact badge summary is a better first-screen shape; detailed diagnostics should stay below.
- v6.80 search-sheet inspection found the ETF database summary could show low
  catalog-only readiness counts during fast startup even though the
  static-public ETF price-history index was available. Repository-level merging
  is the correct fix because the search sheet, settings panel, and fast startup
  all need the same source-truth metadata.
- v6.81 search-sheet review found the corrected global readiness summary was
  followed by English internal result chips. Current-result chips need explicit
  local context so users do not confuse them with full database coverage.
- v6.82 search-sheet review found the expanded database detail still used
  internal labels (`catalog`, `history source`, `long-term`, `recent`). These
  belong in code/tests, not the public app surface.
- v6.83 search-sheet review found the expanded detail could show a loaded-list
  count and a larger readiness denominator together. The data is expected, but
  labels should explicitly say loaded list versus full denominator.
- v6.84 investigation found public GitHub Pages static data is correctly
  classified with 231 ready histories out of 347 ETF catalog rows and zero
  unclassified gaps. The stale local ignored static folder still reflected
  older v5.96 evidence because local Pages builds skipped public attempt
  restore by default, while GitHub Actions already restored it.
- v6.85 UI review found the settings gap-detail panel still exposed internal
  reason keys (`official_empty`, `source_error`, `not_saved`) directly to users.
  The raw keys are useful for data contracts, but public UI should show readable
  status labels.
- v6.86 public settings review found several non-contract UI surfaces still
  displayed internal status wording (`local-only`, `rule_based`, `available`,
  `comparison-ready`). These labels are useful for implementation but should be
  mapped before they reach the primary app UI.
- v6.87 public overview screenshot showed the first-screen DAY summary still
  displayed raw `cached`. The overview summary should use the same display-label
  mapping as settings and selected ETF surfaces.
- v6.88 public mobile review showed the official holdings `MIX` tile was
  technically correct but not readable: stock, futures, and cash/margin needed
  separate visual rows instead of one combined value.
- v6.89 public AI-page review showed visible implementation wording in the
  primary analysis card. Analysis output should describe data state in product
  language even when the underlying provider remains rule-based.
- v6.90 public static check found `etfCatalogRows=343` while ETF price-history
  status still covered 347 symbols. The manifest warning showed a transient
  TWSE catalog HTTP 502; catalog export should preserve the committed seed
  catalog instead of publishing a reduced catalog snapshot.
- v6.91 public mobile screenshots found remaining raw implementation phrases on
  first-screen surfaces: the history header displayed `static_official`, and AI
  cards still showed phrases such as `official holdings`, `live intraday NAV`,
  and `price history`.
- v6.92 follow-up screenshots and source scan found a second layer of mixed
  wording after v6.91: `official holdings` in the AI yellow summary, `完整 price
  history` under the history chart, `每日 holdings history`, and English ETF
  comparison guidance.
- v6.93 public static verification found the catalog completeness guard still
  depended on the committed seed catalog. When both TWSE catalog refresh and the
  seed were behind the price-history index, public Pages could publish 347
  history rows but only 343 catalog rows. The static exporter needs to reconcile
  catalog metadata from the history index itself before writing public files.
- v6.94 public mobile inspection found the first 5 seconds of the Pages app can
  show static fallback holdings as unavailable/error while the Render backend
  wakes up. After about 20 seconds the same page shows live/cached data. The
  first screen should describe that transient state as backend warmup.
- v6.95 public reliability pass found the frontend Pages release can advance
  while the public backend release metadata remains older. This is not the same
  as data failure: the app needs a concise deploy-sync label so users can tell
  whether live backend behavior is running the same release as the public PWA.
- v6.96 public homepage audit found a date/phase wording issue: pre-open on a
  later date could show the prior trading day's 13:31 TWSE NAV snapshot with a
  generic pre-open label. The session model needs to distinguish previous-day
  data from same-day pre-open waiting.
## v6.99 Overview Chart Header

- After v6.97 and v6.98, the one-year chart header was the remaining first-screen
  block with a technical `HIS` badge. Removing it makes the chart read more like
  a normal app section while preserving data details in expanded areas.

## v6.98 Overview Holdings Digest Badges

- The first-screen holdings digest still had code-like badges after the daily
  summary strip was cleaned up. Those badges were technically meaningful, but
  they pulled attention away from the section labels and values.
- The digest now treats Chinese labels as the primary hierarchy. Technical
  badges remain available in expanded details where dense status context is
  expected.

## v6.97 Overview Summary Chips

- The public first screen still had technical `DAY / LIVE / HIS` chips in the
  primary summary row. They were useful internally but made the app feel closer
  to diagnostics than a stock app.
- The fix keeps the same data density but moves the primary row to readable
  labels and shorter values. Technical badges remain in the expanded detail
  panel where they are less distracting.
