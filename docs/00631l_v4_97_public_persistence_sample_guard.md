# 00631L lab v4.97 public persistence sample guard

v4.97 tightens the public persistence verifier.

## What changed

`scripts\00631l_verify_public_persistence.cmd` now reports `WARN` when any
sample is missing persistence marker details, even if another sample contains
the marker.

This catches transient public backend states where `/ready` is already warning
but the status summary is incomplete during deploy warm-up or platform restart.

## Why it matters

Public ETF history batches should not continue when the backend cannot
consistently report the persistence marker. The marker is the operational proof
that `/data/00631l` is stable across deploys.

## Expected action

Run:

```cmd
scripts\00631l_public_backend_status.cmd --soft-fail
scripts\00631l_verify_public_persistence.cmd --soft-fail
```

Continue public ETF data maintenance only after the verifier reports stable
marker details and no ready-count regression.
