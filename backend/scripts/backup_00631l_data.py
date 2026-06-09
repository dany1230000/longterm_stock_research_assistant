from __future__ import annotations

import json
import argparse
from pathlib import Path
import sys


ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from backend.app.config import settings  # noqa: E402
from backend.app.data_backup import backup_00631l_data  # noqa: E402


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Back up local 00631L data and rotate old archives.",
    )
    parser.add_argument(
        "--retention-count",
        type=int,
        default=settings.backup_retention_count,
    )
    args = parser.parse_args()

    payload = backup_00631l_data(
        holdings_history_path=settings.holdings_history_path,
        intraday_history_path=settings.intraday_nav_history_path,
        daily_cycle_status_path=settings.daily_cycle_status_path,
        export_dir=settings.history_export_dir,
        backup_dir=settings.backup_dir,
        retention_count=args.retention_count,
    )
    print(json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=True))
    print(
        "[summary] "
        f"sourceStatus={payload['sourceStatus']} "
        f"included={payload['includedCount']} "
        f"missing={payload['missingCount']} "
        f"pruned={payload['prunedCount']} "
        f"backup={payload['backupPath']}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
