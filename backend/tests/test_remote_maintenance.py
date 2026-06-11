import unittest

from backend.scripts.remote_maintenance_00631l import (
    MaintenanceEndpoint,
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


if __name__ == "__main__":
    unittest.main()
