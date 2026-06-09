from __future__ import annotations

import json
import os
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[2]

FORBIDDEN_TERMS = [
    "\u8cb7\u9032",
    "\u8ce3\u51fa",
    "\u52a0\u78bc",
    "\u6e1b\u78bc",
    "\u9032\u5834",
    "\u51fa\u5834",
    "\u5957\u5229",
    "\u9069\u5408\u8cb7",
    "\u4fbf\u5b9c\u53ef\u4ee5\u8cb7",
    "\u592a\u8cb4\u4e0d\u8981\u8cb7",
]


def main() -> int:
    steps = [
        _required_files_check(),
        _run_command("env_check", ["cmd", "/c", "scripts\\00631l_check_env.cmd"]),
        _run_command("flutter_analyze", ["cmd", "/c", "flutter", "analyze"]),
        _run_command("flutter_test", ["cmd", "/c", "flutter", "test"]),
        _run_command("flutter_build_web", ["cmd", "/c", "flutter", "build", "web"]),
        _run_command(
            "backend_tests",
            ["py", "-m", "unittest", "discover", "-s", "backend\\tests"],
        ),
        _run_command("daily_cycle", ["cmd", "/c", "scripts\\00631l_daily_cycle.cmd"]),
        _run_command("export", ["cmd", "/c", "scripts\\00631l_export_history.cmd"]),
        _run_command("report", ["cmd", "/c", "scripts\\00631l_generate_daily_report.cmd"]),
        _run_command("integrity", ["cmd", "/c", "scripts\\00631l_check_integrity.cmd"]),
        _run_command(
            "backup_rotation",
            ["cmd", "/c", "scripts\\00631l_backup_data.cmd", "--retention-count", "30"],
        ),
        _run_command("restore_dry_run", ["cmd", "/c", "scripts\\00631l_restore_dry_run.cmd"]),
        _run_command("smoke", ["py", "backend\\scripts\\smoke_00631l_live.py"]),
        _forbidden_wording_scan(),
        _run_command("git_diff_check", ["git", "diff", "--check"]),
    ]
    failures = [
        f"{step['name']}: {step['message']}"
        for step in steps
        if step["status"] == "FAIL"
    ]
    warnings = [
        f"{step['name']}: {step['message']}"
        for step in steps
        if step["status"] == "WARN"
    ]
    overall_status = "FAIL" if failures else "WARN" if warnings else "PASS"
    next_action = (
        "Fix failures and rerun scripts\\00631l_release_check.cmd."
        if failures
        else "Review warnings; PASS/WARN is acceptable when warnings are expected local or off-hours data freshness states."
        if warnings
        else "Ready for commit/tag."
    )
    payload = {
        "sourceContract": "00631l_release_check",
        "checkedAt": _now_iso(),
        "overallStatus": overall_status,
        "failures": failures,
        "warnings": warnings,
        "nextAction": next_action,
        "steps": steps,
    }
    print(json.dumps(payload, ensure_ascii=True, indent=2, sort_keys=True))
    print(
        "[summary] "
        f"overallStatus={overall_status} "
        f"warnings={len(warnings)} "
        f"failures={len(failures)}"
    )
    return 1 if failures else 0


def _required_files_check() -> dict[str, Any]:
    required_files = [
        "docs/00631l_scheduler_setup.md",
        "docs/00631l_daily_report_guide.md",
        "backend/app/data_integrity.py",
        "backend/app/data_backup.py",
        "backend/app/restore_dry_run.py",
        "scripts/00631l_bootstrap_deploy.cmd",
        "scripts/00631l_daily_cycle_scheduled.cmd",
        "scripts/00631l_generate_daily_report.cmd",
        "scripts/00631l_check_integrity.cmd",
        "scripts/00631l_backup_data.cmd",
        "scripts/00631l_restore_dry_run.cmd",
    ]
    missing = [path for path in required_files if not (ROOT / path).exists()]
    return {
        "name": "maintenance_artifacts",
        "command": "internal required maintenance artifact check",
        "status": "FAIL" if missing else "PASS",
        "message": f"missing {len(missing)} required files" if missing else "ok",
        "exitCode": 1 if missing else 0,
        "missingFiles": missing,
        "stdoutTail": "",
        "stderrTail": "",
    }


def _run_command(name: str, command: list[str]) -> dict[str, Any]:
    completed = subprocess.run(
        command,
        cwd=ROOT,
        capture_output=True,
        check=False,
        env=_subprocess_env(),
    )
    stdout = _decode(completed.stdout)
    stderr = _decode(completed.stderr)
    if completed.returncode != 0:
        status = "FAIL"
        message = f"exitCode {completed.returncode}"
    elif _has_overall(stdout, "FAIL") or _has_overall(stderr, "FAIL"):
        status = "FAIL"
        message = "reported overallStatus FAIL"
    elif _has_overall(stdout, "WARN") or _has_overall(stderr, "WARN"):
        status = "WARN"
        message = "reported overallStatus WARN"
    else:
        status = "PASS"
        message = "ok"
    return {
        "name": name,
        "command": " ".join(command),
        "status": status,
        "message": message,
        "exitCode": completed.returncode,
        "stdoutTail": _tail(stdout),
        "stderrTail": _tail(stderr),
    }


def _forbidden_wording_scan() -> dict[str, Any]:
    roots = [
        ROOT / "README.md",
        ROOT / "backend",
        ROOT / "docs",
        ROOT / "lib",
        ROOT / "scripts",
        ROOT / "test",
    ]
    hits: list[str] = []
    for path in _iter_text_files(roots):
        try:
            text = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue
        for term in FORBIDDEN_TERMS:
            if term in text:
                hits.append(str(path.relative_to(ROOT)))
                break
    return {
        "name": "forbidden_wording_scan",
        "command": "internal unicode-escaped forbidden wording scan",
        "status": "FAIL" if hits else "PASS",
        "message": "hits found" if hits else "ok",
        "exitCode": 1 if hits else 0,
        "hits": hits,
        "stdoutTail": "",
        "stderrTail": "",
    }


def _subprocess_env() -> dict[str, str]:
    env = os.environ.copy()
    clean_flutter = Path("C:/src/flutter-clean/bin")
    if clean_flutter.exists():
        env["PATH"] = f"{clean_flutter};{env.get('PATH', '')}"
    return env


def _iter_text_files(roots: list[Path]) -> list[Path]:
    files: list[Path] = []
    ignored_parts = {
        ".dart_tool",
        ".git",
        ".idea",
        "build",
        "backups",
        "data",
        "exports",
        "reports",
        "__pycache__",
    }
    allowed_suffixes = {".dart", ".py", ".md", ".cmd", ".ps1", ".txt", ".json", ".yaml", ".yml"}
    for root in roots:
        if root.is_file():
            files.append(root)
            continue
        if not root.exists():
            continue
        for path in root.rglob("*"):
            if not path.is_file():
                continue
            try:
                relative_parts = set(path.relative_to(ROOT).parts)
            except ValueError:
                relative_parts = set(path.parts)
            if relative_parts & ignored_parts:
                continue
            if path.suffix.lower() in allowed_suffixes:
                files.append(path)
    return files


def _has_overall(text: str, status: str) -> bool:
    return (
        f'"overallStatus": "{status}"' in text
        or f"overallStatus {status}" in text
        or f"overallStatus={status}" in text
    )


def _decode(data: bytes) -> str:
    for encoding in ("utf-8", "cp950", "mbcs"):
        try:
            return data.decode(encoding)
        except (LookupError, UnicodeDecodeError):
            continue
    return data.decode("utf-8", errors="replace")


def _tail(text: str, *, max_lines: int = 24) -> str:
    return "\n".join(text.splitlines()[-max_lines:])


def _now_iso() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


if __name__ == "__main__":
    raise SystemExit(main())
