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


def main() -> int:
    started_at = _now_iso()
    steps = [
        _run_step(
            "collect",
            ["cmd", "/c", "scripts\\00631l_collect_snapshot.cmd", "--samples", "1"],
        ),
        _run_step("export", ["cmd", "/c", "scripts\\00631l_export_history.cmd"]),
        _run_step("smoke", ["cmd", "/c", "scripts\\00631l_daily_smoke.cmd"]),
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
    overall_status = "FAIL" if failures else "WARN" if warnings else "PASS"
    payload: dict[str, Any] = {
        "sourceContract": "00631l_daily_cycle_status",
        "startedAt": started_at,
        "finishedAt": _now_iso(),
        "overallStatus": overall_status,
        "collect": steps[0],
        "export": steps[1],
        "smoke": steps[2],
        "warnings": warnings,
        "failures": failures,
    }
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
