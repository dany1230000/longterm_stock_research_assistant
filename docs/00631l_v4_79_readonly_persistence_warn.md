# 00631L lab v4.79 read-only persistence warning

v4.79 changes the read-only public backend status check so persistence problems
do not hide otherwise usable public data.

## What Changed

- `scripts\00631l_public_backend_status.cmd` now treats `/ready` failures that
  are only about an unwritable data directory as WARN.
- The backend `/ready` endpoint itself still reports the issue as a readiness
  failure. This keeps deployment health strict.
- Read-only public status remains useful for checking release tag, static
  history, ETF history readiness, and public data coverage even when the host
  needs a persistent volume fix.

## Why

Hosted public deployments can still serve committed seed/static data while the
persistent data volume is missing or misconfigured. The public status script
should keep that distinction clear: read-only public data may be usable, but
daily collection/export/report writes require a writable persistent path.

## Operator Action

If this WARN appears on Render or another host, configure a persistent volume
and set the backend data env vars to that mounted path. Then rerun:

```cmd
scripts\00631l_public_backend_status.cmd --soft-fail
scripts\00631l_wait_public_deploy.cmd --soft-fail
```
