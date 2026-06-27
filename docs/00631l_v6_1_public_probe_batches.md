# 00631L lab v6.1 public ETF probe batches

v6.1 lets each GitHub Pages deployment run a bounded three-batch missing-ETF
probe after restoring public import-attempt evidence.

## What Changed

- GitHub Pages now runs three missing-ETF probe batches per deployment.
- Each batch is still limited to 20 symbols.
- Each batch still uses `--missing-only --skip-attempted`.
- Local Pages build mirrors this behavior when called with:

```cmd
scripts\00631l_build_pages_static.cmd --restore-public-attempts --probe-missing
```

## Why

v6.0 proved that public attempt evidence can be carried forward. Running only
one 20-symbol batch per deployment would still require many deployments to
classify the remaining ETF history gaps.

Three bounded batches make the public maintenance path progress faster while
keeping source load limited and keeping Pages export resilient.

## Data Boundary

This does not make up missing price rows. If TWSE returns no rows or a request
fails, the ETF remains classified by the actual gap reason, such as
`official_empty`, `source_error`, or `not_saved`.
