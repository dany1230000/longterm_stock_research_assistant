import unittest

from backend.scripts.public_post_deploy_refresh_00631l import (
    run_public_post_deploy_refresh,
)


def _payload(status: str = "PASS", summary: dict | None = None) -> dict:
    return {
        "overallStatus": status,
        "summary": summary or {},
        "warnings": [],
        "failures": [],
        "actionItems": [],
    }


class PublicPostDeployRefreshTests(unittest.TestCase):
    def test_dry_run_lists_planned_steps(self) -> None:
        payload = run_public_post_deploy_refresh(dry_run=True)

        self.assertEqual(payload["overallStatus"], "PASS")
        self.assertEqual(
            [step["name"] for step in payload["steps"]],
            [
                "deploy_wait",
                "public_backend_status",
                "remote_maintenance",
                "gap_discovery",
                "gap_batches",
                "freshness",
            ],
        )
        self.assertTrue(payload["dryRun"])

    def test_catalog_gap_maps_to_targeted_batch_offset(self) -> None:
        batch_calls: list[dict] = []

        def requester(base_url, path, timeout_seconds, query):
            if path == "/api/etf/catalog":
                return {
                    "httpStatus": 200,
                    "payload": {
                        "items": [
                            {"code": "0050", "name": "ETF 0050"},
                            {"code": "009824", "name": "ETF 009824"},
                        ]
                    },
                }
            if path == "/api/etf/history/gaps":
                return {
                    "httpStatus": 200,
                    "payload": {
                        "items": [
                            {
                                "code": "009824",
                                "name": "ETF 009824",
                                "gapReason": "not_saved",
                            }
                        ]
                    },
                }
            raise AssertionError(f"unexpected path {path}")

        def batch_runner(**kwargs):
            batch_calls.append(kwargs)
            return _payload("PASS", {"plannedOffsets": [kwargs["start_offset"]]})

        payload = run_public_post_deploy_refresh(
            base_url="https://backend.example.com",
            expected_release_tag="00631l-lab-test",
            deploy_wait_runner=lambda **kwargs: _payload("PASS"),
            backend_status_runner=lambda **kwargs: _payload("PASS"),
            maintenance_runner=lambda **kwargs: _payload("PASS"),
            batch_runner=batch_runner,
            freshness_runner=lambda **kwargs: _payload("PASS"),
            requester=requester,
            max_gap_batches=5,
        )

        self.assertEqual(payload["overallStatus"], "PASS")
        self.assertEqual(payload["summary"]["gapCount"], 1)
        self.assertEqual(payload["summary"]["batchCount"], 1)
        self.assertEqual(batch_calls[0]["start_offset"], 1)
        self.assertEqual(batch_calls[0]["batch_size"], 1)
        self.assertTrue(batch_calls[0]["enable_preflight"])

    def test_no_catalog_gaps_skips_batch_runner(self) -> None:
        batch_calls: list[dict] = []

        def requester(base_url, path, timeout_seconds, query):
            if path == "/api/etf/catalog":
                return {
                    "httpStatus": 200,
                    "payload": {"items": [{"code": "0050", "name": "ETF 0050"}]},
                }
            if path == "/api/etf/history/gaps":
                return {"httpStatus": 200, "payload": {"items": []}}
            raise AssertionError(f"unexpected path {path}")

        payload = run_public_post_deploy_refresh(
            deploy_wait_runner=lambda **kwargs: _payload("PASS"),
            backend_status_runner=lambda **kwargs: _payload("PASS"),
            maintenance_runner=lambda **kwargs: _payload("PASS"),
            batch_runner=lambda **kwargs: batch_calls.append(kwargs) or _payload("PASS"),
            freshness_runner=lambda **kwargs: _payload("PASS"),
            requester=requester,
        )

        self.assertEqual(payload["overallStatus"], "PASS")
        self.assertEqual(payload["summary"]["gapCount"], 0)
        self.assertEqual(payload["summary"]["batchCount"], 0)
        self.assertEqual(batch_calls, [])

    def test_resolved_initial_warnings_return_pass_when_freshness_passes(self) -> None:
        def requester(base_url, path, timeout_seconds, query):
            if path == "/api/etf/catalog":
                return {
                    "httpStatus": 200,
                    "payload": {
                        "items": [
                            {"code": "009824", "name": "ETF 009824"},
                        ]
                    },
                }
            if path == "/api/etf/history/gaps":
                return {
                    "httpStatus": 200,
                    "payload": {
                        "items": [
                            {
                                "code": "009824",
                                "name": "ETF 009824",
                                "gapReason": "not_saved",
                            }
                        ]
                    },
                }
            raise AssertionError(f"unexpected path {path}")

        payload = run_public_post_deploy_refresh(
            deploy_wait_runner=lambda **kwargs: {
                **_payload("WARN"),
                "warnings": ["initial freshness warning"],
                "actionItems": ["run maintenance"],
            },
            backend_status_runner=lambda **kwargs: {
                **_payload("WARN"),
                "warnings": ["fresh marker warning"],
            },
            maintenance_runner=lambda **kwargs: {
                **_payload("WARN"),
                "warnings": ["fresh persistence marker"],
            },
            batch_runner=lambda **kwargs: {
                **_payload("WARN"),
                "warnings": ["preflight warning"],
                "summary": {"finalReadyCount": 1},
            },
            freshness_runner=lambda **kwargs: _payload("PASS"),
            requester=requester,
        )

        self.assertEqual(payload["overallStatus"], "PASS")
        self.assertEqual(payload["warnings"], [])
        self.assertEqual(payload["actionItems"], [])
        self.assertEqual(len(payload["summary"]["resolvedWarnings"]), 4)

    def test_backend_status_failure_stops_before_writes(self) -> None:
        maintenance_calls: list[dict] = []

        payload = run_public_post_deploy_refresh(
            deploy_wait_runner=lambda **kwargs: _payload("PASS"),
            backend_status_runner=lambda **kwargs: {
                **_payload("FAIL"),
                "failures": ["storage paths are not writable"],
            },
            maintenance_runner=lambda **kwargs: maintenance_calls.append(kwargs)
            or _payload("PASS"),
            batch_runner=lambda **kwargs: _payload("PASS"),
            freshness_runner=lambda **kwargs: _payload("PASS"),
            requester=lambda *args: {"httpStatus": 200, "payload": {"items": []}},
        )

        self.assertEqual(payload["overallStatus"], "FAIL")
        self.assertEqual(maintenance_calls, [])
        self.assertTrue(
            any(
                item.startswith("Fix public backend storage readiness")
                for item in payload["actionItems"]
            )
        )
        self.assertEqual(
            [step["name"] for step in payload["steps"]],
            ["deploy_wait", "public_backend_status"],
        )

    def test_gap_discovery_error_is_reported_as_warning(self) -> None:
        payload = run_public_post_deploy_refresh(
            deploy_wait_runner=lambda **kwargs: _payload("PASS"),
            backend_status_runner=lambda **kwargs: _payload("PASS"),
            maintenance_runner=lambda **kwargs: _payload("PASS"),
            batch_runner=lambda **kwargs: _payload("PASS"),
            freshness_runner=lambda **kwargs: _payload("PASS"),
            requester=lambda *args: (_ for _ in ()).throw(RuntimeError("offline")),
        )

        self.assertEqual(payload["overallStatus"], "WARN")
        self.assertIn("gap_discovery", payload["warnings"][0])
        self.assertEqual(payload["summary"]["batchCount"], 0)


if __name__ == "__main__":
    unittest.main()
