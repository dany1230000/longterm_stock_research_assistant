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
    from backend.app.price_history import PriceHistoryStore, parse_twse_stock_day
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
        self.assertNotEqual(payload["appVersion"], "3.4-live-backend")
        self.assertEqual(
            payload["appVersion"], "9.56-public-post-deploy-refresh"
        )
        self.assertEqual(
            payload["release"]["tag"],
            "00631l-lab-v9.56-public-post-deploy-refresh",
        )
        self.assertEqual(payload["release"]["version"], payload["appVersion"])
        self.assertIn("tag", payload["release"])
        self.assertIn("buildTime", payload["release"])
        self.assertIn("gitSha", payload["release"])
        self.assertEqual(payload["scope"], "00631L only")
        self.assertIn("liveSourceConfigured", payload)
        self.assertIn("localState", payload)
        self.assertIn("operationsStatus", payload["endpoints"])
        self.assertIn("analysisSummary", payload["endpoints"])
        self.assertIn("readiness", payload["endpoints"])

    def test_health_uses_configured_release_metadata(self) -> None:
        service = Etf00631LService(
            config=Settings(
                backend_app_version="4.54-test",
                backend_release_tag="00631l-lab-v4.54-test",
                backend_git_sha="abc123",
                backend_build_time="2026-06-22T20:45:00+08:00",
            ),
            cache=TimedMemoryCache(),
        )
        client = TestClient(main_module.create_app(app_service=service))

        payload = client.get("/health").json()

        self.assertEqual(payload["appVersion"], "4.54-test")
        self.assertEqual(payload["release"]["version"], "4.54-test")
        self.assertEqual(payload["release"]["tag"], "00631l-lab-v4.54-test")
        self.assertEqual(payload["release"]["gitSha"], "abc123")
        self.assertEqual(
            payload["release"]["buildTime"],
            "2026-06-22T20:45:00+08:00",
        )

    def test_ready_endpoint_reports_public_persistent_config(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            data_dir = Path(temp_dir) / "data"
            service = Etf00631LService(
                config=Settings(
                    public_api_base_url="https://api.example.com",
                    allowed_origins=("https://dany1230000.github.io",),
                    data_dir=str(data_dir),
                    data_persistence_mode="persistent",
                    twse_intraday_nav_url="fixture://twse/all_etf",
                    yuanta_intraday_nav_url="",
                    holdings_history_path=str(data_dir / "history.jsonl"),
                    intraday_nav_history_path=str(data_dir / "intraday.jsonl"),
                    price_history_path=str(data_dir / "price.jsonl"),
                    etf_catalog_path=str(data_dir / "catalog.json"),
                    etf_price_history_dir=str(data_dir / "etf_price_history"),
                    history_export_dir=str(data_dir / "exports"),
                    daily_cycle_status_path=str(data_dir / "daily_cycle.json"),
                    integrity_status_path=str(data_dir / "integrity.json"),
                    restore_dry_run_status_path=str(data_dir / "restore.json"),
                    persistence_marker_path=str(data_dir / "marker.json"),
                    backup_dir=str(data_dir / "backups"),
                    report_dir=str(data_dir / "reports"),
                ),
                fetcher=lambda url, timeout_seconds: '{"msgArray":[]}',
                cache=TimedMemoryCache(),
                history_store=HoldingsHistoryStore(data_dir / "history.jsonl"),
                intraday_history_store=IntradayNavHistoryStore(
                    data_dir / "intraday.jsonl"
                ),
                price_history_store=PriceHistoryStore(data_dir / "price.jsonl"),
            )
            client = TestClient(main_module.create_app(app_service=service))

            response = client.get("/ready")
            self.assertEqual(response.status_code, 200)
            payload = response.json()
            self.assertEqual(payload["sourceContract"], "00631l_backend_readiness")
            self.assertIn(payload["overallStatus"], {"PASS", "WARN"})
            self.assertEqual(payload["failures"], [])
            self.assertEqual(payload["publicApiBaseUrl"], "https://api.example.com")
            self.assertEqual(payload["allowedOrigins"], ["https://dany1230000.github.io"])
            checks = {item["name"]: item for item in payload["checks"]}
            self.assertEqual(checks["data_dir_writable"]["status"], "PASS")
            self.assertEqual(checks["storage_paths"]["status"], "PASS")
            self.assertEqual(checks["persistence_marker"]["status"], "WARN")
            self.assertTrue(checks["persistence_marker"]["newlyCreated"])
            self.assertTrue(checks["persistence_marker"]["fresh"])
            self.assertEqual(checks["persistence_marker"]["freshThresholdSeconds"], 900)
            storage_paths = {
                item["key"]: item for item in checks["storage_paths"]["paths"]
            }
            self.assertTrue(storage_paths["etfPriceHistory"]["writable"])
            self.assertTrue(storage_paths["persistenceMarker"]["writable"])
            self.assertTrue(storage_paths["etfPriceHistory"]["underDataDir"])
            self.assertEqual(checks["data_persistence"]["status"], "PASS")
            self.assertEqual(checks["live_source_connectivity"]["status"], "PASS")

            second_payload = client.get("/ready").json()
            second_checks = {item["name"]: item for item in second_payload["checks"]}
            self.assertFalse(second_checks["persistence_marker"]["newlyCreated"])
            self.assertTrue(second_checks["persistence_marker"]["fresh"])
            self.assertEqual(
                second_checks["persistence_marker"]["createdAt"],
                checks["persistence_marker"]["createdAt"],
            )

    def test_ready_endpoint_accepts_stable_old_persistence_marker(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            data_dir = root / "data"
            data_dir.mkdir()
            marker_path = data_dir / "marker.json"
            marker_path.write_text(
                json.dumps(
                    {
                        "sourceContract": "00631l_persistence_marker",
                        "createdAt": "2026-01-01T00:00:00+00:00",
                        "path": str(marker_path),
                    }
                ),
                encoding="utf-8",
            )
            service = Etf00631LService(
                config=Settings(
                    public_api_base_url="https://api.example.com",
                    allowed_origins=("https://dany1230000.github.io",),
                    data_dir=str(data_dir),
                    data_persistence_mode="persistent",
                    twse_intraday_nav_url="fixture://twse/all_etf",
                    yuanta_intraday_nav_url="",
                    holdings_history_path=str(data_dir / "history.jsonl"),
                    intraday_nav_history_path=str(data_dir / "intraday.jsonl"),
                    price_history_path=str(data_dir / "price.jsonl"),
                    etf_catalog_path=str(data_dir / "catalog.json"),
                    etf_price_history_dir=str(data_dir / "etf_price_history"),
                    daily_cycle_status_path=str(data_dir / "daily_cycle.json"),
                    integrity_status_path=str(data_dir / "integrity.json"),
                    restore_dry_run_status_path=str(data_dir / "restore.json"),
                    persistence_marker_path=str(marker_path),
                ),
                fetcher=lambda url, timeout_seconds: '{"msgArray":[]}',
                cache=TimedMemoryCache(),
            )
            client = TestClient(main_module.create_app(app_service=service))

            payload = client.get("/ready").json()
            checks = {item["name"]: item for item in payload["checks"]}

            self.assertEqual(checks["persistence_marker"]["status"], "PASS")
            self.assertFalse(checks["persistence_marker"]["newlyCreated"])
            self.assertFalse(checks["persistence_marker"]["fresh"])

    def test_ready_endpoint_warns_when_required_storage_path_is_outside_data_dir(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            data_dir = root / "data"
            external_dir = root / "external_etf_history"
            service = Etf00631LService(
                config=Settings(
                    public_api_base_url="https://api.example.com",
                    allowed_origins=("https://dany1230000.github.io",),
                    data_dir=str(data_dir),
                    data_persistence_mode="persistent",
                    twse_intraday_nav_url="fixture://twse/all_etf",
                    yuanta_intraday_nav_url="",
                    holdings_history_path=str(data_dir / "history.jsonl"),
                    intraday_nav_history_path=str(data_dir / "intraday.jsonl"),
                    price_history_path=str(data_dir / "price.jsonl"),
                    etf_catalog_path=str(data_dir / "catalog.json"),
                    etf_price_history_dir=str(external_dir),
                    daily_cycle_status_path=str(data_dir / "daily_cycle.json"),
                    integrity_status_path=str(data_dir / "integrity.json"),
                    restore_dry_run_status_path=str(data_dir / "restore.json"),
                    persistence_marker_path=str(data_dir / "marker.json"),
                ),
                fetcher=lambda url, timeout_seconds: '{"msgArray":[]}',
                cache=TimedMemoryCache(),
            )
            client = TestClient(main_module.create_app(app_service=service))

            payload = client.get("/ready").json()

            checks = {item["name"]: item for item in payload["checks"]}
            self.assertEqual(payload["overallStatus"], "WARN")
            self.assertEqual(checks["storage_paths"]["status"], "WARN")
            self.assertEqual(checks["storage_paths"]["requiredFailureCount"], 0)
            self.assertGreaterEqual(checks["storage_paths"]["warningCount"], 1)
            storage_paths = {
                item["key"]: item for item in checks["storage_paths"]["paths"]
            }
            self.assertTrue(storage_paths["etfPriceHistory"]["writable"])
            self.assertFalse(storage_paths["etfPriceHistory"]["underDataDir"])
            self.assertIn("outside 00631L_DATA_DIR", storage_paths["etfPriceHistory"]["message"])

    def test_ready_endpoint_warns_for_local_transient_config(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            service = Etf00631LService(
                config=Settings(
                    public_api_base_url="",
                    allowed_origins=(),
                    data_dir=str(Path(temp_dir) / "data"),
                    data_persistence_mode="local",
                    twse_intraday_nav_url="",
                    yuanta_intraday_nav_url="",
                ),
                fetcher=lambda url, timeout_seconds: "",
                cache=TimedMemoryCache(),
            )
            client = TestClient(main_module.create_app(app_service=service))

            payload = client.get("/ready").json()
            self.assertEqual(payload["overallStatus"], "WARN")
            self.assertEqual(payload["failures"], [])
            self.assertTrue(payload["warnings"])
            checks = {item["name"]: item for item in payload["checks"]}
            self.assertEqual(checks["public_api_base_url"]["status"], "WARN")
            self.assertEqual(checks["allowed_origins"]["status"], "WARN")
            self.assertEqual(checks["data_persistence"]["status"], "WARN")

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
        self.assertIn("marketSession", payload)
        self.assertEqual(
            payload["marketSession"]["sourceContract"],
            "twse_intraday_market_session",
        )

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
        self.assertIn("marketSession", payload)
        self.assertEqual(payload["marketSession"]["timezone"], "Asia/Taipei")
        self.assertEqual(payload["marketSession"]["regularSessionStart"], "09:00:00")
        self.assertEqual(payload["marketSession"]["regularSessionEnd"], "13:30:00")

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

    def test_holdings_endpoint_uses_local_history_when_live_parse_fails(self) -> None:
        holdings_fixture = (FIXTURES / "00631l_yuanta_ratio_fixture.txt").read_text(encoding="utf-8")

        with tempfile.TemporaryDirectory() as temp_dir:
            history_store = HoldingsHistoryStore(Path(temp_dir) / "history.jsonl")
            saved_service = Etf00631LService(
                config=Settings(yuanta_holdings_url="fixture://holdings"),
                fetcher=lambda url, timeout_seconds: holdings_fixture,
                cache=TimedMemoryCache(),
                history_store=history_store,
            )
            saved = saved_service.holdings()
            self.assertEqual(saved["sourceStatus"], "official")

            fallback_service = Etf00631LService(
                config=Settings(yuanta_holdings_url="fixture://changed-holdings"),
                fetcher=lambda url, timeout_seconds: "<html>temporarily changed</html>",
                cache=TimedMemoryCache(),
                history_store=history_store,
            )
            client = TestClient(main_module.create_app(app_service=fallback_service))

            response = client.get("/api/etf/00631l/holdings")
            self.assertEqual(response.status_code, 200)
            payload = response.json()
            self.assertEqual(payload["sourceStatus"], "cached")
            self.assertEqual(payload["sourceContract"], "local_jsonl_history")
            self.assertEqual(payload["sourceUrl"], "local://00631l-holdings-history")
            self.assertEqual(payload["tradeDate"], "2026-06-05")
            self.assertIn("Live holdings unavailable", payload["errorMessage"])

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
                "taifex_realtime_when_backend_ready",
            )
            self.assertIn("txQuote", payload)
            self.assertIn(payload["txQuote"]["sourceStatus"], {"unavailable", "cached", "official"})
            self.assertIn("gapDetailCount", payload["etfPriceHistory"])
            self.assertEqual(payload["statusSummary"]["export"], "cached")
            self.assertEqual(payload["statusSummary"]["report"], "cached")
            self.assertIn("integrity", payload)
            self.assertIn("holdings", payload["integrity"])
            self.assertIn("integrity", payload["statusSummary"])
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
                    persistence_marker_path=str(data_dir / "marker.json"),
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
            self.assertIn("storagePaths", payload["dataDirectoryHealth"])
            storage_paths = {
                item["key"]: item for item in payload["dataDirectoryHealth"]["storagePaths"]
            }
            self.assertIn("etfPriceHistory", storage_paths)
            self.assertTrue(storage_paths["etfPriceHistory"]["writable"])
            self.assertIn("storageSummary", payload["dataDirectoryHealth"])
            self.assertEqual(
                payload["dataDirectoryHealth"]["persistenceMarker"]["sourceStatus"],
                "cached",
            )
            self.assertEqual(payload["backendHealth"]["publicApiBaseUrl"], "https://api.example.com")
            self.assertEqual(payload["backendHealth"]["allowedOrigins"], ["https://00631l.example.com"])

    def test_etf_history_gaps_endpoint_filters_gap_reason(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            catalog_seed = root / "catalog_seed.json"
            catalog_seed.write_text(
                json.dumps(
                    {
                        "items": [
                            {"code": "00999", "name": "ETF A"},
                            {"code": "00998", "name": "ETF B"},
                        ],
                    },
                ),
                encoding="utf-8",
            )
            service = Etf00631LService(
                config=Settings(
                    data_dir=str(root / "data"),
                    etf_price_history_dir=str(root / "etf_history"),
                    etf_catalog_path=str(root / "catalog.json"),
                    etf_catalog_seed_path=str(catalog_seed),
                ),
            )
            service._etf_price_history_store.record_import_attempt(
                "00999",
                {
                    "attemptedAt": "2026-06-21T00:00:00+00:00",
                    "sourceStatus": "error",
                    "sourceUrl": "https://example.test/STOCK_DAY?stockNo=00999",
                    "requestedMonths": 1,
                    "rowCount": 0,
                    "warnings": ["emptyMonths=1"],
                    "errorMessage": None,
                },
            )
            main_module.service = service

            response = self.client.get(
                "/api/etf/history/gaps?reason=official_empty&limit=1&fromCatalog=true",
            )

        self.assertEqual(response.status_code, 200)
        payload = response.json()
        self.assertEqual(payload["sourceContract"], "twse_multi_etf_price_history_gaps")
        self.assertTrue(payload["fromCatalog"])
        self.assertEqual(payload["catalogRowCount"], 2)
        self.assertEqual(payload["reason"], "official_empty")
        self.assertEqual(payload["returnedCount"], 1)
        self.assertEqual(payload["items"][0]["code"], "00999")
        self.assertEqual(payload["items"][0]["gapReason"], "official_empty")
        self.assertEqual(payload["gapReasonSamples"]["official_empty"], ["00999"])

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

    def test_price_history_and_backtest_endpoints_return_fixture_data(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            price_store = PriceHistoryStore(Path(temp_dir) / "price.jsonl")
            price_store.save_points(
                parse_twse_stock_day(
                    json.dumps(
                        {
                            "data": [
                                ["115/06/01", "1,000,000", "30,500,000", "30.00", "31.00", "29.50", "30.50", "+0.50", "1,234"],
                                ["115/06/02", "1,100,000", "34,100,000", "31.00", "32.00", "30.50", "31.00", "+0.50", "1,300"],
                                ["115/06/03", "1,200,000", "36,000,000", "30.50", "31.00", "29.80", "30.00", "-1.00", "1,400"],
                            ]
                        }
                    ),
                    source_url="fixture://twse",
                )
            )
            main_module.service = Etf00631LService(
                config=Settings(
                    price_history_path=str(Path(temp_dir) / "price.jsonl"),
                    holdings_history_path=str(Path(temp_dir) / "history.jsonl"),
                    intraday_nav_history_path=str(Path(temp_dir) / "intraday.jsonl"),
                ),
                cache=TimedMemoryCache(),
                history_store=HoldingsHistoryStore(Path(temp_dir) / "history.jsonl"),
                intraday_history_store=IntradayNavHistoryStore(
                    Path(temp_dir) / "intraday.jsonl"
                ),
                price_history_store=price_store,
            )

            price_response = self.client.get("/api/etf/00631l/history/price")
            self.assertEqual(price_response.status_code, 200)
            price_payload = price_response.json()
            self.assertEqual(price_payload["sourceStatus"], "cached")
            self.assertEqual(price_payload["coverageStart"], "2026-06-01")
            self.assertEqual(len(price_payload["items"]), 3)
            self.assertEqual(price_payload["priceField"], "adjustedClose")
            self.assertEqual(price_payload["items"][0]["adjustedClose"], 30.5)

            performance = self.client.get("/api/etf/00631l/history/performance").json()
            self.assertEqual(performance["sourceStatus"], "cached")
            self.assertEqual(performance["rowCount"], 3)
            self.assertEqual(performance["priceField"], "adjustedClose")

            defaults = self.client.get("/api/etf/00631l/backtest/defaults").json()
            self.assertEqual(defaults["defaultStrategy"], "monthly_contribution")
            self.assertEqual(defaults["disclaimer"], "回測不代表未來表現，非買賣建議")

            result = self.client.post(
                "/api/etf/00631l/backtest/run",
                json={
                    "strategy": "lump_sum",
                    "startDate": "2026-06-01",
                    "endDate": "2026-06-03",
                    "initialAmount": 100000,
                    "monthlyAmount": 0,
                    "monthlyDay": 5,
                    "feeRatePct": 0,
                },
            ).json()
            self.assertEqual(result["sourceStatus"], "calculated")
            self.assertEqual(result["totalInvested"], 100000)
            self.assertGreater(len(result["equityCurve"]), 1)

    def test_price_history_endpoint_uses_configured_seed_when_local_cache_empty(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            seed_store = PriceHistoryStore(root / "seed.jsonl")
            seed_store.save_points(
                parse_twse_stock_day(
                    json.dumps(
                        {
                            "data": [
                                ["115/06/01", "1,000,000", "30,500,000", "30.00", "31.00", "29.50", "30.50", "+0.50", "1,234"],
                                ["115/06/02", "1,100,000", "34,100,000", "31.00", "32.00", "30.50", "31.00", "+0.50", "1,300"],
                            ]
                        }
                    ),
                    source_url="fixture://seed",
                )
            )
            main_module.service = Etf00631LService(
                config=Settings(
                    price_history_path=str(root / "price.jsonl"),
                    price_history_seed_path=str(seed_store.path),
                    holdings_history_path=str(root / "history.jsonl"),
                    intraday_nav_history_path=str(root / "intraday.jsonl"),
                ),
                cache=TimedMemoryCache(),
                history_store=HoldingsHistoryStore(root / "history.jsonl"),
                intraday_history_store=IntradayNavHistoryStore(root / "intraday.jsonl"),
            )

            status_response = self.client.get("/api/etf/00631l/history/status")
            price_response = self.client.get("/api/etf/00631l/history/price")

            self.assertEqual(status_response.status_code, 200)
            self.assertEqual(price_response.status_code, 200)
            status_payload = status_response.json()
            price_payload = price_response.json()
            self.assertEqual(status_payload["sourceStatus"], "static_official")
            self.assertEqual(status_payload["rowCount"], 2)
            self.assertEqual(status_payload["coverageStart"], "2026-06-01")
            self.assertEqual(price_payload["sourceStatus"], "static_official")
            self.assertEqual(len(price_payload["items"]), 2)

    def test_etf_catalog_import_and_status_endpoints(self) -> None:
        fixture = (FIXTURES / "00631l_twse_all_etf_fixture.json").read_text(
            encoding="utf-8"
        )
        with tempfile.TemporaryDirectory() as temp_dir:
            data_dir = Path(temp_dir) / "data"
            main_module.service = Etf00631LService(
                config=Settings(
                    twse_intraday_nav_url="fixture://twse/all_etf",
                    etf_catalog_path=str(data_dir / "twse_etf_catalog.json"),
                ),
                fetcher=lambda url, timeout_seconds: fixture,
                cache=TimedMemoryCache(),
            )

            imported = self.client.post("/api/etf/catalog/import").json()
            self.assertEqual(imported["sourceStatus"], "official")
            self.assertGreaterEqual(imported["rowCount"], 1)

            status = self.client.get("/api/etf/catalog/status").json()
            self.assertEqual(status["sourceStatus"], "cached")
            self.assertGreaterEqual(status["rowCount"], 1)

            catalog = self.client.get("/api/etf/catalog").json()
            self.assertEqual(catalog["sourceStatus"], "cached")
            self.assertTrue(any(item["code"] == "00631L" for item in catalog["items"]))


if __name__ == "__main__":
    unittest.main()
