from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys


ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from backend.app.collector import collect_00631l_snapshot  # noqa: E402
from backend.app.service import service  # noqa: E402


def main() -> int:
    parser = argparse.ArgumentParser(
        description=(
            "Collect one 00631L operational snapshot. Successful official "
            "holdings and intraday NAV payloads are saved by the backend "
            "service into the configured local JSONL history stores."
        )
    )
    parser.add_argument("--skip-profile", action="store_true")
    parser.add_argument("--skip-holdings", action="store_true")
    parser.add_argument("--skip-intraday", action="store_true")
    parser.add_argument(
        "--samples",
        type=int,
        default=1,
        help="Number of intraday NAV samples to collect in this run.",
    )
    parser.add_argument(
        "--interval-seconds",
        type=float,
        default=15.0,
        help=(
            "Seconds to wait between intraday samples. Use at least the "
            "configured intraday NAV cache interval when collecting multiple "
            "samples."
        ),
    )
    args = parser.parse_args()

    payload = collect_00631l_snapshot(
        service,
        include_profile=not args.skip_profile,
        include_holdings=not args.skip_holdings,
        include_intraday=not args.skip_intraday,
        intraday_samples=max(0, args.samples),
        interval_seconds=max(0.0, args.interval_seconds),
    )
    print(json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=True))
    return 1 if payload["overallStatus"] == "FAIL" else 0


if __name__ == "__main__":
    raise SystemExit(main())
