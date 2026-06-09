import os
from datetime import datetime, timedelta, timezone
from pathlib import Path
import tempfile
import unittest

from backend.app.retention_policy import apply_00631l_retention_policy


class RetentionPolicyTests(unittest.TestCase):
    def test_retention_prunes_old_reports_only(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            data_dir = root / "data"
            report_dir = root / "reports"
            export_dir = root / "exports"
            data_dir.mkdir()
            report_dir.mkdir()
            export_dir.mkdir()
            holdings = data_dir / "holdings.jsonl"
            intraday = data_dir / "intraday.jsonl"
            holdings.write_text('{"tradeDate":"2026-06-08"}\n', encoding="utf-8")
            intraday.write_text(
                '{"dataTime":"2026-06-09T10:00:00+08:00"}\n',
                encoding="utf-8",
            )
            metadata = export_dir / "00631l_history_export_metadata.json"
            metadata.write_text('{"totalRowCount":2}', encoding="utf-8")
            (report_dir / "00631l_daily_report_latest.json").write_text(
                "{}", encoding="utf-8"
            )
            base = datetime(2026, 6, 9, tzinfo=timezone.utc)
            for index in range(4):
                report = report_dir / f"00631l_daily_report_20260609T100{index}00Z.md"
                report.write_text(f"report {index}", encoding="utf-8")
                mtime = (base + timedelta(minutes=index)).timestamp()
                os.utime(report, (mtime, mtime))
            keep = report_dir / "manual_note.md"
            keep.write_text("keep", encoding="utf-8")

            payload = apply_00631l_retention_policy(
                holdings_history_path=holdings,
                intraday_history_path=intraday,
                report_dir=report_dir,
                export_dir=export_dir,
                report_retention_count=2,
            )

            self.assertEqual(payload["overallStatus"], "PASS")
            self.assertEqual(payload["reportPolicy"]["totalReportCount"], 4)
            self.assertEqual(payload["reportPolicy"]["candidatePrunedCount"], 2)
            self.assertEqual(payload["reportPolicy"]["prunedCount"], 2)
            self.assertTrue(holdings.exists())
            self.assertTrue(intraday.exists())
            self.assertTrue(metadata.exists())
            self.assertTrue((report_dir / "00631l_daily_report_latest.json").exists())
            self.assertTrue(keep.exists())
            self.assertEqual(len(list(report_dir.glob("00631l_daily_report_*.md"))), 2)

    def test_retention_dry_run_does_not_prune(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            data_dir = root / "data"
            report_dir = root / "reports"
            export_dir = root / "exports"
            data_dir.mkdir()
            report_dir.mkdir()
            export_dir.mkdir()
            holdings = data_dir / "holdings.jsonl"
            intraday = data_dir / "intraday.jsonl"
            holdings.write_text("{}\n", encoding="utf-8")
            intraday.write_text("{}\n", encoding="utf-8")
            for index in range(3):
                (report_dir / f"00631l_daily_report_20260609T100{index}00Z.md").write_text(
                    "report", encoding="utf-8"
                )

            payload = apply_00631l_retention_policy(
                holdings_history_path=holdings,
                intraday_history_path=intraday,
                report_dir=report_dir,
                export_dir=export_dir,
                report_retention_count=1,
                dry_run=True,
            )

            self.assertTrue(payload["dryRun"])
            self.assertEqual(payload["reportPolicy"]["candidatePrunedCount"], 2)
            self.assertEqual(payload["reportPolicy"]["prunedCount"], 0)
            self.assertEqual(len(list(report_dir.glob("00631l_daily_report_*.md"))), 3)


if __name__ == "__main__":
    unittest.main()
