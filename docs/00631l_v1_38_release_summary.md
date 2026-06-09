# 00631L lab v1.38 release check strengthening summary

v1.38 strengthens the local release check for semi-automated maintenance.

## Added To Release Check

- scheduler documentation and script presence check
- daily report generation
- data integrity check
- backup rotation run
- restore dry-run
- local reports/backups exclusion from forbidden wording scan

## Command

```cmd
scripts\00631l_release_check.cmd
```

The command still returns failure only for failed required checks. WARN remains acceptable when it reflects local setup or off-hours freshness state and `failures` is empty.

## Scope

This release does not connect TX live, expand beyond 00631L, add notification features, or add investment guidance.
