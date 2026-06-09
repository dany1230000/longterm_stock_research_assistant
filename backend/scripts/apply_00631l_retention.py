from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys


ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from backend.app.config import settings  # noqa: E402
from backend.app.retention_policy import apply_00631l_retention_policy  # noqa: E402


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Apply local retention policy for 00631L reports and export state.",
    )
    parser.add_argument(
        "--report-retention-count",
        type=int,
        default=settings.report_retention_count,
    )
    parser.add_argument(
        "--export-retention-count",
        type=int,
        default=settings.export_retention_count,
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show retention candidates without deleting report files.",
    )
    args = parser.parse_args()

    payload = apply_00631l_retention_policy(
        holdings_history_path=settings.holdings_history_path,
        intraday_history_path=settings.intraday_nav_history_path,
        report_dir=settings.report_dir,
        export_dir=settings.history_export_dir,
        report_retention_count=args.report_retention_count,
        export_retention_count=args.export_retention_count,
        dry_run=args.dry_run,
    )
    print(json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=True))
    print(
        "[summary] "
        f"overallStatus={payload['overallStatus']} "
        f"dryRun={payload['dryRun']} "
        f"reports={payload['reportPolicy']['totalReportCount']} "
        f"candidatePruned={payload['reportPolicy']['candidatePrunedCount']} "
        f"pruned={payload['reportPolicy']['prunedCount']}"
    )
    return 1 if payload["overallStatus"] == "FAIL" else 0


if __name__ == "__main__":
    raise SystemExit(main())
