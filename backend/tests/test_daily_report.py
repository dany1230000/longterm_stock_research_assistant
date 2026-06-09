import json
from pathlib import Path
import tempfile
import unittest

from backend.app.daily_report import generate_00631l_daily_report, report_status


class DailyReportTests(unittest.TestCase):
    def test_generate_daily_report_writes_markdown_and_metadata(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            data = root / "data"
            reports = root / "reports"
            data.mkdir()
            holdings_path = data / "holdings.jsonl"
            intraday_path = data / "intraday.jsonl"
            status_path = data / "daily_status.json"

            holdings_path.write_text(
                json.dumps(
                    {
                        "tradeDate": "2026-06-08",
                        "sourceStatus": "official",
                        "navPerUnit": 35.12,
                        "fundNetAssetValue": 1000000,
                        "outstandingUnits": 2000,
                        "stockHoldings": [{"code": "2330", "weightPct": 37.5}],
                        "futuresHoldings": [{"code": "TX", "weightPct": 160.2}],
                    }
                )
                + "\n",
                encoding="utf-8",
            )
            intraday_path.write_text(
                json.dumps(
                    {
                        "dataTime": "2026-06-08T13:31:00+08:00",
                        "sourceStatus": "official",
                        "sourceContract": "twse_a_k_json",
                        "marketPrice": 120.5,
                        "estimatedNav": 120.1,
                        "premiumDiscountPct": 0.33,
                    }
                )
                + "\n",
                encoding="utf-8",
            )
            status_path.write_text("{}", encoding="utf-8")
            cycle_status = {
                "overallStatus": "WARN",
                "startedAt": "2026-06-08T10:00:00+00:00",
                "finishedAt": "2026-06-08T10:05:00+00:00",
                "collect": {"status": "WARN"},
                "export": {"status": "PASS"},
                "smoke": {"status": "WARN"},
                "warnings": ["collect returned WARN", "smoke returned WARN"],
                "failures": [],
            }

            payload = generate_00631l_daily_report(
                holdings_history_path=holdings_path,
                intraday_history_path=intraday_path,
                daily_cycle_status_path=status_path,
                report_dir=reports,
                daily_cycle_status=cycle_status,
            )

            self.assertEqual(payload["sourceStatus"], "cached")
            self.assertEqual(payload["overallStatus"], "WARN")
            self.assertEqual(payload["warningCount"], 2)
            report_path = Path(payload["reportPath"])
            self.assertTrue(report_path.exists())
            body = report_path.read_text(encoding="utf-8")
            self.assertIn("# 00631L daily report", body)
            self.assertIn("tradeDate: 2026-06-08", body)
            self.assertIn("premiumDiscountPct: 0.33", body)
            self.assertIn("collect returned WARN", body)
            latest = report_status(reports)
            self.assertEqual(latest["reportPath"], str(report_path))

    def test_report_status_handles_missing_report(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            payload = report_status(Path(temp_dir) / "reports")

            self.assertEqual(payload["sourceStatus"], "unavailable")
            self.assertEqual(payload["overallStatus"], "missing")
            self.assertTrue(payload["isStale"])


if __name__ == "__main__":
    unittest.main()
