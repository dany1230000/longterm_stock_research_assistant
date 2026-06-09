from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[2]


def main() -> int:
    payload = run_deploy_precheck()
    print(json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=True))
    print(
        "[summary] "
        f"overallStatus={payload['overallStatus']} "
        f"warnings={payload['warningCount']} "
        f"failures={payload['failureCount']}"
    )
    return 1 if payload["overallStatus"] == "FAIL" else 0


def run_deploy_precheck(root: Path = ROOT) -> dict[str, Any]:
    checks: list[dict[str, Any]] = []
    checks.append(
        _file_check(
            root=Path("C:/"),
            relative_path=Path("src/flutter-clean/bin/flutter.bat"),
            name="flutter_clean_sdk",
            required=False,
            warning_message="C:\\src\\flutter-clean\\bin\\flutter.bat is not present.",
        )
    )
    for path in [
        "backend/.env.example",
        "backend/Dockerfile",
        "backend/requirements.txt",
        "web/index.html",
        "web/manifest.json",
        "scripts/00631l_check_public_config.cmd",
        "scripts/00631l_build_web_public.cmd",
        "scripts/00631l_start_backend.cmd",
        "scripts/00631l_start_frontend_live.cmd",
        "scripts/00631l_open_lab.cmd",
        "scripts/00631l_daily_cycle.cmd",
        "scripts/00631l_release_check.cmd",
        "scripts/00631l_apply_retention.cmd",
        "scripts/00631l_restore_dry_run.cmd",
        "docs/00631l_daily_usage.md",
        "docs/00631l_deployment_notes.md",
        "docs/00631l_public_deployment.md",
        "docs/00631l_pwa_usage.md",
        "docs/00631l_app_store_path.md",
        "docs/00631l_troubleshooting.md",
        "docs/00631l_maintenance_index.md",
    ]:
        checks.append(_file_check(root=root, relative_path=Path(path), name=path))

    checks.append(
        _file_check(
            root=root,
            relative_path=Path("backend/.env"),
            name="backend_env",
            required=False,
            warning_message="backend/.env is missing; copy backend/.env.example for live local proxy settings.",
        )
    )
    for path in [
        "backend/data",
        "backend/exports",
        "backend/backups",
        "backend/reports",
    ]:
        checks.append(_directory_check(root=root, relative_path=Path(path)))

    failures = [check["message"] for check in checks if check["status"] == "FAIL"]
    warnings = [check["message"] for check in checks if check["status"] == "WARN"]
    overall_status = "FAIL" if failures else "WARN" if warnings else "PASS"
    return {
        "sourceContract": "00631l_deploy_precheck",
        "checkedAt": datetime.now(timezone.utc).replace(microsecond=0).isoformat(),
        "overallStatus": overall_status,
        "checks": checks,
        "failures": failures,
        "warnings": warnings,
        "failureCount": len(failures),
        "warningCount": len(warnings),
    }


def _file_check(
    *,
    root: Path,
    relative_path: Path,
    name: str,
    required: bool = True,
    warning_message: str | None = None,
) -> dict[str, Any]:
    path = root / relative_path
    exists = path.is_file()
    if exists:
        status = "PASS"
        message = "ok"
    elif required:
        status = "FAIL"
        message = f"{relative_path} is missing"
    else:
        status = "WARN"
        message = warning_message or f"{relative_path} is missing"
    return {
        "name": name,
        "path": str(path),
        "status": status,
        "message": message,
    }


def _directory_check(*, root: Path, relative_path: Path) -> dict[str, Any]:
    path = root / relative_path
    if not path.exists():
        return {
            "name": str(relative_path),
            "path": str(path),
            "status": "WARN",
            "message": f"{relative_path} is missing; run scripts\\00631l_check_env.cmd.",
        }
    if not path.is_dir():
        return {
            "name": str(relative_path),
            "path": str(path),
            "status": "FAIL",
            "message": f"{relative_path} is not a directory.",
        }
    writable = _is_writable(path)
    return {
        "name": str(relative_path),
        "path": str(path),
        "status": "PASS" if writable else "FAIL",
        "message": "ok" if writable else f"{relative_path} is not writable.",
    }


def _is_writable(path: Path) -> bool:
    probe = path / ".00631l_deploy_precheck.tmp"
    try:
        probe.write_text("write-test", encoding="utf-8")
        probe.unlink()
        return True
    except OSError:
        try:
            if probe.exists():
                probe.unlink()
        except OSError:
            pass
        return False


if __name__ == "__main__":
    raise SystemExit(main())
