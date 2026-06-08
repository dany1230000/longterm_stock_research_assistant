from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any
from zipfile import ZIP_DEFLATED, ZipFile


def backup_00631l_data(
    *,
    holdings_history_path: str | Path,
    intraday_history_path: str | Path,
    daily_cycle_status_path: str | Path,
    export_dir: str | Path,
    backup_dir: str | Path,
    backed_up_at: datetime | None = None,
) -> dict[str, Any]:
    timestamp = (backed_up_at or datetime.now(timezone.utc)).astimezone(
        timezone.utc
    ).replace(microsecond=0)
    backup_root = Path(backup_dir)
    backup_root.mkdir(parents=True, exist_ok=True)

    output_path = backup_root / (
        "00631l_local_data_backup_"
        f"{timestamp.strftime('%Y%m%d_%H%M%SZ')}.zip"
    )
    export_root = Path(export_dir)
    candidates = [
        (Path(holdings_history_path), "backend/data/00631l_holdings_history.jsonl"),
        (
            Path(intraday_history_path),
            "backend/data/00631l_intraday_nav_history.jsonl",
        ),
        (
            Path(daily_cycle_status_path),
            "backend/data/00631l_daily_cycle_status.json",
        ),
        (
            export_root / "00631l_history_export_metadata.json",
            "backend/exports/00631l_history_export_metadata.json",
        ),
    ]

    included: list[dict[str, Any]] = []
    missing: list[dict[str, str]] = []
    manifest: dict[str, Any] = {
        "sourceContract": "00631l_local_data_backup",
        "backedUpAt": timestamp.isoformat(),
        "includedFiles": included,
        "missingFiles": missing,
    }

    with ZipFile(output_path, "w", compression=ZIP_DEFLATED) as archive:
        for source_path, archive_name in candidates:
            if source_path.exists() and source_path.is_file():
                archive.write(source_path, archive_name)
                included.append(
                    {
                        "archiveName": archive_name,
                        "sourcePath": str(source_path),
                        "sizeBytes": source_path.stat().st_size,
                    }
                )
            else:
                missing.append(
                    {
                        "archiveName": archive_name,
                        "sourcePath": str(source_path),
                    }
                )
        archive.writestr(
            "backup_manifest.json",
            json.dumps(manifest, ensure_ascii=False, indent=2, sort_keys=True),
        )

    source_status = "cached" if included else "unavailable"
    return {
        "sourceStatus": source_status,
        "sourceContract": "00631l_local_data_backup",
        "backupPath": str(output_path),
        "backupDir": str(backup_root),
        "backedUpAt": timestamp.isoformat(),
        "includedCount": len(included),
        "missingCount": len(missing),
        "includedFiles": included,
        "missingFiles": missing,
        "errorMessage": None
        if included
        else "No local 00631L data files were found to back up.",
    }
