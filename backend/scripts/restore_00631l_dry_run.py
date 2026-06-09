from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys


ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from backend.app.config import settings  # noqa: E402
from backend.app.restore_dry_run import restore_00631l_dry_run  # noqa: E402


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Validate that a local 00631L backup archive can be read without restoring it.",
    )
    parser.add_argument("--backup-path", default=None)
    parser.add_argument("--backup-dir", default=settings.backup_dir)
    parser.add_argument("--output-path", default=settings.restore_dry_run_status_path)
    args = parser.parse_args()

    payload = restore_00631l_dry_run(
        backup_dir=args.backup_dir,
        backup_path=args.backup_path,
        output_path=args.output_path,
    )
    print(json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=True))
    print(
        "[summary] "
        f"overallStatus={payload['overallStatus']} "
        f"sourceStatus={payload['sourceStatus']} "
        f"entriesChecked={payload['entriesChecked']} "
        f"entriesVerified={payload['checksum']['entriesVerified']} "
        f"warnings={payload['warningCount']} "
        f"failures={payload['failureCount']} "
        f"backup={payload['backupPath']}"
    )
    return 1 if payload["overallStatus"] == "FAIL" else 0


if __name__ == "__main__":
    raise SystemExit(main())
