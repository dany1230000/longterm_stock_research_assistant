from __future__ import annotations

import json
import subprocess
import sys
import tempfile
from datetime import datetime, timezone
from pathlib import Path
from typing import Any
from urllib.parse import urlparse


ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

REQUIRED_ENV_KEYS = [
    "PUBLIC_API_BASE_URL",
    "ALLOWED_ORIGINS",
    "TWSE_00631L_INTRADAY_NAV_URL",
    "TWSE_00631L_PRICE_HISTORY_URL_TEMPLATE",
    "00631L_INTRADAY_NAV_SOURCE",
    "00631L_TX_QUOTE_CACHE_SECONDS",
    "TAIFEX_TX_SOCKJS_URL",
    "TAIFEX_TX_FUTURES_SYMBOL",
    "TAIFEX_TX_SPOT_SYMBOL",
    "00631L_DATA_DIR",
    "00631L_DATA_PERSISTENCE_MODE",
    "00631L_HOLDINGS_HISTORY_PATH",
    "00631L_INTRADAY_NAV_HISTORY_PATH",
    "00631L_PRICE_HISTORY_PATH",
    "ETF_CATALOG_PATH",
    "00631L_HISTORY_EXPORT_DIR",
    "00631L_BACKUP_DIR",
    "00631L_REPORT_DIR",
]

REQUIRED_FILES = [
    "backend/Dockerfile",
    "backend/.env.example",
    "deploy/docker-compose.yml",
    "deploy/Caddyfile",
    "deploy/nginx.example.conf",
    "deploy/render.yaml",
    "docs/00631l_live_backend_deployment.md",
    "docs/00631l_v3_3_live_public_summary.md",
]


def main() -> int:
    payload = run_backend_prod_check()
    print(json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=True))
    print(
        "[summary] "
        f"overallStatus={payload['overallStatus']} "
        f"warnings={payload['warningCount']} "
        f"failures={payload['failureCount']}"
    )
    return 1 if payload["overallStatus"] == "FAIL" else 0


def run_backend_prod_check(root: Path = ROOT) -> dict[str, Any]:
    env_example = _load_env(root / "backend" / ".env.example")
    checks = [
        *[_required_file_check(root, path) for path in REQUIRED_FILES],
        _env_template_check(env_example),
        _public_api_url_check(env_example),
        _allowed_origins_check(env_example),
        _data_persistence_check(env_example),
        _tracked_artifact_check(root),
        _readiness_endpoint_contract_check(),
    ]
    failures = [check["message"] for check in checks if check["status"] == "FAIL"]
    warnings = [check["message"] for check in checks if check["status"] == "WARN"]
    overall_status = "FAIL" if failures else "WARN" if warnings else "PASS"
    return {
        "sourceContract": "00631l_backend_prod_check",
        "checkedAt": _now_iso(),
        "overallStatus": overall_status,
        "checks": checks,
        "warnings": warnings,
        "failures": failures,
        "warningCount": len(warnings),
        "failureCount": len(failures),
    }


def _required_file_check(root: Path, relative_path: str) -> dict[str, Any]:
    path = root / relative_path
    return _check(
        relative_path,
        "PASS" if path.is_file() else "FAIL",
        "ok" if path.is_file() else f"{relative_path} is missing.",
    )


def _env_template_check(env: dict[str, str]) -> dict[str, Any]:
    missing = [key for key in REQUIRED_ENV_KEYS if not env.get(key)]
    return _check(
        "env_template",
        "FAIL" if missing else "PASS",
        f"backend/.env.example missing: {', '.join(missing)}" if missing else "ok",
        missing=missing,
    )


def _public_api_url_check(env: dict[str, str]) -> dict[str, Any]:
    return _url_check("public_api_base_url", env.get("PUBLIC_API_BASE_URL", ""))


def _allowed_origins_check(env: dict[str, str]) -> dict[str, Any]:
    raw = env.get("ALLOWED_ORIGINS", "")
    origins = [item.strip() for item in raw.split(",") if item.strip()]
    if not origins:
        return _check("allowed_origins", "FAIL", "ALLOWED_ORIGINS is empty.")
    if "*" in origins:
        return _check("allowed_origins", "FAIL", "ALLOWED_ORIGINS must not use wildcard.")
    invalid = [origin for origin in origins if _parse_url(origin) is None]
    if invalid:
        return _check(
            "allowed_origins",
            "FAIL",
            f"Invalid allowed origins: {', '.join(invalid)}",
            origins=origins,
        )
    return _check("allowed_origins", "PASS", "ok", origins=origins)


def _data_persistence_check(env: dict[str, str]) -> dict[str, Any]:
    mode = env.get("00631L_DATA_PERSISTENCE_MODE", "")
    data_dir = env.get("00631L_DATA_DIR", "")
    if mode != "persistent":
        return _check(
            "data_persistence",
            "FAIL",
            "backend/.env.example should default production examples to persistent mode.",
            mode=mode,
            dataDir=data_dir,
        )
    if not data_dir.startswith("/data"):
        return _check(
            "data_persistence",
            "WARN",
            "Production data dir should normally be mounted under /data.",
            mode=mode,
            dataDir=data_dir,
        )
    return _check("data_persistence", "PASS", "ok", mode=mode, dataDir=data_dir)


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
        return _check("tracked_artifacts", "FAIL", completed.stderr.strip() or "git ls-files failed.")
    tracked = [line for line in completed.stdout.splitlines() if line.strip()]
    return _check(
        "tracked_artifacts",
        "FAIL" if tracked else "PASS",
        f"Tracked local artifacts: {', '.join(tracked)}" if tracked else "ok",
        tracked=tracked,
    )


def _readiness_endpoint_contract_check() -> dict[str, Any]:
    try:
        from fastapi.testclient import TestClient
        from backend.app.config import Settings
        from backend.app.main import create_app
        from backend.app.service import Etf00631LService

        with tempfile.TemporaryDirectory() as temp_dir:
            data_dir = Path(temp_dir) / "data"
            service = Etf00631LService(
                config=Settings(
                    public_api_base_url="https://api.example.com",
                    allowed_origins=("https://dany1230000.github.io",),
                    data_dir=str(data_dir),
                    data_persistence_mode="persistent",
                    twse_intraday_nav_url="fixture://twse/all_etf",
                    yuanta_intraday_nav_url="",
                    holdings_history_path=str(data_dir / "holdings.jsonl"),
                    intraday_nav_history_path=str(data_dir / "intraday.jsonl"),
                    price_history_path=str(data_dir / "price.jsonl"),
                ),
                fetcher=lambda url, timeout_seconds: '{"msgArray":[]}',
            )
            response = TestClient(create_app(app_service=service)).get("/ready")
        payload = response.json()
        failures = []
        if response.status_code != 200:
            failures.append(f"status_code={response.status_code}")
        if payload.get("sourceContract") != "00631l_backend_readiness":
            failures.append("missing readiness sourceContract")
        if payload.get("overallStatus") == "FAIL":
            failures.append(f"readiness failed: {payload.get('failures')}")
        return _check(
            "readiness_endpoint_contract",
            "FAIL" if failures else "PASS",
            "; ".join(failures) if failures else "ok",
            overallStatus=payload.get("overallStatus"),
        )
    except Exception as error:
        return _check("readiness_endpoint_contract", "FAIL", str(error))


def _url_check(name: str, url: str) -> dict[str, Any]:
    parsed = _parse_url(url)
    if parsed is None:
        return _check(name, "FAIL", f"{url or '<empty>'} is not a valid http(s) URL.")
    if parsed.hostname in {"localhost", "127.0.0.1"}:
        return _check(name, "WARN", f"{url} is local-only.")
    return _check(name, "PASS", "ok", url=url)


def _parse_url(url: str):
    parsed = urlparse(url)
    if parsed.scheme not in {"http", "https"} or not parsed.netloc:
        return None
    return parsed


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
        key, value = line.split("=", 1)
        values[key.strip()] = value.strip().strip('"').strip("'")
    return values


def _now_iso() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


if __name__ == "__main__":
    raise SystemExit(main())
