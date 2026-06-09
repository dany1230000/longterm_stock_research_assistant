import json
from pathlib import Path
import tempfile
import unittest
from zipfile import ZipFile

from backend.app.data_backup import backup_00631l_data
from backend.app.restore_dry_run import restore_00631l_dry_run


class RestoreDryRunTests(unittest.TestCase):
    def test_restore_dry_run_reads_backup_without_modifying_sources(self) -> None:
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
            output = data_dir / "restore_status.json"
            holdings.write_text('{"tradeDate":"2026-06-08"}\n', encoding="utf-8")
            intraday.write_text('{"dataTime":"2026-06-08T13:31:00+08:00"}\n', encoding="utf-8")
            status.write_text('{"overallStatus":"PASS"}', encoding="utf-8")
            metadata.write_text('{"totalRowCount":2}', encoding="utf-8")

            backup = backup_00631l_data(
                holdings_history_path=holdings,
                intraday_history_path=intraday,
                daily_cycle_status_path=status,
                export_dir=exports_dir,
                backup_dir=backup_dir,
            )

            before = holdings.read_text(encoding="utf-8")
            payload = restore_00631l_dry_run(
                backup_dir=backup_dir,
                backup_path=backup["backupPath"],
                output_path=output,
            )

            self.assertEqual(payload["overallStatus"], "PASS")
            self.assertEqual(payload["sourceStatus"], "cached")
            self.assertEqual(payload["entriesChecked"], 4)
            self.assertEqual(payload["failureCount"], 0)
            self.assertTrue(output.exists())
            self.assertEqual(holdings.read_text(encoding="utf-8"), before)
            saved = json.loads(output.read_text(encoding="utf-8"))
            self.assertEqual(saved["sourceContract"], "00631l_restore_dry_run")

    def test_restore_dry_run_warns_when_no_backup_exists(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            payload = restore_00631l_dry_run(backup_dir=Path(temp_dir) / "backups")

            self.assertEqual(payload["overallStatus"], "WARN")
            self.assertEqual(payload["sourceStatus"], "unavailable")
            self.assertEqual(payload["warningCount"], 1)
            self.assertEqual(payload["failureCount"], 0)

    def test_restore_dry_run_fails_when_manifest_missing(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            backup_dir = Path(temp_dir) / "backups"
            backup_dir.mkdir()
            backup_path = backup_dir / "00631l_local_data_backup_20260608_100000Z.zip"
            with ZipFile(backup_path, "w") as archive:
                archive.writestr("backend/data/00631l_holdings_history.jsonl", "{}\n")

            payload = restore_00631l_dry_run(
                backup_dir=backup_dir,
                backup_path=backup_path,
            )

            self.assertEqual(payload["overallStatus"], "FAIL")
            self.assertEqual(payload["sourceStatus"], "error")
            self.assertIn("backup_manifest.json is missing.", payload["failures"])


if __name__ == "__main__":
    unittest.main()
