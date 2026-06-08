# 00631L lab v1.26 release summary

Completed on 2026-06-09.

## Scope

v1.26 adds a small local helper for daily use:

- `scripts/00631l_open_lab.cmd`
- local environment check
- backend health check at `http://127.0.0.1:8000/health`
- backend startup command reminder
- daily cycle command reminder
- Flutter live proxy command reminder
- direct route reminder: `/#/00631l-lab`

The helper does not run hidden background servers. It keeps backend and Flutter startup visible in terminal windows so the user can stop them normally.

## Usage

```cmd
cd C:\dev\longterm_stock_research_assistant
scripts\00631l_open_lab.cmd
```

Then follow the printed commands:

```cmd
scripts\00631l_start_backend.cmd
scripts\00631l_daily_cycle.cmd
scripts\00631l_start_frontend_live.cmd
```

After Flutter opens Chrome, use:

```text
http://127.0.0.1:<flutter-port>/#/00631l-lab
```

## Constraints

- TX live remains mock/fallback by design.
- Scope remains 00631L only.
- The helper only describes app operation status and startup steps.
- Mock/fallback data is not labeled as official.
