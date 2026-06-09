from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys


ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from backend.app.config import settings  # noqa: E402
from backend.app.data_integrity import check_00631l_data_integrity  # noqa: E402


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Check local 00631L history data integrity.",
    )
    parser.add_argument("--holdings-history-path", default=settings.holdings_history_path)
    parser.add_argument("--intraday-history-path", default=settings.intraday_nav_history_path)
    parser.add_argument("--output-path", default=settings.integrity_status_path)
    args = parser.parse_args()

    payload = check_00631l_data_integrity(
        holdings_history_path=args.holdings_history_path,
        intraday_history_path=args.intraday_history_path,
        output_path=args.output_path,
    )
    print(json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=True))
    print(
        "[summary] "
        f"overallStatus={payload['overallStatus']} "
        f"warnings={payload['warningCount']} "
        f"failures={payload['failureCount']}"
    )
    return 1 if payload["overallStatus"] == "FAIL" else 0


if __name__ == "__main__":
    raise SystemExit(main())
