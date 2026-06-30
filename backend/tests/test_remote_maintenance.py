import unittest
from datetime import date
from unittest.mock import patch

from backend.scripts.remote_maintenance_00631l import (
    MaintenanceEndpoint,
    _history_update_ranges,
    _request_etf_history_update,
    _request_with_retries,
    run_remote_maintenance,
)


class RemoteMaintenanceTests(unittest.TestCase):
    def test_dry_run_lists_planned_endpoints(self) -> None:
        payload = run_remote_maintenance(
            base_url="https://example.com/",
            mode="all",
            dry_run=True,
        )

        self.assertEqual(payload["overallStatus"], "PASS")
        self.assertTrue(payload["dryRun"])
        names = {step["name"] for step in payload["steps"]}
        self.assertIn("health", names)
        self.assertIn("intraday_nav", names)
        self.assertIn("history_update", names)
        self.assertIn("catalog_import", names)
        self.assertIn("etf_history_update", names)
        self.assertIn("etf_history_status", names)
        self.assertEqual(payload["baseUrl"], "https://example.com")

    def test_daily_runs_multi_etf_history_maintenance(self) -> None:
        called: list[str] = []

        def requester(
            base_url: str,
            endpoint: MaintenanceEndpoint,
            timeout_seconds: int,
        ) -> dict:
            called.append(endpoint.name)
            if endpoint.name == "ready":
                return {"httpStatus": 200, "payload": {"overallStatus": "PASS"}}
            if endpoint.name == "history_status":
                return {"httpStatus": 200, "payload": {"rowCount": 2800}}
            if endpoint.name == "catalog_import":
                return {
                    "httpStatus": 200,
                    "payload": {"sourceStatus": "official", "rowCount": 343},
                }
            if endpoint.name == "etf_history_update":
                return {
                    "httpStatus": 200,
                    "payload": {
                        "sourceStatus": "cached",
                        "readyCount": 15,
                        "validationFailureCount": 0,
                    },
                }
            if endpoint.name == "etf_history_status":
                return {
                    "httpStatus": 200,
                    "payload": {
                        "sourceStatus": "cached",
                        "readyCount": 15,
                        "rowCount": 15,
                        "validationFailureCount": 0,
                    },
                }
            return {"httpStatus": 200, "payload": {"sourceStatus": "official"}}

        payload = run_remote_maintenance(
            base_url="https://example.com",
            mode="daily",
            requester=requester,
        )

        self.assertEqual(payload["overallStatus"], "PASS")
        self.assertIn("catalog_import", called)
        self.assertIn("etf_history_update", called)
        self.assertIn("etf_history_status", called)

    def test_daily_warns_when_catalog_import_has_no_rows(self) -> None:
        def requester(
            base_url: str,
            endpoint: MaintenanceEndpoint,
            timeout_seconds: int,
        ) -> dict:
            if endpoint.name == "ready":
                return {"httpStatus": 200, "payload": {"overallStatus": "PASS"}}
            if endpoint.name == "catalog_import":
                return {
                    "httpStatus": 200,
                    "payload": {"sourceStatus": "unavailable", "rowCount": 0},
                }
            if endpoint.name == "history_status":
                return {"httpStatus": 200, "payload": {"rowCount": 2800}}
            if endpoint.name == "etf_history_status":
                return {
                    "httpStatus": 200,
                    "payload": {
                        "sourceStatus": "cached",
                        "readyCount": 15,
                        "rowCount": 15,
                        "validationFailureCount": 0,
                    },
                }
            return {"httpStatus": 200, "payload": {"sourceStatus": "official"}}

        payload = run_remote_maintenance(
            base_url="https://example.com",
            mode="daily",
            requester=requester,
        )

        self.assertEqual(payload["overallStatus"], "WARN")
        self.assertEqual(payload["failures"], [])
        self.assertTrue(any("catalog_import" in item for item in payload["warnings"]))

    def test_remote_etf_history_update_can_request_catalog_batch(self) -> None:
        requested_paths: list[str] = []

        def fake_request(base_url: str, path: str, method: str, timeout_seconds: int) -> dict:
            requested_paths.append(path)
            if path.startswith("/api/etf/history/update"):
                return {
                    "httpStatus": 200,
                    "payload": {
                        "sourceStatus": "cached",
                        "requestedCodes": ["006203"],
                        "updatedCount": 1,
                        "readyCount": 2,
                        "validationFailureCount": 0,
                        "items": [
                            {
                                "code": "006203",
                                "sourceStatus": "official",
                                "savedRows": 1800,
                                "rowCount": 1800,
                                "coverageStart": "2019-01-02",
                                "coverageEnd": "2026-06-22",
                            }
                        ],
                    },
                }
            return {
                "httpStatus": 200,
                "payload": {
                    "sourceStatus": "cached",
                    "readyCount": 2,
                    "rowCount": 2,
                    "validationFailureCount": 0,
                },
            }

        with patch(
            "backend.scripts.remote_maintenance_00631l._request_once",
            side_effect=fake_request,
        ):
            response = _request_etf_history_update(
                "https://example.com",
                120,
                from_catalog=True,
                limit=25,
                offset=50,
            )

        self.assertEqual(response["httpStatus"], 200)
        self.assertIn("fromCatalog=true", requested_paths[0])
        self.assertIn("limit=25", requested_paths[0])
        self.assertIn("offset=50", requested_paths[0])
        self.assertEqual(response["payload"]["requestedCodes"], ["006203"])
        self.assertEqual(response["payload"]["updatedCount"], 1)
        self.assertEqual(response["payload"]["items"][0]["code"], "006203")
        self.assertEqual(response["payload"]["items"][0]["savedRows"], 1800)

    def test_get_endpoint_retries_transient_http_status(self) -> None:
        endpoint = MaintenanceEndpoint(
            name="operations_status",
            method="GET",
            path="/status",
            mode="intraday",
            description="status",
        )
        calls: list[int] = []

        def requester(
            base_url: str,
            endpoint: MaintenanceEndpoint,
            timeout_seconds: int,
        ) -> dict:
            calls.append(len(calls))
            if len(calls) == 1:
                return {"httpStatus": 502, "payload": {"errorMessage": "bad gateway"}}
            return {"httpStatus": 200, "payload": {"sourceStatus": "cached"}}

        response = _request_with_retries(
            requester,
            "https://example.com",
            endpoint,
            10,
            retry_count=2,
            retry_delay_seconds=0,
            sleep_fn=lambda _: None,
        )

        self.assertEqual(response["httpStatus"], 200)
        self.assertEqual(response["retryAttempts"], 1)
        self.assertEqual(len(calls), 2)

    def test_post_endpoint_is_not_retried(self) -> None:
        endpoint = MaintenanceEndpoint(
            name="etf_history_update",
            method="POST",
            path="/update",
            mode="daily",
            description="update",
        )
        calls: list[int] = []

        def requester(
            base_url: str,
            endpoint: MaintenanceEndpoint,
            timeout_seconds: int,
        ) -> dict:
            calls.append(len(calls))
            return {"httpStatus": 502, "payload": {"errorMessage": "bad gateway"}}

        response = _request_with_retries(
            requester,
            "https://example.com",
            endpoint,
            10,
            retry_count=2,
            retry_delay_seconds=0,
            sleep_fn=lambda _: None,
        )

        self.assertEqual(response["httpStatus"], 502)
        self.assertEqual(len(calls), 1)

    def test_non_critical_status_transient_http_is_warning(self) -> None:
        def requester(
            base_url: str,
            endpoint: MaintenanceEndpoint,
            timeout_seconds: int,
        ) -> dict:
            if endpoint.name == "operations_status":
                return {"httpStatus": 502, "payload": {"errorMessage": "bad gateway"}}
            if endpoint.name == "ready":
                return {"httpStatus": 200, "payload": {"overallStatus": "PASS"}}
            return {"httpStatus": 200, "payload": {"sourceStatus": "cached"}}

        payload = run_remote_maintenance(
            base_url="https://example.com",
            mode="intraday",
            retry_count=0,
            requester=requester,
        )

        self.assertEqual(payload["overallStatus"], "WARN")
        self.assertEqual(payload["failures"], [])
        self.assertTrue(
            any("operations_status" in item for item in payload["warnings"])
        )

    def test_etf_update_warns_when_post_check_is_transient(self) -> None:
        requested_paths: list[str] = []

        def fake_request(base_url: str, path: str, method: str, timeout_seconds: int) -> dict:
            requested_paths.append(path)
            if path.startswith("/api/etf/history/update"):
                return {
                    "httpStatus": 200,
                    "payload": {
                        "sourceStatus": "cached",
                        "readyCount": 2,
                        "validationFailureCount": 0,
                    },
                }
            return {
                "httpStatus": 502,
                "payload": {"errorMessage": "bad gateway"},
            }

        with patch(
            "backend.scripts.remote_maintenance_00631l._request_once",
            side_effect=fake_request,
        ):
            response = _request_etf_history_update(
                "https://example.com",
                120,
                from_catalog=True,
                limit=25,
                offset=50,
                retry_count=0,
            )

        self.assertEqual(response["httpStatus"], 200)
        self.assertEqual(response["payload"]["postCheckHttpStatus"], 502)
        self.assertEqual(len(requested_paths), 2)

    def test_daily_warns_when_etf_post_check_is_transient(self) -> None:
        def requester(
            base_url: str,
            endpoint: MaintenanceEndpoint,
            timeout_seconds: int,
        ) -> dict:
            if endpoint.name == "ready":
                return {"httpStatus": 200, "payload": {"overallStatus": "PASS"}}
            if endpoint.name == "history_status":
                return {"httpStatus": 200, "payload": {"rowCount": 2800}}
            if endpoint.name == "etf_history_update":
                return {
                    "httpStatus": 200,
                    "payload": {
                        "sourceStatus": "cached",
                        "readyCount": 2,
                        "validationFailureCount": 0,
                        "postCheckHttpStatus": 502,
                    },
                }
            if endpoint.name == "etf_history_status":
                return {
                    "httpStatus": 200,
                    "payload": {
                        "sourceStatus": "cached",
                        "readyCount": 2,
                        "rowCount": 2,
                        "validationFailureCount": 0,
                    },
                }
            return {"httpStatus": 200, "payload": {"sourceStatus": "official"}}

        payload = run_remote_maintenance(
            base_url="https://example.com",
            mode="daily",
            requester=requester,
        )

        self.assertEqual(payload["overallStatus"], "WARN")
        self.assertEqual(payload["failures"], [])
        self.assertTrue(
            any("ETF history post-check" in item for item in payload["warnings"])
        )

    def test_daily_warns_when_multi_etf_history_has_no_ready_rows(self) -> None:
        def requester(
            base_url: str,
            endpoint: MaintenanceEndpoint,
            timeout_seconds: int,
        ) -> dict:
            if endpoint.name == "ready":
                return {"httpStatus": 200, "payload": {"overallStatus": "PASS"}}
            if endpoint.name == "history_status":
                return {"httpStatus": 200, "payload": {"rowCount": 2800}}
            if endpoint.name == "etf_history_status":
                return {
                    "httpStatus": 200,
                    "payload": {
                        "sourceStatus": "cached",
                        "readyCount": 0,
                        "rowCount": 0,
                        "validationFailureCount": 0,
                    },
                }
            return {"httpStatus": 200, "payload": {"sourceStatus": "official"}}

        payload = run_remote_maintenance(
            base_url="https://example.com",
            mode="daily",
            requester=requester,
        )

        self.assertEqual(payload["overallStatus"], "WARN")
        self.assertEqual(payload["failures"], [])
        self.assertTrue(
            any("etf_history_status" in item for item in payload["warnings"])
        )

    def test_intraday_warns_when_nav_is_unavailable(self) -> None:
        def requester(
            base_url: str,
            endpoint: MaintenanceEndpoint,
            timeout_seconds: int,
        ) -> dict:
            self.assertEqual(base_url, "https://example.com")
            if endpoint.name == "ready":
                return {"httpStatus": 200, "payload": {"overallStatus": "PASS"}}
            if endpoint.name == "intraday_nav":
                return {
                    "httpStatus": 200,
                    "payload": {"sourceStatus": "unavailable"},
                }
            return {"httpStatus": 200, "payload": {"sourceStatus": "cached"}}

        payload = run_remote_maintenance(
            base_url="https://example.com",
            mode="intraday",
            retry_count=0,
            requester=requester,
        )

        self.assertEqual(payload["overallStatus"], "WARN")
        self.assertEqual(payload["failures"], [])
        self.assertTrue(any("intraday_nav" in item for item in payload["warnings"]))

    def test_daily_detects_history_coverage_warning(self) -> None:
        def requester(
            base_url: str,
            endpoint: MaintenanceEndpoint,
            timeout_seconds: int,
        ) -> dict:
            if endpoint.name == "ready":
                return {"httpStatus": 200, "payload": {"overallStatus": "PASS"}}
            if endpoint.name == "history_status":
                return {"httpStatus": 200, "payload": {"rowCount": 1}}
            return {"httpStatus": 200, "payload": {"sourceStatus": "official"}}

        payload = run_remote_maintenance(
            base_url="https://example.com",
            mode="daily",
            requester=requester,
        )

        self.assertEqual(payload["overallStatus"], "WARN")
        self.assertEqual(payload["failures"], [])
        self.assertTrue(any("history_status" in item for item in payload["warnings"]))

    def test_daily_warns_when_holdings_unavailable(self) -> None:
        def requester(
            base_url: str,
            endpoint: MaintenanceEndpoint,
            timeout_seconds: int,
        ) -> dict:
            if endpoint.name == "ready":
                return {"httpStatus": 200, "payload": {"overallStatus": "PASS"}}
            if endpoint.name == "holdings":
                return {
                    "httpStatus": 200,
                    "payload": {"sourceStatus": "unavailable"},
                }
            if endpoint.name == "history_status":
                return {"httpStatus": 200, "payload": {"rowCount": 2800}}
            return {"httpStatus": 200, "payload": {"sourceStatus": "official"}}

        payload = run_remote_maintenance(
            base_url="https://example.com",
            mode="daily",
            requester=requester,
        )

        self.assertEqual(payload["overallStatus"], "WARN")
        self.assertEqual(payload["failures"], [])
        self.assertTrue(any("holdings" in item for item in payload["warnings"]))

    def test_http_error_is_failure(self) -> None:
        def requester(
            base_url: str,
            endpoint: MaintenanceEndpoint,
            timeout_seconds: int,
        ) -> dict:
            return {"httpStatus": 503, "payload": {"errorMessage": "unavailable"}}

        payload = run_remote_maintenance(
            base_url="https://example.com",
            mode="intraday",
            retry_count=0,
            requester=requester,
        )

        self.assertEqual(payload["overallStatus"], "FAIL")
        self.assertGreater(len(payload["failures"]), 0)

    def test_history_update_ranges_seed_from_listing_when_empty(self) -> None:
        ranges = _history_update_ranges(
            {"rowCount": 0, "isCompleteFromListing": False},
            today=date(2016, 2, 3),
        )

        self.assertEqual(ranges[0], (date(2014, 10, 31), date(2014, 12, 31)))
        self.assertEqual(ranges[1], (date(2015, 1, 1), date(2015, 12, 31)))
        self.assertEqual(ranges[2], (date(2016, 1, 1), date(2016, 2, 3)))

    def test_history_update_ranges_use_recent_window_when_complete(self) -> None:
        ranges = _history_update_ranges(
            {
                "rowCount": 2800,
                "coverageEnd": "2026-06-12",
                "isCompleteFromListing": True,
            },
            today=date(2026, 6, 13),
        )

        self.assertEqual(ranges, [(date(2026, 4, 28), date(2026, 6, 13))])


if __name__ == "__main__":
    unittest.main()
