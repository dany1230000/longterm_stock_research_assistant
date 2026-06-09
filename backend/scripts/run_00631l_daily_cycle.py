from __future__ import annotations

import json
import re
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from backend.app.config import settings  # noqa: E402
from backend.app.daily_report import generate_00631l_daily_report  # noqa: E402


def main() -> int:
    started_at = _now_iso()
    steps = [
        _run_step(
            "collect",
            ["cmd", "/c", "scripts\\00631l_collect_snapshot.cmd", "--samples", "1"],
        ),
        _run_step("export", ["cmd", "/c", "scripts\\00631l_export_history.cmd"]),
        _run_step("smoke", ["cmd", "/c", "scripts\\00631l_daily_smoke.cmd"]),
        _run_step("integrity", ["cmd", "/c", "scripts\\00631l_check_integrity.cmd"]),
    ]
    failures = [
        f"{step['name']} failed with exitCode {step['exitCode']}"
        for step in steps
        if step["status"] == "FAIL"
    ]
    warnings = [
        f"{step['name']} returned WARN"
        for step in steps
        if step["status"] == "WARN"
    ]
    payload: dict[str, Any] = {
        "sourceContract": "00631l_daily_cycle_status",
        "startedAt": started_at,
        "finishedAt": _now_iso(),
        "overallStatus": "FAIL" if failures else "WARN" if warnings else "PASS",
        "collect": steps[0],
        "export": steps[1],
        "smoke": steps[2],
        "integrity": steps[3],
        "warnings": warnings,
        "failures": failures,
    }
    report_step = _generate_report_step(payload)
    payload["report"] = report_step
    all_steps = [*steps, report_step]
    failures = [
        f"{step['name']} failed with exitCode {step['exitCode']}"
        for step in all_steps
        if step["status"] == "FAIL"
    ]
    warnings = [
        f"{step['name']} returned WARN"
        for step in all_steps
        if step["status"] == "WARN"
    ]
    payload["finishedAt"] = _now_iso()
    payload["overallStatus"] = "FAIL" if failures else "WARN" if warnings else "PASS"
    payload["warnings"] = warnings
    payload["failures"] = failures
    _write_status(payload)
    print(json.dumps(payload, ensure_ascii=True, indent=2, sort_keys=True))
    return 1 if failures else 0


def _run_step(name: str, command: list[str]) -> dict[str, Any]:
    started_at = _now_iso()
    completed = subprocess.run(
        command,
        cwd=ROOT,
        capture_output=True,
        check=False,
    )
    stdout = _decode(completed.stdout)
    stderr = _decode(completed.stderr)
    status = _derive_status(completed.returncode, stdout, stderr)
    return {
        "name": name,
        "command": " ".join(command),
        "status": status,
        "exitCode": completed.returncode,
        "startedAt": started_at,
        "finishedAt": _now_iso(),
        "stdoutTail": _tail(stdout),
        "stderrTail": _tail(stderr),
    }


def _generate_report_step(daily_cycle_status: dict[str, Any]) -> dict[str, Any]:
    started_at = _now_iso()
    try:
        payload = generate_00631l_daily_report(
            holdings_history_path=settings.holdings_history_path,
            intraday_history_path=settings.intraday_nav_history_path,
            daily_cycle_status_path=settings.daily_cycle_status_path,
            report_dir=settings.report_dir,
            daily_cycle_status=daily_cycle_status,
        )
    except Exception as exc:  # pragma: no cover - defensive operational path
        return {
            "name": "report",
            "command": "generate_00631l_daily_report",
            "status": "FAIL",
            "exitCode": 1,
            "startedAt": started_at,
            "finishedAt": _now_iso(),
            "stdoutTail": "",
            "stderrTail": str(exc),
        }

    return {
        "name": "report",
        "command": "generate_00631l_daily_report",
        "status": "PASS",
        "exitCode": 0,
        "startedAt": started_at,
        "finishedAt": _now_iso(),
        "stdoutTail": json.dumps(payload, ensure_ascii=True, sort_keys=True),
        "stderrTail": "",
    }


def _derive_status(exit_code: int, stdout: str, stderr: str) -> str:
    combined = f"{stdout}\n{stderr}"
    if exit_code != 0 or _contains_overall_status(combined, "FAIL"):
        return "FAIL"
    if _contains_overall_status(combined, "WARN"):
        return "WARN"
    return "PASS"


def _contains_overall_status(text: str, status: str) -> bool:
    return bool(re.search(rf'"overallStatus"\s*:\s*"{status}"', text))


def _write_status(payload: dict[str, Any]) -> None:
    path = Path(settings.daily_cycle_status_path)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=True),
        encoding="utf-8",
    )


def _decode(data: bytes) -> str:
    for encoding in ("utf-8", "cp950", "mbcs"):
        try:
            return data.decode(encoding)
        except (LookupError, UnicodeDecodeError):
            continue
    return data.decode("utf-8", errors="replace")


def _tail(text: str, *, max_lines: int = 40) -> str:
    lines = text.splitlines()
    return "\n".join(lines[-max_lines:])


def _now_iso() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


if __name__ == "__main__":
    raise SystemExit(main())
