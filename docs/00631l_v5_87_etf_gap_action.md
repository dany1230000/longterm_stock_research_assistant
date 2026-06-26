# v5.87 ETF Gap Action

## Scope

v5.87 adds a compact action row to the ETF data-library status card.

When ETF history gaps remain, the app now shows:

- current ready / total ETF history count
- remaining missing count
- the safe missing-only import command
- the static status command to rerun after import

## User-Facing Behavior

The `我的` page still shows the ETF data-library metrics, but now also includes
`資料補齊動作` so the next maintenance command is visible in the app instead of
only in release logs.

## Commands

```cmd
scripts\00631l_import_missing_etf_batch.cmd
scripts\00631l_export_static_data.cmd --status-only
```

The command imports only missing ETF histories and keeps unavailable official
data visible as a coverage gap.
