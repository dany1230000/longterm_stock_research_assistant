# 00631L lab v3.5 remote maintenance summary

Completed date: 2026-06-11

## Scope

v3.5 adds remote daily maintenance for the public backend.

The goal is to keep the public 00631L lab usable after deployment:

- wake and check the public backend
- verify `/health` and `/ready`
- collect intraday NAV status
- refresh official price history
- verify holdings, operations status, AI summary, history status, and performance endpoints
- keep GitHub Pages static fallback unchanged

## New artifacts

- `.github/workflows/00631l_backend_maintenance.yml`
- `backend/scripts/remote_maintenance_00631l.py`
- `scripts/00631l_remote_maintenance.cmd`
- `docs/00631l_remote_maintenance.md`

## Modes

`intraday` mode checks live backend status, intraday NAV, operations/status, and AI summary.

`daily` mode checks live backend status, official holdings, price history update, history status, and performance.

`all` mode runs both.

## Public backend

Default backend:

```text
https://longterm-stock-research-assistant.onrender.com
```

The backend URL can be overridden with:

```text
PUBLIC_BACKEND_URL
```

## GitHub Actions

The maintenance workflow supports:

- `workflow_dispatch`
- weekday intraday schedule
- weekday daily schedule

It does not require cloud tokens. It only calls the configured public backend URL.

## Validation

Release check uses `--dry-run` so normal validation is not blocked by temporary network conditions.

Manual live check:

```cmd
scripts\00631l_remote_maintenance.cmd --mode all
```

## Boundaries

This release does not add trading functions, account login, or personal portfolio transmission. It keeps the existing public static fallback and live proxy behavior.
