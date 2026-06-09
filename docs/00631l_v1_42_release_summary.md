# 00631L lab v1.42 backend health/status summary

v1.42 expands backend health metadata for deployment checks.

## Updated

- `/health` now returns:
  - `status`
  - `serverTime`
  - `appName`
  - `appVersion`
  - `sourceContract`
  - `scope`
  - configured live-source flags
  - local env/data/export/backup readiness
  - key endpoint paths
- `/api/etf/00631l/operations/status` includes a `backendHealth` block.

The health endpoint remains local and lightweight. It does not fetch Yuanta or TWSE live data.

## Validation

```cmd
flutter analyze
flutter test
flutter build web
py -m unittest discover -s backend\tests
scripts\00631l_release_check.cmd
git diff --check
```

This release does not connect TX live, expand beyond 00631L, add notifications, automated trading, or investment guidance.
