from __future__ import annotations

import json
import os
import subprocess
from datetime import datetime, timezone
from pathlib import Path
from typing import Any
from urllib.parse import urlparse


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_PUBLIC_BACKEND_URL = "https://longterm-stock-research-assistant.onrender.com"
DEFAULT_PUBLIC_FRONTEND_ORIGIN = "https://dany1230000.github.io"


def main() -> int:
    payload = run_public_config_check()
    print(json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=True))
    print(
        "[summary] "
        f"overallStatus={payload['overallStatus']} "
        f"warnings={payload['warningCount']} "
        f"failures={payload['failureCount']}"
    )
    return 1 if payload["overallStatus"] == "FAIL" else 0


def run_public_config_check(root: Path = ROOT) -> dict[str, Any]:
    env = _load_env(root / "backend" / ".env")
    checks = [
        _backend_url_check(env),
        _public_api_url_check(env),
        _allowed_origins_check(env),
        _twse_url_check(env),
        _data_persistence_check(env),
        _required_file_check(root, "backend/Dockerfile"),
        _required_file_check(root, "docs/00631l_public_deployment.md"),
        _required_file_check(root, "docs/00631l_pwa_usage.md"),
        _required_file_check(root, "docs/00631l_app_store_path.md"),
        _required_file_check(root, "docs/00631l_v3_1_static_public_summary.md"),
        _required_file_check(root, "docs/00631l_live_backend_deployment.md"),
        _required_file_check(root, "docs/00631l_v3_3_live_public_summary.md"),
        _required_file_check(root, "docs/00631l_v3_4_live_backend_summary.md"),
        _required_file_check(root, "deploy/docker-compose.yml"),
        _required_file_check(root, "deploy/Caddyfile"),
        _required_file_check(root, "deploy/nginx.example.conf"),
        _required_file_check(root, "deploy/render.yaml"),
        _required_file_check(root, "render.yaml"),
        _render_disk_check(root, "deploy/render.yaml"),
        _render_disk_check(root, "render.yaml"),
        _required_file_check(root, "scripts/00631l_export_static_data.cmd"),
        _required_file_check(root, "scripts/00631l_build_pages_static.cmd"),
        _required_file_check(root, "scripts/00631l_backend_prod_check.cmd"),
        _required_file_check(root, "scripts/00631l_backend_docker_check.cmd"),
        _tracked_artifact_check(root),
    ]
    failures = [check["message"] for check in checks if check["status"] == "FAIL"]
    warnings = [check["message"] for check in checks if check["status"] == "WARN"]
    overall_status = "FAIL" if failures else "WARN" if warnings else "PASS"
    return {
        "sourceContract": "00631l_public_config_check",
        "checkedAt": datetime.now(timezone.utc).replace(microsecond=0).isoformat(),
        "overallStatus": overall_status,
        "checks": checks,
        "warnings": warnings,
        "failures": failures,
        "warningCount": len(warnings),
        "failureCount": len(failures),
    }


def _backend_url_check(env: dict[str, str]) -> dict[str, Any]:
    url = (
        os.getenv("00631L_PUBLIC_BACKEND_URL")
        or os.getenv("PUBLIC_BACKEND_URL")
        or DEFAULT_PUBLIC_BACKEND_URL
    )
    if not url:
        return _check(
            "frontend_backend_url",
            "WARN",
            "PUBLIC_BACKEND_URL is not set; public build will use a placeholder URL.",
        )
    return _url_check("frontend_backend_url", url, require_https=False)


def _public_api_url_check(env: dict[str, str]) -> dict[str, Any]:
    url = env.get("PUBLIC_API_BASE_URL") or os.getenv("PUBLIC_API_BASE_URL") or DEFAULT_PUBLIC_BACKEND_URL
    if not url:
        return _check(
            "public_api_base_url",
            "WARN",
            "PUBLIC_API_BASE_URL is not set; backend health will not advertise a public URL.",
        )
    return _url_check("public_api_base_url", url, require_https=False)


def _allowed_origins_check(env: dict[str, str]) -> dict[str, Any]:
    raw = env.get("ALLOWED_ORIGINS") or os.getenv("ALLOWED_ORIGINS") or DEFAULT_PUBLIC_FRONTEND_ORIGIN
    if not raw:
        return _check(
            "allowed_origins",
            "WARN",
            "ALLOWED_ORIGINS is not set; backend will use localhost/LAN development CORS.",
        )
    origins = [item.strip() for item in raw.split(",") if item.strip()]
    if not origins:
        return _check("allowed_origins", "FAIL", "ALLOWED_ORIGINS is empty.")
    if "*" in origins:
        return _check(
            "allowed_origins",
            "FAIL",
            "ALLOWED_ORIGINS must list explicit frontend origins, not wildcard.",
        )
    failures = [
        origin
        for origin in origins
        if _url_check("origin", origin, require_https=False)["status"] == "FAIL"
    ]
    if failures:
        return _check(
            "allowed_origins",
            "FAIL",
            f"Invalid origin values: {', '.join(failures)}",
        )
    return _check("allowed_origins", "PASS", "ok", origins=origins)


def _twse_url_check(env: dict[str, str]) -> dict[str, Any]:
    url = env.get("TWSE_00631L_INTRADAY_NAV_URL") or os.getenv(
        "TWSE_00631L_INTRADAY_NAV_URL",
        "",
    )
    if not url:
        return _check(
            "twse_intraday_url",
            "WARN",
            "TWSE_00631L_INTRADAY_NAV_URL is not set; intraday NAV may be unavailable.",
        )
    return _url_check("twse_intraday_url", url, require_https=True)


def _data_persistence_check(env: dict[str, str]) -> dict[str, Any]:
    mode = (
        env.get("00631L_DATA_PERSISTENCE_MODE")
        or os.getenv("00631L_DATA_PERSISTENCE_MODE")
        or "local"
    ).lower()
    data_dir = env.get("00631L_DATA_DIR") or os.getenv("00631L_DATA_DIR") or "backend/data"
    if mode not in {"local", "persistent", "transient"}:
        return _check(
            "data_persistence",
            "FAIL",
            "00631L_DATA_PERSISTENCE_MODE must be local, persistent, or transient.",
            dataDir=data_dir,
        )
    if mode != "persistent":
        return _check(
            "data_persistence",
            "WARN",
            "Public deployment should mount a persistent volume and set mode=persistent.",
            dataDir=data_dir,
            mode=mode,
        )
    return _check("data_persistence", "PASS", "ok", dataDir=data_dir, mode=mode)


def _render_disk_check(root: Path, relative_path: str) -> dict[str, Any]:
    path = root / relative_path
    if not path.is_file():
        return _check(
            f"{relative_path}:disk",
            "WARN",
            f"{relative_path} is missing; Render disk template cannot be checked.",
        )
    text = path.read_text(encoding="utf-8")
    missing: list[str] = []
    if "disk:" not in text:
        missing.append("disk")
    if "mountPath: /data/00631l" not in text:
        missing.append("mountPath=/data/00631l")
    if "sizeGB:" not in text:
        missing.append("sizeGB")
    if missing:
        return _check(
            f"{relative_path}:disk",
            "WARN",
            f"{relative_path} should define a persistent disk ({', '.join(missing)} missing).",
            missing=missing,
        )
    return _check(f"{relative_path}:disk", "PASS", "ok")


def _required_file_check(root: Path, relative_path: str) -> dict[str, Any]:
    path = root / relative_path
    return _check(
        relative_path,
        "PASS" if path.is_file() else "FAIL",
        "ok" if path.is_file() else f"{relative_path} is missing.",
    )


def _tracked_artifact_check(root: Path) -> dict[str, Any]:
    completed = subprocess.run(
        [
            "git",
            "ls-files",
            "backend/.env",
            "build",
            "backend/data",
            "backend/exports",
            "backend/backups",
            "backend/reports",
            "web/00631l-static-data",
        ],
        cwd=root,
        capture_output=True,
        check=False,
        text=True,
    )
    if completed.returncode != 0:
        return _check(
            "tracked_artifacts",
            "FAIL",
            completed.stderr.strip() or "git ls-files failed.",
        )
    tracked = [line for line in completed.stdout.splitlines() if line.strip()]
    return _check(
        "tracked_artifacts",
        "FAIL" if tracked else "PASS",
        f"Tracked local artifacts: {', '.join(tracked)}" if tracked else "ok",
        tracked=tracked,
    )


def _url_check(name: str, url: str, *, require_https: bool) -> dict[str, Any]:
    parsed = urlparse(url)
    if parsed.scheme not in {"http", "https"} or not parsed.netloc:
        return _check(name, "FAIL", f"{url} is not a valid http(s) URL.")
    if require_https and parsed.scheme != "https":
        return _check(name, "FAIL", f"{url} must use https.")
    if parsed.hostname in {"localhost", "127.0.0.1"}:
        return _check(
            name,
            "WARN",
            f"{url} is local-only; public phone access needs a public host.",
        )
    return _check(name, "PASS", "ok", url=url)


def _check(name: str, status: str, message: str, **extra: Any) -> dict[str, Any]:
    payload = {"name": name, "status": status, "message": message}
    payload.update(extra)
    return payload


def _load_env(path: Path) -> dict[str, str]:
    if not path.exists():
        return {}
    values: dict[str, str] = {}
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        if line.startswith("export "):
            line = line[len("export ") :].strip()
        key, value = line.split("=", 1)
        values[key.strip()] = value.strip().strip('"').strip("'")
    return values


if __name__ == "__main__":
    raise SystemExit(main())
