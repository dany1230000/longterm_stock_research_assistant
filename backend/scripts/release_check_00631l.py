from __future__ import annotations

import json
import os
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

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
        _pwa_metadata_check(),
        _readiness_endpoint_check(),
        _analysis_endpoint_check(),
        _run_command("public_config", ["cmd", "/c", "scripts\\00631l_check_public_config.cmd"]),
        _run_command("backend_prod_check", ["cmd", "/c", "scripts\\00631l_backend_prod_check.cmd"]),
        _run_command("backend_docker_check", ["cmd", "/c", "scripts\\00631l_backend_docker_check.cmd"]),
        _run_command("deploy_precheck", ["cmd", "/c", "scripts\\00631l_deploy_precheck.cmd"]),
        _run_command(
            "remote_maintenance_dry_run",
            ["cmd", "/c", "scripts\\00631l_remote_maintenance.cmd", "--dry-run"],
        ),
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
            "retention_dry_run",
            [
                "cmd",
                "/c",
                "scripts\\00631l_apply_retention.cmd",
                "--dry-run",
                "--report-retention-count",
                "30",
            ],
        ),
        _run_command(
            "backup_rotation",
            ["cmd", "/c", "scripts\\00631l_backup_data.cmd", "--retention-count", "30"],
        ),
        _run_command("restore_dry_run", ["cmd", "/c", "scripts\\00631l_restore_dry_run.cmd"]),
        _run_command(
            "price_history_status",
            ["cmd", "/c", "scripts\\00631l_update_price_history.cmd", "--status-only"],
        ),
        _run_command(
            "static_public_data",
            ["cmd", "/c", "scripts\\00631l_export_static_data.cmd", "--status-only"],
        ),
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
        "docs/00631l_docs_index.md",
        "docs/00631l_mobile_usage.md",
        "docs/00631l_ai_analysis.md",
        "docs/00631l_public_deployment.md",
        "docs/00631l_pwa_usage.md",
        "docs/00631l_app_store_path.md",
        "docs/00631l_v2_2_public_deploy_ready_summary.md",
        "docs/00631l_backtest_guide.md",
        "docs/00631l_position_tracking.md",
        "docs/00631l_data_sources_freshness.md",
        "docs/00631l_v3_0_app_ready_summary.md",
        "docs/00631l_v3_1_static_public_summary.md",
        "docs/00631l_v3_2_standalone_pwa_summary.md",
        "docs/00631l_live_backend_deployment.md",
        "docs/00631l_v3_3_live_public_summary.md",
        "docs/00631l_v3_4_live_backend_summary.md",
        "docs/00631l_v3_5_remote_maintenance_summary.md",
        "docs/00631l_v3_6_app_ui_refresh_summary.md",
        "docs/00631l_v3_7_complete_data_ui_summary.md",
        "docs/00631l_v3_8_market_app_ui_summary.md",
        "docs/00631l_v3_9_mobile_information_architecture_summary.md",
        "docs/00631l_v3_10_mobile_polish_summary.md",
        "docs/00631l_v3_11_section_summaries.md",
        "docs/00631l_v3_12_navigation_settings_summary.md",
        "docs/00631l_v3_13_data_coverage_summary.md",
        "docs/00631l_v3_14_holdings_coverage_summary.md",
        "docs/00631l_v3_15_holdings_mobile_cards_summary.md",
        "docs/00631l_v3_16_overview_first_screen_summary.md",
        "docs/00631l_v3_17_information_hierarchy_summary.md",
        "docs/00631l_v3_18_detail_progressive_disclosure_summary.md",
        "docs/00631l_v3_19_first_screen_speed_layout_summary.md",
        "docs/00631l_v3_20_home_at_a_glance_summary.md",
        "docs/00631l_v3_21_compact_home_summary.md",
        "docs/00631l_v3_22_fast_startup_summary.md",
        "docs/00631l_v3_23_live_cold_start_fallback_summary.md",
        "docs/00631l_v3_24_overview_layout_summary.md",
        "docs/00631l_v3_25_compact_quote_board_summary.md",
        "docs/00631l_v3_26_user_facing_status_labels_summary.md",
        "docs/00631l_v3_27_four_metric_home_summary.md",
        "docs/00631l_v3_28_home_sparkline_exposure_summary.md",
        "docs/00631l_v3_29_first_screen_segmentation_summary.md",
        "docs/00631l_v3_30_home_data_readiness_summary.md",
        "docs/00631l_v3_31_mobile_quote_trim_summary.md",
        "docs/00631l_v3_32_mobile_first_screen_density_summary.md",
        "docs/00631l_v3_33_fast_first_data_load_summary.md",
        "docs/00631l_v3_34_settings_page_cleanup_summary.md",
        "docs/00631l_v3_35_compact_section_headers_summary.md",
        "docs/00631l_v3_36_overview_history_performance_summary.md",
        "docs/00631l_v3_37_overview_metric_grid_summary.md",
        "docs/00631l_v3_38_history_backtest_merge_summary.md",
        "docs/00631l_v3_39_compact_quote_nav_line_summary.md",
        "docs/00631l_v3_40_live_timeout_static_fallback_summary.md",
        "docs/00631l_v3_41_holdings_exposure_compare_summary.md",
        "docs/00631l_v3_42_web_loading_shell_summary.md",
        "docs/00631l_v3_43_yuanta_maintenance_detection_summary.md",
        "docs/00631l_v3_44_live_static_history_merge_summary.md",
        "docs/00631l_v3_45_remote_history_chunk_update_summary.md",
        "docs/00631l_v3_46_first_screen_live_clarity_summary.md",
        "docs/00631l_v3_47_split_adjusted_history_summary.md",
        "docs/00631l_remote_maintenance.md",
        ".github/workflows/00631l_backend_maintenance.yml",
        "docs/00631l_daily_report_guide.md",
        "deploy/docker-compose.yml",
        "deploy/Caddyfile",
        "deploy/nginx.example.conf",
        "deploy/render.yaml",
        "backend/Dockerfile",
        "backend/app/analysis.py",
        "backend/app/backtest.py",
        "backend/app/price_history.py",
        "backend/app/static_export.py",
        "backend/app/data_integrity.py",
        "backend/app/data_backup.py",
        "backend/app/restore_dry_run.py",
        "backend/app/retention_policy.py",
        "backend/scripts/check_public_config_00631l.py",
        "backend/scripts/backend_prod_check_00631l.py",
        "backend/scripts/backend_docker_check_00631l.py",
        "backend/scripts/deploy_precheck_00631l.py",
        "backend/scripts/remote_maintenance_00631l.py",
        "scripts/00631l_check_public_config.cmd",
        "scripts/00631l_build_web_public.cmd",
        "scripts/00631l_backend_prod_check.cmd",
        "scripts/00631l_backend_docker_check.cmd",
        "scripts/00631l_bootstrap_deploy.cmd",
        "scripts/00631l_deploy_precheck.cmd",
        "scripts/00631l_remote_maintenance.cmd",
        "scripts/00631l_daily_cycle_scheduled.cmd",
        "scripts/00631l_lan_info.cmd",
        "scripts/00631l_start_backend_lan.cmd",
        "scripts/00631l_start_frontend_lan.cmd",
        "scripts/00631l_generate_daily_report.cmd",
        "scripts/00631l_check_integrity.cmd",
        "scripts/00631l_apply_retention.cmd",
        "scripts/00631l_backup_data.cmd",
        "scripts/00631l_restore_dry_run.cmd",
        "scripts/00631l_update_price_history.cmd",
        "scripts/00631l_export_static_data.cmd",
        "scripts/00631l_build_pages_static.cmd",
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


def _pwa_metadata_check() -> dict[str, Any]:
    failures = []
    try:
        manifest = json.loads((ROOT / "web" / "manifest.json").read_text(encoding="utf-8"))
        index = (ROOT / "web" / "index.html").read_text(encoding="utf-8")
    except Exception as error:
        return {
            "name": "pwa_metadata",
            "command": "internal web manifest/index metadata check",
            "status": "FAIL",
            "message": str(error),
            "exitCode": 1,
            "stdoutTail": "",
            "stderrTail": str(error),
        }
    if manifest.get("name") != "00631L 正二研究室":
        failures.append("manifest name is not 00631L dedicated")
    if manifest.get("short_name") != "00631L":
        failures.append("manifest short_name is not 00631L")
    if manifest.get("start_url") != "./":
        failures.append("manifest start_url does not open root")
    if manifest.get("scope") != "./":
        failures.append("manifest scope is not root")
    if "00631L 正二研究室" not in index:
        failures.append("index title/app metadata missing 00631L")
    if "LongTerm Stock Research Assistant" in index:
        failures.append("index still exposes generic app title")
    return {
        "name": "pwa_metadata",
        "command": "internal web manifest/index metadata check",
        "status": "FAIL" if failures else "PASS",
        "message": "; ".join(failures) if failures else "ok",
        "exitCode": 1 if failures else 0,
        "stdoutTail": json.dumps(manifest, ensure_ascii=True)[-3000:],
        "stderrTail": "",
    }


def _readiness_endpoint_check() -> dict[str, Any]:
    try:
        from fastapi.testclient import TestClient
        from backend.app.main import app

        response = TestClient(app).get("/ready")
        payload = response.json()
        failures = []
        if response.status_code != 200:
            failures.append(f"status_code={response.status_code}")
        if payload.get("sourceContract") != "00631l_backend_readiness":
            failures.append("missing readiness sourceContract")
        if payload.get("overallStatus") == "FAIL":
            failures.extend(payload.get("failures") or ["readiness failed"])
        status = "FAIL" if failures else "PASS"
        return {
            "name": "readiness_endpoint",
            "command": "internal TestClient GET /ready",
            "status": status,
            "message": "; ".join(str(item) for item in failures) if failures else "ok",
            "exitCode": 1 if failures else 0,
            "stdoutTail": json.dumps(payload, ensure_ascii=True)[-3000:],
            "stderrTail": "",
        }
    except Exception as error:  # pragma: no cover - release guard
        return {
            "name": "readiness_endpoint",
            "command": "internal TestClient GET /ready",
            "status": "FAIL",
            "message": str(error),
            "exitCode": 1,
            "stdoutTail": "",
            "stderrTail": str(error),
        }


def _analysis_endpoint_check() -> dict[str, Any]:
    try:
        from fastapi.testclient import TestClient
        from backend.app.main import app

        response = TestClient(app).get("/api/etf/00631l/analysis/summary")
        payload = response.json()
        failures = []
        if response.status_code != 200:
            failures.append(f"status_code={response.status_code}")
        if payload.get("source") != "rule_based":
            failures.append("source is not rule_based")
        if payload.get("disclaimer") != "\u975e\u8cb7\u8ce3\u5efa\u8b70":
            failures.append("missing non-advice disclaimer")
        if not isinstance(payload.get("bullets"), list):
            failures.append("bullets missing")
        if not isinstance(payload.get("actionItems"), list):
            failures.append("actionItems missing")
        status = "FAIL" if failures else "PASS"
        return {
            "name": "analysis_endpoint",
            "command": "internal TestClient GET /api/etf/00631l/analysis/summary",
            "status": status,
            "message": "; ".join(failures) if failures else "ok",
            "exitCode": 1 if failures else 0,
            "stdoutTail": json.dumps(payload, ensure_ascii=True)[-3000:],
            "stderrTail": "",
        }
    except Exception as error:  # pragma: no cover - defensive release check guard
        return {
            "name": "analysis_endpoint",
            "command": "internal TestClient GET /api/etf/00631l/analysis/summary",
            "status": "FAIL",
            "message": str(error),
            "exitCode": 1,
            "stdoutTail": "",
            "stderrTail": str(error),
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
