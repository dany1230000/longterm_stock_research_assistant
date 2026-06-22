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

1. v4.54 backend release metadata.
2. v4.55 public backend remote maintenance visibility in app status.
3. v4.56 broader ETF history import verification and selector readiness.
4. v4.57 selected ETF comparison cleanup.
5. v4.58 mobile history/backtest date interaction polish.
