# ETF Research Room Next Direction

This roadmap keeps the app moving toward a formal ETF research-room product while preserving truthful data labels and verifiable releases.

## Product Direction

The app should feel like a mobile-first ETF research tool:

- Open quickly on phone.
- Show the selected ETF immediately.
- Keep 00631L as the first complete room.
- Allow other ETF data to be searched, inspected, and compared when verified history exists.
- Keep live, static, cached, stale, and mock states explicit.
- Keep analysis descriptive: data status, exposure, history, deviation, and maintenance actions.

## Track 1: Data Trust

Priority:

1. Show exact backend release metadata in `/health`, `/ready`, and app status.
2. Keep 00631L price history split-adjusted and verified.
3. Expand ETF history readiness from the seed basket to broader imported coverage.
4. Validate selected ETF history before allowing comparison/backtest confidence labels.
5. Keep official daily holdings separate from intraday NAV and historical price data.

## Track 2: Public Operations

Priority:

1. Remote maintenance must warm public backend caches.
2. GitHub Actions should keep backend history, status, and static data observable.
3. Persistent volume, backup, restore dry-run, report, and export status should stay visible.
4. Release check must catch missing artifacts, forbidden wording, and broken public config.

## Track 3: Mobile UX

Priority:

1. First screen: compact quote, chart, premium/discount, data time, and source.
2. Search: top-left ETF selector must switch the full selected ETF context.
3. History/backtest: default one-year view, clear date range controls, tap details.
4. Position: compact local-only card with source context.
5. Settings: only operational information that helps the user understand app state.

## Track 4: Analysis

Priority:

1. Rule-based analysis should reference the selected ETF, not only 00631L.
2. Analysis should describe today's data status and historical context.
3. Action items should be program actions only, such as updating data or checking backend config.
4. External LLM remains a disabled adapter until keys and privacy policy are intentionally added.

## Near-Term Release Order

The current public baseline is v5.73. Continue with small, verifiable releases:

1. v5.74 selected ETF search and context audit.
   - Confirm the top-left selector switches the quote, history, comparison,
     position context, and rule-based AI context together.
   - Keep catalog-only symbols visible but clearly marked as missing history.
2. v5.75 ETF comparison basket polish.
   - Let the user compare a manually selected basket instead of always comparing
     every ETF against 00631L.
   - Keep same-category suggestions as optional chips only.
3. v5.76 history/backtest interaction polish.
   - Keep one-year as the default range.
   - Make date controls compact and clear on phone.
   - Show tapped chart details with exact date and value.
4. v5.77 daily AI context upgrade.
   - Analyze the selected ETF's current data state, latest history, coverage
     quality, and comparison basket.
   - Keep action items limited to app/data maintenance steps.
5. v5.78 public data completeness pass.
   - Increase the number of ready ETF histories where official data validates.
   - Keep unavailable catalog items visible as coverage gaps.
6. v5.79 app-store packaging preflight.
   - Add store-readiness checklist for PWA-to-mobile-shell packaging.
   - Keep the public backend requirement explicit.
7. v5.80 ETF research-room checkpoint.
   - Run full release check, public marker check, and public Pages checkup.
   - Summarize what is complete and what still depends on public backend or
     official source availability.
