from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys


ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from backend.app.config import settings  # noqa: E402
from backend.app.history_export import export_00631l_history  # noqa: E402


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Export local 00631L JSONL history stores to CSV files.",
    )
    parser.add_argument(
        "--output-dir",
        default=str(ROOT / "backend" / "exports"),
    )
    parser.add_argument(
        "--holdings-history-path",
        default=settings.holdings_history_path,
    )
    parser.add_argument(
        "--intraday-history-path",
        default=settings.intraday_nav_history_path,
    )
    args = parser.parse_args()

    payload = export_00631l_history(
        holdings_history_path=args.holdings_history_path,
        intraday_history_path=args.intraday_history_path,
        output_dir=args.output_dir,
    )
    print(json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=True))
    print(
        "[summary] "
        f"holdingsRows={payload['holdingsRowCount']} "
        f"intradayRows={payload['intradayRowCount']} "
        f"metadata={payload['metadataOutputPath']}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
