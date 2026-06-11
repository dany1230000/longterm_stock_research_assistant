# 00631L lab v3.1 static public summary

Completion target: 00631L GitHub Pages static-public mode.

## What This Adds

- Static public data export for 00631L price history.
- GitHub Pages workflow can generate static data before Flutter Web build.
- Flutter Web can read `web/00631l-static-data` without a live backend.
- History and backtest sections can work on a public static page.
- Operations status labels static data as `static_public`.
- AI summary labels static history as `static_official`.

## Static Export Files

Generated folder:

```text
web\00631l-static-data\
```

Generated files:

- `price_history.json`
- `performance.json`
- `status.json`
- `manifest.json`

The folder is ignored by git. GitHub Actions generates it during the Pages build and packages it into the Pages artifact.

## Commands

Check static export status without network:

```cmd
scripts\00631l_export_static_data.cmd --status-only
```

Update TWSE price history and export static JSON:

```cmd
scripts\00631l_export_static_data.cmd --update
```

Strict public build:

```cmd
scripts\00631l_build_pages_static.cmd
```

## Flutter Build Defines

```cmd
flutter build web --base-href="/longterm_stock_research_assistant/" --dart-define=USE_00631L_STATIC_DATA=true --dart-define=00631L_STATIC_DATA_BASE_URL=00631l-static-data
```

Repository priority:

1. `USE_00631L_LIVE_PROXY=true`: live proxy.
2. `USE_00631L_STATIC_DATA=true`: static public data.
3. default: mock fallback.

## Data Truthfulness

- Static price history comes from TWSE STOCK_DAY export when the update succeeds.
- If official data cannot be fetched, strict mode fails instead of deploying empty history.
- Holdings ratio remains daily official data only when backend live proxy is available.
- Intraday NAV remains live only through backend proxy.
- TX live remains out of scope.

## Mobile Public URL

After GitHub Pages deployment:

```text
https://dany1230000.github.io/longterm_stock_research_assistant/#/00631l-lab
```

## Remaining Work For Live Anywhere

Static public mode does not replace the public backend. For live intraday NAV, official holdings refresh, daily cycle, reports, exports, and backups from anywhere, a public backend plus persistent volume is still required.
