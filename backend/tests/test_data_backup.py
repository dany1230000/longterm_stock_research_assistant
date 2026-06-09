import json
import os
from pathlib import Path
import tempfile
import unittest
from datetime import datetime, timezone, timedelta
from zipfile import ZipFile

from backend.app.data_backup import backup_00631l_data


class DataBackupTests(unittest.TestCase):
    def test_backup_includes_local_data_without_modifying_sources(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            data_dir = root / "data"
            exports_dir = root / "exports"
            backup_dir = root / "backups"
            data_dir.mkdir()
            exports_dir.mkdir()

            holdings = data_dir / "holdings.jsonl"
            intraday = data_dir / "intraday.jsonl"
            status = data_dir / "daily_status.json"
            metadata = exports_dir / "00631l_history_export_metadata.json"
            holdings.write_text('{"tradeDate":"2026-06-08"}\n', encoding="utf-8")
            intraday.write_text('{"dataTime":"2026-06-08T13:31:00+08:00"}\n', encoding="utf-8")
            status.write_text('{"overallStatus":"PASS"}', encoding="utf-8")
            metadata.write_text('{"totalRowCount":2}', encoding="utf-8")

            before = {
                path: path.read_text(encoding="utf-8")
                for path in (holdings, intraday, status, metadata)
            }

            payload = backup_00631l_data(
                holdings_history_path=holdings,
                intraday_history_path=intraday,
                daily_cycle_status_path=status,
                export_dir=exports_dir,
                backup_dir=backup_dir,
            )

            self.assertEqual(payload["sourceStatus"], "cached")
            self.assertEqual(payload["includedCount"], 4)
            self.assertEqual(payload["prunedCount"], 0)
            self.assertRegex(payload["backupSha256"], r"^[0-9a-f]{64}$")
            backup_path = Path(payload["backupPath"])
            self.assertTrue(backup_path.exists())

            with ZipFile(backup_path) as archive:
                names = set(archive.namelist())
                self.assertIn("backend/data/00631l_holdings_history.jsonl", names)
                self.assertIn("backend/data/00631l_intraday_nav_history.jsonl", names)
                self.assertIn("backend/data/00631l_daily_cycle_status.json", names)
                self.assertIn("backend/exports/00631l_history_export_metadata.json", names)
                manifest = json.loads(
                    archive.read("backup_manifest.json").decode("utf-8")
                )
                self.assertEqual(manifest["sourceContract"], "00631l_local_data_backup")
                self.assertEqual(len(manifest["includedFiles"]), 4)
                for item in manifest["includedFiles"]:
                    self.assertRegex(item["sha256"], r"^[0-9a-f]{64}$")

            after = {
                path: path.read_text(encoding="utf-8")
                for path in (holdings, intraday, status, metadata)
            }
            self.assertEqual(before, after)

    def test_backup_handles_missing_local_data(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            payload = backup_00631l_data(
                holdings_history_path=root / "missing_holdings.jsonl",
                intraday_history_path=root / "missing_intraday.jsonl",
                daily_cycle_status_path=root / "missing_status.json",
                export_dir=root / "missing_exports",
                backup_dir=root / "backups",
            )

            self.assertEqual(payload["sourceStatus"], "unavailable")
            self.assertEqual(payload["includedCount"], 0)
            self.assertEqual(payload["missingCount"], 4)
            self.assertTrue(Path(payload["backupPath"]).exists())

    def test_backup_rotation_keeps_latest_archives_only(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            data_dir = root / "data"
            exports_dir = root / "exports"
            backup_dir = root / "backups"
            data_dir.mkdir()
            exports_dir.mkdir()
            backup_dir.mkdir()
            holdings = data_dir / "holdings.jsonl"
            intraday = data_dir / "intraday.jsonl"
            status = data_dir / "daily_status.json"
            holdings.write_text('{"tradeDate":"2026-06-08"}\n', encoding="utf-8")
            intraday.write_text(
                '{"dataTime":"2026-06-08T13:31:00+08:00"}\n',
                encoding="utf-8",
            )
            status.write_text('{"overallStatus":"PASS"}', encoding="utf-8")
            (backup_dir / "manual_note.txt").write_text("keep", encoding="utf-8")

            base = datetime(2026, 6, 8, tzinfo=timezone.utc)
            for index in range(3):
                path = backup_dir / f"00631l_local_data_backup_20260608_00000{index}Z.zip"
                path.write_bytes(b"old")
                mtime = (base + timedelta(minutes=index)).timestamp()
                os.utime(path, (mtime, mtime))

            payload = backup_00631l_data(
                holdings_history_path=holdings,
                intraday_history_path=intraday,
                daily_cycle_status_path=status,
                export_dir=exports_dir,
                backup_dir=backup_dir,
                backed_up_at=base + timedelta(minutes=5),
                retention_count=2,
            )

            self.assertEqual(payload["retentionCount"], 2)
            self.assertEqual(payload["prunedCount"], 2)
            remaining = sorted(backup_dir.glob("00631l_local_data_backup_*.zip"))
            self.assertEqual(len(remaining), 2)
            self.assertTrue((backup_dir / "manual_note.txt").exists())


if __name__ == "__main__":
    unittest.main()
