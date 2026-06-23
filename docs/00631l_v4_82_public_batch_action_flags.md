# 00631L lab v4.82 public batch action flags

v4.82 fixes the public ETF catalog batch runner's own next-step guidance.

## What changed

- Successful or failed public catalog batch payloads now include the same safe
  flags used by maintenance status:

```cmd
scripts\00631l_public_etf_catalog_batches.cmd --start-offset <offset> --batch-size 1 --max-batches 1 --soft-fail
```

- The runner still uses deploy/stability preflight before non-dry-run remote
  updates.
- The change only affects operational command guidance. It does not change ETF
  data parsing, UI calculations, or investment logic.

## Why

After v4.81, maintenance guidance was production-safe, but a successful runner
payload could still show a shorter next-offset command. v4.82 keeps both
outputs consistent so public maintenance remains one catalog item per run.
