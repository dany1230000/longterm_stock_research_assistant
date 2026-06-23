import unittest

from backend.scripts.public_backend_status_00631l import (
    PublicStatusEndpoint,
    run_public_backend_status,
)


class PublicBackendStatusTests(unittest.TestCase):
    def test_dry_run_lists_public_status_endpoints(self) -> None:
        payload = run_public_backend_status(
            base_url="https://example.com/",
            dry_run=True,
        )

        self.assertEqual(payload["overallStatus"], "PASS")
        self.assertTrue(payload["dryRun"])
        self.assertEqual(payload["baseUrl"], "https://example.com")
        names = {step["name"] for step in payload["steps"]}
        self.assertIn("health", names)
        self.assertIn("ready", names)
        self.assertIn("history_status", names)
        self.assertIn("etf_history_status", names)

    def test_status_summarizes_release_and_history_readiness(self) -> None:
        def requester(
            base_url: str,
            endpoint: PublicStatusEndpoint,
            timeout_seconds: int,
        ) -> dict:
            if endpoint.name == "health":
                return {
                    "httpStatus": 200,
                    "payload": {
                        "status": "ok",
                        "appVersion": "4.54-test",
                        "release": {
                            "tag": "00631l-lab-v4.54-test",
                            "gitSha": "abc123",
                        },
                    },
                }
            if endpoint.name == "ready":
                return {
                    "httpStatus": 200,
                    "payload": {"overallStatus": "PASS", "warnings": [], "failures": []},
                }
            if endpoint.name == "history_status":
                return {
                    "httpStatus": 200,
                    "payload": {
                        "rowCount": 2833,
                        "coverageStart": "2014-10-31",
                        "coverageEnd": "2026-06-22",
                    },
                }
            if endpoint.name == "etf_history_status":
                return {
                    "httpStatus": 200,
                    "payload": {
                        "readyCount": 15,
                        "rowCount": 15,
                        "validationFailureCount": 0,
                    },
                }
            return {"httpStatus": 200, "payload": {"sourceStatus": "cached"}}

        payload = run_public_backend_status(
            base_url="https://example.com",
            requester=requester,
        )

        self.assertEqual(payload["overallStatus"], "PASS")
        self.assertEqual(payload["summary"]["backendVersion"], "4.54-test")
        self.assertEqual(payload["summary"]["releaseTag"], "00631l-lab-v4.54-test")
        self.assertEqual(payload["summary"]["gitSha"], "abc123")
        self.assertEqual(payload["summary"]["priceHistoryRows"], 2833)
        self.assertEqual(payload["summary"]["etfHistoryReadyCount"], 15)

    def test_status_warns_when_etf_history_has_no_ready_rows(self) -> None:
        def requester(
            base_url: str,
            endpoint: PublicStatusEndpoint,
            timeout_seconds: int,
        ) -> dict:
            if endpoint.name == "health":
                return {"httpStatus": 200, "payload": {"status": "ok"}}
            if endpoint.name == "ready":
                return {"httpStatus": 200, "payload": {"overallStatus": "PASS"}}
            if endpoint.name == "history_status":
                return {"httpStatus": 200, "payload": {"rowCount": 2833}}
            if endpoint.name == "etf_history_status":
                return {
                    "httpStatus": 200,
                    "payload": {"readyCount": 0, "validationFailureCount": 0},
                }
            return {"httpStatus": 200, "payload": {}}

        payload = run_public_backend_status(
            base_url="https://example.com",
            requester=requester,
        )

        self.assertEqual(payload["overallStatus"], "WARN")
        self.assertEqual(payload["failures"], [])
        self.assertTrue(any("ETF history" in item for item in payload["warnings"]))

    def test_status_warns_when_public_ready_count_is_below_configured_floor(self) -> None:
        def requester(
            base_url: str,
            endpoint: PublicStatusEndpoint,
            timeout_seconds: int,
        ) -> dict:
            if endpoint.name == "health":
                return {"httpStatus": 200, "payload": {"status": "ok"}}
            if endpoint.name == "ready":
                return {"httpStatus": 200, "payload": {"overallStatus": "PASS"}}
            if endpoint.name == "history_status":
                return {"httpStatus": 200, "payload": {"rowCount": 2829}}
            if endpoint.name == "etf_history_status":
                return {
                    "httpStatus": 200,
                    "payload": {"readyCount": 15, "validationFailureCount": 0},
                }
            return {"httpStatus": 200, "payload": {}}

        payload = run_public_backend_status(
            base_url="https://example.com",
            requester=requester,
            min_etf_ready_count=200,
            min_price_history_rows=2800,
        )

        self.assertEqual(payload["overallStatus"], "WARN")
        self.assertEqual(payload["failures"], [])
        self.assertTrue(
            any("below minimum 200" in item for item in payload["warnings"])
        )
        self.assertEqual(payload["summary"]["minEtfReadyCount"], 200)
        self.assertEqual(payload["summary"]["minPriceHistoryRows"], 2800)

    def test_status_warns_for_read_only_public_data_dir_failures(self) -> None:
        def requester(
            base_url: str,
            endpoint: PublicStatusEndpoint,
            timeout_seconds: int,
        ) -> dict:
            if endpoint.name == "health":
                return {"httpStatus": 200, "payload": {"status": "ok"}}
            if endpoint.name == "ready":
                return {
                    "httpStatus": 200,
                    "payload": {
                        "overallStatus": "FAIL",
                        "warnings": [],
                        "failures": [
                            "data_dir_writable: 00631L_DATA_DIR is not writable.",
                            "data_persistence: Data directory is not writable; history/report/export persistence may fail.",
                        ],
                    },
                }
            if endpoint.name == "history_status":
                return {"httpStatus": 200, "payload": {"rowCount": 2829}}
            if endpoint.name == "etf_history_status":
                return {
                    "httpStatus": 200,
                    "payload": {"readyCount": 15, "validationFailureCount": 0},
                }
            return {"httpStatus": 200, "payload": {}}

        payload = run_public_backend_status(
            base_url="https://example.com",
            requester=requester,
        )

        self.assertEqual(payload["overallStatus"], "WARN")
        self.assertEqual(payload["failures"], [])
        self.assertTrue(
            any("data directory" in item.lower() for item in payload["warnings"])
        )


if __name__ == "__main__":
    unittest.main()
