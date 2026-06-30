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
                            {"code": "0050", "name": "元大台灣50"},
                            {"code": "009824", "name": "群益台灣精選高息"},
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
                                "name": "群益台灣精選高息",
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
                    "payload": {"items": [{"code": "0050", "name": "元大台灣50"}]},
                }
            if path == "/api/etf/history/gaps":
                return {"httpStatus": 200, "payload": {"items": []}}
            raise AssertionError(f"unexpected path {path}")

        payload = run_public_post_deploy_refresh(
            deploy_wait_runner=lambda **kwargs: _payload("PASS"),
            maintenance_runner=lambda **kwargs: _payload("PASS"),
            batch_runner=lambda **kwargs: batch_calls.append(kwargs) or _payload("PASS"),
            freshness_runner=lambda **kwargs: _payload("PASS"),
            requester=requester,
        )

        self.assertEqual(payload["overallStatus"], "PASS")
        self.assertEqual(payload["summary"]["gapCount"], 0)
        self.assertEqual(payload["summary"]["batchCount"], 0)
        self.assertEqual(batch_calls, [])

    def test_gap_discovery_error_is_reported_as_warning(self) -> None:
        payload = run_public_post_deploy_refresh(
            deploy_wait_runner=lambda **kwargs: _payload("PASS"),
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
