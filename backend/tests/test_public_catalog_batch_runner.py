import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from backend.scripts.run_public_etf_catalog_batches_00631l import (
    _run_single_batch,
    run_public_etf_catalog_batches,
)


class PublicCatalogBatchRunnerTests(unittest.TestCase):
    def test_dry_run_plans_offsets_from_catalog_row_count(self) -> None:
        payload = run_public_etf_catalog_batches(
            base_url="https://example.com",
            batch_size=50,
            max_batches=10,
            catalog_row_count=125,
            dry_run=True,
        )

        self.assertEqual(payload["overallStatus"], "PASS")
        self.assertTrue(payload["dryRun"])
        self.assertEqual(payload["summary"]["plannedOffsets"], [0, 50, 100])
        self.assertEqual(payload["summary"]["plannedBatchCount"], 3)

    def test_dry_run_without_catalog_count_does_not_contact_backend(self) -> None:
        def requester(base_url: str, path: str, timeout_seconds: int) -> dict:
            raise AssertionError("dry run should not call network")

        payload = run_public_etf_catalog_batches(
            base_url="https://example.com",
            batch_size=50,
            max_batches=2,
            dry_run=True,
            requester=requester,
        )

        self.assertEqual(payload["overallStatus"], "PASS")
        self.assertEqual(payload["summary"]["plannedOffsets"], [0, 50])

    def test_runs_batches_and_reports_final_ready_count(self) -> None:
        maintenance_calls: list[tuple[int, int]] = []
        history_status_calls = 0

        def requester(base_url: str, path: str, timeout_seconds: int) -> dict:
            nonlocal history_status_calls
            if path == "/api/etf/catalog/status":
                return {
                    "httpStatus": 200,
                    "payload": {
                        "sourceStatus": "static_official",
                        "rowCount": 200,
                    },
                }
            if path == "/api/etf/history/status":
                history_status_calls += 1
                return {
                    "httpStatus": 200,
                    "payload": {
                        "sourceStatus": "cached",
                        "readyCount": 90,
                        "rowCount": 90,
                        "validationFailureCount": 0,
                    },
                }
            raise AssertionError(path)

        def maintenance_runner(
            *,
            base_url: str,
            offset: int,
            limit: int,
            timeout_seconds: int,
            retry_count: int,
            retry_delay_seconds: float,
        ) -> dict:
            maintenance_calls.append((offset, limit))
            return {
                "overallStatus": "PASS",
                "failures": [],
                "warnings": [],
                "steps": [],
            }

        payload = run_public_etf_catalog_batches(
            base_url="https://example.com",
            batch_size=50,
            max_batches=3,
            requester=requester,
            maintenance_runner=maintenance_runner,
        )

        self.assertEqual(payload["overallStatus"], "PASS")
        self.assertEqual(maintenance_calls, [(0, 50), (50, 50), (100, 50)])
        self.assertEqual(payload["summary"]["catalogRowCount"], 200)
        self.assertEqual(payload["summary"]["finalReadyCount"], 90)
        self.assertEqual(history_status_calls, 2)
        self.assertTrue(
            any("--start-offset 150" in item for item in payload["actionItems"])
        )

    def test_batch_timeout_is_warning_when_ready_count_increases(self) -> None:
        history_ready_counts = [15, 17]

        def requester(base_url: str, path: str, timeout_seconds: int) -> dict:
            if path == "/api/etf/catalog/status":
                return {
                    "httpStatus": 200,
                    "payload": {
                        "sourceStatus": "static_official",
                        "rowCount": 120,
                    },
                }
            if path == "/api/etf/history/status":
                return {
                    "httpStatus": 200,
                    "payload": {
                        "sourceStatus": "cached",
                        "readyCount": history_ready_counts.pop(0),
                        "rowCount": 17,
                        "validationFailureCount": 0,
                    },
                }
            raise AssertionError(path)

        def maintenance_runner(
            *,
            base_url: str,
            offset: int,
            limit: int,
            timeout_seconds: int,
            retry_count: int,
            retry_delay_seconds: float,
        ) -> dict:
            return {
                "overallStatus": "FAIL",
                "failures": ["etf_history_update: The read operation timed out"],
                "warnings": [],
                "steps": [],
            }

        payload = run_public_etf_catalog_batches(
            base_url="https://example.com",
            batch_size=50,
            max_batches=1,
            requester=requester,
            maintenance_runner=maintenance_runner,
        )

        self.assertEqual(payload["overallStatus"], "WARN")
        self.assertEqual(payload["failures"], [])
        self.assertEqual(payload["summary"]["initialReadyCount"], 15)
        self.assertEqual(payload["summary"]["finalReadyCount"], 17)
        self.assertTrue(any("partial progress" in item for item in payload["warnings"]))

    def test_failed_batch_recommends_retrying_failed_offset(self) -> None:
        history_ready_counts = [56, 15]

        def requester(base_url: str, path: str, timeout_seconds: int) -> dict:
            if path == "/api/etf/catalog/status":
                return {
                    "httpStatus": 200,
                    "payload": {
                        "sourceStatus": "static_official",
                        "rowCount": 343,
                    },
                }
            if path == "/api/etf/history/status":
                return {
                    "httpStatus": 200,
                    "payload": {
                        "sourceStatus": "cached",
                        "readyCount": history_ready_counts.pop(0),
                        "rowCount": 15,
                        "validationFailureCount": 0,
                    },
                }
            raise AssertionError(path)

        def maintenance_runner(
            *,
            base_url: str,
            offset: int,
            limit: int,
            timeout_seconds: int,
            retry_count: int,
            retry_delay_seconds: float,
        ) -> dict:
            return {
                "overallStatus": "FAIL",
                "failures": ["etf_history_update: HTTP 502"],
                "warnings": [],
                "steps": [],
            }

        payload = run_public_etf_catalog_batches(
            base_url="https://example.com",
            batch_size=10,
            max_batches=1,
            start_offset=30,
            requester=requester,
            maintenance_runner=maintenance_runner,
        )

        self.assertEqual(payload["overallStatus"], "FAIL")
        self.assertEqual(payload["summary"]["nextOffset"], 30)
        self.assertTrue(any("HTTP 502" in item for item in payload["failures"]))
        self.assertTrue(
            any("--start-offset 30" in item for item in payload["actionItems"])
        )
        self.assertTrue(
            any("ready count decreased" in item for item in payload["warnings"])
        )
        self.assertFalse(
            any("--start-offset 40" in item for item in payload["actionItems"])
        )

    def test_failed_batch_writes_resume_state(self) -> None:
        history_ready_counts = [56, 15]

        def requester(base_url: str, path: str, timeout_seconds: int) -> dict:
            if path == "/api/etf/catalog/status":
                return {
                    "httpStatus": 200,
                    "payload": {"sourceStatus": "static_official", "rowCount": 343},
                }
            if path == "/api/etf/history/status":
                return {
                    "httpStatus": 200,
                    "payload": {
                        "sourceStatus": "cached",
                        "readyCount": history_ready_counts.pop(0),
                        "rowCount": 15,
                        "validationFailureCount": 0,
                    },
                }
            raise AssertionError(path)

        def maintenance_runner(
            *,
            base_url: str,
            offset: int,
            limit: int,
            timeout_seconds: int,
            retry_count: int,
            retry_delay_seconds: float,
        ) -> dict:
            return {
                "overallStatus": "FAIL",
                "failures": ["etf_history_update: HTTP 502"],
                "warnings": [],
                "steps": [],
            }

        with tempfile.TemporaryDirectory() as temp_dir:
            state_path = Path(temp_dir) / "batch_state.json"
            run_public_etf_catalog_batches(
                base_url="https://example.com",
                batch_size=10,
                max_batches=1,
                start_offset=30,
                requester=requester,
                maintenance_runner=maintenance_runner,
                state_path=state_path,
            )

            state = json.loads(state_path.read_text(encoding="utf-8"))

        self.assertEqual(state["overallStatus"], "FAIL")
        self.assertEqual(state["nextOffset"], 30)
        self.assertEqual(state["failedOffset"], 30)
        self.assertEqual(state["finalReadyCount"], 15)

    def test_runner_timeout_is_captured_and_writes_resume_state(self) -> None:
        history_ready_counts = [15, 15]

        def requester(base_url: str, path: str, timeout_seconds: int) -> dict:
            if path == "/api/etf/catalog/status":
                return {
                    "httpStatus": 200,
                    "payload": {"sourceStatus": "static_official", "rowCount": 343},
                }
            if path == "/api/etf/history/status":
                return {
                    "httpStatus": 200,
                    "payload": {
                        "sourceStatus": "cached",
                        "readyCount": history_ready_counts.pop(0),
                        "rowCount": 15,
                        "validationFailureCount": 0,
                    },
                }
            raise AssertionError(path)

        def maintenance_runner(
            *,
            base_url: str,
            offset: int,
            limit: int,
            timeout_seconds: int,
            retry_count: int,
            retry_delay_seconds: float,
        ) -> dict:
            raise TimeoutError("The read operation timed out")

        with tempfile.TemporaryDirectory() as temp_dir:
            state_path = Path(temp_dir) / "batch_state.json"
            payload = run_public_etf_catalog_batches(
                base_url="https://example.com",
                batch_size=10,
                max_batches=1,
                start_offset=15,
                requester=requester,
                maintenance_runner=maintenance_runner,
                state_path=state_path,
            )
            state = json.loads(state_path.read_text(encoding="utf-8"))

        self.assertEqual(payload["overallStatus"], "FAIL")
        self.assertTrue(any("timed out" in item for item in payload["failures"]))
        self.assertEqual(payload["summary"]["nextOffset"], 15)
        self.assertEqual(state["failedOffset"], 15)

    def test_resume_uses_saved_next_offset_for_dry_run(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            state_path = Path(temp_dir) / "batch_state.json"
            state_path.write_text(
                json.dumps({"nextOffset": 40}),
                encoding="utf-8",
            )

            payload = run_public_etf_catalog_batches(
                base_url="https://example.com",
                batch_size=10,
                max_batches=2,
                dry_run=True,
                resume=True,
                state_path=state_path,
            )

        self.assertEqual(payload["summary"]["plannedOffsets"], [40, 50])

    def test_warns_when_catalog_is_not_available(self) -> None:
        def requester(base_url: str, path: str, timeout_seconds: int) -> dict:
            return {
                "httpStatus": 200,
                "payload": {
                    "sourceStatus": "unavailable",
                    "rowCount": 0,
                    "errorMessage": "catalog missing",
                },
            }

        payload = run_public_etf_catalog_batches(
            base_url="https://example.com",
            requester=requester,
        )

        self.assertEqual(payload["overallStatus"], "WARN")
        self.assertEqual(payload["failures"], [])
        self.assertTrue(payload["warnings"])
        self.assertIn("/api/etf/catalog/status", payload["actionItems"][0])

    def test_single_batch_uses_etf_history_update_only(self) -> None:
        with patch(
            "backend.scripts.run_public_etf_catalog_batches_00631l._request_etf_history_update",
            return_value={
                "httpStatus": 200,
                "payload": {
                    "sourceStatus": "cached",
                    "readyCount": 24,
                    "validationFailureCount": 0,
                },
            },
        ) as request_update:
            payload = _run_single_batch(
                base_url="https://example.com",
                offset=10,
                limit=10,
                timeout_seconds=120,
                retry_count=2,
                retry_delay_seconds=3,
            )

        self.assertEqual(payload["overallStatus"], "PASS")
        request_update.assert_called_once()
        kwargs = request_update.call_args.kwargs
        self.assertTrue(kwargs["from_catalog"])
        self.assertEqual(kwargs["offset"], 10)
        self.assertEqual(kwargs["limit"], 10)


if __name__ == "__main__":
    unittest.main()
