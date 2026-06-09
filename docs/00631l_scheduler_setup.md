# 00631L daily cycle Windows Task Scheduler setup

This document shows how to prepare a local Windows Task Scheduler task for the 00631L daily cycle. It does not add cloud services, notifications, TX live, or any trading function.

## What the task runs

Use this wrapper:

```cmd
C:\dev\longterm_stock_research_assistant\scripts\00631l_daily_cycle_scheduled.cmd
```

The wrapper:

- changes directory to the repo root
- runs `scripts\00631l_daily_cycle.cmd`
- writes local logs under ignored `backend\data\scheduled\`
- returns the daily cycle exit code

`backend\data\scheduled\` is local state and must not be committed.

## Create the scheduled task

Open Command Prompt or PowerShell with the permissions normally used for your Windows account.

Example: run once every weekday at 18:30 local time:

```cmd
schtasks /Create /TN "00631L Daily Cycle" /SC WEEKLY /D MON,TUE,WED,THU,FRI /ST 18:30 /TR "C:\dev\longterm_stock_research_assistant\scripts\00631l_daily_cycle_scheduled.cmd"
```

Example: run every day at 18:30 local time:

```cmd
schtasks /Create /TN "00631L Daily Cycle" /SC DAILY /ST 18:30 /TR "C:\dev\longterm_stock_research_assistant\scripts\00631l_daily_cycle_scheduled.cmd"
```

## Run manually

```cmd
schtasks /Run /TN "00631L Daily Cycle"
```

Or run the wrapper directly:

```cmd
cd C:\dev\longterm_stock_research_assistant
scripts\00631l_daily_cycle_scheduled.cmd
```

## Check task status

```cmd
schtasks /Query /TN "00631L Daily Cycle" /V /FO LIST
```

Check the latest local wrapper log:

```cmd
dir /b /o-d backend\data\scheduled\00631l_daily_cycle_*.log
```

The daily cycle status JSON remains:

```text
backend\data\00631l_daily_cycle_status.json
```

## Delete the scheduled task

```cmd
schtasks /Delete /TN "00631L Daily Cycle" /F
```

## Expected WARN cases

WARN can be acceptable when `failures` is empty, for example:

- local `.env` has not been created
- intraday NAV URL is not configured in the local environment
- intraday data is stale outside trading hours

FAIL should be reviewed before relying on the latest local files.
