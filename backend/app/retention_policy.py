from __future__ import annotations

from datetime import datetime, timezone
from pathlib import Path
from typing import Any


KNOWN_EXPORT_FILES = (
    "00631l_holdings_history_summary.csv",
    "00631l_intraday_nav_history.csv",
    "00631l_history_export_metadata.json",
)


def apply_00631l_retention_policy(
    *,
    holdings_history_path: str | Path,
    intraday_history_path: str | Path,
    report_dir: str | Path,
    export_dir: str | Path,
    report_retention_count: int = 30,
    export_retention_count: int = 30,
    dry_run: bool = False,
    checked_at: datetime | None = None,
) -> dict[str, Any]:
    checked = (checked_at or datetime.now(timezone.utc)).astimezone(
        timezone.utc
    ).replace(microsecond=0)
    report_root = Path(report_dir)
    export_root = Path(export_dir)
    retention = max(1, report_retention_count)

    reports = _daily_report_files(report_root)
    stale_reports = reports[retention:]
    pruned_reports: list[str] = []
    failures: list[str] = []

    if not dry_run:
        for path in stale_reports:
            try:
                path.unlink()
                pruned_reports.append(str(path))
            except OSError as error:
                failures.append(f"failed to prune report {path}: {error}")
    else:
        pruned_reports = [str(path) for path in stale_reports]

    export_files = [
        {
            "name": name,
            "path": str(export_root / name),
            "exists": (export_root / name).is_file(),
        }
        for name in KNOWN_EXPORT_FILES
    ]
    holdings_path = Path(holdings_history_path)
    intraday_path = Path(intraday_history_path)
    history_files = [
        _history_state("holdings", holdings_path),
        _history_state("intraday", intraday_path),
    ]
    source_status = (
        "cached"
        if reports or any(item["exists"] for item in export_files) or any(
            item["exists"] for item in history_files
        )
        else "unavailable"
    )
    return {
        "sourceContract": "00631l_retention_policy",
        "sourceStatus": source_status,
        "checkedAt": checked.isoformat(),
        "overallStatus": "FAIL" if failures else "PASS",
        "dryRun": dry_run,
        "historyPolicy": {
            "mode": "retain_all",
            "reason": "Holdings and intraday JSONL history are the long-term local record.",
            "files": history_files,
        },
        "reportPolicy": {
            "retentionCount": retention,
            "totalReportCount": len(reports),
            "staleReportCount": len(stale_reports),
            "prunedCount": 0 if dry_run else len(pruned_reports),
            "candidatePrunedCount": len(stale_reports),
            "prunedFiles": pruned_reports,
            "latestReportPath": str(reports[0]) if reports else None,
        },
        "exportPolicy": {
            "retentionCount": max(1, export_retention_count),
            "mode": "fixed_current_files",
            "reason": "CSV export overwrites the current summary files instead of creating dated archives.",
            "files": export_files,
        },
        "failures": failures,
        "failureCount": len(failures),
        "errorMessage": "; ".join(failures) if failures else None,
    }


def _daily_report_files(report_root: Path) -> list[Path]:
    if not report_root.exists():
        return []
    return sorted(
        [
            path
            for path in report_root.glob("00631l_daily_report_*.md")
            if path.is_file()
        ],
        key=lambda path: (path.stat().st_mtime, path.name),
        reverse=True,
    )


def _history_state(kind: str, path: Path) -> dict[str, Any]:
    return {
        "kind": kind,
        "path": str(path),
        "exists": path.is_file(),
        "sizeBytes": path.stat().st_size if path.is_file() else 0,
    }
