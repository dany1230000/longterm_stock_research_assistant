import unittest

from backend.app.collector import collect_00631l_snapshot


class CollectorTests(unittest.TestCase):
    def test_collects_profile_holdings_intraday_and_history_summaries(self) -> None:
        service = _FakeCollectorService()
        sleeps: list[float] = []

        payload = collect_00631l_snapshot(
            service,
            intraday_samples=2,
            interval_seconds=3,
            sleep_fn=sleeps.append,
        )

        self.assertEqual(payload["overallStatus"], "PASS")
        self.assertEqual(payload["failures"], [])
        self.assertEqual(payload["warnings"], [])
        self.assertEqual(service.profile_calls, 1)
        self.assertEqual(service.holdings_calls, 1)
        self.assertEqual(service.intraday_calls, 2)
        self.assertEqual(sleeps, [3])
        self.assertEqual(payload["holdings"]["tradeDate"], "2026-06-08")
        self.assertEqual(payload["holdingsHistorySummary"]["latestKey"], "2026-06-08")
        self.assertEqual(payload["intradayHistorySummary"]["sampleCount"], 2)

    def test_intraday_unavailable_is_warning_not_collection_failure(self) -> None:
        service = _FakeCollectorService(intraday_status="unavailable")

        payload = collect_00631l_snapshot(service)

        self.assertEqual(payload["overallStatus"], "WARN")
        self.assertEqual(payload["failures"], [])
        self.assertEqual(len(payload["warnings"]), 1)
        self.assertIn("intraday sample 1 sourceStatus=unavailable", payload["warnings"][0])

    def test_holdings_error_is_failure(self) -> None:
        service = _FakeCollectorService(holdings_status="error")

        payload = collect_00631l_snapshot(service)

        self.assertEqual(payload["overallStatus"], "FAIL")
        self.assertEqual(len(payload["failures"]), 1)
        self.assertIn("holdings sourceStatus=error", payload["failures"][0])


class _FakeCollectorService:
    def __init__(
        self,
        *,
        profile_status: str = "official",
        holdings_status: str = "official",
        intraday_status: str = "official",
    ) -> None:
        self.profile_status = profile_status
        self.holdings_status = holdings_status
        self.intraday_status = intraday_status
        self.profile_calls = 0
        self.holdings_calls = 0
        self.intraday_calls = 0

    def profile(self) -> dict:
        self.profile_calls += 1
        return {
            "sourceStatus": self.profile_status,
            "sourceUrl": "fixture://profile",
            "fetchedAt": "2026-06-08T01:00:00+00:00",
            "sourceUpdatedAt": None,
            "isStale": False,
            "fundName": "00631L",
            "errorMessage": None if self.profile_status == "official" else "profile unavailable",
        }

    def holdings(self) -> dict:
        self.holdings_calls += 1
        return {
            "sourceStatus": self.holdings_status,
            "sourceUrl": "fixture://holdings",
            "fetchedAt": "2026-06-08T01:01:00+00:00",
            "sourceUpdatedAt": "2026-06-08T00:00:00+00:00",
            "dataTime": "2026-06-08T00:00:00+00:00",
            "isStale": False,
            "tradeDate": "2026-06-08",
            "sourceHash": "hash",
            "fundNetAssetValue": 1000.0,
            "navPerUnit": 33.35,
            "outstandingUnits": 100,
            "stockHoldings": [{"code": "2330"}],
            "futuresHoldings": [{"code": "TX"}],
            "cashHoldings": [{"name": "保證金"}],
            "errorMessage": None if self.holdings_status == "official" else "holdings failed",
        }

    def holdings_history_summary(self, *, limit: int) -> dict:
        return {
            "items": [{"tradeDate": "2026-06-08"}],
            "sourceStatus": "cached",
            "sourceContract": "local_jsonl_history_summary",
            "sourceUrl": "local://00631l-holdings-history",
            "fetchedAt": "2026-06-08T01:02:00+00:00",
            "sourceUpdatedAt": "2026-06-08T00:00:00+00:00",
            "dataTime": "2026-06-08T00:00:00+00:00",
            "isStale": False,
            "errorMessage": None,
        }

    def intraday_nav(self) -> dict:
        self.intraday_calls += 1
        data_time = f"2026-06-08T09:0{self.intraday_calls}:00+08:00"
        return {
            "sourceStatus": self.intraday_status,
            "sourceContract": "twse_a_k_json" if self.intraday_status == "official" else None,
            "sourceUrl": "fixture://twse/all_etf",
            "fetchedAt": "2026-06-08T01:03:00+00:00",
            "sourceUpdatedAt": data_time,
            "dataDate": "2026-06-08",
            "dataTime": data_time,
            "isStale": False,
            "marketPrice": 33.8,
            "estimatedNav": 33.55,
            "premiumDiscountPct": 0.75,
            "errorMessage": None if self.intraday_status == "official" else "intraday unavailable",
        }

    def intraday_nav_history_summary(self, *, date: str | None) -> dict:
        return {
            "items": [{"dataTime": "2026-06-08T09:02:00+08:00"}],
            "sourceStatus": "cached",
            "sourceContract": "local_jsonl_intraday_nav_history_summary",
            "sourceUrl": "local://00631l-intraday-nav-history",
            "fetchedAt": "2026-06-08T01:04:00+00:00",
            "sourceUpdatedAt": "2026-06-08T09:02:00+08:00",
            "dataTime": "2026-06-08T09:02:00+08:00",
            "isStale": False,
            "errorMessage": None,
            "sampleCount": self.intraday_calls,
            "highestPremiumDiscountPct": 0.75,
            "lowestPremiumDiscountPct": 0.75,
            "averagePremiumDiscountPct": 0.75,
            "firstDataTime": "2026-06-08T09:01:00+08:00",
            "lastDataTime": "2026-06-08T09:02:00+08:00",
            "date": date,
        }


if __name__ == "__main__":
    unittest.main()
