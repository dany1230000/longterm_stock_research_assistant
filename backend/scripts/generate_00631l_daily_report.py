from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys


ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from backend.app.config import settings  # noqa: E402
from backend.app.daily_report import generate_00631l_daily_report  # noqa: E402


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Generate a local Markdown daily report for 00631L.",
    )
    parser.add_argument("--holdings-history-path", default=settings.holdings_history_path)
    parser.add_argument("--intraday-history-path", default=settings.intraday_nav_history_path)
    parser.add_argument("--daily-cycle-status-path", default=settings.daily_cycle_status_path)
    parser.add_argument("--report-dir", default=settings.report_dir)
    args = parser.parse_args()

    payload = generate_00631l_daily_report(
        holdings_history_path=args.holdings_history_path,
        intraday_history_path=args.intraday_history_path,
        daily_cycle_status_path=args.daily_cycle_status_path,
        report_dir=args.report_dir,
    )
    print(json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=True))
    print(
        "[summary] "
        f"overallStatus={payload['overallStatus']} "
        f"report={payload['reportPath']}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
