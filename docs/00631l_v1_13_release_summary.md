# 00631L Lab v1.13 Release Summary

Date: 2026-06-09

## Scope

v1.13 adds one-command local startup and environment check scripts.

Added:

- `scripts/00631l_check_env.cmd`
- `scripts/00631l_start_backend.cmd`
- `scripts/00631l_start_frontend_live.cmd`

## Usage

Environment check:

```cmd
scripts\00631l_check_env.cmd
```

Backend:

```cmd
scripts\00631l_start_backend.cmd
```

Frontend live proxy:

```cmd
scripts\00631l_start_frontend_live.cmd
```

## Notes

Missing `backend/.env` is a warning, not a failure. Copy `backend/.env.example` to `backend/.env` when local live intraday NAV URLs should be configured.

## Boundaries

This release does not connect TX live, expand beyond 00631L, or add trading advice.
