from __future__ import annotations

import json
import socket
import subprocess
import tempfile
import time
import urllib.request
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
IMAGE_NAME = "00631l-lab-backend:prod-check"


def main() -> int:
    payload = run_backend_docker_check()
    print(json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=True))
    print(
        "[summary] "
        f"overallStatus={payload['overallStatus']} "
        f"warnings={payload['warningCount']} "
        f"failures={payload['failureCount']}"
    )
    return 1 if payload["overallStatus"] == "FAIL" else 0


def run_backend_docker_check(root: Path = ROOT) -> dict[str, Any]:
    checks = [
        _file_check(root, "backend/Dockerfile"),
        _file_check(root, "deploy/docker-compose.yml"),
    ]
    docker_check = _docker_available_check()
    checks.append(docker_check)
    if docker_check["status"] == "PASS":
        checks.extend(_build_and_smoke(root))
    failures = [check["message"] for check in checks if check["status"] == "FAIL"]
    warnings = [check["message"] for check in checks if check["status"] == "WARN"]
    overall_status = "FAIL" if failures else "WARN" if warnings else "PASS"
    return {
        "sourceContract": "00631l_backend_docker_check",
        "checkedAt": _now_iso(),
        "overallStatus": overall_status,
        "checks": checks,
        "warnings": warnings,
        "failures": failures,
        "warningCount": len(warnings),
        "failureCount": len(failures),
    }


def _file_check(root: Path, relative_path: str) -> dict[str, Any]:
    path = root / relative_path
    return _check(
        relative_path,
        "PASS" if path.is_file() else "FAIL",
        "ok" if path.is_file() else f"{relative_path} is missing.",
    )


def _docker_available_check() -> dict[str, Any]:
    try:
        version = subprocess.run(
            ["docker", "--version"],
            cwd=ROOT,
            capture_output=True,
            check=False,
            text=True,
        )
    except FileNotFoundError:
        return _check(
            "docker_available",
            "WARN",
            "Docker is not available; install Docker Desktop or use VPS Python run.",
        )
    if version.returncode != 0:
        return _check(
            "docker_available",
            "WARN",
            "Docker is not available; install Docker Desktop or use VPS Python run.",
            stderr=version.stderr.strip(),
        )
    info = subprocess.run(
        ["docker", "info"],
        cwd=ROOT,
        capture_output=True,
        check=False,
        text=True,
    )
    if info.returncode != 0:
        return _check(
            "docker_daemon",
            "WARN",
            "Docker command exists but the daemon is not reachable.",
            stderr=info.stderr.strip()[-1000:],
        )
    return _check("docker_available", "PASS", version.stdout.strip())


def _build_and_smoke(root: Path) -> list[dict[str, Any]]:
    checks: list[dict[str, Any]] = []
    build = subprocess.run(
        [
            "docker",
            "build",
            "-f",
            "backend/Dockerfile",
            "-t",
            IMAGE_NAME,
            ".",
        ],
        cwd=root,
        capture_output=True,
        check=False,
        text=True,
    )
    checks.append(
        _check(
            "docker_build",
            "PASS" if build.returncode == 0 else "FAIL",
            "ok" if build.returncode == 0 else "docker build failed.",
            stdoutTail=build.stdout[-2000:],
            stderrTail=build.stderr[-2000:],
        )
    )
    if build.returncode != 0:
        return checks

    port = _find_free_port()
    container_id = ""
    with tempfile.TemporaryDirectory(prefix="00631l_docker_data_") as temp_dir:
        run = subprocess.run(
            [
                "docker",
                "run",
                "--rm",
                "-d",
                "-p",
                f"{port}:8000",
                "-v",
                f"{temp_dir}:/data/00631l",
                "-e",
                "PUBLIC_API_BASE_URL=http://127.0.0.1:8000",
                "-e",
                "ALLOWED_ORIGINS=http://127.0.0.1:8080",
                "-e",
                "TWSE_00631L_INTRADAY_NAV_URL=https://mis.twse.com.tw/stock/data/all_etf.txt",
                "-e",
                "00631L_INTRADAY_NAV_SOURCE=twse",
                IMAGE_NAME,
            ],
            cwd=root,
            capture_output=True,
            check=False,
            text=True,
        )
        if run.returncode != 0:
            checks.append(
                _check(
                    "docker_run",
                    "FAIL",
                    "docker run failed.",
                    stderrTail=run.stderr[-2000:],
                )
            )
            return checks
        container_id = run.stdout.strip()
        try:
            checks.append(_smoke_container(port))
        finally:
            subprocess.run(
                ["docker", "stop", container_id],
                cwd=root,
                capture_output=True,
                check=False,
                text=True,
            )
    return checks


def _smoke_container(port: int) -> dict[str, Any]:
    last_error = ""
    for _ in range(30):
        try:
            with urllib.request.urlopen(
                f"http://127.0.0.1:{port}/ready",
                timeout=3,
            ) as response:
                payload = json.loads(response.read().decode("utf-8"))
            if payload.get("sourceContract") != "00631l_backend_readiness":
                return _check("docker_ready_smoke", "FAIL", "Unexpected /ready payload.")
            if payload.get("overallStatus") == "FAIL":
                return _check(
                    "docker_ready_smoke",
                    "FAIL",
                    f"/ready reported failures: {payload.get('failures')}",
                    payload=payload,
                )
            return _check(
                "docker_ready_smoke",
                "PASS" if payload.get("overallStatus") == "PASS" else "WARN",
                "ok" if payload.get("overallStatus") == "PASS" else "container /ready returned WARN.",
                overallStatus=payload.get("overallStatus"),
                warnings=payload.get("warnings", []),
            )
        except Exception as error:
            last_error = str(error)
            time.sleep(1)
    return _check("docker_ready_smoke", "FAIL", f"Container /ready did not respond: {last_error}")


def _find_free_port() -> int:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
        sock.bind(("127.0.0.1", 0))
        return int(sock.getsockname()[1])


def _check(name: str, status: str, message: str, **extra: Any) -> dict[str, Any]:
    payload = {"name": name, "status": status, "message": message}
    payload.update(extra)
    return payload


def _now_iso() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


if __name__ == "__main__":
    raise SystemExit(main())
