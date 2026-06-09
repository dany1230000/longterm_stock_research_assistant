# 00631L v2.2 public deploy-ready summary

Date: 2026-06-09

v2.2 prepares the 00631L lab for public Flutter Web / PWA frontend deployment with a public FastAPI backend. It does not deploy to a specific platform and does not require cloud credentials.

## Completed

- Backend Dockerfile for generic container deployment.
- `PUBLIC_API_BASE_URL` metadata.
- `ALLOWED_ORIGINS` CORS configuration.
- `00631L_DATA_DIR` and `00631L_DATA_PERSISTENCE_MODE` settings.
- operations/status persistence warning for non-persistent data mode.
- frontend operations panel showing API base URL, backend public URL, allowed origins, and data persistence state.
- public config check script.
- public web build script.
- public deployment, PWA usage, and future App Store path docs.

## Public usage shape

1. Deploy backend.
2. Set backend env and persistent data volume.
3. Build frontend with:

```cmd
set PUBLIC_BACKEND_URL=https://your-backend.example.com
scripts\00631l_build_web_public.cmd
```

4. Deploy `build\web` to static hosting.
5. Open:

```text
https://your-frontend.example.com/#/00631l-lab
```

## Data update frequency

- Yuanta holdings / ratio: official daily snapshot.
- TWSE intraday NAV / premium-discount: live/cached source, approximately 15-30 seconds when backend and env are ready.
- TX live: not connected; mock/fallback only.

## Validation

Use:

```cmd
flutter analyze
flutter test
flutter build web
py -m unittest discover -s backend\tests
scripts\00631l_release_check.cmd
scripts\00631l_check_public_config.cmd
scripts\00631l_build_web_public.cmd
git diff --check
```

`scripts\00631l_check_public_config.cmd` may WARN when no real public backend URL is configured.

## Not included

- TX live.
- All leveraged ETFs.
- Notifications.
- Automated trading.
- Investment guidance.
- App Store submission.
