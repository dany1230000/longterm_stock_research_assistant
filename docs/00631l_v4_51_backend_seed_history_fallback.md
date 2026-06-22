# v4.51 backend seed history fallback

## Purpose

Public backend deployments can start with an empty persistent volume. Before v4.51, that made `/api/etf/00631l/history/status` report `unavailable` even though the repository already has a committed official 00631L price-history seed for GitHub Pages static mode.

v4.51 lets the backend read that seed when local `00631L_PRICE_HISTORY_PATH` has no rows.

## Behavior

- Seed file: `backend/seeds/00631l_price_history_seed.jsonl`.
- Config key: `00631L_PRICE_HISTORY_SEED_PATH`.
- Empty local cache plus seed rows returns `sourceStatus: static_official`.
- Local cache rows plus seed rows returns `sourceStatus: cached`.
- If the same date exists in both sources, the local cache row wins.
- Writes still go only to the local cache path. The backend does not copy the seed into app data automatically.

## Why this matters

This keeps public backend history, performance, backtest, and AI context usable immediately after deployment while remaining honest about data provenance. Seed history is official historical price data, but it is not live intraday data.

## Operational notes

Run the normal history update flow after deployment:

```cmd
scripts\00631l_remote_maintenance.cmd --mode history
```

or locally:

```cmd
scripts\00631l_update_price_history.cmd --update
```

Status checks can also point at a custom seed file:

```cmd
py backend\scripts\update_00631l_price_history.py --status-only --seed-path backend\seeds\00631l_price_history_seed.jsonl
```

After new rows are saved, backend history status should move from seed-only `static_official` to local `cached` or `local+seed` backed history.

## Validation

- Backend unit tests cover seed-only history and local-over-seed merge behavior.
- Endpoint tests cover `/api/etf/00631l/history/status` and `/api/etf/00631l/history/price` with an empty local cache and configured seed.
- Release check requires this summary and the committed seed file.
