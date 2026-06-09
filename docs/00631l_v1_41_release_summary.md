# 00631L lab v1.41 deployment bootstrap summary

v1.41 adds a deployment bootstrap helper for local Windows setup.

## Added

- `scripts\00631l_bootstrap_deploy.cmd`

## What It Does

- Prefers `C:\src\flutter-clean\bin` when available.
- Installs backend dependencies from `backend\requirements.txt`.
- Creates `backend\.env` from `backend\.env.example` only when missing.
- Creates ignored local directories:
  - `backend\data`
  - `backend\exports`
  - `backend\backups`
  - `backend\reports`
- Runs `scripts\00631l_check_env.cmd`.
- Prints the backend, frontend, daily cycle, and release check commands.

`backend\.env` and local data/output folders remain ignored and must not be committed.

## Validation

```cmd
scripts\00631l_bootstrap_deploy.cmd
flutter analyze
flutter test
flutter build web
py -m unittest discover -s backend\tests
scripts\00631l_release_check.cmd
git diff --check
```

This release does not connect TX live, expand beyond 00631L, add notifications, automated trading, or investment guidance.
