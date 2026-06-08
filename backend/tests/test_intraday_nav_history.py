from pathlib import Path
import tempfile
import unittest

from backend.app.intraday_nav_history import IntradayNavHistoryStore
from backend.app.parsers import parse_intraday_nav


FIXTURES = Path(__file__).parent / "fixtures"


class IntradayNavHistoryStoreTests(unittest.TestCase):
    def test_save_official_intraday_nav_deduplicates_by_contract_and_time(self) -> None:
        source = (FIXTURES / "00631l_twse_all_etf_fixture.json").read_text(encoding="utf-8")
        nav = parse_intraday_nav(
            source,
            source_url="fixture://twse/all_etf",
            fetched_at="2026-06-08T10:15:00+00:00",
        )

        with tempfile.TemporaryDirectory() as temp_dir:
            store = IntradayNavHistoryStore(Path(temp_dir) / "intraday.jsonl")

            self.assertTrue(store.save_official_nav(nav))
            self.assertFalse(store.save_official_nav(nav))
            self.assertEqual(len(store.records_for_date(date="2026-06-08", limit=500)), 1)

    def test_intraday_nav_summary_calculates_daily_stats(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            store = IntradayNavHistoryStore(Path(temp_dir) / "intraday.jsonl")
            store.save_official_nav(_nav("2026-06-08T09:01:00+08:00", 0.20))
            store.save_official_nav(_nav("2026-06-08T09:02:00+08:00", -0.30))
            store.save_official_nav(_nav("2026-06-08T09:03:00+08:00", 0.70))

            payload = store.summary_response(
                date="2026-06-08",
                fetched_at="2026-06-08T10:15:00+00:00",
            )

            self.assertEqual(payload["sourceStatus"], "cached")
            self.assertEqual(payload["sampleCount"], 3)
            self.assertEqual(payload["highestPremiumDiscountPct"], 0.70)
            self.assertEqual(payload["lowestPremiumDiscountPct"], -0.30)
            self.assertAlmostEqual(payload["averagePremiumDiscountPct"], 0.20)
            self.assertEqual(payload["firstDataTime"], "2026-06-08T09:01:00+08:00")
            self.assertEqual(payload["lastDataTime"], "2026-06-08T09:03:00+08:00")


def _nav(data_time: str, premium: float) -> dict:
    return {
        "code": "00631L",
        "symbol": "00631L",
        "name": "00631L",
        "marketPrice": 33.8,
        "estimatedNav": 33.55,
        "premiumDiscountPct": premium,
        "estimatedPremiumDiscountPct": premium,
        "dataDate": "2026-06-08",
        "dataTime": data_time,
        "sourceStatus": "official",
        "sourceContract": "twse_a_k_json",
        "sourceUrl": "fixture://twse/all_etf",
        "fetchedAt": "2026-06-08T10:15:00+00:00",
        "sourceUpdatedAt": data_time,
        "isStale": False,
        "errorMessage": None,
    }


if __name__ == "__main__":
    unittest.main()
