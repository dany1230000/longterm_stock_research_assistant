# 00631L v4.71 Public Batch Fail Fast

v4.71 changes public ETF catalog batch maintenance to stop after the first
failed offset by default.

## What Changed

- The runner no longer continues to later offsets after a FAIL step unless
  explicitly requested.
- Use `--continue-on-failure` only when you intentionally want to keep testing
  later offsets.
- The failed offset is kept in the resume state so the next maintenance run can
  restart from a known point.

## Default Command

```cmd
scripts\00631l_public_etf_catalog_batches.cmd --start-offset 25 --batch-size 10 --max-batches 2 --soft-fail
```

## Explicit Continue Mode

```cmd
scripts\00631l_public_etf_catalog_batches.cmd --start-offset 25 --batch-size 10 --max-batches 2 --continue-on-failure --soft-fail
```

## Why

Public backend and official source calls can be slow or temporarily unstable.
Stopping at the first failed offset reduces repeated pressure on the same
remote path and makes the resume state clearer.
