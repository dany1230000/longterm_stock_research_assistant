import json
import tempfile
import unittest
from pathlib import Path

from backend.app.price_history import PriceHistoryStore
from backend.scripts.restore_public_00631l_price_history import (
    compact_restore_response,
    restore_public_00631l_price_history,
)


class Public00631LHistoryRestoreTests(unittest.TestCase):
    def test_restore_public_history_writes_newer_primary_rows(self) -> None:
        public_payload = {
            "sourceStatus": "static_official",
            "sourceContract": "00631l_static_price_history",
            "coverageEnd": "2026-06-30",
            "rowCount": 3,
            "items": [
                _point("2026-06-26", 100),
                _point("2026-06-29", 101),
                _point("2026-06-30", 102),
            ],
        }

        with tempfile.TemporaryDirectory() as temp_dir:
            path = Path(temp_dir) / "00631l_price_history.jsonl"
            store = PriceHistoryStore(path)
            store.save_points([_point("2026-06-26", 100)])

            result = restore_public_00631l_price_history(
                base_url="https://example.test/static",
                output_path=path,
                timeout_seconds=1,
                fetcher=lambda _url, _timeout: json.dumps(public_payload),
            )
            records = store.all()

        self.assertEqual(result["overallStatus"], "PASS")
        self.assertTrue(result["restoreNeeded"])
        self.assertEqual(result["savedRowCount"], 2)
        self.assertEqual([record["date"] for record in records], [
            "2026-06-26",
            "2026-06-29",
            "2026-06-30",
        ])

    def test_restore_public_history_warns_when_local_is_current(self) -> None:
        public_payload = {
            "coverageEnd": "2026-06-30",
            "rowCount": 2,
            "items": [_point("2026-06-29", 101), _point("2026-06-30", 102)],
        }

        with tempfile.TemporaryDirectory() as temp_dir:
            path = Path(temp_dir) / "00631l_price_history.jsonl"
            store = PriceHistoryStore(path)
            store.save_points(public_payload["items"])

            result = restore_public_00631l_price_history(
                base_url="https://example.test/static",
                output_path=path,
                timeout_seconds=1,
                fetcher=lambda _url, _timeout: json.dumps(public_payload),
            )

        self.assertEqual(result["overallStatus"], "WARN")
        self.assertFalse(result["restoreNeeded"])
        self.assertEqual(result["savedRowCount"], 0)
        self.assertEqual(compact_restore_response(result)["failureCount"], 0)

    def test_restore_public_history_warns_when_public_unavailable(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            result = restore_public_00631l_price_history(
                base_url="https://example.test/static",
                output_path=Path(temp_dir) / "00631l_price_history.jsonl",
                timeout_seconds=1,
                fetcher=lambda _url, _timeout: (_ for _ in ()).throw(
                    OSError("offline"),
                ),
            )

        self.assertEqual(result["overallStatus"], "WARN")
        self.assertEqual(result["failures"], [])

    def test_restore_public_history_fails_for_invalid_payload(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            result = restore_public_00631l_price_history(
                base_url="https://example.test/static",
                output_path=Path(temp_dir) / "00631l_price_history.jsonl",
                timeout_seconds=1,
                fetcher=lambda _url, _timeout: json.dumps({"items": []}),
            )

        self.assertEqual(result["overallStatus"], "FAIL")
        self.assertTrue(result["failures"])


def _point(day: str, close: float) -> dict[str, object]:
    return {
        "date": day,
        "open": close,
        "high": close,
        "low": close,
        "close": close,
        "volume": 1000,
        "sourceStatus": "official",
        "sourceContract": "twse_stock_day_json",
        "sourceUrl": "https://example.test/stock-day",
    }


if __name__ == "__main__":
    unittest.main()
