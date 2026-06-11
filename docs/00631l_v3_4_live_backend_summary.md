# 00631L lab v3.4 live backend summary

完成日期：2026-06-11

## Public backend

Render backend URL:

```text
https://longterm-stock-research-assistant.onrender.com
```

Frontend origin:

```text
https://dany1230000.github.io
```

Persistent data path:

```text
/data/00631l
```

## v3.4 changes

- Dockerfile now includes the Render public backend URL.
- Dockerfile now includes the GitHub Pages frontend origin for CORS.
- Dockerfile now includes the TWSE intraday NAV URL.
- GitHub Pages workflow builds with the Render backend URL by default.
- `scripts\00631l_build_web_public.cmd` builds against the Render backend URL by default.
- Public config check uses the Render URL when no override is provided.

## Expected mode

The public PWA should run as:

1. `live_proxy` when Render backend is reachable.
2. `static_public` fallback when live API is unavailable.
3. `mock_default` only if both live and static data are unavailable.

## Required backend checks

```text
GET /health
GET /ready
GET /api/etf/00631l/intraday-nav
GET /api/etf/00631l/holdings
GET /api/etf/00631l/operations/status
GET /api/etf/00631l/analysis/summary
```

`/ready` should have no failures. WARN can still appear for temporary official source connectivity or missing optional Yuanta INAV fallback.

## Data freshness

- Yuanta ratio holdings remain official daily snapshots.
- TWSE intraday NAV is the live price / estimated NAV / premium-discount source.
- Static history remains GitHub Pages data and is not live intraday data.

## Remaining deployment notes

Render must redeploy from the v3.4 commit before the backend reflects these defaults. If auto-deploy is disabled in Render, trigger a manual deploy from the Render dashboard.

This version still does not connect TX live, does not expand to all leveraged ETFs, and does not provide investment guidance.
