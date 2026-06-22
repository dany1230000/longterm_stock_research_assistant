# 00631L v4.55 Public Backend Status Check

## Scope

v4.55 adds a short, read-only public backend status check. It is for deployment diagnosis and does not update backend data.

## Command

```cmd
scripts\00631l_public_backend_status.cmd
```

Use a custom backend:

```cmd
scripts\00631l_public_backend_status.cmd --base-url https://your-backend.example.com
```

Dry run:

```cmd
scripts\00631l_public_backend_status.cmd --dry-run
```

## What It Checks

- `GET /health`
- `GET /ready`
- `GET /api/etf/00631l/operations/status`
- `GET /api/etf/00631l/history/status`
- `GET /api/etf/history/status`

## Summary Fields

- backend version
- release tag
- git sha
- readiness
- 00631L price-history row count and coverage
- selected ETF basket ready count
- ETF history validation failure count

## Status Rules

- HTTP failures are `FAIL`.
- `/ready` failures are `FAIL`.
- `/ready` warnings are `WARN`.
- 00631L price history with fewer than two rows is `WARN`.
- ETF history with no ready symbols is `WARN`.
- ETF history validation failures are `WARN`.

This script is separate from remote maintenance. Use remote maintenance when data should be updated; use this script when you only need to inspect the public backend.
