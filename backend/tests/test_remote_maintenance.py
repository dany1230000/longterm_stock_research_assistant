import unittest
from datetime import date

from backend.scripts.remote_maintenance_00631l import (
    MaintenanceEndpoint,
    _history_update_ranges,
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
        self.assertEqual(payload["baseUrl"], "https://example.com")

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
