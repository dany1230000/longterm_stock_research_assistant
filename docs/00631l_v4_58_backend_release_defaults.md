# 00631L lab v4.58 backend release defaults

v4.58 updates the backend release metadata defaults used when deployment env vars
are not supplied.

## Changed Defaults

`backend/app/config.py` and `backend/.env.example` now default to:

- `00631L_BACKEND_APP_VERSION=4.58-release-defaults`
- `00631L_BACKEND_RELEASE_TAG=00631l-lab-v4.58-release-defaults`

Deployment platforms should still set explicit release metadata when possible:

- `00631L_BACKEND_APP_VERSION`
- `00631L_BACKEND_RELEASE_TAG`
- `00631L_BACKEND_GIT_SHA`
- `00631L_BACKEND_BUILD_TIME`

## Why

The public backend status check depends on `/health` release metadata. A stale
default can make a freshly deployed backend look older than it is when env vars
are missing.
