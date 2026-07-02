# ETF 研究室 · 00631L 正二研究室

## 00631L lab status

Latest mobile UI polish:

- v15.10 keeps the phone overview AI card focused on the daily summary. Program
  operation details stay in the AI tab instead of taking space on the first
  screen.

- v15.9 cleans up the phone overview sparkline. Compact mode now keeps the
  selected date/value summary above the chart and only shows the start/end date
  axis below it.

- v15.8 adds a compact rule-based daily insight to the phone AI tab. The first
  screen now summarizes holdings, premium/discount state, and historical sample
  count before the detailed AI panels.

- v15.7 tightens the phone history/backtest date-range summary. Narrow metric
  chips now avoid long `start - end` strings while the editable start/end date
  cards remain visible.

- v15.6 restores a concise holdings digest to the phone overview. TX, TSMC,
  and exposure structure are visible on the first screen without opening the
  history or settings tabs.

- v15.5 tightens the left-top symbol search result list on phones. ETF code,
  name, readiness, and price stay in one cleaner result row while details stay
  available behind the row detail toggle.

- v15.4 tightens the backtest quick result strip on phones. Technical source
  badges move out of the compact result row while strategy and non-advice
  context remain visible.

- v15.3 tightens the settings first screen on phones. The account-style summary
  now keeps only essential mode badges and one data-mode line before the
  preference cards.

- v15.2 tightens the overview chart touch detail on phones. Date and value
  remain visible after tapping the chart, but the detail row uses a smaller
  market-app style footprint.

- v15.1 tightens the AI first screen on phones. DAY / LIVE / HOLD facts now
  stay in one compact row, keeping the daily interpretation and program action
  visible sooner.

- v15.0 tightens the empty position screen on phones. The local-only input
  fields and save action now live in one compact card, so the position tab no
  longer starts with a repeated full-width action card when no position is
  saved.

- v14.9 tightens history chart cards. Phone width now uses content-sized chart
  cards instead of fixed-height grid cells, removing blank space after chart
  touch detail.

- v14.8 cleans up the history/backtest title strip. ETF codes are no longer
  repeated when the history source name is the same as the code.

- v14.7 improves the loading state. The public app now shows a market-stack
  skeleton with quote, premium/discount, chart, date chips, and data ribbon
  placeholders while repositories are still loading.

- v14.6 tightens the overview top density. The top market bar, symbol search
  pill, premium/discount box, one-year chart, and overview AI glance use less
  vertical space on phone screens while keeping the chart visible.

- v14.5 tightens ETF comparison guidance. The history/backtest comparison area
  now relies on the compact selected-basket summary instead of repeating
  guidance, mode, and selected-code text blocks.

- v14.4 tightens the history/backtest page. Holdings history remains available,
  but it now lives under `內容物歷史` so the first screen stays focused on date
  range, price chart, and backtest context.

- v14.3 tightens the overview AI glance on phones. The home screen now shows a
  two-line AI summary/action card with `非買賣建議`, while the full AI page keeps
  the complete daily interpretation.

- v14.2 tightens the AI page first screen on phones. The compact view now keeps
  only today's conclusion, data-time facts, the primary program action, and the
  `AI 資料細節` entry visible; the four-tile daily decision strip moves into the
  expanded detail area on phone width.

- v14.1 tightens the position page. The first screen focuses on account summary,
  shares, average cost, and save/update; JSON export and clear-local-data tools
  move under `持倉工具` after a position exists.

- v14.0 tightens the overview chart area. The one-year chart remains visible on
  the home screen, but compact phones use a shorter chart and `起 / 中 / 迄`
  axis labels while touch detail keeps the full date and value.

- v13.9 tightens the history/backtest ETF comparison area. The first screen now
  shows the selected-basket summary and chart entry first; filter chips, manual
  ETF selection, and quick actions live under `選擇比較 ETF`.

- v13.8 tightens the `我的` page first screen. Account, appearance, selected
  ETF, and local-position preferences stay visible; ETF database readiness,
  comparison details, and maintenance diagnostics move under `進階設定`.

- v13.7 tightens the public loading shell. Startup now uses shorter status copy
  and smaller quote/section skeleton cards before the first market data appears.

- v13.6 tightens history/backtest chart date labels. Phone axis chips use short
  `起 / 中 / 迄` labels with `yy/MM/dd`, while touch detail keeps full dates.

- v13.5 tightens the overview sparkline header on phones. The one-year chart
  now uses one compact row for title, latest price, and one-year change, while
  the date context stays on the chart axis.

- v13.4 tightens the phone position input flow. Empty local-position state now
  keeps shares and average cost in one compact row, with optional fields
  available after a position exists or on wider layouts.

- v13.3 tightens the phone AI page. Compact width now opens with the daily
  interpretation, source/readiness badges, and primary program action; long AI
  bullets and the conclusion card move into the detail panel.

- v13.2 tightens the phone position page. The empty local-position first screen
  now focuses on shares, average cost, and save; the local-only note stays
  available after a position exists or on wider layouts.

- v13.1 tightens the history/backtest top strip on phones. Coverage remains in
  the date-range card, while the top strip focuses on symbol, source, latest
  value, row count, and adjustment context.

- v13.0 tightens the embedded overview quote header. The full ETF name stays in
  the app header and top-left symbol selector, while the market stack focuses on
  price, source status, premium/discount, and chart.

- v12.9 replaces the separate phone daily-summary and holdings-digest rows with
  one compact data ribbon. The overview first screen now prioritizes quote,
  chart, DAY, NAV, TX, 2330, and history row count in one market stack.

- v12.8 tightens the overview AI glance card. It keeps the same short summary
  and program action, but uses less vertical space on the phone first screen.

- v12.7 cleans up the left-top ETF search results. Result rows now keep only
  code, name, type, ready state, and price; coverage metadata moves under
  `更多資料`.

- v12.6 tightens the `我的` page preference grid. Account, appearance, current
  ETF, and local-position cards use a flatter 2x2 phone layout while advanced
  diagnostics stay behind details.

- v12.5 moves the AI daily interpretation out of the detail expansion. The AI
  page now shows today's data readout, price-divergence interpretation,
  historical context, and program action before advanced details.

- v12.4 tightens the phone position page. Empty local-position flow now keeps
  the save action primary, while source diagnostics and secondary actions stop
  competing with the first input screen.

- v12.3 tightens the history/backtest date controls on phones. Preset ranges
  stay in one short row, start/end date buttons drop lower-priority captions on
  compact width, and the chart appears sooner.

- v12.2 fixes sparse history charts. If a selected date range has only one
  valid price point, the chart now shows a clear sparse-data state with the
  date/value instead of a blank-looking frame.

- v12.1 adds a compact overview AI glance card, using the lower phone first
  screen for one short interpretation line and one program action without
  turning the overview into the full AI page.

- v12.0 folds the official holdings digest into the overview market stack, so
  quote, one-year chart, data time, and daily holdings context read as one
  compact first-screen block.

- v11.9 makes the top-left ETF selector and app title proportion clearer on
  phones. The selector is easier to tap and remains the single place to switch
  ETF symbols.

- v11.8 makes the AI page lead with today's interpretation. The first-screen
  facts now show DAY, LIVE, and HOLD context, with HOLD focused on TX and TSMC
  weights from official holdings.

- v11.7 trims the phone position entry flow. The share and average-cost fields
  stay visible, while duplicate local-only guidance is hidden on compact width.

- v11.6 shortens the history/backtest range controls on phones. The latest
  one-year range remains the default, start/end date buttons stay visible, and
  duplicate inline date labels are hidden on compact width.

- v11.5 shortens the phone quote chart stack. The one-year chart remains
  visible, while the date axis and touch-detail row use compact spacing so the
  first screen reaches holdings context sooner.

- v11.4 removes the secondary overview `更多資料` expansion from phone width,
  keeping the first screen focused on quote, chart, data time, and official
  holdings digest. Wider layouts still keep the expansion.

- v11.3 reuses in-memory static fallback data after the first public load, so
  later live warmup attempts do not re-fetch the same static preview/status
  JSON when it is already available.

- v11.2 reduces public first-load refresh pressure. Live-core warmup now makes
  only two short attempts before returning to the normal market-session refresh
  interval, so static/public fallback pages do not keep reloading heavy data.

- v11.1 compacts the AI first screen by replacing the paragraph-style source
  note with source/readiness/disclaimer badges.

- v11.0 starts the next density pass: position source detail is no longer
  duplicated on the first screen, position actions are narrower, and settings
  cards use tighter mobile proportions.

- v10.9 moves the overview one-year chart directly under the quote header and
  pushes the daily data ticker below the chart, so the first screen reads like
  a market page instead of a status dashboard.

- v10.8 shortens the ETF comparison first screen by moving the basket consistency
  explanation behind `組合檢查`, leaving selection chips, current basket, data
  readiness, and chart expansion as the primary flow.

- v10.7 tightens the overview market stack again by shortening the embedded
  quote padding and daily data ticker item widths, keeping the one-year chart
  visible sooner on phone screens.

- v10.6 cleans up the left-top ETF search sheet: result rows now focus on ETF
  name, price, and history readiness, while price-basis, split-adjustment, and
  gap details move under `更多資料`.

- v10.5 compresses the history/backtest first screen: the large repeated
  history card is replaced by a compact heading, the top strip now shows latest
  date/close, row count, source, and adjustment status, and date controls remain
  directly above charts and backtest context.

- v10.4 reduces overview status noise by replacing the technical `Mock 預設`
  top badge with the shorter `示範` label while preserving truthful data mode
  status elsewhere.

- v10.3 cleans up the `我的` page: daily account, appearance, ETF, position,
  and ETF data controls stay first; data diagnostics and App Store planning move
  into `進階設定`.

- v10.2 makes the AI page answer sooner by showing the rule-based `今日重點`
  bullets on the first screen while keeping matrices and full diagnostics
  behind details.

- v10.1 tightens the position first screen: market value, unrealized P/L, cost,
  position weight, source status, and data time now sit in one compact account
  card before optional input details.

- v10.0 renames the overview technical disclosure to `更多資料`, keeping quote,
  NAV, premium/discount, and the one-year chart as the first read.

- v9.99 makes the left-top ETF search sheet more app-like: current target first,
  compact result rows, and detailed data capability behind `更多資料`.

- v9.98 moves App Store planning to the bottom of `我的`, keeping daily account,
  appearance, ETF, position, and data controls first.

- v9.97 shortens the history/backtest first-screen copy so the date range,
  chart, and metrics read faster.

- v9.96 tightens the overview daily-data ticker so the one-year chart appears
  sooner on mobile.

- v9.95 keeps the position page first screen focused on local position numbers
  by moving source chips into a `資料來源` expansion.

- v9.94 makes the AI page first screen answer-first: today's conclusion,
  data-time facts, and the primary program action appear before detailed AI
  panels.

- v9.93 makes ETF search results show history and backtest capability badges
  directly, so switching symbols is easier to verify on mobile.

- v9.92 tightens the history/backtest top strip on mobile, keeping the source
  status visible while hiding lower-priority contract detail on narrow screens.

- v9.91 shortens the bottom navigation history/backtest label and lowers the
  bottom bar height for a tighter phone app feel.

- v9.90 combines the quote header, daily source summary, and one-year chart into
  one mobile market stack so the public overview first screen reads faster.

- v9.89 makes the overview chart touch detail a single compact row while
  keeping exact date and value feedback.

- v9.88 keeps the `我的` page more daily-use oriented by placing ETF data
  capability and data-mode sections before app-store planning details.

- v9.87 moves the AI page's primary program action above the detail expansion
  and makes the daily AI decision tiles denser on mobile.

- v9.86 tightens the position page first screen. The selected ETF now appears
  in the position card title, and the main row focuses on market value,
  unrealized P/L, and position weight.

- v9.85 compacts the history/backtest top context card so date controls and
  charts appear sooner on mobile.

- v9.84 compresses the overview daily data-status row into a mobile ticker so
  the one-year chart appears sooner on the first screen.

- v9.83 makes the left-top ETF search results easier to scan on mobile. Each
  result now shows one capability summary and keeps the live NAV scope visible.

- v9.82 makes the left-top ETF search sheet show history coverage and pending
  data counts before opening advanced database details.

- v9.81 tightens the overview first screen so the daily status strip is shorter
  and the main chart appears earlier on mobile.

- v9.80 trims the bottom-right `我的` page into a user-facing account/settings
  first screen, with deployment diagnostics kept behind advanced expansion.

- v9.79 clarifies ETF comparison charts: the comparison basket stays
  user-selected, date labels are visible under the chart, and the touch detail
  panel uses actual data dates.

- v9.78 trims the AI first screen by keeping the conclusion and program action
  visible first, while longer readouts and fact cards move into an expandable
  `AI 資料細節` panel.

- v9.77 makes the overview ETF-aware after symbol search. 00631L keeps the
  official holdings/NAV summary, while other ETFs show a data completeness
  digest instead of 00631L-specific live fields.

- v9.76 merges history/backtest range chips, range summary, and start/end date
  buttons into one compact mobile panel. History and backtest still default to
  the latest one-year window, with direct date adjustment visible.

- v9.75 keeps the top-left search pill compact enough for the `ETF 研究室`
  title to fit on phone width while preserving the search and down-arrow icons.

- v9.74 makes the top-left ETF code pill more obviously searchable by adding a
  short search label and down-arrow while preserving the existing ETF/stock
  search sheet.

- v9.73 removes the duplicated mobile exposure row from the overview chart
  panel, leaving official holdings exposure in the nearby holdings digest while
  keeping the one-year chart expanded.

- v9.72 derives intraday premium/discount from TWSE market price and estimated
  NAV when the TWSE premium field is blank, so the public app does not show an
  unavailable state while official price/NAV fields are present.

- v9.71 extends the live-core warm-up retry window so the public app can replace
  static fallback quote/holdings data sooner after a cold backend response.

- v9.70 tightens the mobile overview: the chart stays visible, official exposure
  becomes a compact row, and the holdings digest uses shorter app-style copy.

- v9.69 clears stale Flutter service worker registrations for this Pages app
  and reloads once, reducing cases where phones keep an old bundle after deploy.

- v9.68 adds short live-core retries after a static fallback first screen, so
  public Pages can recover from a slow Render response without waiting for the
  normal 15-second refresh interval.

- v9.67 makes fast public startup prefer the live backend when it responds
  inside the short startup timeout; static public data remains the fallback.

- v9.66 makes live-proxy public builds refresh full backend data on the overview
  page after the fast static first screen renders.

- v9.65 makes Pages builds default to the public Render backend
  (`https://longterm-stock-research-assistant.onrender.com`) with static public
  data as fallback.

- v9.64 compresses the overview daily summary strip by removing the duplicate
  header row, keeping the first screen focused on quote, chart, and exposure.

- v9.63 makes the overview `近一年走勢` chart actually use the latest one-year
  price-history window instead of showing older axis dates.

- v9.62 localizes the first-screen fallback and live-proxy status chips so the
  overview no longer exposes raw `Mock` text in the quote card.

- v9.61 changes the day/night control to action labels: `切換夜間` in light
  mode and `切換日間` in dark mode.

- v9.60 polishes the public HTML loading shell so the very first GitHub Pages
  frame uses Chinese app labels instead of English debug-style placeholders.

- v9.59 restores a compact first-screen daily summary, shows official exposure
  next to the overview trend on phones, and moves history date controls above
  the chart so the range is adjustable without opening an advanced panel.

- v9.33 adds a stricter first-screen chart-position guard so future header
  changes cannot push the overview chart down again.

- v9.32 tightens the 00631L mobile quote header with a stricter 118px height
  guard and two-line readiness chips.

- v9.31 removes the redundant first-screen `行情 / 資料 / 歷史` label strip so
  the overview moves from quote data into the chart faster on phones.

- v9.30 makes the 00631L first-screen quote header show the price field and
  split-adjustment status directly, so history/backtest data basis is visible
  without opening advanced details.

- v9.29 aligns the overview sparkline with the history chart. The first-screen
  chart date strip now uses full start / middle / end labels.

- v9.28 locks the bottom navigation to the main app pages only. ETF search and
  switching stay in the top-left symbol button, while the bottom bar keeps
  Overview, History/Backtest, Position, AI, and My.

- v9.27 makes the history chart date axis clearer on phones. Chart labels now
  read start / middle / end in full wording so users can match the line chart
  to the visible date range more quickly.

- v9.26 tightens the first-screen quote header. The main mobile quote card now
  has a height guard so price, source readiness, and the one-year chart stay
  visible without a large hero block.

- v9.25 makes the overview update-time chips show source status directly. The
  TX chip now distinguishes missing live backend data from a real futures quote,
  so static public mode is less likely to be mistaken for live TX data.

- v9.24 makes ETF comparison easier to read on phones. The history/backtest
  page now has a compact comparison summary strip that shows the selected ETF
  basket, common range, row count, and that no fixed benchmark is applied.

- v9.23 compacts the position page source details. The position account summary
  now uses market source, history source, and data-time chips instead of a long
  first-screen sentence.

- v9.22 makes the AI page more answer-first. The top AI briefing now includes a
  daily decision strip for today data, deviation interpretation, history data,
  and follow-up program action.

- v9.21 clarifies history and backtest date ranges. The history page now shows
  range mode, start date, and end date as separate compact labels, and chart
  touch detail separates date from value for phone readability.

- v9.20 adds a compact data summary to ETF search results. Before switching an
  ETF, the search sheet now shows historical row count, coverage, and price
  basis so data readiness is clearer.

- v9.19 adds a compact first-glance row to the mobile quote header. The first
  screen now groups price, data, and history before the detailed readiness
  numbers while keeping the one-year chart visible.

- v9.18 makes ETF comparison explicitly user-selected. The history/backtest
  comparison panel now shows a custom-basket summary, and selecting one ETF no
  longer implies that 00631L is part of the comparison set.

- v9.17 moves selected-ETF price correctness into the quote header. After using
  the top-left ETF search, the header now shows the history coverage, price
  field, and split-adjustment status together.

- v9.16 makes the AI tab more answer-first. The first AI card now includes a
  dedicated daily-data interpretation with holdings date, intraday NAV time,
  premium/discount context, history coverage, and a non-investment disclaimer.

- v9.15 adds a first-screen guard for the overview chart. Phone-width tests now
  verify that the one-year chart itself remains visible in the first viewport,
  so future header/status changes cannot quietly push the main trend view too
  far down.

- v9.4 compacts the left-top ETF search sheet: database readiness is now a
  one-line summary, with detailed coverage behind a scrollable expansion panel.

- v9.3 adds `scripts\00631l_check_static_first_load_budget.cmd`, a focused
  guard that keeps the public first screen from loading the full ETF catalog or
  history index before search/comparison opens.

- v9.2 adds explicit loading and error states to the left-top ETF search sheet
  while the full static ETF catalog is fetched on demand.

- v9.1 lazy-loads the static ETF catalog. GitHub Pages first screen no longer
  pulls `etf_catalog.json` or `etf_price_history_index.json`; the left-top ETF
  search loads those files only when opened.

- v9.0 trims the static-public first load. The first-screen operations status
  now reads compact readiness fields from `status.json` instead of also loading
  the full ETF catalog and price-history index.

- v8.9 keeps public static ETF price histories from regressing by restoring
  deployed `etf_price_history/*.json` rows before the next GitHub Pages export.
  Missing official rows still remain unavailable instead of being inferred.

- v8.8 shows ETF price-history source provenance in the app and static JSON.
  TWSE STOCK_DAY rows and TPEx ETF daily-history fallback rows are counted
  separately so source labels stay truthful.

- v8.7 adds an official TPEx ETF daily-history fallback for ETF symbols that
  return empty TWSE STOCK_DAY rows. The importer keeps `tpex_etf_historical_daily_json`
  separate from TWSE and leaves symbols unavailable when TPEx also has no rows.

- v8.6 adds a clearer ETF database completion strip in Settings: usable
  histories, official empty data, source items requiring attention, and
  unclassified items are separated.

- v8.5 lets the ETF history importer retry previous `source_error` attempts
  while still skipping official empty attempts, so fixed transport issues can
  be resolved by the next maintenance run.

- v8.4 handles TWSE STOCK_DAY HTTP redirects during ETF history imports, so
  redirect responses are not misclassified as source errors. Official empty
  responses remain unavailable and are not treated as usable history.

- v8.3 carries ETF price-basis metadata into search results: history-ready ETF
  rows can now show whether comparison/backtest context uses adjusted prices or
  raw close prices.

- v8.2 carries per-symbol ETF history gap metadata into the search catalog:
  catalog-only ETF rows now show why history is unavailable without treating
  missing data as usable history.

- v8.1 makes the left-top ETF search clearer: the sheet now shows ETF data
  readiness, whether a result can be used for history/backtest/comparison, and
  classified missing-data reasons without pretending unavailable ETF histories
  are usable.
- v8.0 removes the duplicated daily summary on the phone first screen. The
  overview now keeps a compact quote, one `今日快覽`, and the visible one-year
  chart.
- v7.0 cleans up the loading skeleton labels. Slow first loads now show
  `盤中`, `內容物`, `歷史`, and `分析` instead of `LIVE / DAY / HIS / AI`.
- v6.99 removes the `HIS` badge from the overview chart header so the first
  chart starts directly with `近一年走勢`.
- v6.98 removes code-like badges from the overview holdings digest. The
  first-screen holdings cards now lead with `期貨`, `台積電`, and `曝險結構`
  instead of `TX / 2330 / MIX`.
- v6.97 clarifies the first-screen daily summary chips: `DAY / LIVE / HIS`
  no longer occupy the primary overview row; the row now uses `官方內容物`,
  `盤中 NAV`, and `歷史資料` with compact values for phone width.
- v6.96 fixes pre-open intraday labeling: when the app is showing a previous
  trading day's TWSE NAV snapshot before the next session opens, the quote card
  labels it as previous-trading-day data instead of generic pre-open waiting.
- v6.94 clarifies public live-backend warmup on the first screen: when GitHub
  Pages is waiting for the Render backend, the DAY chip shows backend warmup
  instead of a confirmed data error.
- v6.95 adds a public deploy sync badge in Settings/My so frontend Pages and
  backend release drift is visible without opening scripts.
- v6.93 reconciles public static ETF catalog rows against the ETF price-history
  index, so a stale seed catalog cannot publish a smaller searchable universe
  than the history/backtest data already exported to GitHub Pages.
- v6.83 clarifies the expanded ETF search database counts: `目前清單` is the
  currently loaded list, while `統計母數` is the full readiness denominator.
- v6.82 cleans up the expanded ETF search database detail panel by replacing
  internal English labels with user-facing Chinese labels.
- v6.81 cleans up the left-top ETF search sheet result counters: local result
  chips now say `目前結果 歷史可用` and `目前結果 未匯入歷史`, separate from the
  full database readiness summary.
- v6.80 fixes the left-top ETF search sheet readiness summary: fast startup now
  merges static-public ETF library readiness metadata, so the database
  completion count matches the static index instead of catalog-only fallback
  flags.
- v6.79 compacts the settings/account first screen: the old overview grid is
  now a short summary card with account state, selected ETF, data mode, release
  version, and daily status badges.
- v6.78 makes the ETF data-library panel easier to read: the app now shows a
  concise summary of usable ETF histories, classified missing histories, and
  remaining unclassified gaps before the detailed diagnostics.
- v6.77 improves ETF data-completion transparency: catalog-only missing ETF
  histories now count as `not_saved`, so status gap reasons add up to the
  reported completion gap.
- v6.76 shortens the position page first screen by hiding the redundant
  local-position header, so account summary, actions, and input fields appear
  sooner.
- v6.75 makes the AI page answer-first: the first screen now shows the daily
  rule-based interpretation and program actions, while source grids and deeper
  matrices move into an advanced detail panel.
- v6.74 makes the history/backtest range context fit phone width by wrapping
  the range metrics into two columns and giving mini charts enough height for
  their date strip and touch detail.
- v6.73 cleans up history chart date labeling by removing overlapping in-chart
  x-axis dates and keeping the clearer date strip below the chart.
- v6.72 softens the settings data-mode caption so backend errors stay in
  advanced diagnostics while static data availability remains clear.
- v6.71 makes the account/settings first screen user-focused by keeping backend
  persistence diagnostics inside advanced status panels.
- v6.70 localizes the position account unavailable percentage state so the
  phone account summary no longer shows raw English fallback text.
- v6.69 makes the position account summary fit phone width with a 2x2 metric
  layout instead of a clipped horizontal strip.
- v6.68 further shortens the history/backtest first screen: charts now appear
  before data-quality details, and the top history card no longer repeats four
  summary tiles.
- v6.67 moves the history/backtest phone page toward chart-first scanning:
  range chips and the price chart appear before detailed date controls, and
  duplicate history badges are removed.
- v6.66 removes the duplicated phone-width exposure strip under the overview
  chart; official holdings remain in the dedicated digest card below.
- v6.65 localizes background-pending labels in the summary row, replacing
  `syncing` / `checking` with short Chinese labels.
- v6.64 replaces technical holdings-unavailable wording with concise
  user-facing data status text and avoids showing placeholder trade dates.
- v6.63 makes the DAY/LIVE/HIS summary row prefer known unavailable/error
  states over background-sync wording, so confirmed data issues do not look
  like an endless load.
- v6.62 hides invalid zero-value official exposure strips when holdings are not
  usable.

v4.0 is the App Store foundation release. The app is now framed as `ETF 研究室`, with `00631L 正二研究室` as the first complete research room. The public root URL opens the 00631L app directly, without first showing the old general research dashboard.

Public root URL:

```text
https://dany1230000.github.io/longterm_stock_research_assistant/
```

Compatibility route:

```text
https://dany1230000.github.io/longterm_stock_research_assistant/#/00631l-lab
```

Start from `docs/00631l_docs_index.md`, `docs/00631l_v4_0_app_store_foundation_summary.md`, or `docs/00631l_app_store_release_plan.md`.

Daily helper:

```cmd
scripts\00631l_open_lab.cmd
```

Intraday update timing:

- Official holdings are daily snapshots.
- Intraday NAV / premium-discount uses the live backend during TWSE regular trading hours, 09:00-13:30 Asia/Taipei.
- Static public mode keeps history/backtest usable but is not live intraday data.
- Details: `docs\00631l_intraday_update_timing.md`.

Local direct route:

```text
/
```

The old general research screens remain available as internal routes for development, but the product experience is now 00631L-only.

Mobile LAN helper:

```cmd
scripts\00631l_lan_info.cmd
scripts\00631l_start_backend_lan.cmd
scripts\00631l_start_frontend_lan.cmd
```

Public deployment helpers:

```cmd
scripts\00631l_check_public_config.cmd
scripts\00631l_backend_prod_check.cmd
scripts\00631l_backend_docker_check.cmd
scripts\00631l_remote_maintenance.cmd --dry-run
scripts\00631l_remote_maintenance.cmd --mode all
scripts\00631l_remote_maintenance.cmd --mode daily --etf-from-catalog --etf-limit 50 --etf-offset 0 --soft-fail
scripts\00631l_remote_maintenance.cmd --mode daily --etf-from-catalog --etf-limit 50 --etf-offset 0 --retry-count 2 --retry-delay-seconds 3 --soft-fail
scripts\00631l_public_etf_catalog_batches.cmd --dry-run --batch-size 1 --max-batches 1
scripts\00631l_public_backend_status.cmd
scripts\00631l_compare_public_freshness.cmd --soft-fail
scripts\00631l_export_static_data.cmd --status-only
scripts\00631l_export_static_data.cmd --update
set PUBLIC_BACKEND_URL=https://your-backend.example.com
scripts\00631l_build_web_public.cmd
scripts\00631l_build_pages_static.cmd
scripts\00631l_build_pages_static.cmd --skip-restore-public-attempts
```

Multi-ETF price-history status:

```cmd
scripts\00631l_import_etf_price_history.cmd --status-only --summary-only
scripts\00631l_validate_etf_price_history.cmd
scripts\00631l_import_etf_price_history.cmd --from-catalog --missing-only --limit 25 --allow-partial --summary-only --progress-every 5
scripts\00631l_import_missing_etf_batch.cmd
scripts\00631l_import_etf_price_history.cmd --from-catalog --offset 230 --limit 25 --allow-partial --summary-only --progress-every 5
```

Use `--summary-only` for daily rowCount/readyCount/coverage checks. Use the validation command when full per-ETF detail is needed.
Use `--missing-only` to skip ETF codes that already have ready price-history rows. Use `--retry-source-errors` with `--skip-attempted` when fixed source transport issues should be retried without rechecking prior official empty results. Use `--offset` and `--limit` for broad catalog backfills so a failed or paused run can continue from the middle of the catalog. Full refresh mode uses the earliest supported ETF history start date; incremental mode starts from the latest cached month for each ETF.
Use `scripts\00631l_import_missing_etf_batch.cmd` for the default safe local missing-only batch.

ETF price-history coverage tiers:

- `long_term`: enough local history for longer-range comparison/backtest context.
- `recent`: usable recent rows, but long-range comparison is limited.
- `unavailable` / `error`: not ready for comparison until data is imported or validation is fixed.

v4.27 makes static export status read ETF coverage tiers from `etf_price_history_index.json` when an older manifest does not contain tier counts. This keeps public static maintenance status backward-compatible.

v4.48 keeps the AI page concise on mobile: current-day bullets and program actions stay visible, while the complete data briefing moves into an expandable detail panel.

v4.49 improves chart readability: mini chart hint lines now include the visible date range before the user taps a point for the exact date and value.

v4.50 fixes the left-top ETF search sheet selected-state label after switching ETFs; the actual current ETF is now marked as the current page.

v4.51 lets the public backend read `backend/seeds/00631l_price_history_seed.jsonl` when its local persistent volume has no price-history rows. Seed-only backend history is labeled `static_official`; once local rows are saved, local cache rows override same-date seed rows and the status becomes cached/local+seed history.

v4.52 applies the same seed fallback to multi-ETF price histories. Public backend ETF search, selected ETF history, and comparison context can read `backend/seeds/etf_price_history_seed/` before the persistent volume is populated; seed-only ETF histories are labeled `static_official`.

v4.53 extends public backend remote maintenance so `daily` / `all` mode also runs the multi-ETF history update and status check. This helps a deployed backend fill persistent ETF history cache rows instead of relying only on committed seed fallback.

v4.54 replaces stale hard-coded backend version text with release metadata from config/env. `/health`, operations/status, and the app settings/status view can now show the backend version, release tag, git sha, and build time when deployment supplies them.

v4.55 adds `scripts\00631l_public_backend_status.cmd`, a read-only public backend status check for `/health`, `/ready`, 00631L history, and multi-ETF history readiness.

v4.56 adds `scripts\00631l_compare_public_freshness.cmd`, a read-only comparison between public backend history, local history, and GitHub Pages static data.

v4.57 adds catalog-batch remote ETF history maintenance. `POST /api/etf/history/update` now supports `fromCatalog=true`, `limit`, and `offset` so a deployed backend can fill ETF history in controlled batches.

v4.58 refreshes backend release metadata defaults so `/health` does not fall back to an older v4.54 label when deployment env vars are missing.

v4.59 hardens public remote maintenance with read-only retries and post-check metadata, so temporary public-backend `502/503` status reads are WARNs when core updates complete.

v4.60 lets a public backend use `backend/seeds/twse_etf_catalog_seed.json` when `ETF_CATALOG_PATH` has not been imported yet. Seed-backed catalog data is labeled `static_official`, and catalog-batch maintenance can start filling ETF histories before the persistent catalog cache exists.

v4.61 adds `scripts\00631l_public_etf_catalog_batches.cmd`, which plans catalog offsets from `/api/etf/catalog/status` and runs broad ETF history batches without manually typing each offset.

v4.62 hardens that batch runner for hosted backend restarts: failed batches keep the same `--start-offset` in the next action item, and ready-count regressions are reported clearly.

v4.63 adds `scripts\00631l_public_deploy_drift.cmd`, a read-only check that warns when the public backend is still running an older release tag than the current local release metadata.

v4.64 makes `scripts\00631l_public_etf_catalog_batches.cmd` resumable with `--resume`. The runner writes its ignored local state to `backend\data\00631l_public_etf_catalog_batch_state.json`.

v4.65 adds readiness floors to `scripts\00631l_public_backend_status.cmd`, for example `--min-etf-ready-count 200`, so hosted backend history regressions are visible as `WARN`.

v4.66 adds `scripts\00631l_public_maintenance_status.cmd`, a read-only public maintenance summary that combines deploy drift, readiness floors, freshness, and action items.

Next direction is tracked in `docs\00631l_next_direction.md`: data trust, public operations, mobile UX, and analysis quality.

v6.51 keeps the position page shorter on phones by showing only share count and average cost first. Optional total assets, fee, and note fields are still available in an advanced panel.

v6.52 makes the first-screen DAY / LIVE / HIS row show `syncing`, `checking`, and ready history counts instead of generic loading text while background refresh continues.

v6.53 shortens those DAY / LIVE / HIS captions so the phone first screen avoids clipped `daily...` and `backend...` labels.

v6.54 shortens the fast-first-screen refresh banner to `背景更新中，已先顯示可用資料。` so the quote and chart remain the visual focus.

v6.55 cleans up the quote header title so 00631L shows `元大台灣50正2` instead of `00631L 00631L` when history data only contains the code.

v6.56 keeps the public first screen chart usable during live-proxy background refresh by overlaying static public price history when the live fast payload still reports price history as deferred or unavailable.

v6.57 prevents unavailable holdings snapshots from rendering misleading 0-value digest tiles; the overview now shows a compact unavailable state until live backend holdings are usable.

v6.58 shortens the 00631L quote card title to `00631L 元大台灣50正2` so the first card reads like a stock app instead of truncating the long fund registration name.

v6.59 hides the background-refresh banner when the first screen already has a usable quote plus history or official holdings context. Error/fallback states still appear, but normal background refresh no longer takes first-screen space.

v6.60 makes the 00631L quote-card premium/discount value depend on intraday NAV only. If intraday NAV is unavailable, the card shows unavailable instead of mixing catalog/static reference values with live labels.

v6.61 makes the DAY / LIVE / HIS summary row show available dates and times during background refresh. It only shows syncing/checking when that specific data is still missing.

v6.62 hides the overview exposure strip when official holdings are not usable, so the app does not show 0% stock/futures/cash values as if they were valid official data.

v4.35 adds a selected ETF history-quality card on the history/backtest page, so the visible row count, coverage range, source status, and adjustment status follow the ETF chosen from the top-left selector.

v4.36 adds explicit chart range guidance on the history/backtest page and clearer selected-date wording for chart touch details.

v4.37 changes ETF comparison to start with the currently selected ETF only; users can add other ETFs with chips or category filters instead of being forced into a 00631L-anchored comparison.

v4.38 trims the quote header metadata so the first screen focuses on estimated NAV, session/time, and history readiness; previous NAV and frontend mode remain in detail/status sections.

v4.39 makes the overview data-quality card follow the selected ETF, including the current code, coverage range, data source, and price field.

v4.40 improves selected ETF AI summaries with latest trading date, daily change, drawdown, coverage, and source status instead of generic wording.

v4.41 surfaces selected ETF price-field and split-adjustment status inside the AI context, so history and backtest interpretation stays tied to the actual loaded data.

v4.42 separates quote source and historical source on the local-only position page, and labels the currently selected ETF before any position estimate.

v4.43 moves the always-visible overview chart directly below the compact quote header, so the first screen shows current context and recent movement before lower-priority data-quality cards.

v4.44 compresses the quote metadata strip into one horizontal text line, keeping estimated NAV, session, and history count without tall pill boxes.

v4.45 makes selected ETF quote captions distinguish catalog market price from historical-close fallback, so source labels stay tied to the value actually shown.

v4.46 adds dedicated backtest range chips for latest 1 year, latest 3 years, and full loaded coverage, while keeping custom start/end date buttons.

v4.47 merges position status, input fields, estimates, and local actions into one compact position card, reducing the mobile page length without changing local-only storage.

v4.28 adds ETF price-history readiness and coverage tier counts to the final `[summary]` line printed by `scripts\00631l_export_static_data.cmd --status-only`, so daily logs can be checked without opening the JSON payload.

v4.29 lets static status derive ETF coverage tier counts from older `web\00631l-static-data\etf_price_history\*.json` files when both manifest and index metadata are missing tier counts. It is read-only and does not change generated static data.

v4.30 adds a release-check guard so static-public ETF history cannot be ready while the final summary line hides coverage tiers as unavailable.

v4.31 reconciles legacy static ETF history row/ready counts with derived tier counts, so `scripts\00631l_export_static_data.cmd --status-only` reports consistent ETF history availability.

v4.32 makes the top-left ETF selector use operations/static price-history readiness metadata, so the UI can reflect the full static ETF history set instead of only the old representative list.

v4.33 cleans up the top-left ETF / stock-code selector wording so the title, input, ready count, and result captions read like production UI instead of legacy debug text.

v4.34 adds compact ETF history metadata badges to selector/catalog rows, showing coverage tier and row count such as `recent · 12 筆`.

v3.3 live-public ready status:

- GitHub Pages static mode remains usable without a backend.
- A public FastAPI backend can be deployed with `backend\Dockerfile` or `deploy\docker-compose.yml`.
- Public backend readiness is exposed at `/ready`.
- Production data should be mounted at `/data/00631l` with `00631L_DATA_PERSISTENCE_MODE=persistent`.
- Public frontend builds can enable both live proxy and static fallback through `scripts\00631l_build_web_public.cmd`.
- Live intraday NAV requires the public backend; static mode is not live intraday data.

v3.4 live backend URL:

```text
https://longterm-stock-research-assistant.onrender.com
```

GitHub Pages builds now use this backend URL by default and keep static history fallback.

Remote maintenance:

```cmd
scripts\00631l_remote_maintenance.cmd --mode all
```

GitHub Actions also runs `.github/workflows/00631l_backend_maintenance.yml` to wake the public backend, collect intraday status, update official 00631L price history, update the selected ETF basket history, and verify key public endpoints. Details: `docs\00631l_remote_maintenance.md`.

v3.47 split-adjusted history:

- TWSE raw OHLC prices are preserved.
- Historical performance, charts, static public data, CSV export, and backtest calculations use `adjustedClose`.
- The 00631L 2026 split is handled with a 1/22 adjustment before 2026-03-31.
- Summary: `docs\00631l_v3_47_split_adjusted_history_summary.md`.

v3.48 home chart visibility:

- The overview price chart and official exposure summary are visible on the home screen without expanding a panel.
- Deeper comparison and technical details remain collapsed below.
- Summary: `docs\00631l_v3_48_home_chart_visible_summary.md`.

v3.49 ETF research room information architecture:

- Bottom navigation now focuses on overview, history/backtest, position, AI, and settings.
- Official holdings highlights are merged into the overview so the first screen stays concise.
- Backtest inputs now include start/end date selectors.
- AI analysis is framed around today's data status and price-deviation context.
- Summary: `docs\00631l_v3_49_etf_research_room_ia_summary.md`.

v4.0 App Store foundation:

- PWA metadata now uses the `ETF 研究室 · 00631L 正二研究室` product name.
- History/backtest opens with the backtest form visible instead of hiding it behind an expansion panel.
- Settings includes an `App 上架準備` checklist for PWA, Android, iOS, privacy/support, and live backend readiness.
- Native Android / iOS packaging is planned next and requires platform signing and store accounts.
- Summary: `docs\00631l_v4_0_app_store_foundation_summary.md`.
- Plan: `docs\00631l_app_store_release_plan.md`.

v4.1 TX live, history controls, and ETF catalog:

- The history/backtest tab now opens on a one-year default range and lets the user adjust start/end dates.
- The light/dark toggle now changes the 00631L market shell palette instead of only changing the app theme mode.
- Backend exposes TAIFEX TX live quote at `/api/etf/00631l/tx-quote`; off-hours can return unavailable/stale instead of mock official data.
- TWSE all-ETF catalog can be imported with `scripts\00631l_import_etf_catalog.cmd`; it is a data foundation and does not change the app into an all-ETF product.
- Summary: `docs\00631l_v4_1_tx_live_history_controls_summary.md`.

v4.2 history range and theme fix:

- The history/backtest page clearly defaults to the latest one-year range.
- Start/end date controls and quick ranges update charts, metrics, and the price table.

v4.12 intraday session update:

- Intraday NAV now carries Asia/Taipei market-session metadata from the backend.
- The frontend refreshes intraday data faster during regular trading hours and keeps full data refresh lower frequency.
- The quote header and data coverage area show session phase, data freshness, age, and next refresh timing.
- Summary: `docs\00631l_v4_12_intraday_session_update_summary.md`.

v4.13 intraday time and TX quote fix:

- Home quote time now shows a date when the source data is not from the current Taipei calendar day.
- TAIFEX TX live quote resolves the active month-coded futures symbol automatically; legacy `TXF-P` is treated as auto because it can omit futures last price.
- Overview and data status show the resolved contract month and TX symbol.
- Summary: `docs\00631l_v4_13_intraday_tx_fix_summary.md`.

v4.15 TX stale status fix:

- TAIFEX TX quotes with old `dataTime` now show `stale` instead of looking like a current live quote.
- Frontend mapping also treats `isStale: true` TX payloads as stale for older backend compatibility.
- Summary: `docs\00631l_v4_15_tx_stale_status_summary.md`.

v4.16 goal plan and home chart readability:

- Added `docs\00631l_product_goal_plan.md` as the working product direction for the ETF research room.
- The overview price chart now defaults to roughly one year, shows bottom date labels, and supports touch tooltips with date and price.
- Summary: `docs\00631l_v4_16_home_chart_goal_plan_summary.md`.

v4.17 data correctness panel:

- The overview page now shows price field, split-adjustment status, coverage, row count, and source status in a compact `資料正確性` panel.
- `EtfPriceHistoryCompletenessSummary` exposes adjusted-price and non-unit adjustment flags for tests and UI.
- Summary: `docs\00631l_v4_17_data_correctness_panel_summary.md`.

v4.18 ETF search readiness:

- The top-left ETF search sheet now labels history-ready ETFs and catalog-only ETFs more clearly.
- Search results explain whether verified price history is available before switching ETF context.
- Summary: `docs\00631l_v4_18_etf_search_readiness_summary.md`.

v4.19 comparison basket clarity:

- ETF comparison now states that users can choose a 1-5 ETF basket instead of being locked to 00631L.
- Widget tests verify that toggling comparison chips updates the selected basket.
- Summary: `docs\00631l_v4_19_comparison_basket_summary.md`.

v4.20 compact backtest and position pages:

- Backtest now shows a compact status row for date range, strategy, sample count, and cost parameter.
- Position tracking now shows local-only, no-login, no-upload, source, and market-price status in one row.
- Summary: `docs\00631l_v4_20_backtest_position_compact_summary.md`.

- The light/dark toggle is a visible `日間` / `夜間` control and rebuilds the 00631L market palette.

v4.3 position, AI, settings, and ETF catalog:

- Position tracking now starts with local-only status, an empty state, and grouped result cards.
- AI analysis now separates source/readiness, daily signals, action items, and full-data briefing.
- Settings prioritizes account/privacy, appearance, local position data, and ETF catalog preview.
- Frontend repository mapping now reads `/api/etf/catalog`; ETF comparison remains a later feature.
- Summary: `docs\00631l_v4_3_position_ai_etf_catalog_summary.md`.

v4.4 ETF catalog explorer:

- Bottom navigation now includes a dedicated `ETF` section instead of hiding ETF data inside settings.
- The ETF page shows catalog status, row count, data time, local search, and simple filters for common groups.
- Settings now keeps only ETF data status and comparison readiness, so account/theme/local data controls stay easier to scan.
- The theme toggle now labels the current state as `日間模式` or `夜間模式`.
- Summary: `docs\00631l_v4_4_etf_catalog_explorer_summary.md`.

v4.5 ETF comparison foundation:

- The ETF page now includes a comparison foundation table for common catalog items.
- The table compares only verified catalog snapshot fields: code, name, market price, estimated NAV, premium/discount, previous NAV, and data time.
- Full multi-ETF performance/backtest comparison still requires verified historical data for each ETF and remains a later feature.
- Summary: `docs\00631l_v4_5_etf_comparison_foundation_summary.md`.

v4.6 header symbol search:

- The top app bar now has a larger `ETF 研究室` title and a clearer `00631L 正二研究室` subtitle.
- The left `00631L ▼` pill is tappable and opens an ETF / stock-code search sheet.
- Search currently uses the ETF catalog. If a stock code is not in the loaded catalog, the UI says the stock data source is not connected yet.
- Summary: `docs\00631l_v4_6_header_symbol_search_summary.md`.

v4.7 static ETF catalog import:

- Static public export now writes `etf_catalog.json` next to price history, performance, status, and manifest.
- GitHub Pages builds refresh the TWSE all-ETF catalog before Flutter build and use a committed official snapshot seed only when live refresh is temporarily unavailable.
- Static mode can load ETF catalog/search data without waiting for a live backend. Broader ETF history/backtest comparison still needs separate verified data.
- Summary: `docs\00631l_v4_7_static_etf_catalog_summary.md`.

v4.8 multi-ETF price history import foundation:

- Backend can import TWSE `STOCK_DAY` price history for selected ETF catalog codes into ignored local JSONL files.
- New endpoints expose multi-ETF history index, per-code price history, and manual update.
- The import keeps each ETF separate and does not apply 00631L split adjustment to other ETFs.
- This is the data foundation for later ETF comparison; the 00631L research room remains the primary app.
- Summary: `docs\00631l_v4_8_multi_etf_history_import_summary.md`.

v4.9 ETF history selection:

- The top-left ETF selector and ETF catalog list can switch the history/backtest view to selected ETF price history.
- Proxy mode reads `/api/etf/history/price?code=<ETF_CODE>`.
- Static public mode reads `00631l-static-data/etf_price_history/<ETF_CODE>.json`.
- GitHub Pages builds import selected ETF history before exporting static public data.
- Summary: `docs\00631l_v4_9_etf_history_selection_summary.md`.

v4.10 ETF history comparison:

- The history/backtest page now shows an `ETF 歷史比較` section using imported histories for `00631L`, `0050`, `006208`, `00878`, and `00919`.
- The comparison defaults to the selected ETF's latest one-year window and reports return, drawdown, volatility, latest close, row count, and source status.
- The top-left ETF selector remains the entry point; the bottom navigation stays focused on overview, history/backtest, position, AI, and settings.
- Summary: `docs\00631l_v4_10_etf_history_comparison_summary.md`.

v4.11 ETF comparison basket:

- The default ETF history import basket now covers 15 representative ETFs across market-cap, dividend, tech, and 00631L categories.
- The ETF history comparison section has filters for representative, market-cap style, dividend style, tech theme, and all imported histories.
- Static public Pages builds import the expanded basket before exporting static data.
- Summary: `docs\00631l_v4_11_etf_comparison_basket_summary.md`.

v3.6 UI refresh:

- `/00631l-lab` now uses a quote-first stock-app style header.
- Section navigation is a compact horizontal app bar.
- Desktop width is constrained while mobile layout stays first-class.
- Summary: `docs\00631l_v3_6_app_ui_refresh_summary.md`.

v3.7 complete-data UI:

- Overview and history now use more of the existing official/static data, including OHLC, volume, row count, coverage, trailing 52-week range, drawdown, and holdings trend charts.
- The AI tab includes a complete-data daily briefing built from price history, holdings history, intraday NAV history, and operations state.
- Summary: `docs\00631l_v3_7_complete_data_ui_summary.md`.

v3.8 market app UI:

- The 00631L lab now uses a market-dark mobile app shell with top tabs, data-status strip, market-focus rows, and bottom navigation.
- This is a visual/product polish release only; it does not add TX live, new ETF scope, notifications, or investment guidance.
- Summary: `docs\00631l_v3_8_market_app_ui_summary.md`.

v3.9 mobile information architecture:

- Bottom navigation is now the single primary section switcher; the duplicate top tab row was removed.
- The large quote hero appears only on the overview page. Other sections open directly into holdings, history, backtest, position, AI, or system content.
- Market-focus rows use clear DAY/LIVE/HIS/AI/SYS data badges instead of decorative icons.
- Summary: `docs\00631l_v3_9_mobile_information_architecture_summary.md`.

v3.10 mobile polish:

- Bottom navigation now fits all seven 00631L sections without horizontal scrolling.
- Mobile tables render as readable cards; wider screens still use dense tables.
- Summary: `docs\00631l_v3_10_mobile_polish_summary.md`.

v3.11 section summaries:

- Each non-overview bottom tab now starts with its own compact summary instead of repeating the overview quote card.
- Holdings, history, backtest, position, AI, and system pages surface their main data status and key values first.
- Summary: `docs\00631l_v3_11_section_summaries.md`.

v3.12 navigation and settings:

- History and backtest are merged into one `歷史回測` bottom tab.
- The old user-facing system status tab is replaced by `設定`; diagnostics now live under settings as an advanced section.
- Settings also states which data is complete, which data requires live backend, and how TX live quote is sourced from TAIFEX when backend is connected.
- Summary: `docs\00631l_v3_12_navigation_settings_summary.md`.

v3.13 data coverage status:

- Overview now answers whether the core datasets are filled: price history, holdings history, intraday NAV, and TX live.
- Settings uses the same data coverage rows, so static-public, live backend, and mock/fallback boundaries stay consistent.
- Summary: `docs\00631l_v3_13_data_coverage_summary.md`.

v3.14 holdings coverage:

- The holdings tab now shows local holdings history coverage, integrity status, and missing weekday previews.
- Backend operations/status includes data integrity status so the UI can explain history gaps without acting like old official holdings were reconstructed.
- Summary: `docs\00631l_v3_14_holdings_coverage_summary.md`.

v3.15 holdings mobile cards:

- The holdings tab now starts with asset mix cards and key holdings cards before the full detail tables.
- Full stock/futures/cash details remain available, but the mobile-first view is easier to scan.
- Summary: `docs\00631l_v3_15_holdings_mobile_cards_summary.md`.

v3.16 overview first screen:

- The overview first screen now starts with a concise daily brief and data-mode cards instead of a table-like status list.
- Detailed coverage and diagnostics remain available below the fold and in settings.
- Summary: `docs\00631l_v3_16_overview_first_screen_summary.md`.

v3.17 information hierarchy:

- The overview page now groups related numbers together for comparison and hides lower-priority diagnostics behind expandable panels.
- Settings keeps account/privacy and data completeness visible, while technical backend/report/export/backup diagnostics are collapsed by default.
- Summary: `docs\00631l_v3_17_information_hierarchy_summary.md`.

v3.18 progressive details:

- Holdings and history pages now show key summaries first and keep full detail tables behind expandable panels.
- Mobile users can scan exposure, charts, and changes before opening raw stock/futures/cash/history tables.
- Summary: `docs\00631l_v3_18_detail_progressive_disclosure_summary.md`.

v3.19 first-screen speed and layout:

- Initial loading now shows the 00631L app shell and skeleton cards instead of a single spinner.
- The overview quote area is compact, with low-priority data-source details collapsed by default.
- Summary: `docs\00631l_v3_19_first_screen_speed_layout_summary.md`.

v3.20 home at-a-glance:

- The overview page now starts with a compact quote card and a single at-a-glance panel for official holdings date, intraday NAV, major exposure, historical coverage, historical return, and data mode.
- Full numeric comparison remains available in an expandable section instead of occupying the first screen.
- Summary: `docs\00631l_v3_20_home_at_a_glance_summary.md`.

v3.21 compact home:

- The quote card now uses a compact market row and small facts strip instead of tall stacked metric boxes.
- Holdings change details are collapsed by default, while latest exposure remains visible in a concise row.
- Summary: `docs\00631l_v3_21_compact_home_summary.md`.

v3.22 fast startup:

- The app now loads first-screen essentials through a fast data path before full history, AI, and operations data finish loading.
- If full details fail, the quote and overview remain visible with a clear fallback state instead of a blank page.
- Summary: `docs\00631l_v3_22_fast_startup_summary.md`.

v3.23 live cold-start fallback:

- Fast startup now gives the public live backend a short first-screen timeout, then shows static/mock fallback if the backend is still cold.
- Full live data continues loading in the normal path and can replace the fallback once available.
- Summary: `docs\00631l_v3_23_live_cold_start_fallback_summary.md`.

v3.24 overview layout:

- The mobile overview first screen now keeps the quote, core status, and a few key metrics visible without filling the page with diagnostics.
- Full numeric comparison, data sources, holdings changes, and technical checks are grouped under `更多檢視`.
- Summary: `docs\00631l_v3_24_overview_layout_summary.md`.

v3.25 compact quote board:

- The top quote card now uses a lean market-board layout and avoids repeating source-contract badges in the first screen.
- Detailed source labels remain available in `更多檢視` and settings.
- Summary: `docs\00631l_v3_25_compact_quote_board_summary.md`.

v3.26 user-facing status labels:

- The top app chrome and overview first screen now use short labels such as `公開靜態`, `Live 後端`, `Mock 預設`, and `盤中資料暫無`.
- Raw source contracts remain available in deeper diagnostics instead of crowding the first screen.
- Summary: `docs\00631l_v3_26_user_facing_status_labels_summary.md`.

v3.27 four-metric home:

- The overview "今日一眼看" panel is now a four-metric grid: official holdings date, intraday NAV, holdings exposure, and historical coverage.
- Data mode remains in the top bar instead of taking another metric slot.
- Summary: `docs\00631l_v3_27_four_metric_home_summary.md`.

v3.28 home sparkline and exposure:

- The overview first screen now includes a compact 60-day close sparkline and official stock/futures/cash exposure bars.
- The panel uses existing price history and official daily holdings data; it does not add a new data source.
- Summary: `docs\00631l_v3_28_home_sparkline_exposure_summary.md`.

v3.29 first-screen segmentation:

- The overview first screen now prioritizes quote, 60-day sparkline, and official exposure before secondary details.
- The history/backtest tab uses an in-page switch so users see history first and open backtest inputs only when needed.
- Summary: `docs\00631l_v3_29_first_screen_segmentation_summary.md`.

v3.30 home data readiness:

- The overview first screen now has a compact data readiness strip for history rows, backtest availability, official holdings date, and intraday NAV time.
- The strip answers whether data is usable without sending users to settings or technical diagnostics.
- Summary: `docs\00631l_v3_30_home_data_readiness_summary.md`.

v3.31 mobile quote trim:

- Mobile top chrome now keeps only the 00631L pill and app controls, avoiding a repeated full title.
- The first quote card keeps market price, premium/discount, estimated NAV, and previous NAV; lower-priority reference numbers live deeper in the app.
- Backend holdings and live smoke now use local cached official holdings history when the live Yuanta ratio page cannot be parsed, and clearly mark that state as cached fallback.
- Summary: `docs\00631l_v3_31_mobile_quote_trim_summary.md`.

v3.32 mobile first-screen density:

- The overview first screen now shows quote data and compact data readiness first.
- The 60-day chart and official exposure bars are available under `圖表與曝險`, so they no longer push key status below the first mobile viewport.
- Summary: `docs\00631l_v3_32_mobile_first_screen_density_summary.md`.

v3.33 fast-first data load:

- The app now starts the full data provider only after the fast first-screen data resolves.
- This keeps large historical/static data requests from competing with the first visible quote/status screen.
- Summary: `docs\00631l_v3_33_fast_first_data_load_summary.md`.

v3.34 settings page cleanup:

- The bottom-right settings page now prioritizes account/privacy, appearance, and local-only position data.
- Data coverage and maintenance diagnostics are still available, but hidden behind expandable panels.
- Summary: `docs\00631l_v3_34_settings_page_cleanup_summary.md`.

v3.35 compact section headers:

- Feature page headers now use tighter spacing, smaller icons, and capped subtitles.
- Contents, history/backtest, position, AI, and settings pages reach their primary content sooner on mobile.
- Summary: `docs\00631l_v3_35_compact_section_headers_summary.md`.

v3.36 overview history performance:

- The overview `今日一眼看` strip now includes historical cumulative return and maximum drawdown.
- This makes the completed price history dataset visible from the first app screen without opening history/backtest.
- Summary: `docs\00631l_v3_36_overview_history_performance_summary.md`.

v3.37 overview metric grid:

- The overview first-screen metrics now use a responsive grid instead of a horizontal strip.
- Phone widths show official holdings, intraday NAV, holdings focus, history coverage, and historical performance without requiring sideways scrolling.
- Summary: `docs\00631l_v3_37_overview_metric_grid_summary.md`.

v3.38 history/backtest merge:

- The `歷史回測` page no longer has a second in-page switch.
- Historical coverage and metrics are first; the backtest tool stays on the same page behind a compact expansion panel.
- Summary: `docs\00631l_v3_38_history_backtest_merge_summary.md`.

v3.39 compact quote NAV line:

- The overview quote header now uses one compact NAV metadata line instead of separate NAV chips.
- This reduces the first-screen height while keeping market price, premium/discount state, estimated NAV, previous NAV, and data time visible.
- Summary: `docs\00631l_v3_39_compact_quote_nav_line_summary.md`.

v3.40 live timeout static fallback:

- Public live proxy builds can set `00631L_PROXY_TIMEOUT_MS`; default is 3000 ms.
- When the live backend is slow or waking up, the app falls back to static public data faster so history/backtest remain usable.
- Summary: `docs\00631l_v3_40_live_timeout_static_fallback_summary.md`.

v3.41 holdings exposure compare:

- The holdings page now shows a compact `曝險比較` card near the top.
- TX futures, TSMC stock, stock assets, futures assets, and cash/margin are grouped on the same visual scale.
- Summary: `docs\00631l_v3_41_holdings_exposure_compare_summary.md`.

v3.42 web loading shell:

- `web/index.html` now shows a lightweight 00631L loading shell before Flutter finishes booting.
- The shell is removed on `flutter-first-frame`, reducing the blank-page feeling on mobile web/PWA startup.
- Summary: `docs\00631l_v3_42_web_loading_shell_summary.md`.

v3.43 Yuanta maintenance detection:

- Yuanta Basic/ratio maintenance pages are now detected instead of being parsed as normal official data.
- Holdings can use cached local history during Yuanta maintenance, with `sourceStatus=cached` and a clear maintenance message.
- Summary: `docs\00631l_v3_43_yuanta_maintenance_detection_summary.md`.

v3.44 live/static history merge:

- Public live proxy remains the first source for live data.
- If the public backend has no price history rows, the app uses static public history so historical charts and backtest remain available.
- Summary: `docs\00631l_v3_44_live_static_history_merge_summary.md`.

v3.45 remote history chunk update:

- Remote maintenance updates public backend price history in chunks instead of one large request.
- The Render backend has been seeded to 2828 rows, covering 2014-10-31 to 2026-06-12.
- Summary: `docs\00631l_v3_45_remote_history_chunk_update_summary.md`.

v3.46 first-screen and live-data clarity:

- The overview first screen is more compact: quote, premium/discount, intraday time, NAV, history row count, and frontend mode are grouped in one board.
- The top summary now uses `核心資料`; lower-priority AI/detail text stays below the first screen.
- Remote maintenance reports official holdings `unavailable` as WARN instead of PASS, while price history can still be complete.
- Summary: `docs\00631l_v3_46_first_screen_live_clarity_summary.md`.

Rule-based AI analysis is available at `/api/etf/00631l/analysis/summary` and on `/00631l-lab`. It does not call an external LLM by default and does not require an API key.

Price history and historical backtest:

```cmd
scripts\00631l_update_price_history.cmd --status-only
scripts\00631l_update_price_history.cmd
```

Guides:

- `docs\00631l_data_sources_freshness.md`
- `docs\00631l_backtest_guide.md`
- `docs\00631l_position_tracking.md`

Current source timing:

- Yuanta holdings ratio is an official daily snapshot, not an intraday holdings feed.
- TWSE intraday NAV is the fast-updating market price, estimated NAV, premium/discount, and data-time source.
- TWSE price history is cached locally after running the update script.
- Static public mode reads `00631l-static-data` generated from official TWSE price history and TWSE all-ETF catalog snapshots.
- TAIFEX TX live quote is available through the backend and is shown separately from daily Yuanta holdings.
- TWSE all-ETF catalog import supports search/catalog data; 00631L remains the focused app.
- Selected ETF price history can be imported with `scripts\00631l_import_etf_price_history.cmd`; this prepares comparison data without changing the app focus.

## 00631L lab v1.0 completed

Release status: completed on 2026-06-08. Release summary: `docs/00631l_v1_release_summary.md`. Release checklist: `docs/00631l_release_checklist.md`.

Main 00631L documentation entry: `docs/00631l_docs_index.md`.

The 00631L lab remains a single-product tool. TAIFEX TX live quote is available through backend data status, while the app still does not expand to all leveraged ETFs and does not provide buy/sell advice.

Default mode is mock/fallback. Live proxy mode requires:

```powershell
flutter run -d chrome --dart-define=USE_00631L_LIVE_PROXY=true --dart-define=00631L_PROXY_BASE_URL=http://127.0.0.1:8000
```

v1.0 live sources:

- Yuanta 00631L Basic information: live official through backend proxy.
- Yuanta 00631L holdings ratio: live official daily snapshot through backend proxy.
- TWSE intraday NAV: live official through `https://mis.twse.com.tw/stock/data/all_etf.txt`, `sourceContract: twse_a_k_json`.
- Yuanta INAV: verified official fallback, `sourceContract: yuanta_inav`.
- TX quote: TAIFEX live through backend when available; otherwise cached/unavailable/mock is labeled explicitly.
- Premium/discount status: shown as a price-deviation hint only, based on intraday NAV `premiumDiscountPct`, and not shown as official when data is stale or unavailable.
- Holdings history v1.2: backend stores official Yuanta ratio snapshots locally by `tradeDate` in JSONL and exposes `/api/etf/00631l/holdings/history` plus `/summary`; default mock mode shows no official history.
- Holdings change notices v1.3: compares the latest two official holdings history rows and shows data-status reminders for TX, TSMC, cash/margin, and exposure changes. These reminders are not trading advice.
- Intraday premium/discount history v1.4: backend stores official intraday NAV samples locally and the app shows today's highest, lowest, and average premium/discount. This is not a trading signal.
- Status summary v1.5: combines official holdings freshness, intraday NAV status, premium/discount state, holdings change notices, and intraday history into a non-advice data health summary.
- Daily workflow v1.6: `docs/00631l_v1_6_daily_runbook.md` documents backend startup, live proxy mode, smoke checks, and web build flow. `scripts/00631l_release_validate.ps1` runs the release validation sequence.
- Daily collector v1.7: `backend/scripts/collect_00631l_snapshot.py` and `scripts/00631l_collect_snapshot.cmd` collect official holdings and intraday NAV samples into local JSONL history without requiring the Flutter page to be open.
- Holdings trend v1.8: the daily holdings history section shows a simple trend chart for TX weight, TSMC weight, and cash/margin weight, while keeping the table as the source-of-truth detail view.
- Intraday premium trend v1.9: the intraday premium/discount history section shows a simple premiumDiscountPct trend chart with a 0% reference line, using only stored official intraday NAV history.
- Operations status v1.10: backend exposes local collector/history readiness at `/api/etf/00631l/operations/status`, and the lab page shows whether holdings history, intraday samples, and intraday NAV URLs are configured.
- History export v1.11: `scripts/00631l_export_history.cmd` exports local holdings and intraday JSONL history into CSV files under `backend/exports/` for backup or offline review.
- Daily cycle v1.12: `scripts/00631l_daily_cycle.cmd` runs collect, export, and live smoke in one command.
- Local startup checks v1.13: `scripts/00631l_check_env.cmd`, `scripts/00631l_start_backend.cmd`, and `scripts/00631l_start_frontend_live.cmd` provide one-command local environment, backend, and live proxy startup flows.
- Data freshness summary v1.14: `/api/etf/00631l/operations/status` reports local history, intraday samples, export availability, env readiness, and latest daily cycle state; `/00631l-lab` shows a compact "今日資料狀態" section.
- Daily cycle status v1.15: `scripts/00631l_daily_cycle.cmd` records the latest run result to local ignored state at `backend/data/00631l_daily_cycle_status.json`.
- Holdings history polish v1.16: `/00631l-lab` adds a recent 7-row holdings summary plus day-over-day and first-to-latest change columns for key official holdings history metrics.
- CSV export v1.17: history export includes exposure columns, source metadata, row counts, source history range, and `00631l_history_export_metadata.json`.
- Release check v1.18: `scripts/00631l_release_check.cmd` runs env check, Flutter validation, backend tests, daily cycle, export, smoke, wording scan, and git diff check in one command.
- Daily usage v1.19: `docs/00631l_daily_usage.md` gives the daily startup, collection, export, status review, and fallback interpretation flow.
- Final daily-use release v1.20: `docs/00631l_v1_20_final_summary.md` summarizes the completed daily-use scope, live/fallback sources, scripts, endpoints, tests, and limitations.
- Entry experience v1.21: Dashboard now has a clear `00631L 正二研究室` entry and the live frontend startup script prints the direct `/#/00631l-lab` route.
- Mobile layout v1.22: `/00631l-lab` uses compact one-column cards and horizontal tables on phone-width screens.
- Web app metadata v1.23: Flutter web manifest and HTML metadata now present the app as `00631L 正二研究室` and start at `/#/00631l-lab` when installed.
- Local data backup v1.24: `scripts/00631l_backup_data.cmd` writes local history/status/export metadata backups under ignored `backend/backups/`.
- Data directory health v1.25: environment check and operations/status report local `backend/data`, `backend/exports`, and `backend/backups` readiness.
- Open lab helper v1.26: `scripts/00631l_open_lab.cmd` runs the local environment check, reports backend reachability, and prints the backend, daily cycle, live frontend, and direct `/#/00631l-lab` route commands.
- Troubleshooting v1.27: `docs/00631l_troubleshooting.md` covers common local startup, backend, intraday NAV, smoke WARN, Flutter path, CSV export, and history data issues.
- Operations guidance v1.28: `/00631l-lab` shows app operation next steps for daily cycle, `.env`, intraday NAV availability, CSV export, backup, and data directory checks.
- Deployment notes v1.29: `docs/00631l_deployment_notes.md` documents local mode, Flutter web build output, backend proxy needs, `.env`, data persistence, GitHub Pages limits, and home server/VPS considerations.
- Daily experience release v1.30: `docs/00631l_v1_30_daily_experience_summary.md` summarizes direct entry, mobile layout, PWA metadata, backup, data health, helper scripts, troubleshooting, deployment notes, and operations guidance.
- Scheduler prep v1.31: `scripts/00631l_daily_cycle_scheduled.cmd` and `docs/00631l_scheduler_setup.md` prepare Windows Task Scheduler usage for daily cycle runs.
- Daily report v1.32: daily cycle now writes a local Markdown report under ignored `backend/reports/`; `scripts/00631l_generate_daily_report.cmd` can regenerate it manually.
- Operations report UI v1.33: `/api/etf/00631l/operations/status` and `/00631l-lab` show latest daily report availability, overallStatus, generatedAt, and WARN/FAIL counts.
- Data integrity v1.34: `scripts/00631l_check_integrity.cmd` checks local holdings/intraday JSONL for duplicate keys, missing required fields, weekday gaps, and abnormal source statuses.
- Backup rotation v1.35: `scripts/00631l_backup_data.cmd` keeps the latest configured number of local backup archives, default 30.
- Restore dry-run v1.36: `scripts/00631l_restore_dry_run.cmd` verifies the latest local backup archive can be read without overwriting any data.
- Daily report guide v1.37: `docs/00631l_daily_report_guide.md` explains how to read Markdown reports, WARN states, FAIL states, source status, and local report files.
- Release check v1.38: `scripts\00631l_release_check.cmd` now also checks scheduler artifacts, report generation, integrity, backup rotation, and restore dry-run.
- Maintenance stability v1.39: `docs/00631l_maintenance_index.md` consolidates maintenance docs and key scripts now use a compact `[summary] overallStatus=...` line.
- Maintenance release v1.40: `docs/00631l_v1_40_maintenance_summary.md` summarizes the semi-automated daily maintenance release line.
- Deployment bootstrap v1.41: `scripts\00631l_bootstrap_deploy.cmd` prepares dependencies, `.env`, local directories, and environment checks before deployment or first use.
- Backend health v1.42: `/health` and operations/status now expose deployment-friendly backend health, source configuration, and local-state readiness metadata.
- Backend disconnected state v1.43: live proxy fallback now keeps `/00631l-lab` readable while explicitly showing `backend disconnected` and mock/fallback status.
- Daily report UI v1.44: `/00631l-lab` now shows the latest local daily report status, generated time, WARN/FAIL counts, and report path.
- Retention policy v1.45: `scripts\00631l_apply_retention.cmd` prunes old daily report Markdown files, reports fixed CSV export retention state, and keeps JSONL history as the long-term local record.
- Backup checksum v1.46: local backup manifests include SHA256 per included file, and restore dry-run verifies archive entries before any manual restore workflow.
- Release check v1.47: `scripts\00631l_release_check.cmd` now includes deployment precheck and retention dry-run coverage.
- Documentation index v1.48: `docs\00631l_docs_index.md` is the main entry point for daily use, troubleshooting, maintenance, deployment, and release-summary routing.
- Stability patch v1.49: backend tests verify that local paths in `docs\00631l_docs_index.md` exist, and release check requires the docs index.
- Deployment stability release v1.50: `docs\00631l_v1_50_deployment_stability_summary.md` summarizes the stable deployment and data reliability checkpoint.
- Mobile + AI v2.1: `docs\00631l_mobile_usage.md` explains LAN phone usage, and `docs\00631l_ai_analysis.md` explains rule-based AI analysis. holdings/ratio remains a daily official snapshot; intraday NAV is the 15–30 second live/cached source; TX live uses TAIFEX through backend when available; fallback states stay explicit.
- Public deploy-ready v2.2: `backend\Dockerfile`, `scripts\00631l_check_public_config.cmd`, `scripts\00631l_build_web_public.cmd`, `docs\00631l_public_deployment.md`, and `docs\00631l_pwa_usage.md` prepare the lab for a public Flutter Web frontend plus public FastAPI backend. Local LAN mode remains available.
- Static-public v3.1: GitHub Pages can serve generated 00631L price history and backtest data without a live backend.
- Standalone PWA v3.2: the public root URL opens `00631L 正二研究室` directly; `/#/00631l-lab` remains compatible.
- Live-public ready v3.3: backend deployment package, `/ready`, persistent volume guidance, deploy templates, and live-to-static frontend fallback are complete.

Local backend env:

```powershell
cd C:\dev\longterm_stock_research_assistant
Copy-Item backend\.env.example backend\.env
```

Start backend:

```powershell
.\backend\run_dev.ps1
```

CMD wrapper:

```cmd
scripts\00631l_start_backend.cmd
```

Start frontend live proxy:

```powershell
flutter run -d chrome --dart-define=USE_00631L_LIVE_PROXY=true --dart-define=00631L_PROXY_BASE_URL=http://127.0.0.1:8000
```

CMD wrapper:

```cmd
scripts\00631l_start_frontend_live.cmd
```

Check local environment:

```cmd
scripts\00631l_check_env.cmd
```

Manual smoke:

```powershell
.\scripts\00631l_daily_smoke.ps1
```

Holdings history is populated by calling the backend holdings endpoint after the backend is running:

```powershell
Invoke-RestMethod http://127.0.0.1:8000/api/etf/00631l/holdings
Invoke-RestMethod http://127.0.0.1:8000/api/etf/00631l/holdings/history/summary?limit=30
```

Daily collector:

```cmd
scripts\00631l_collect_snapshot.cmd --samples 1
```

For intraday observation, run repeated samples with an interval at least as long as the configured intraday NAV cache seconds:

```cmd
scripts\00631l_collect_snapshot.cmd --skip-profile --skip-holdings --samples 20 --interval-seconds 15
```

Export local history:

```cmd
scripts\00631l_export_history.cmd
```

Back up local 00631L data:

```cmd
scripts\00631l_backup_data.cmd
```

Open the 00631L lab daily helper:

```cmd
scripts\00631l_open_lab.cmd
```

Run the daily cycle:

```cmd
scripts\00631l_daily_cycle.cmd
```

The smoke script prints an `[overall]` block with `PASS`, `WARN`, or `FAIL`. A freshness warning after market close is a manual-review warning, not an automatic app test failure.

Release checklist:

```text
docs/00631l_release_checklist.md
```

Daily usage guide:

```text
docs/00631l_daily_usage.md
```

Daily report guide:

```text
docs/00631l_daily_report_guide.md
```

Maintenance index:

```text
docs/00631l_maintenance_index.md
```

Maintenance release summary:

```text
docs/00631l_v1_40_maintenance_summary.md
```

Deployment bootstrap:

```cmd
scripts\00631l_bootstrap_deploy.cmd
```

Troubleshooting guide:

```text
docs/00631l_troubleshooting.md
```

Deployment notes:

```text
docs/00631l_deployment_notes.md
```

Daily experience release summary:

```text
docs/00631l_v1_30_daily_experience_summary.md
```

Windows Task Scheduler setup:

```text
docs/00631l_scheduler_setup.md
```

Generate the latest local daily report:

```cmd
scripts\00631l_generate_daily_report.cmd
```

Check local history integrity:

```cmd
scripts\00631l_check_integrity.cmd
```

Backup with rotation:

```cmd
scripts\00631l_backup_data.cmd --retention-count 30
```

Restore dry-run:

```cmd
scripts\00631l_restore_dry_run.cmd
```

Final v1.20 summary:

```text
docs/00631l_v1_20_final_summary.md
```

Full local validation wrapper:

```powershell
.\scripts\00631l_release_validate.ps1
```

If PowerShell script execution is disabled locally, use:

```cmd
scripts\00631l_release_validate.cmd
```

Official daily holdings are daily snapshots. Intraday NAV is only market price, estimated NAV, premium/discount, and timestamps. If live proxy or intraday URLs are unavailable, the app must show `mock`, `cached`, `unavailable`, or `error` state clearly and must not label fallback data as official.

## 00631L live smoke - 2026-06-08

The 00631L lab remains a single-product MVP. Do not treat mock data as official data.

Manual backend live smoke:

```powershell
cd C:\dev\longterm_stock_research_assistant
py backend\scripts\smoke_00631l_live.py
```

Run backend proxy:

```powershell
py -m uvicorn backend.app.main:app --host 127.0.0.1 --port 8000
```

Optional intraday NAV live proxy env:

```powershell
$env:TWSE_00631L_INTRADAY_NAV_URL="https://mis.twse.com.tw/stock/data/all_etf.txt"
$env:YUANTA_00631L_INTRADAY_NAV_URL="https://etfapi.yuantaetfs.com/ectranslation/api/trans?APIType=ETFBackstage&CompanyName=YUANTAFUNDS&PageName=%2FtradeInfo%2FINav%2FAsia_ETF&DeviceId=00000000-0000-4000-8000-000000000631&FuncId=ETFNAV%2FGetINAV_Data&AppName=ETF&Device=4&Platform=ETF"
${env:00631L_INTRADAY_NAV_SOURCE}="auto"
${env:00631L_PROFILE_CACHE_SECONDS}="86400"
${env:00631L_HOLDINGS_CACHE_SECONDS}="600"
${env:00631L_INTRADAY_NAV_CACHE_SECONDS}="15"
```

Run Flutter with live proxy:

```powershell
flutter run -d chrome --dart-define=USE_00631L_LIVE_PROXY=true --dart-define=00631L_PROXY_BASE_URL=http://127.0.0.1:8000
```

Direct web route:

```text
http://127.0.0.1:<flutter-port>/#/00631l-lab
```

Current source status:

- Yuanta 00631L Basic information: verified live through backend proxy.
- Yuanta 00631L holdings ratio: verified live through backend proxy.
- Intraday NAV: verified via TWSE official `all_etf.txt` aggregate a-k feed when `TWSE_00631L_INTRADAY_NAV_URL` is configured. Yuanta INAV is also supported as `sourceContract: yuanta_inav` fallback.
- TX quote: TAIFEX live through backend when available; otherwise cached/unavailable/mock is labeled explicitly.

Official daily holdings are not intraday live holdings. Intraday data should only be used for market price, estimated NAV, and premium/discount observation.

## 00631L live proxy validation notes

`00631L 正二研究室` 預設仍使用 mock/fallback，不會把 mock 偽裝成官方資料。若要使用 live proxy，先啟動 backend：

```powershell
py -m pip install -r backend\requirements.txt
py -m uvicorn backend.app.main:app --reload --host 127.0.0.1 --port 8000
```

再以 dart define 啟用前端 proxy：

```powershell
flutter run -d chrome --dart-define=USE_00631L_LIVE_PROXY=true --dart-define=00631L_PROXY_BASE_URL=http://localhost:8000
```

官方每日內容物是每日快照；盤中即時資料是市價、預估淨值與折溢價。live proxy 是為了解決 Flutter Web CORS 與來源格式處理問題。更多細節見 `docs/00631l_lab.md`、`docs/00631l_live_proxy.md`、`docs/windows_flutter_policy_block.md`。

Flutter SDK policy block has been resolved locally by using the clean official SDK at `C:\src\flutter-clean`. Current validation commands pass: `flutter analyze`, `flutter test`, `flutter build web`, and `py -m unittest discover -s backend\tests`. Historical Windows policy details remain in `docs/windows_flutter_policy_block.md`.

中長線股票研究助理是一個 Flutter Web MVP，定位為研究與教育用途的股票研究工具。v0.2 以本地模擬資料呈現財報趨勢、估值區間、風險提醒、條件篩選、策略研究、ETF 比較、投資組合風險與輔助研究筆記流程。

## Flutter Test Runner Note

This Flutter app uses `flutter_test`; the primary app test command is:

```powershell
flutter test
```

`dart test` is not the main validation command for this repo because the project does not currently define a pure Dart `package:test` test runner. Do not treat `dart test` package-not-found output as an app test failure unless a future change intentionally adds `package:test` tests.

## GitHub Pages Demo

公開 Demo：

```text
https://dany1230000.github.io/longterm_stock_research_assistant/
```

## Demo 狀態

- 目前是 Web MVP Demo 版本。
- 目前使用本地模擬資料，不串接真實股市 API。
- 內容僅供研究與教育用途，不構成投資建議、買賣建議或收益保證。
- 目前沒有登入、後端、訂閱制或永久資料儲存。

## 本機開發方式

```bash
flutter pub get
dart format .
flutter analyze
flutter test
flutter run -d chrome
```

## Web Build 方式

一般本機 build：

```bash
flutter build web
```

GitHub Pages project page build：

```bash
flutter build web --base-href="/longterm_stock_research_assistant/"
```

`build/web` 是部署產物。

## 主要功能

- 研究工作台：今日研究摘要、觀察清單、估值偏高觀察清單、營收轉強觀察清單、風險升高觀察清單、產業分布與快速入口。
- 個股詳情頁：總覽、財務、估值、營收、籌碼 / 觀察資料、風險、研究筆記七個分段。
- 條件篩選頁：以 ROE、營收 YoY、PE、PB、殖利率、分數、風險程度、產業與長期均線整理條件篩選結果，並支援 preset。
- 策略研究頁：以模擬歷史資料呈現多策略統計、年度報酬表、權益曲線、回撤曲線與 0050 比較。
- 投資組合頁：持股總覽、持股清單、產業集中度、曝險、風險提醒與情境模擬。
- ETF 比較頁：兩檔 ETF mock 比較、持股、產業曝險與重疊率提醒。
- 00631L 正二研究室：單一 00631L MVP，整理元大官方每日內容物、TWSE 即時淨值格式資料、TX 期貨觀察與基礎分析摘要；目前預設使用明確標示的 mock/fallback。
- 提醒中心：營收、估值、風險、ETF、投資組合與 mock 事件提醒。
- 研究筆記頁：作為輔助頁保留，支援觀察紀錄新增、編輯、刪除與篩選，資料暫存於 memory repository。
- 設定頁：免責聲明、資料來源、授權提醒、版本資訊與未來功能 placeholder。

## 專案架構

```text
lib/
  main.dart
  app.dart
  router.dart
  theme/
  models/
  repositories/
  services/
  features/
    dashboard/
    stock_detail/
    screener/
    backtest/
    portfolio_risk/
    etf_compare/
    leveraged_etf_lab/
    alerts/
    journal/
    settings/
  shared/
    widgets/
    utils/
test/
docs/
```

## 技術選擇

- Flutter / Dart
- Riverpod
- go_router
- fl_chart
- 本地 mock repository

## 產品語氣

App 文案必須維持研究參考、觀察清單、條件篩選結果、歷史統計與風險提醒語氣。不得使用交易指令、價格承諾、收益承諾或煽動式文案。

## 00631L 正二研究室

詳細設計與資料限制見 `docs/00631l_lab.md`。此頁只針對 00631L，不擴大成全市場正二或所有槓桿 ETF。官方每日內容物與盤中估算資料分開標示；若 live source 被 CORS 阻擋，需透過 backend/proxy 接入，不能把 mock 資料偽裝成官方即時資料。

v4.21 補強 AI 分析頁的當日資料狀態：先顯示 readiness、backend/static/mock 狀態、official holdings 日期、盤中 NAV 時間、歷史 coverage 與需要的程式操作。AI 仍採 rule_based，僅解釋資料狀態與缺口，非買賣建議。

v4.22 將 00631L 歷史價格與 static public export 的預設更新改為 incremental，只回抓最新 cached 月份；需要全量回補時再使用 `--full-refresh`。這讓日常更新更快，也降低舊月份網路 timeout 對 daily flow 的干擾。

v4.23 強化 GitHub Pages static build：CI 若沒有 `backend/data`，會先載入 committed seed history，再做 incremental update，避免 public build 嘗試全量抓取。

v4.24 將泛用 ETF price-history import 也改成每檔 incremental 預設，並保留 `--full-refresh` 作為明確回補選項。這是 ETF 搜尋、切換與未來比較頁的資料穩定性基礎。

## 下一步

- 建立資料授權清單與資料欄位規格。
- 設計 API-backed repository，但保留 mock repository。
- 補充更多 widget 測試與視覺回歸檢查。
- 規劃研究提醒、ETF 比較、投資組合風險分析與 AI 摘要。
## 00631L public maintenance

v4.67 adds public batch resume status to
`scripts\00631l_public_maintenance_status.cmd`. The summary now shows the
latest public ETF catalog batch state and the next resume offset when local
state exists.

```cmd
scripts\00631l_public_maintenance_status.cmd --soft-fail
scripts\00631l_public_etf_catalog_batches.cmd --resume --batch-size 1 --max-batches 1 --soft-fail
```

v4.68 also suggests a concrete `--start-offset` when the public backend already
has ETF history rows but no usable resume offset exists.

v4.69 converts public ETF catalog batch timeout exceptions into JSON payloads
and resume state, so soft-fail maintenance runs do not end as tracebacks.

v4.70 includes child batch failure details in top-level public catalog batch
payloads, making HTTP 502 and timeout reasons visible without reading each step.

v4.71 stops public ETF catalog batches after the first failed offset by default;
use `--continue-on-failure` only for deliberate diagnostic runs.

v4.72 flags public ETF history ready-count regression in
`scripts\00631l_public_maintenance_status.cmd`. If the current public backend
ready count is lower than the latest local batch state, check the persistent
data volume and redeploy status before continuing catalog batches.

v4.73 preserves useful public catalog batch resume state when the catalog status
temporarily reports unavailable. A low-information zero-row catalog warning no
longer replaces the last known `nextOffset`, `failedOffset`, or ready-count
progress.

v4.74 adjusts the public catalog batch `nextOffset` after partial progress. If
a request times out but the public `readyCount` increases, the next action uses
the newer ready count instead of repeating the just-completed offset.

v4.75 changes public catalog batch action items when `readyCount` moves
backward during the same run. In that case, check public backend persistence
and redeploy status before continuing offsets.

v4.76 adds `scripts\00631l_public_history_stability.cmd`, a read-only sampler
for public `/api/etf/history/status`. Use it before catalog batches when public
ETF ready counts look inconsistent.

v4.77 reduces noise in `scripts\00631l_public_deploy_drift.cmd`: when the
public backend release tag matches the expected tag, a missing public git SHA is
reported as metadata quality instead of changing the overall status to WARN.

v4.78 adds `scripts\00631l_wait_public_deploy.cmd`, a read-only helper that
polls public deploy drift until the public backend exposes the expected release
tag. Run it after pushing backend releases and before continuing public ETF
history catalog batches.

v4.79 keeps `scripts\00631l_public_backend_status.cmd` useful when a public
host can serve static/seed data but its data directory is not writable. The
script reports that state as WARN for read-only observation while `/ready`
continues to flag the deployment persistence problem.

v4.80 makes `scripts\00631l_public_maintenance_status.cmd` persistence-first:
when the public backend data path is unhealthy, the next action is to fix the
public volume before running ETF history catalog batches.

v4.81 makes public ETF catalog batches production-safe by default. The runner
now plans one catalog item at a time, runs deploy/stability preflight before
remote writes, and only suggests `--batch-size 1 --max-batches 1` in current
maintenance guidance.

v4.82 keeps successful public catalog batch payloads consistent with that
guidance: next-offset action items now include `--batch-size 1 --max-batches 1
--soft-fail`.

v4.83 blocks catalog batch suggestions whenever public backend readiness is
failing. Fix public readiness or persistence first, then continue ETF catalog
history maintenance.

v4.84 isolates public catalog batch tests from local operational state. Backend
tests no longer write `backend\data\00631l_public_etf_catalog_batch_state.json`
unless a test passes an explicit temporary state path.

v4.85 improves public catalog batch observability. Each batch now reports the
requested ETF code, source status, saved rows, coverage, and item error so an
unavailable catalog row can be skipped without pretending it was imported.

v4.86 adds an independent public readiness probe to maintenance status. If any
readiness sample is WARN/FAIL, ETF catalog batch commands are hidden until the
public backend data directory and persistence checks are healthy.

v4.87 carries remote ETF history update item details through maintenance
wrappers, so public batch output can show requested codes, saved rows, coverage,
and per-code errors instead of only readyCount changes.

v4.88 blocks all public catalog batch commands when public readyCount regresses
below the last successful batch state. Fix public backend persistence before
continuing data import.

v4.89 adds path-level public storage diagnostics. `/ready` now checks the
effective holdings, intraday, 00631L price, ETF catalog, multi-ETF history,
daily-cycle, integrity, restore, export, backup, and report paths so a deployed
backend can show whether required data is really writing under the persistent
`00631L_DATA_DIR`.

v4.90 adds a public persistence marker. The backend writes a small marker file
inside `00631L_DATA_DIR` and reports its `createdAt`, age, and newly-created
state through `/ready`, operations/status, and public backend status checks.
Use it with readyCount after redeploys to tell whether the public data volume is
actually being preserved.

v4.91 carries the public persistence marker into maintenance status. The daily
public maintenance output now shows marker createdAt/age/newlyCreated next to
ETF readyCount, and asks for a recheck after the next deploy when the marker was
just created.

v4.92 treats a very fresh public persistence marker plus low ETF readyCount as a
batch blocker. In that state, maintenance output hides public ETF catalog batch
commands and asks you to verify the hosted persistent volume first.

v4.93 refreshes backend release metadata so `/health`, deploy drift, and deploy
wait checks target the current release tag instead of the previous public marker
maintenance tag.

v4.94 adds Render persistent disk Blueprint configuration. Both `render.yaml`
and `deploy\render.yaml` now mount `/data/00631l`, and public config checks
verify the disk fields before release.

v4.95 makes `/ready` warn when a persistent-mode backend has a fresh persistence
marker. This keeps newly recreated public data directories visible even when the
path is writable.

v4.96 adds `scripts\00631l_verify_public_persistence.cmd`, a read-only verifier
that samples the public backend marker and ETF ready count before public catalog
batch maintenance. Use it after Render deploys and before continuing ETF data
imports.

v4.97 makes that verifier stricter: if any public sample is missing persistence
marker details, it reports WARN and asks for `/ready` inspection before data
batch maintenance continues.

v4.98 classifies observed public backend readiness/storage failures as verifier
WARN instead of checker failure. Request errors can still fail the verifier.

v4.99 tightens the mobile home context. The top bar subtitle follows the
currently selected ETF, the first screen uses a compact DATA ribbon for price
field / split-adjustment / coverage status, and full data-correctness details
move under `更多資料`.

v5.0 defers multi-ETF comparison history loading until the user opens
`歷史回測`. The overview page now avoids preloading the comparison basket, which
keeps the public PWA first screen lighter on mobile.

v5.1 improves history chart readability. Chart x-axis labels now show `YYYY`
and `MM/DD`, and every chart displays the latest date/value by default before
the user touches a point.

v5.2 cleans up ETF comparison wording. The ETF database and settings pages now
describe the current self-selected comparison flow instead of showing old
roadmap text.

v5.3 shortens the mobile overview by replacing the stacked exposure bars with a
single official-exposure row on phone width. Wider screens still use the fuller
exposure layout.

v5.4 makes the left-top symbol search clearer. Each ETF result now states
whether switching enables history/backtest/comparison or only a catalog
snapshot.

v5.5 makes the history/backtest date range easier to read. History charts and
backtest results now show a compact range context strip with the selected
dates, row/sample count, and latest data date before the detailed cards.

v5.6 makes the position page feel more like an account view. It adds a compact
local-only position summary before the input form and keeps save/export/clear
controls in place.

v5.7 strengthens the rule-based AI summary. The backend now emits a clearer
daily briefing for holdings date, intraday NAV time, premium-discount range,
exposure context, and data-risk status.

v5.8 makes the AI page easier to scan on mobile. The page now opens with
three compact briefing cards for daily status, intraday premium/discount
context, and data-risk context, while the full rule-based report remains
available in the detail panel.

v5.9 makes the settings page feel more like an account/settings tab. It now
starts with compact cards for no-login usage, selected ETF, frontend data mode,
and daily readiness, while deployment diagnostics remain in expandable panels.

v5.10 makes data readiness visible on the overview page. The DATA ribbon now
shows coverage type and ETF history readiness count next to the selected ETF,
price field, split-adjustment status, and loaded row count.

v5.11 makes the top-left symbol search sheet clearer about imported data. It
now shows the ETF history coverage ratio, using the actual ready-history count
against the current catalog row count.

v5.12 makes ETF history comparison read as a user-selected basket. The
history/backtest page now labels the comparison group as `目前 basket`, keeps
the 1-5 ETF limit clear, and avoids implying that every comparison is fixed to
00631L.

v5.13 makes selected ETF history quality more explicit. The history/backtest
quality card now labels split-adjustment status as `分割調整`, distinguishing
split-adjusted, adjusted-price-available, and unadjusted histories.

v5.14 surfaces ETF data-library readiness in the settings page. Users can now
see catalog count, history-ready count, long-term/recent coverage tiers, and
data time without opening maintenance diagnostics.

v5.15 adds history-availability filters to the left-top symbol search sheet.
Users can filter search results by all ETFs, history-ready ETFs, or catalog-only
ETFs before switching the active research symbol.

v5.16 adds a selected ETF readiness banner on the overview screen. After
switching symbols, the first screen states whether the ETF has imported
history/backtest data or only catalog fields, with program-operation guidance.

v5.17 adds a date inspector below the overview price chart. The home chart keeps
its one-year default window, but now shows the selected or latest date and value
instead of leaving users to infer chart points from the line alone.

v5.18 adds a top-level AI today snapshot. The AI page now starts with holdings
date, intraday NAV time, premium/discount status, price history coverage, and
program-operation guidance before the longer rule-based details.

v5.19 adds an ETF data readiness ratio to Settings. The ETF data library now
shows the share of catalog symbols that have imported price history, making data
coverage easier to verify before switching symbols or running comparisons.

v5.20 adds an ETF room readiness panel to Settings. It summarizes public PWA,
00631L core data, multi-ETF history readiness, selected symbol readiness,
local-only position data, and rule-based AI status in one checklist.

v5.21 improves the ETF comparison basket. History/backtest comparison now
starts from the active ETF's peer group, lets users clear the basket, apply a
peer preset, or view only the active ETF, and avoids treating 00631L as a fixed
comparison baseline.

v5.22 adds a compact overview update-time strip. The first screen now separates
official daily holdings, live intraday NAV, TX quote time, and historical price
coverage so users can see which data is daily, live, or static at a glance.

v5.23 compacts the position page. The account-style summary remains visible,
while detailed value/cost/PnL calculations move into an expandable estimate
detail block so mobile users can reach the local input and export controls
faster.

v5.24 strengthens the rule-based AI page with a daily interpretation matrix.
It separates freshness, premium/discount, holdings movement, and historical
coverage into short status cards while keeping the output non-directional and
data-focused.

v5.25 moves ETF data completion status into the left-top ETF search sheet.
Catalog count, history-ready count, coverage tiers, remaining gap, and data
time are visible before users search or switch ETFs, while Settings keeps the
same maintenance summary.

v5.26 makes history chart dates easier to read. Compact charts now show full
start, middle, and end dates below the chart while keeping tap-to-inspect date
details.

v5.27 makes ETF data-completion counts stricter. The app now compares imported
ETF price histories against the broader catalog count when available, so the
visible gap does not disappear just because the history index itself is fully
ready.

v5.28 makes ETF import status output stricter too. The multi-ETF history
status command now prints catalogSymbols and gap, so daily maintenance can see
which catalog rows still lack usable price-history coverage.

v5.29 aligns local Dart formatting with the GitHub Pages workflow gate. The
public Pages build runs `dart format --set-exit-if-changed .`, so local release
work now keeps that check clean before pushing.

v5.30 adds that Dart formatting gate directly to `scripts\00631l_release_check.cmd`.
Release validation now catches formatter drift before GitHub Pages starts its
public build.

v5.31 tightens ETF data readiness wording. The app now labels the section as
`ETF 資料庫狀態` and clarifies that history-ready ETFs support history,
backtest, and comparison, but do not imply that official holdings history is
complete.

v5.32 makes the overview update-time area more compact. DAY, LIVE, TX, and HIS
timestamps are shown in one horizontal ticker so the mobile first screen reaches
the chart sooner.

v5.33 moves the overview price chart directly under the quote header. Data
quality and update-time strips still remain visible, but they no longer push the
chart below the first screen.

v5.34 adds a public GitHub Pages smoke check. Release validation now verifies
that the deployed root page, PWA manifest, and static public data status are
reachable and still identify the 00631L app before a release is treated as
ready.

v5.35 adds a GitHub Pages deployment-status check. It reports the latest Pages
workflow run and GitHub Pages settings alongside the public smoke result, so
public phone deployment problems are visible from the local release flow.

v5.36 adds a Pages deploy wait helper. After pushing a release, run
`scripts\00631l_wait_pages_deploy.cmd` to wait for the GitHub Pages workflow to
finish and confirm the public PWA smoke check passes for the expected commit.

v5.37 adds `scripts\00631l_public_pages_checkup.cmd`, a short daily check for
the public phone app. It reports the public URL, static data rows and coverage,
and latest GitHub Pages workflow state in one output.

v5.38 makes the public Pages checkup rate-limit friendly. Daily public app
checks can run with `scripts\00631l_public_pages_checkup.cmd --skip-github-api`
to verify the public PWA and static data without consuming GitHub workflow API
quota; release checks still keep one deploy-status step for post-push context.

v5.39 adds a public release marker to `00631l-static-data`. Static export now
writes `release.json`, and public smoke checks report the deployed app version,
release tag, commit SHA, and build time directly from the public Pages files.

v5.40 improves release-marker guidance. Public Pages checkup now reports
`releaseMarkerStatus` and gives a concrete rerun command while GitHub Pages is
still deploying the static bundle.

v5.41 adds explicit release mismatch guidance. If public Pages is reachable but
`release.json` still points to an older commit, checkup reports
`releaseMatchesExpected=false` with failures empty and a rerun action.

v5.42 adds a public-only release marker wait command:
`scripts\00631l_wait_public_release_marker.cmd --expected-sha <commit>`.
It polls the public `release.json` served by GitHub Pages and avoids the GitHub
Actions API, so post-push checks still work when API quota is limited.

v5.43 reads that static `release.json` inside the PWA operations status. The
settings page can show the public static release version, tag, commit, and
build time directly on mobile.

v5.44 adds `--summary-only` to
`scripts\00631l_wait_public_release_marker.cmd`. Release checks now use compact
public-release wait output by default, while the full sampled payload remains
available for debugging.

v5.45 shortens that summary output further. Daily waits now show first/latest
release-marker samples and the transition count; add `--include-attempts` only
when each polling attempt is needed for debugging.

v5.46 adds `--summary-only` to `scripts\00631l_public_pages_checkup.cmd` and
uses it in release check. Daily public phone-app checks now show the public URL,
release marker, row count, coverage, and workflow mode without printing full
nested smoke payloads.

v5.47 makes `scripts\00631l_release_check.cmd` compact by default. Use
`scripts\00631l_release_check.cmd --verbose` only when full per-step stdout and
stderr tails are needed for debugging.

v5.48 adds a selected ETF data-context card to the overview and AI pages. When
the top-left selector switches away from 00631L, the app now shows history row
count, coverage, price field, split-adjustment context, backtest readiness, and
live NAV scope before any analysis text.

v5.49 strengthens the selected ETF AI briefing. The rule-based summary now uses
the selected ETF history to describe coverage, latest movement, return,
drawdown, volatility, one-year range position, data field choice, and program
actions for refreshing or extending verified data.

v5.50 adds a compact selected ETF history-readiness strip to the history/backtest
page. After switching the top-left symbol, users can see row count, coverage,
backtest readiness, and live NAV scope before reading the full chart.

v5.51 makes the selected ETF overview more compact. The overview uses the short
history-readiness strip, while the full selected ETF data-context card stays in
the AI section for deeper explanation.

v5.52 removes duplicated selected ETF readiness content from the overview. The
larger readiness banner is kept only for missing-history guidance in the
history/backtest flow.

v5.53 strengthens the top-left ETF selector. Search rows now show capability
badges for history, backtest, comparison, AI context, and live NAV scope before
the user switches symbols.

v5.54 clarifies ETF comparison as a user-selected basket. The history/backtest
page now shows common coverage, minimum row count, and source status for the
selected comparison set.

v5.76 renames the visible comparison wording to `比較組合`, keeping same-category
chips as quick-fill helpers while avoiding the engineering term `basket` in the
mobile UI.

v5.77 makes chart date ticks easier to read by showing full `yyyy/MM/dd` labels
while retaining tap details for exact date and value inspection.

v5.78 improves selected ETF AI wording. The rule-based summary now describes the
latest historical close move, keeps one-year range position in Chinese, and
states when data is historical rather than intraday.

v5.80 records the ETF research-room checkpoint after the data-trust, comparison
wording, chart date-axis, selected ETF AI, and missing-only import pass. Summary:
`docs\00631l_v5_80_etf_research_room_checkpoint.md`.

v5.81 polishes the rightmost bottom tab into a user-facing `我的` page and
replaces search/status debug labels with clearer Chinese readiness wording.
Summary: `docs\00631l_v5_81_my_page_language_polish.md`.

v5.82 adds `scripts\00631l_import_missing_etf_batch.cmd`, a safe default wrapper
for local missing-only ETF price-history batches, and makes missing-only catalog
batches apply `limit` after filtering ready ETFs. Summary:
`docs\00631l_v5_82_missing_etf_batch_helper.md`.

v5.83 wires the missing-only ETF batch into both local Pages builds and the
GitHub Pages workflow, so public static builds can continue filling verified ETF
history gaps. Summary: `docs\00631l_v5_83_pages_missing_etf_batch.md`.

v5.84 adds `scripts\00631l_check_public_static_data.cmd`, a read-only public
Pages checker that merges `status.json`, `manifest.json`, and `release.json` so
daily checks show 00631L rows, coverage, ETF catalog readiness, missing count,
and release marker in one summary. Summary:
`docs\00631l_v5_84_public_static_status_check.md`.

v5.85 adds optional expected release tag/SHA checks to that public static checker.
Use `--expected-sha <commit> --strict-release` after a Pages deploy should have
finished to verify the phone app is serving the intended bundle. Summary:
`docs\00631l_v5_85_public_static_release_match.md`.

v5.86 cleans up remaining English operational labels in the app status surface,
including backend connection, backend release, public static release, public
deployment persistence, and backend-disconnected fallback guidance. Summary:
`docs\00631l_v5_86_public_status_language.md`.

v5.87 adds a `資料補齊動作` row to the ETF data-library status card, so missing
ETF history gaps point directly to `scripts\00631l_import_missing_etf_batch.cmd`
and the follow-up static status check. Summary:
`docs\00631l_v5_87_etf_gap_action.md`.

v5.88 makes GitHub Pages static publishing faster. Push builds now skip the
broad all-catalog recent ETF refresh and keep the selected ETF import plus
missing-only batch; weekday schedule or manual dispatch with
`full_etf_refresh=true` still runs the broad refresh. Local full refresh is
available with `scripts\00631l_build_pages_static.cmd --full-etf-refresh`.
Summary: `docs\00631l_v5_88_pages_fast_static_build.md`.

v5.89 reconciles one verified official ETF history seed. `00407A` had recent
TWSE STOCK_DAY rows in local cache but not in the committed Pages seed set; it
is now included so public static readiness can match local validation. Summary:
`docs\00631l_v5_89_etf_seed_ready_reconcile.md`.

v5.90 separates normal Pages publishing from ETF history maintenance. Push builds
now skip selected/missing ETF history refresh and rely on strict 00631L export
plus committed ETF seeds; schedule/manual dispatch or local
`--refresh-etf-history` / `--full-etf-refresh` runs the slower maintenance
refresh. Summary: `docs\00631l_v5_90_pages_maintenance_split.md`.

v5.91 adds a public static regression guard. GitHub Pages now compares the new
local static export with the currently published static status before upload and
fails if coverage, row count, or ETF ready count would move backward. The 00631L
official price-history seed is also updated through 2026-06-26 so clean runners
can restore the latest validated coverage. Summary:
`docs\00631l_v5_91_static_regression_guard.md`.

v5.92 moves that static regression guard into the normal release check as a real
public comparison, so local validation fails before commit when static coverage
would move backward. Summary: `docs\00631l_v5_92_release_static_guard.md`.

v5.93 adds ETF price-history gap classification. Static/public and live/backend
status now distinguish not-saved, insufficient-row, validation, and source-error
gaps instead of showing only one missing count. Summary:
`docs\00631l_v5_93_etf_gap_classification.md`.

v5.94 persists ETF import-attempt evidence in local data state. Missing ETF
histories can now be classified as `official_empty` only when a STOCK_DAY import
attempt actually returned no rows for the requested months. Summary:
`docs\00631l_v5_94_etf_import_attempts.md`.

v5.95 adds ETF gap-reason counts to the public static-data check output, so
daily Pages verification can show whether remaining ETF history gaps are
not-saved, official-empty, validation-related, or source-related. Summary:
`docs\00631l_v5_95_public_gap_summary.md`.

v5.96 adds `scripts\00631l_probe_missing_etf_reasons.cmd` and attempted-count
metadata for ETF price-history gaps. Missing ETF histories can now be probed in
small batches, with evidence surfaced through backend/static/public status.
Summary: `docs\00631l_v5_96_missing_etf_reason_probe.md`.

v5.97 runs that missing ETF probe as a small `continue-on-error` step in the
GitHub Pages static build, so public data can gradually classify or fill ETF
history gaps without blocking the 00631L app when a source is temporarily
unavailable. Local opt-in: `scripts\00631l_build_pages_static.cmd --probe-missing`.
Summary: `docs\00631l_v5_97_pages_missing_probe.md`.

v5.98 makes the public static-data checker show ETF history row count and
completion gap separately from the current catalog row count. If those counts
temporarily differ, the checker returns WARN with an explanation instead of
hiding the mismatch. Summary:
`docs\00631l_v5_98_public_etf_count_consistency.md`.

v5.99 makes the public missing-ETF probe skip symbols that already have
import-attempt evidence, so scheduled Pages builds can advance to later missing
ETF histories instead of repeating the same first batch. Summary:
`docs\00631l_v5_99_skip_attempted_probe.md`.

v6.0 restores public ETF import-attempt evidence from the previous static export
before running missing-only probes in GitHub Pages. This lets scheduled builds
carry gap evidence forward across clean runners. Summary:
`docs\00631l_v6_0_public_attempt_carry_forward.md`.

v6.84 makes the local Pages static build restore public ETF import-attempt
evidence by default, so local ignored static exports use the same classified ETF
history gap evidence as GitHub Pages. Use
`scripts\00631l_build_pages_static.cmd --skip-restore-public-attempts` only for
offline local builds. Summary:
`docs\00631l_v6_84_local_static_attempt_restore.md`.

v6.85 changes user-facing ETF gap reason labels from internal keys to readable
status text such as `官方無資料`, `來源錯誤`, and `尚未匯入`. The raw API/model
keys remain unchanged. Summary:
`docs\00631l_v6_85_etf_gap_reason_labels.md`.

v6.1 runs three bounded missing-ETF probe batches per Pages deployment after
restoring public attempt evidence, so remaining ETF history gaps can be
classified faster while keeping static export resilient. Summary:
`docs\00631l_v6_1_public_probe_batches.md`.

v6.2 adds `etfPriceHistoryUnclassifiedGapCount` to the public static-data check,
making the remaining unprobed ETF history gap visible without reading the full
gap-reason map. Summary:
`docs\00631l_v6_2_public_unclassified_gap.md`.

v6.3 adds `--max-unclassified-gap` to the public static-data check, so daily
verification can warn when any ETF history gap remains unclassified. Summary:
`docs\00631l_v6_3_public_unclassified_threshold.md`.

v6.4 makes the Pages ETF history import/probe use a runtime TWSE ETF catalog
with seed fallback, so new catalog symbols are not missed by the missing-only
probe. Summary: `docs\00631l_v6_4_runtime_catalog_probe.md`.

v6.5 separates the current ETF catalog count from retained ETF history index
rows. Classified out-of-catalog history rows are reported as
`etfPriceHistoryOutOfCatalogCount` instead of causing a public static-data WARN
by themselves. Summary: `docs\00631l_v6_5_public_catalog_universe.md`.

v6.6 carries `etfPriceHistoryOutOfCatalogCount` into static export, backend
operations status, Flutter repositories, and the app status UI. Classified
missing histories are shown separately from unclassified gaps. Summary:
`docs\00631l_v6_6_etf_library_status.md`.

v6.7 makes release check run the public static-data check with
`--max-unclassified-gap 0`, so unclassified ETF history gaps cannot silently
return. Summary: `docs\00631l_v6_7_public_gap_release_guard.md`.

v6.8 adds `etf_price_history_gaps.json` to public static export so unavailable
ETF histories have inspectable code-level reasons, and public checks report
`etfPriceHistoryGapDetailCount`. Summary:
`docs\00631l_v6_8_etf_gap_detail_export.md`.

v6.9 carries that gap-detail count into backend operations status, Flutter
repositories, and the app settings page as `缺口明細`. Summary:
`docs\00631l_v6_9_gap_detail_status.md`.

v6.10 adds compact ETF gap reason samples, so settings/status and public static
checks can show short code examples for each gap reason without loading the full
gap-detail file. Summary: `docs\00631l_v6_10_gap_reason_samples.md`.

v6.11 adds `GET /api/etf/history/gaps` for filtering ETF price-history gaps by
reason and inspecting full detail from the backend. Summary:
`docs\00631l_v6_11_gap_detail_api.md`.

v6.12 shows ETF price-history gap details inside the app settings page. Live
proxy reads `/api/etf/history/gaps`; static public mode reads
`etf_price_history_gaps.json`. These rows are maintenance status only and are
not used as history, backtest, comparison, or AI performance data. Summary:
`docs\00631l_v6_12_gap_detail_ui.md`.

v6.13 adds reason filters to the app settings `ETF gap details` panel. The
filter helps inspect `official_empty`, `source_error`, and other maintenance
buckets without changing which ETF histories are eligible for history,
backtest, comparison, or AI context. Summary:
`docs\00631l_v6_13_gap_detail_filters.md`.

v6.14 adds ETF search filter result counts, so the top-left ETF/stock search
sheet shows how many ETF rows match the selected `all`, `ready`, or
`catalogOnly` filter for the current query. Summary:
`docs\00631l_v6_14_symbol_search_filter_counts.md`.

v6.15 adds a query-level readiness mix to the same search sheet. It shows
`history-ready` and `catalog-only` counts for the current query before the user
changes filters or switches symbols. Summary:
`docs\00631l_v6_15_symbol_search_readiness_mix.md`.

v6.16 adds selected ETF capability badges after a symbol is chosen. The current
ETF now shows whether history, backtest, comparison, and AI context are ready or
paused because the row is catalog-only. Summary:
`docs\00631l_v6_16_selected_etf_capability_badges.md`.

v6.17 fixes public static release metadata. GitHub Pages now also deploys on
`00631l-lab-v*` tag pushes and tag-triggered builds inject release metadata, so
public `release.json` does not fall back to a stale label. Summary:
`docs\00631l_v6_17_pages_release_tag_trigger.md`.

v6.18 keeps Pages deployment on the main branch and polls for the just-pushed
release tag before static export. This avoids tag-ref deploy rejection while
still keeping public `release.json` aligned with the release tag. Summary:
`docs\00631l_v6_18_pages_release_tag_polling.md`.

v5.55 shortens the position page by moving save, JSON export, and clear actions
directly under the local account summary.

v5.56 adds a daily interpretation card to the AI page, combining holdings date,
intraday NAV time, premium discount state, exposure weights, and the first
program action item.

v5.57 makes the bottom-right settings page more like an account/preferences
area. Daily-use items stay visible first, while ETF data-library details,
deployment readiness, and backend diagnostics are moved behind compact
expanders.

v5.58 tightens the overview first screen. The home page now starts with quote,
core data, visible one-year chart, and official holdings highlights; update
times and data-quality diagnostics live under `更多資料`.

v5.59 shortens the history/backtest page. Date range controls stay visible,
while amount and cost inputs move behind `金額與成本參數`; a compact backtest
result strip replaces the taller result header.

v5.60 shortens the position page. A compact local-only title and account
summary replace the tall position header; saved positions keep edit inputs
behind a compact expander.

v5.61 shortens the AI page first screen. The daily interpretation and three
brief cards stay visible first, while the matrix, data status, complete report,
and integrity details move behind `進階 AI 明細`.

v5.62 improves public static startup. Static mode now loads verified price
history, operations status, AI summary, and ETF catalog through a dedicated fast
path; live-only holdings, intraday NAV, and TX fields stay marked as backend
required instead of falling through mock data.

v5.63 makes the ETF search sheet more compact. The selector keeps the search
field, completion percentage, history-ready count, gap count, filters, and
results visible first; detailed catalog and coverage-tier diagnostics move under
the compact data detail expander.

v5.64 makes the GitHub Pages static ETF import reproducible. The broad ETF
history step now uses the committed TWSE ETF seed catalog in both Actions and
the local Pages build script, so public static data does not depend on a
maintainer-only local catalog file.

v5.65 keeps static Pages build logs concise. ETF import and static export now
support compact normal-run summaries, so daily validation shows status, row
counts, ETF readiness, warnings, and failures without dumping every ETF row.

v5.66 adds progress lines to long ETF history imports. GitHub Pages and local
static builds now show compact `[progress]` updates while the seed catalog is
being checked.

v5.67 refreshes the committed official 00631L price-history seed and adds a
strict coverage-age guard to static export. GitHub Pages will not replace public
static data with a fallback whose price-history coverage is more than seven days
old.

v5.68 makes compact maintenance output shorter. `--summary-only` import and
static export logs keep the status numbers but trim sample rows and long warning
text, so daily checks stay readable.

v5.69 makes the static ETF price-history index catalog-complete. GitHub Pages
static export now includes every TWSE ETF catalog code in the readiness index;
symbols without saved price history are shown as unavailable instead of being
hidden from the denominator.

v5.70 commits a broader validated ETF price-history seed set. Static Pages
export can merge 230 ready ETF histories from seed before live refresh, keeping
public ETF readiness stable when a workflow run gets partial TWSE responses.

v5.71 cleans up static export warning semantics. Normal seed merges, update
counts, and all-catalog resolution now appear as notes or structured counts;
warnings are reserved for source, coverage, seed, or strict export issues.

v5.72 fixes public release metadata. Static export can derive the app version
from an exact `00631l-lab-v*` tag on `HEAD`, and the GitHub Pages workflow now
checks out tags so the public marker can show the deployed release tag instead
of an older default.

v5.73 carries ETF history missing-count metadata into the Flutter app. Static
and live operations status now preserve `etfPriceHistoryMissingCount`, so the
ETF data-library panel can show ready and missing histories directly instead of
inferring the gap from row counts.

v5.74 refreshes the next-direction roadmap around the current v5.73 baseline.
The next checkpoints are selected ETF context, manual comparison baskets,
history/backtest interaction, daily AI context, broader validated ETF coverage,
and mobile packaging preflight.

v6.19 aligns the Pages deploy status checker with the current main-branch tag
polling flow. When public `release.json` already matches the expected commit,
stale workflow-run noise no longer blocks local release validation.

v6.20 improves the top-left ETF search ranking. Symbol-like queries now prefer
code matches and history-ready rows before looser name-only or catalog-only
matches.

v6.21 clarifies ETF comparison readiness. The comparison panel now separates
candidate, comparison-ready, and skipped rows so catalog-only or insufficient
history symbols are not silently mixed into comparison charts.

v6.22 adds skipped-row detail chips to the comparison panel. Skipped ETFs now
show code, active-range row count, and source status while remaining excluded
from chart and table calculations.

v6.23 compacts ETF comparison controls for phone screens. Comparison actions
now stay in one horizontal strip while preserving the existing filter and basket
behavior.

v6.24 shortens ETF comparison guidance so readiness counts, skipped details, and
the chart appear sooner on phone screens.

v6.25 compacts the public web and Flutter loading shells so the first visible
screen looks like the 00631L app instead of a large centered splash card.

v6.26 improves the overview sparkline date axis so phone-width start and end
date labels stay inside the chart area.

v6.27 turns the overview core data metrics into a compact horizontal strip so
the quote card and chart stay closer together on phone screens.

v6.28 adds a compact `今日 AI 判讀` card so the AI page opens with daily data
context, key holdings exposure, intraday NAV status, and the first program
action before showing detailed status panels.

v6.29 makes the local-only position account summary a horizontal metric strip,
so the position page shows market value, P/L, symbol, and storage status without
a tall two-row grid on phone screens.

v6.30 adds a stable chart touch-detail hook for the history/backtest view so
date/value interaction can keep improving without fragile text matching.

v6.31 improves the history/backtest chart date labels on phone screens. Axis
dates now use compact bordered chips, and the touch-detail panel uses two lines
so the date/value detail stays readable.

v6.32 adds a compact active-range summary above the history/backtest date
buttons, making the default one-year range and custom date range clearer without
changing historical data or backtest formulas.

v6.33 shortens the position page action area. Save, JSON export, and clear are
now compact horizontal quick actions while keeping position data local-only.

v6.34 makes the AI page more answer-first by showing the first rule-based daily
interpretation bullets directly inside the top AI briefing card.

v6.35 adds a compact overview daily summary strip below the quote header so the
first mobile screen shows mode, daily holdings date, intraday NAV time,
premium/discount status, history coverage, and the first AI brief together.

v6.36 removes the duplicate 00631L quote meta strip from the overview header.
The same context remains in the daily summary strip, so the chart and core
status appear sooner on mobile.

v6.37 cleans up the overview daily summary header by moving frontend mode into a
small badge and keeping AI as a short status chip instead of a truncated line.

v6.38 keeps the overview daily summary strip in a neutral loading state during
fast startup, so temporary full-data loading does not appear as a source error.

v6.39 removes the duplicated 00631L overview core-data card so the first phone
screen goes from quote and daily summary directly into the price/exposure chart.

v6.40 compresses the official holdings digest into a short horizontal strip so
TX, TSMC, and stock/futures/cash mix remain visible without a tall card stack.

v6.41 simplifies the overview daily summary to DAY / LIVE / HIS and replaces
raw intraday source-contract text with user-facing source labels.

v6.42 makes the history/backtest quick range chips visibly selected. The default
remains latest one year, manual start/end dates still work, and short verified
history ranges are labeled as all data when they span the full available
coverage.

v6.43 makes the overview DAY / LIVE / HIS summary fit phone width as a fixed
three-column grid. LIVE now shows time-only and HIS shows row count plus
coverage years, while source labels remain truthful.

v6.44 makes the overview official holdings digest fit phone width. TX futures,
TSMC stock, and stock/futures/cash mix now stay in a fixed three-cell row with
long percentages scaled inside each tile.

v6.45 polishes the same official holdings digest by shortening tile titles to
`期貨`, `台積電`, and `股期現金`, so the phone overview avoids leftover ellipsis.

v6.46 compacts the history/backtest page top area. The page now opens with a
short top strip for ETF, source, coverage, latest close, row count, and default
range, while detailed data-quality notes move into an expandable panel.

v6.47 shortens the local position page empty state. The large no-position panel
is now a compact hint strip so input fields and local-only actions appear sooner
on phone screens.

v6.48 compacts the AI daily briefing facts on phone width. Content, intraday
NAV, and history facts now sit in one row instead of three tall cards, while the
rule-based non-advice summary remains unchanged.

v6.49 compacts the backtest result area. The quick result strip now includes
annualized return and volatility, and the duplicated 2x2 result grid was removed
so the chart and settings appear sooner on phone screens.

v6.50 shortens the AI page first screen. Detailed snapshot and interpretation
cards now live inside advanced AI detail, while the page opens with the daily
briefing and concise rule-based summary.

v6.86 cleans up visible status wording in account/settings, position, AI, and
comparison surfaces. Internal keys such as `local-only`, `rule_based`, and
`comparison-ready` remain in data contracts but no longer appear as primary app
labels.

v6.87 applies the same status-label cleanup to the overview DAY/LIVE/HIS
summary, so the first screen no longer shows raw words such as `cached`,
`backend`, or `unavailable` in the primary summary chips.

v6.88 makes the overview official-holdings digest clearer on phone screens:
the exposure structure now separates stock, futures, and cash/margin
percentages instead of compressing them into one combined `MIX` value.

v6.89 cleans the AI analysis page wording so the public first screen no longer
shows implementation phrases such as `static public mode`, `rows`, `cached`,
or `public backend proxy` in primary bullets and action items.

v6.90 strengthens static public ETF catalog completeness. Pages export now
merges the committed ETF catalog seed into the runtime catalog snapshot by code,
so a temporary TWSE catalog HTTP failure does not publish a smaller catalog than
the ETF price-history index.

v6.91 continues public UI wording cleanup. History and AI screens now map
remaining raw source/status phrases such as `static_official`,
`official holdings`, `live intraday NAV`, and `price history` into product-facing
labels before display.

v6.92 finishes that public wording pass by cleaning the remaining first-screen
and history/backtest labels that mixed Chinese with raw phrases such as
`holdings history`, `official price history`, and English comparison guidance.

v7.1 localizes the remaining settings-panel comparison status label. The
advanced ETF data panel now shows `ETF 比較` instead of an internal English
label.

v7.2 localizes the settings ETF catalog status label. The advanced ETF data
panel now shows `ETF 清單` instead of the raw `catalog` label.

v7.3 localizes the advanced data coverage panel. Labels such as `TX live`,
`ETF catalog`, `ETF history`, `rows`, `coverage`, and `dataTime` now render as
Chinese product wording in the app.

v7.4 localizes the overview status chips and selected ETF context panel. The
first-screen status row, history count captions, selected ETF data context, and
AI detail chips now avoid raw terms such as `core`, `holdings`, `rows`,
`catalog`, and `source`.

v7.5 localizes more history, backtest, and settings wording. Daily-use status
now describes historical price, backtest, local position data, daily cycle,
report/export/backup, static mode, and live backend in product-facing Chinese.

v7.6 localizes data coverage and price completeness panels. Price rows,
intraday state, holdings count, integrity, coverage range, missing OHLC, volume,
daily return, and backend captions now use Chinese product labels.

v7.7 localizes settings and maintenance wording. ETF data gaps, deployment
sync, backend status, reports, exports, backups, history row counts, and daily
workflow prompts now read as product-facing Chinese while keeping script names
available for program actions.

v7.8 localizes ETF catalog and gap-detail wording. ETF catalog now appears as
ETF 清單, and gap metadata such as attempted checks, retained history, and
history indexes is described in Chinese without changing data eligibility.

v7.9 improves the mobile overview density. The first screen now keeps quote,
today summary, one-year chart, holdings digest, and one advanced-data entry in
a clearer order, while detailed data-quality and maintenance diagnostics stay
behind the advanced section.

v8.0 removes the duplicate first-screen daily summary on mobile. The overview
now uses one `今日快覽` block for content date, intraday NAV, history rows, and
backend status, keeps the one-year chart open, and shortens the loading shell
so the public PWA feels less like a blank waiting page.
