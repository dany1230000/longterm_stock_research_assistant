# 00631L lab v9.58 - post-deploy storage gate

## Goal

The public backend can deploy successfully while its runtime data directory is
not writable. When that happens, daily history may still be served from seed or
cache, but ETF catalog history gaps cannot be repaired.

v9.58 adds a storage readiness gate to:

```cmd
scripts\00631l_public_post_deploy_refresh.cmd
```

## Behavior

The command now checks public backend status after the release marker step and
before running maintenance or catalog-gap batches.

If `/ready` reports a hard storage failure, the command stops with `FAIL` and
prints an action item:

```text
Fix public backend storage readiness before running post-deploy data refresh.
```

This prevents a misleading catalog refresh attempt when the backend cannot write
to its configured data volume.

## Current deployment implication

If Render reports:

```text
storage_paths: Required backend storage paths are not writable.
```

the next step is external deployment configuration, not application code:

1. Confirm the Render service has a persistent disk attached.
2. Confirm the mount path matches `00631L_DATA_DIR`.
3. Confirm the service environment uses the same path for ETF history, reports,
   exports, backups, and persistence marker files.
4. Redeploy, then rerun the public post-deploy refresh command.

The static GitHub Pages app remains usable while the public backend storage
issue is being fixed.
