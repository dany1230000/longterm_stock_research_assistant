from __future__ import annotations

import json
import hashlib
from datetime import datetime, timezone
from pathlib import Path
from typing import Any
from zipfile import BadZipFile, ZipFile


MANIFEST_NAME = "backup_manifest.json"
SOURCE_CONTRACT = "00631l_restore_dry_run"


def restore_00631l_dry_run(
    *,
    backup_dir: str | Path,
    backup_path: str | Path | None = None,
    output_path: str | Path | None = None,
    checked_at: datetime | None = None,
) -> dict[str, Any]:
    checked = (checked_at or datetime.now(timezone.utc)).astimezone(
        timezone.utc
    ).replace(microsecond=0)
    backup_root = Path(backup_dir)
    selected_backup = Path(backup_path) if backup_path else _latest_backup(backup_root)

    if selected_backup is None:
        payload = _payload(
            checked_at=checked,
            backup_dir=backup_root,
            backup_path=None,
            source_status="unavailable",
            overall_status="WARN",
            warnings=["No local backup archive was found for restore dry-run."],
            failures=[],
            error_message="No local backup archive was found.",
        )
        _write_output(output_path, payload)
        return payload

    warnings: list[str] = []
    failures: list[str] = []
    entries_checked = 0
    archive_entry_count = 0
    manifest_summary: dict[str, Any] | None = None
    entries_with_sha256 = 0
    entries_verified = 0
    backup_sha256: str | None = None

    try:
        backup_sha256 = _sha256_file(selected_backup)
        with ZipFile(selected_backup) as archive:
            names = set(archive.namelist())
            archive_entry_count = len(names)
            if MANIFEST_NAME not in names:
                failures.append("backup_manifest.json is missing.")
            else:
                manifest = json.loads(archive.read(MANIFEST_NAME).decode("utf-8"))
                if not isinstance(manifest, dict):
                    failures.append("backup_manifest.json is not an object.")
                else:
                    included = _manifest_list(manifest.get("includedFiles"))
                    missing = _manifest_list(manifest.get("missingFiles"))
                    manifest_summary = {
                        "sourceContract": manifest.get("sourceContract"),
                        "backedUpAt": manifest.get("backedUpAt"),
                        "includedCount": len(included),
                        "missingCount": len(missing),
                    }
                    if manifest.get("sourceContract") != "00631l_local_data_backup":
                        warnings.append(
                            "backup_manifest.json sourceContract is not 00631l_local_data_backup."
                        )
                    if not included:
                        warnings.append("Backup manifest has no included data files.")
                    for item in missing:
                        archive_name = str(item.get("archiveName") or "")
                        if archive_name:
                            warnings.append(f"Backup recorded missing source file: {archive_name}")
                    for item in included:
                        archive_name = str(item.get("archiveName") or "")
                        if not archive_name:
                            failures.append("Backup manifest has an included file without archiveName.")
                            continue
                        if archive_name not in names:
                            failures.append(f"Backup archive is missing included entry: {archive_name}")
                            continue
                        data = archive.read(archive_name)
                        entries_checked += 1
                        expected_sha256 = item.get("sha256")
                        if expected_sha256:
                            entries_with_sha256 += 1
                            actual_sha256 = _sha256_bytes(data)
                            if actual_sha256 == expected_sha256:
                                entries_verified += 1
                            else:
                                failures.append(
                                    f"Checksum mismatch for backup entry: {archive_name}"
                                )
                        else:
                            warnings.append(
                                f"Backup entry has no checksum in manifest: {archive_name}"
                            )
    except (OSError, BadZipFile, UnicodeDecodeError, json.JSONDecodeError) as error:
        failures.append(f"Restore dry-run failed to read backup archive: {error}")

    overall_status = "FAIL" if failures else "WARN" if warnings else "PASS"
    source_status = "error" if failures else "cached"
    payload = _payload(
        checked_at=checked,
        backup_dir=backup_root,
        backup_path=selected_backup,
        source_status=source_status,
        overall_status=overall_status,
        warnings=warnings,
        failures=failures,
        error_message="; ".join(failures) if failures else None,
        entries_checked=entries_checked,
        archive_entry_count=archive_entry_count,
        manifest_summary=manifest_summary,
        checksum_summary={
            "backupSha256": backup_sha256,
            "entriesWithSha256": entries_with_sha256,
            "entriesVerified": entries_verified,
        },
    )
    _write_output(output_path, payload)
    return payload


def _latest_backup(backup_root: Path) -> Path | None:
    backups = sorted(
        [
            path
            for path in backup_root.glob("00631l_local_data_backup_*.zip")
            if path.is_file()
        ],
        key=lambda path: (path.stat().st_mtime, path.name),
        reverse=True,
    )
    return backups[0] if backups else None


def _manifest_list(value: Any) -> list[dict[str, Any]]:
    if not isinstance(value, list):
        return []
    return [item for item in value if isinstance(item, dict)]


def _payload(
    *,
    checked_at: datetime,
    backup_dir: Path,
    backup_path: Path | None,
    source_status: str,
    overall_status: str,
    warnings: list[str],
    failures: list[str],
    error_message: str | None,
    entries_checked: int = 0,
    archive_entry_count: int = 0,
    manifest_summary: dict[str, Any] | None = None,
    checksum_summary: dict[str, Any] | None = None,
) -> dict[str, Any]:
    return {
        "sourceStatus": source_status,
        "sourceContract": SOURCE_CONTRACT,
        "checkedAt": checked_at.isoformat(),
        "backupDir": str(backup_dir),
        "backupPath": str(backup_path) if backup_path else None,
        "overallStatus": overall_status,
        "archiveEntryCount": archive_entry_count,
        "entriesChecked": entries_checked,
        "manifest": manifest_summary,
        "checksum": checksum_summary
        or {
            "backupSha256": None,
            "entriesWithSha256": 0,
            "entriesVerified": 0,
        },
        "warnings": warnings,
        "failures": failures,
        "warningCount": len(warnings),
        "failureCount": len(failures),
        "errorMessage": error_message,
    }


def _write_output(output_path: str | Path | None, payload: dict[str, Any]) -> None:
    if output_path is None:
        return
    path = Path(output_path)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=True),
        encoding="utf-8",
    )


def _sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()
