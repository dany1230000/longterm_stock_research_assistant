# 00631L Lab v1.6 Release Summary

Date: 2026-06-08

## Scope

v1.6 documents the daily operating flow and adds small PowerShell wrappers for validation and smoke observation.

Added:

- `scripts/00631l_daily_smoke.ps1`: loads `backend/.env` and runs the live smoke script.
- `scripts/00631l_release_validate.ps1`: runs Flutter validation, backend tests, smoke, and `git diff --check`.
- `scripts/00631l_daily_smoke.cmd`: CMD fallback for local machines that block `.ps1` script execution.
- `scripts/00631l_release_validate.cmd`: CMD fallback for the full validation sequence.
- `docs/00631l_v1_6_daily_runbook.md`: daily backend, frontend, smoke, and build workflow.

## Boundaries

This release does not change parser behavior, connect TX live, expand beyond 00631L, add alert delivery, or add trading advice.

## Operational Notes

The default frontend mode remains mock/fallback. Live official data requires backend proxy mode with:

```powershell
flutter run -d chrome --dart-define=USE_00631L_LIVE_PROXY=true --dart-define=00631L_PROXY_BASE_URL=http://127.0.0.1:8000
```

The backend smoke can return `WARN` outside market hours because freshness is stale, while live parsing can still be healthy.

## Validation

Run before tagging:

```powershell
.\scripts\00631l_release_validate.ps1
```

If local PowerShell script execution is disabled:

```cmd
scripts\00631l_release_validate.cmd
```
