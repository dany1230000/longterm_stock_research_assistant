import json
import tempfile
import unittest
from pathlib import Path

from backend.app.etf_price_history import EtfPriceHistoryStore
from backend.scripts.restore_public_etf_price_history import (
    compact_restore_response,
    restore_public_etf_price_history,
)


class PublicEtfHistoryRestoreTests(unittest.TestCase):
    def test_restore_public_history_writes_local_price_rows(self) -> None:
        index_payload = {
            "sourceContract": "twse_multi_etf_static_price_history_index",
            "readyCount": 1,
            "missingCount": 1,
            "items": [
                {
                    "code": "0050",
                    "rowCount": 2,
                    "validationFailureCount": 0,
                },
                {
                    "code": "00999",
                    "rowCount": 0,
                    "validationFailureCount": 0,
                },
            ],
        }
        history_payload = {
            "sourceStatus": "static_official",
            "sourceContract": "twse_multi_etf_static_price_history",
            "items": [
                {
                    "code": "0050",
                    "date": "2026-06-25",
                    "open": 50,
                    "high": 51,
                    "low": 49,
                    "close": 50.5,
                    "volume": 1000,
                    "sourceStatus": "official",
                    "sourceContract": "twse_stock_day_json",
                    "sourceUrl": "https://example.test/0050",
                },
                {
                    "code": "0050",
                    "date": "2026-06-26",
                    "open": 51,
                    "high": 52,
                    "low": 50,
                    "close": 51.5,
                    "volume": 1200,
                    "sourceStatus": "official",
                    "sourceContract": "tpex_etf_historical_daily_json",
                    "sourceUrl": "https://example.test/0050",
                },
            ],
        }

        def fetcher(url: str, _timeout: float) -> str:
            if url.endswith("etf_price_history_index.json"):
                return json.dumps(index_payload)
            if url.endswith("etf_price_history/0050.json"):
                return json.dumps(history_payload)
            raise OSError(f"unexpected URL: {url}")

        with tempfile.TemporaryDirectory() as temp_dir:
            result = restore_public_etf_price_history(
                base_url="https://example.test/static",
                output_dir=temp_dir,
                timeout_seconds=1,
                fetcher=fetcher,
            )
            store = EtfPriceHistoryStore(Path(temp_dir))
            records = store.all("0050")
            status = store.status("0050", fetched_at="2026-06-29T00:00:00+00:00")

        self.assertEqual(result["overallStatus"], "PASS")
        self.assertEqual(result["restoredCount"], 1)
        self.assertEqual(result["savedRowCount"], 2)
        self.assertEqual([record["date"] for record in records], ["2026-06-25", "2026-06-26"])
        self.assertEqual(
            status["historySourceContractCounts"],
            {
                "tpex_etf_historical_daily_json": 1,
                "twse_stock_day_json": 1,
            },
        )

    def test_restore_public_history_warns_when_public_index_is_unavailable(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            result = restore_public_etf_price_history(
                base_url="https://example.test/static",
                output_dir=temp_dir,
                timeout_seconds=1,
                fetcher=lambda _url, _timeout: (_ for _ in ()).throw(
                    OSError("offline"),
                ),
            )

        self.assertEqual(result["overallStatus"], "WARN")
        self.assertEqual(result["restoredCount"], 0)
        self.assertEqual(compact_restore_response(result)["failureCount"], 0)

    def test_restore_public_history_skips_missing_price_file_without_failure(self) -> None:
        index_payload = {
            "readyCount": 2,
            "items": [
                {"code": "0050", "rowCount": 2, "validationFailureCount": 0},
                {"code": "0056", "rowCount": 2, "validationFailureCount": 0},
            ],
        }
        history_payload = {
            "items": [
                {"code": "0050", "date": "2026-06-25", "close": 50.5},
                {"code": "0050", "date": "2026-06-26", "close": 51.5},
            ],
        }

        def fetcher(url: str, _timeout: float) -> str:
            if url.endswith("etf_price_history_index.json"):
                return json.dumps(index_payload)
            if url.endswith("etf_price_history/0050.json"):
                return json.dumps(history_payload)
            raise OSError("not found")

        with tempfile.TemporaryDirectory() as temp_dir:
            result = restore_public_etf_price_history(
                base_url="https://example.test/static",
                output_dir=temp_dir,
                timeout_seconds=1,
                fetcher=fetcher,
            )

        self.assertEqual(result["overallStatus"], "WARN")
        self.assertEqual(result["restoredCount"], 1)
        self.assertEqual(result["skippedCount"], 1)
        self.assertEqual(result["failures"], [])


if __name__ == "__main__":
    unittest.main()
