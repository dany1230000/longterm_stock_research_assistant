import unittest
import json
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
        self.assertEqual(payload["sourceContract"], "00631l_backend_health")
        self.assertEqual(payload["scope"], "00631L only")
        self.assertIn("liveSourceConfigured", payload)
        self.assertIn("localState", payload)
        self.assertIn("operationsStatus", payload["endpoints"])
        self.assertIn("analysisSummary", payload["endpoints"])

    def test_cors_allows_private_lan_origin_for_mobile_mode(self) -> None:
        response = self.client.options(
            "/health",
            headers={
                "Origin": "http://192.168.0.19:8080",
                "Access-Control-Request-Method": "GET",
            },
        )

        self.assertEqual(response.status_code, 200)
        self.assertEqual(
            response.headers.get("access-control-allow-origin"),
            "http://192.168.0.19:8080",
        )

    def test_cors_allows_configured_public_origin(self) -> None:
        client = TestClient(
            main_module.create_app(
                app_config=Settings(
                    allowed_origins=("https://00631l.example.com",),
                )
            )
        )

        response = client.options(
            "/health",
            headers={
                "Origin": "https://00631l.example.com",
                "Access-Control-Request-Method": "GET",
            },
        )

        self.assertEqual(response.status_code, 200)
        self.assertEqual(
            response.headers.get("access-control-allow-origin"),
            "https://00631l.example.com",
        )

    def test_intraday_nav_without_config_is_unavailable(self) -> None:
        main_module.service = Etf00631LService(
            config=Settings(
                twse_intraday_nav_url="",
                yuanta_intraday_nav_url="",
                intraday_nav_source="auto",
            ),
            fetcher=lambda url, timeout_seconds: "",
            cache=TimedMemoryCache(),
        )

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
            export_dir = Path(temp_dir) / "exports"
            export_dir.mkdir()
            backup_dir = Path(temp_dir) / "backups"
            backup_dir.mkdir()
            backup_file = backup_dir / "00631l_local_data_backup_20260608_100000Z.zip"
            backup_file.write_bytes(b"fixture backup")
            report_dir = Path(temp_dir) / "reports"
            report_dir.mkdir()
            report_file = report_dir / "00631l_daily_report_20260608T100600Z.md"
            report_file.write_text("# 00631L daily report\n", encoding="utf-8")
            (report_dir / "00631l_daily_report_latest.json").write_text(
                json.dumps(
                    {
                        "sourceStatus": "cached",
                        "sourceContract": "00631l_daily_markdown_report",
                        "generatedAt": "2026-06-08T10:06:00+00:00",
                        "reportPath": str(report_file),
                        "overallStatus": "WARN",
                        "warningCount": 2,
                        "failureCount": 0,
                        "warnings": ["collect returned WARN", "smoke returned WARN"],
                        "failures": [],
                        "isStale": False,
                        "errorMessage": None,
                    }
                ),
                encoding="utf-8",
            )
            export_file = export_dir / "00631l_holdings_history_summary.csv"
            export_file.write_text("tradeDate,navPerUnit\n2026-06-05,36.56\n", encoding="utf-8")
            metadata_file = export_dir / "00631l_history_export_metadata.json"
            metadata_file.write_text(
                '{"exportedAt":"2026-06-08T10:10:00+00:00","totalRowCount":2,'
                '"sourceHistoryRange":{"holdingsStartDate":"2026-06-05",'
                '"holdingsEndDate":"2026-06-08"}}',
                encoding="utf-8",
            )
            status_path = Path(temp_dir) / "00631l_daily_cycle_status.json"
            status_path.write_text(
                '{"overallStatus":"PASS","startedAt":"2026-06-08T10:00:00+00:00",'
                '"finishedAt":"2026-06-08T10:05:00+00:00","warnings":[],"failures":[]}',
                encoding="utf-8",
            )
            main_module.service = Etf00631LService(
                config=Settings(
                    yuanta_holdings_url="fixture://holdings",
                    twse_intraday_nav_url="fixture://twse/all_etf",
                    intraday_nav_source="twse",
                    history_export_dir=str(export_dir),
                    daily_cycle_status_path=str(status_path),
                    backup_dir=str(backup_dir),
                    report_dir=str(report_dir),
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
            self.assertIn("missingKeys", payload["config"])
            self.assertTrue(payload["export"]["available"])
            self.assertEqual(payload["export"]["sourceStatus"], "cached")
            self.assertEqual(payload["export"]["rows"], 2)
            self.assertEqual(
                payload["export"]["sourceHistoryRange"]["holdingsEndDate"],
                "2026-06-08",
            )
            self.assertEqual(payload["dailyCycle"]["overallStatus"], "PASS")
            self.assertEqual(payload["dailyCycle"]["sourceStatus"], "cached")
            self.assertTrue(payload["backup"]["available"])
            self.assertEqual(payload["backup"]["sourceStatus"], "cached")
            self.assertEqual(payload["report"]["sourceStatus"], "cached")
            self.assertEqual(payload["report"]["overallStatus"], "WARN")
            self.assertEqual(payload["report"]["warningCount"], 2)
            self.assertTrue(payload["config"]["backupDirReady"])
            self.assertEqual(payload["dataDirectoryHealth"]["backupDir"]["fileCount"], 1)
            self.assertEqual(
                payload["dataUpdateFrequencies"][0]["frequency"],
                "official_daily_snapshot",
            )
            self.assertEqual(
                payload["dataUpdateFrequencies"][1]["label"],
                "intraday NAV / premium discount",
            )
            self.assertEqual(
                payload["dataUpdateFrequencies"][2]["frequency"],
                "not_connected",
            )
            self.assertEqual(payload["statusSummary"]["export"], "cached")
            self.assertEqual(payload["statusSummary"]["report"], "cached")
            self.assertEqual(payload["backendHealth"]["sourceContract"], "00631l_backend_health")
            self.assertIn("localState", payload["backendHealth"])
            self.assertIn("oneShotCommand", payload["collector"])

            analysis_response = self.client.get("/api/etf/00631l/analysis/summary")
            self.assertEqual(analysis_response.status_code, 200)
            analysis = analysis_response.json()
            self.assertEqual(analysis["source"], "rule_based")
            self.assertEqual(analysis["sourceContract"], "00631l_rule_based_analysis_summary")
            self.assertEqual(analysis["disclaimer"], "非買賣建議")
            self.assertIn(analysis["readinessLevel"], {"ready", "attention", "action_needed"})
            self.assertGreaterEqual(len(analysis["bullets"]), 3)
            self.assertIn("holdingsHistory", analysis["sourceStatuses"])

    def test_operations_status_reports_public_deployment_metadata(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            data_dir = Path(temp_dir) / "data"
            main_module.service = Etf00631LService(
                config=Settings(
                    public_api_base_url="https://api.example.com",
                    allowed_origins=("https://00631l.example.com",),
                    data_dir=str(data_dir),
                    data_persistence_mode="transient",
                    history_export_dir=str(Path(temp_dir) / "exports"),
                    backup_dir=str(Path(temp_dir) / "backups"),
                    report_dir=str(Path(temp_dir) / "reports"),
                    holdings_history_path=str(data_dir / "history.jsonl"),
                    intraday_nav_history_path=str(data_dir / "intraday.jsonl"),
                    daily_cycle_status_path=str(data_dir / "daily_cycle.json"),
                    integrity_status_path=str(data_dir / "integrity.json"),
                    restore_dry_run_status_path=str(data_dir / "restore.json"),
                ),
                cache=TimedMemoryCache(),
                history_store=HoldingsHistoryStore(data_dir / "history.jsonl"),
                intraday_history_store=IntradayNavHistoryStore(
                    data_dir / "intraday.jsonl"
                ),
            )

            response = self.client.get("/api/etf/00631l/operations/status")
            self.assertEqual(response.status_code, 200)
            payload = response.json()
            self.assertEqual(payload["config"]["publicApiBaseUrl"], "https://api.example.com")
            self.assertEqual(payload["config"]["allowedOrigins"], ["https://00631l.example.com"])
            self.assertEqual(payload["config"]["dataPersistenceMode"], "transient")
            self.assertEqual(payload["dataDirectoryHealth"]["dataRoot"], str(data_dir))
            self.assertEqual(payload["dataDirectoryHealth"]["persistence"]["mode"], "transient")
            self.assertTrue(payload["dataDirectoryHealth"]["persistence"]["writable"])
            self.assertFalse(payload["dataDirectoryHealth"]["persistence"]["isPersistent"])
            self.assertIn("persistent volume", payload["dataDirectoryHealth"]["persistence"]["warning"])
            self.assertEqual(payload["backendHealth"]["publicApiBaseUrl"], "https://api.example.com")
            self.assertEqual(payload["backendHealth"]["allowedOrigins"], ["https://00631l.example.com"])

    def test_operations_status_reports_missing_daily_cycle_status(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            main_module.service = Etf00631LService(
                config=Settings(
                    history_export_dir=str(Path(temp_dir) / "exports"),
                    daily_cycle_status_path=str(
                        Path(temp_dir) / "missing_daily_cycle_status.json"
                    ),
                    holdings_history_path=str(Path(temp_dir) / "history.jsonl"),
                    intraday_nav_history_path=str(Path(temp_dir) / "intraday.jsonl"),
                    report_dir=str(Path(temp_dir) / "reports"),
                ),
                cache=TimedMemoryCache(),
                history_store=HoldingsHistoryStore(Path(temp_dir) / "history.jsonl"),
                intraday_history_store=IntradayNavHistoryStore(
                    Path(temp_dir) / "intraday.jsonl"
                ),
            )

            response = self.client.get("/api/etf/00631l/operations/status")
            self.assertEqual(response.status_code, 200)
            payload = response.json()
            self.assertFalse(payload["dailyCycle"]["available"])
            self.assertEqual(payload["dailyCycle"]["overallStatus"], "missing")
            self.assertEqual(payload["dailyCycle"]["sourceStatus"], "unavailable")
            self.assertFalse(payload["export"]["available"])
            self.assertEqual(payload["report"]["sourceStatus"], "unavailable")
            self.assertEqual(payload["statusSummary"]["dailyCycle"], "unavailable")


if __name__ == "__main__":
    unittest.main()
