import json
from pathlib import Path
import tempfile
import unittest

from backend.app.data_integrity import check_00631l_data_integrity, integrity_status


class DataIntegrityTests(unittest.TestCase):
    def test_integrity_passes_for_valid_local_history(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            holdings = root / "holdings.jsonl"
            intraday = root / "intraday.jsonl"
            output = root / "integrity.json"
            holdings.write_text(
                "\n".join(
                    [
                        json.dumps(_holding("2026-06-05")),
                        json.dumps(_holding("2026-06-08")),
                    ]
                )
                + "\n",
                encoding="utf-8",
            )
            intraday.write_text(
                json.dumps(_intraday("2026-06-08T13:31:00+08:00")) + "\n",
                encoding="utf-8",
            )

            payload = check_00631l_data_integrity(
                holdings_history_path=holdings,
                intraday_history_path=intraday,
                output_path=output,
            )

            self.assertEqual(payload["overallStatus"], "PASS")
            self.assertEqual(payload["failureCount"], 0)
            self.assertTrue(output.exists())
            self.assertEqual(integrity_status(output)["overallStatus"], "PASS")

    def test_integrity_detects_duplicates_missing_fields_and_abnormal_source(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            holdings = root / "holdings.jsonl"
            intraday = root / "intraday.jsonl"
            bad_holding = _holding("2026-06-08")
            bad_holding.pop("navPerUnit")
            bad_holding["sourceStatus"] = "cached"
            holdings.write_text(
                "\n".join(
                    [
                        json.dumps(bad_holding),
                        json.dumps(_holding("2026-06-08")),
                    ]
                )
                + "\n",
                encoding="utf-8",
            )
            bad_intraday = _intraday("2026-06-08T13:31:00+08:00")
            bad_intraday.pop("estimatedNav")
            intraday.write_text(json.dumps(bad_intraday) + "\n", encoding="utf-8")

            payload = check_00631l_data_integrity(
                holdings_history_path=holdings,
                intraday_history_path=intraday,
            )

            self.assertEqual(payload["overallStatus"], "FAIL")
            self.assertGreaterEqual(payload["failureCount"], 2)
            self.assertTrue(payload["warnings"])
            self.assertIn("2026-06-08", payload["holdings"]["duplicateTradeDates"])

    def test_integrity_allows_null_intraday_premium_discount(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            holdings = root / "holdings.jsonl"
            intraday = root / "intraday.jsonl"
            holdings.write_text(json.dumps(_holding("2026-06-08")) + "\n", encoding="utf-8")
            intraday_record = _intraday("2026-06-09T10:38:00+08:00")
            intraday_record["premiumDiscountPct"] = None
            intraday.write_text(json.dumps(intraday_record) + "\n", encoding="utf-8")

            payload = check_00631l_data_integrity(
                holdings_history_path=holdings,
                intraday_history_path=intraday,
            )

            self.assertEqual(payload["overallStatus"], "PASS")
            self.assertEqual(payload["intraday"]["missingRequiredFields"], [])


def _holding(trade_date: str) -> dict[str, object]:
    return {
        "tradeDate": trade_date,
        "fundNetAssetValue": 1000,
        "navPerUnit": 10,
        "outstandingUnits": 100,
        "assetValues": {"stock": 100, "futures": 160},
        "stockHoldings": [{"code": "2330", "weightPct": 37.5}],
        "futuresHoldings": [{"code": "TX", "weightPct": 160.2}],
        "cashHoldings": [{"item": "cash", "amount": 100}],
        "sourceStatus": "official",
        "sourceUrl": "fixture://holdings",
        "fetchedAt": "2026-06-08T10:00:00+00:00",
        "sourceHash": trade_date,
    }


def _intraday(data_time: str) -> dict[str, object]:
    return {
        "dataDate": data_time[:10],
        "dataTime": data_time,
        "marketPrice": 33.8,
        "estimatedNav": 33.55,
        "premiumDiscountPct": 0.75,
        "sourceContract": "twse_a_k_json",
        "sourceStatus": "official",
        "sourceUrl": "fixture://twse/all_etf",
        "fetchedAt": "2026-06-08T10:00:00+00:00",
    }


if __name__ == "__main__":
    unittest.main()
