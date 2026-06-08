import unittest
from pathlib import Path
import tempfile

try:
    from fastapi.testclient import TestClient
    import backend.app.main as main_module
    from backend.app.cache import TimedMemoryCache
    from backend.app.config import Settings
    from backend.app.holdings_history import HoldingsHistoryStore
    from backend.app.intraday_nav_history import IntradayNavHistoryStore
    from backend.app.service import Etf00631LService

    HAS_FASTAPI = True
except ModuleNotFoundError:
    HAS_FASTAPI = False
    TestClient = None
    main_module = None


FIXTURES = Path(__file__).parent / "fixtures"


@unittest.skipUnless(HAS_FASTAPI, "FastAPI is not installed in this environment")
class EndpointTests(unittest.TestCase):
    def setUp(self) -> None:
        self._original_service = main_module.service
        self.client = TestClient(main_module.app)

    def tearDown(self) -> None:
        main_module.service = self._original_service

    def test_health(self) -> None:
        response = self.client.get("/health")
        self.assertEqual(response.status_code, 200)
        payload = response.json()
        self.assertEqual(payload["status"], "ok")
        self.assertIn("serverTime", payload)

    def test_intraday_nav_without_config_is_unavailable(self) -> None:
        response = self.client.get("/api/etf/00631l/intraday-nav")
        self.assertEqual(response.status_code, 200)
        payload = response.json()
        self.assertEqual(payload["symbol"], "00631L")
        self.assertIn(payload["sourceStatus"], {"unavailable", "error", "cached"})
        self.assertIn("sourceContract", payload)

    def test_intraday_nav_with_twse_fixture_returns_normalized_payload(self) -> None:
        fixture = (FIXTURES / "00631l_twse_all_etf_fixture.json").read_text(encoding="utf-8")

        def fake_fetcher(url: str, timeout_seconds: float) -> str:
            self.assertEqual(url, "fixture://twse/all_etf")
            return fixture

        main_module.service = Etf00631LService(
            config=Settings(
                twse_intraday_nav_url="fixture://twse/all_etf",
                intraday_nav_source="twse",
            ),
            fetcher=fake_fetcher,
            cache=TimedMemoryCache(),
        )

        response = self.client.get("/api/etf/00631l/intraday-nav")
        self.assertEqual(response.status_code, 200)
        payload = response.json()
        self.assertEqual(payload["symbol"], "00631L")
        self.assertEqual(payload["code"], "00631L")
        self.assertEqual(payload["sourceStatus"], "official")
        self.assertEqual(payload["sourceContract"], "twse_a_k_json")
        self.assertEqual(payload["marketPrice"], 33.8)
        self.assertEqual(payload["estimatedNav"], 33.55)
        self.assertEqual(payload["premiumDiscountPct"], 0.75)

    def test_live_proxy_endpoints_return_consistent_metadata(self) -> None:
        holdings_fixture = (FIXTURES / "00631l_yuanta_ratio_fixture.txt").read_text(encoding="utf-8")
        intraday_fixture = (FIXTURES / "00631l_twse_all_etf_fixture.json").read_text(encoding="utf-8")
        profile_fixture = """
Fund Name
Yuanta Taiwan 50 Daily Bull 2X ETF
Fund Simple Name
Yuanta Taiwan 50 Bull 2X
Benchmark Index
Taiwan 50 Index
Inception Date
2014/10/23
Listing Date
2014/10/31
Dividends
NO
Risk Level
RR5
Management Fee
1.00%
Custodian Fee
0.04%
"""

        def fake_fetcher(url: str, timeout_seconds: float) -> str:
            if url == "fixture://profile":
                return profile_fixture
            if url == "fixture://holdings":
                return holdings_fixture
            if url == "fixture://twse/all_etf":
                return intraday_fixture
            raise AssertionError(f"Unexpected fixture URL: {url}")

        main_module.service = Etf00631LService(
            config=Settings(
                yuanta_profile_url="fixture://profile",
                yuanta_holdings_url="fixture://holdings",
                twse_intraday_nav_url="fixture://twse/all_etf",
                intraday_nav_source="twse",
            ),
            fetcher=fake_fetcher,
            cache=TimedMemoryCache(),
        )

        for path in (
            "/api/etf/00631l/profile",
            "/api/etf/00631l/holdings",
            "/api/etf/00631l/intraday-nav",
        ):
            response = self.client.get(path)
            self.assertEqual(response.status_code, 200)
            payload = response.json()
            for key in (
                "sourceStatus",
                "sourceContract",
                "sourceUrl",
                "fetchedAt",
                "dataTime",
                "sourceUpdatedAt",
                "isStale",
                "errorMessage",
            ):
                self.assertIn(key, payload, msg=f"{path} missing {key}")

    def test_holdings_history_endpoints_return_saved_snapshots(self) -> None:
        holdings_fixture = (FIXTURES / "00631l_yuanta_ratio_fixture.txt").read_text(encoding="utf-8")

        def fake_fetcher(url: str, timeout_seconds: float) -> str:
            self.assertEqual(url, "fixture://holdings")
            return holdings_fixture

        with tempfile.TemporaryDirectory() as temp_dir:
            main_module.service = Etf00631LService(
                config=Settings(yuanta_holdings_url="fixture://holdings"),
                fetcher=fake_fetcher,
                cache=TimedMemoryCache(),
                history_store=HoldingsHistoryStore(Path(temp_dir) / "history.jsonl"),
            )

            holdings_response = self.client.get("/api/etf/00631l/holdings")
            self.assertEqual(holdings_response.status_code, 200)
            self.assertEqual(holdings_response.json()["sourceStatus"], "official")

            history_response = self.client.get("/api/etf/00631l/holdings/history?limit=30")
            self.assertEqual(history_response.status_code, 200)
            history_payload = history_response.json()
            self.assertEqual(history_payload["sourceStatus"], "cached")
            self.assertEqual(len(history_payload["items"]), 1)
            self.assertEqual(history_payload["items"][0]["tradeDate"], "2026-06-05")
            self.assertEqual(history_payload["items"][0]["sourceStatus"], "official")
            self.assertIn("cashBreakdown", history_payload["items"][0])

            summary_response = self.client.get("/api/etf/00631l/holdings/history/summary?limit=30")
            self.assertEqual(summary_response.status_code, 200)
            summary_payload = summary_response.json()
            self.assertEqual(summary_payload["sourceStatus"], "cached")
            summary = summary_payload["items"][0]
            self.assertEqual(summary["tradeDate"], "2026-06-05")
            self.assertEqual(summary["txWeightPct"], 161.53)
            self.assertEqual(summary["tsmcWeightPct"], 37.44)
            self.assertGreater(summary["cashAndMarginPct"], 0)

    def test_intraday_nav_history_endpoints_return_saved_samples(self) -> None:
        intraday_fixture = (FIXTURES / "00631l_twse_all_etf_fixture.json").read_text(encoding="utf-8")

        def fake_fetcher(url: str, timeout_seconds: float) -> str:
            self.assertEqual(url, "fixture://twse/all_etf")
            return intraday_fixture

        with tempfile.TemporaryDirectory() as temp_dir:
            main_module.service = Etf00631LService(
                config=Settings(
                    twse_intraday_nav_url="fixture://twse/all_etf",
                    intraday_nav_source="twse",
                ),
                fetcher=fake_fetcher,
                cache=TimedMemoryCache(),
                intraday_history_store=IntradayNavHistoryStore(
                    Path(temp_dir) / "intraday.jsonl"
                ),
            )

            nav_response = self.client.get("/api/etf/00631l/intraday-nav")
            self.assertEqual(nav_response.status_code, 200)
            self.assertEqual(nav_response.json()["sourceStatus"], "official")

            history_response = self.client.get(
                "/api/etf/00631l/intraday-nav/history?date=2026-06-08"
            )
            self.assertEqual(history_response.status_code, 200)
            history_payload = history_response.json()
            self.assertEqual(history_payload["sourceStatus"], "cached")
            self.assertEqual(len(history_payload["items"]), 1)
            self.assertEqual(history_payload["items"][0]["sourceContract"], "twse_a_k_json")

            summary_response = self.client.get(
                "/api/etf/00631l/intraday-nav/history/summary?date=2026-06-08"
            )
            self.assertEqual(summary_response.status_code, 200)
            summary_payload = summary_response.json()
            self.assertEqual(summary_payload["sampleCount"], 1)
            self.assertEqual(summary_payload["highestPremiumDiscountPct"], 0.75)
            self.assertEqual(summary_payload["lowestPremiumDiscountPct"], 0.75)
            self.assertEqual(summary_payload["averagePremiumDiscountPct"], 0.75)

    def test_operations_status_reports_local_history_state(self) -> None:
        holdings_fixture = (FIXTURES / "00631l_yuanta_ratio_fixture.txt").read_text(encoding="utf-8")
        intraday_fixture = (FIXTURES / "00631l_twse_all_etf_fixture.json").read_text(encoding="utf-8")

        def fake_fetcher(url: str, timeout_seconds: float) -> str:
            if url == "fixture://holdings":
                return holdings_fixture
            if url == "fixture://twse/all_etf":
                return intraday_fixture
            raise AssertionError(f"Unexpected fixture URL: {url}")

        with tempfile.TemporaryDirectory() as temp_dir:
            main_module.service = Etf00631LService(
                config=Settings(
                    yuanta_holdings_url="fixture://holdings",
                    twse_intraday_nav_url="fixture://twse/all_etf",
                    intraday_nav_source="twse",
                ),
                fetcher=fake_fetcher,
                cache=TimedMemoryCache(),
                history_store=HoldingsHistoryStore(Path(temp_dir) / "history.jsonl"),
                intraday_history_store=IntradayNavHistoryStore(
                    Path(temp_dir) / "intraday.jsonl"
                ),
            )

            self.assertEqual(
                self.client.get("/api/etf/00631l/holdings").json()["sourceStatus"],
                "official",
            )
            self.assertEqual(
                self.client.get("/api/etf/00631l/intraday-nav").json()["sourceStatus"],
                "official",
            )

            response = self.client.get("/api/etf/00631l/operations/status")
            self.assertEqual(response.status_code, 200)
            payload = response.json()
            self.assertEqual(payload["sourceStatus"], "cached")
            self.assertEqual(payload["sourceContract"], "00631l_operations_status")
            self.assertEqual(payload["holdingsHistory"]["latestTradeDate"], "2026-06-05")
            self.assertEqual(payload["intradayNavHistory"]["sampleCount"], 1)
            self.assertEqual(payload["config"]["intradaySourceMode"], "twse")
            self.assertTrue(payload["config"]["twseIntradayNavConfigured"])
            self.assertIn("oneShotCommand", payload["collector"])


if __name__ == "__main__":
    unittest.main()
