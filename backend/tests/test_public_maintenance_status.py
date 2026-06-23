import unittest

from backend.scripts.public_maintenance_status_00631l import (
    build_public_maintenance_status,
)


class PublicMaintenanceStatusTests(unittest.TestCase):
    def test_combines_public_checks_and_action_items(self) -> None:
        payload = build_public_maintenance_status(
            deploy_drift={
                "overallStatus": "WARN",
                "warnings": ["public backend release tag differs"],
                "failures": [],
                "actionItems": ["Redeploy the public backend."],
                "summary": {"publicReleaseTag": "old", "expectedReleaseTag": "new"},
            },
            public_status={
                "overallStatus": "WARN",
                "warnings": ["ETF history ready count below minimum 200: 15"],
                "failures": [],
                "summary": {"etfHistoryReadyCount": 15, "minEtfReadyCount": 200},
            },
            freshness={
                "overallStatus": "WARN",
                "warnings": ["public backend ETF history ready count is lower"],
                "failures": [],
                "actionItems": ["Run public ETF catalog batches."],
                "summary": {"publicEtfReadyLagVsStatic": 213},
            },
            checked_at="2026-06-23T00:00:00+00:00",
        )

        self.assertEqual(payload["overallStatus"], "WARN")
        self.assertEqual(payload["failureCount"], 0)
        self.assertGreaterEqual(payload["warningCount"], 3)
        self.assertIn("Redeploy the public backend.", payload["actionItems"])
        self.assertIn("Run public ETF catalog batches.", payload["actionItems"])
        self.assertEqual(payload["summary"]["publicEtfReadyCount"], 15)
        self.assertEqual(payload["summary"]["publicEtfReadyLagVsStatic"], 213)

    def test_failure_in_any_check_makes_overall_fail(self) -> None:
        payload = build_public_maintenance_status(
            deploy_drift={
                "overallStatus": "FAIL",
                "warnings": [],
                "failures": ["health: HTTP 502"],
                "actionItems": [],
                "summary": {},
            },
            public_status={"overallStatus": "PASS", "warnings": [], "failures": [], "summary": {}},
            freshness={"overallStatus": "PASS", "warnings": [], "failures": [], "summary": {}},
            checked_at="2026-06-23T00:00:00+00:00",
        )

        self.assertEqual(payload["overallStatus"], "FAIL")
        self.assertEqual(payload["failureCount"], 1)

    def test_includes_public_catalog_batch_resume_state(self) -> None:
        payload = build_public_maintenance_status(
            deploy_drift={"overallStatus": "PASS", "warnings": [], "failures": [], "summary": {}},
            public_status={
                "overallStatus": "WARN",
                "warnings": ["ETF history ready count below minimum 200: 15"],
                "failures": [],
                "summary": {"etfHistoryReadyCount": 15, "minEtfReadyCount": 200},
            },
            freshness={"overallStatus": "PASS", "warnings": [], "failures": [], "summary": {}},
            catalog_batch_state={
                "updatedAt": "2026-06-23T02:00:00+00:00",
                "overallStatus": "WARN",
                "catalogRowCount": 344,
                "finalReadyCount": 15,
                "nextOffset": 20,
                "failedOffset": None,
            },
            checked_at="2026-06-23T00:00:00+00:00",
        )

        self.assertEqual(payload["summary"]["catalogBatchNextOffset"], 20)
        self.assertEqual(payload["summary"]["catalogBatchFinalReadyCount"], 15)
        self.assertIn(
            "Resume public ETF catalog batches with scripts\\00631l_public_etf_catalog_batches.cmd --resume --batch-size 1 --max-batches 1 --soft-fail.",
            payload["actionItems"],
        )

    def test_suggests_start_offset_from_public_ready_count_without_resume_offset(self) -> None:
        payload = build_public_maintenance_status(
            deploy_drift={"overallStatus": "PASS", "warnings": [], "failures": [], "summary": {}},
            public_status={
                "overallStatus": "WARN",
                "warnings": ["ETF history ready count below minimum 200: 15"],
                "failures": [],
                "summary": {"etfHistoryReadyCount": 15, "minEtfReadyCount": 200},
            },
            freshness={
                "overallStatus": "WARN",
                "warnings": ["public backend ETF history ready count is lower"],
                "failures": [],
                "summary": {"publicEtfReadyLagVsStatic": 213},
            },
            catalog_batch_state={
                "updatedAt": "2026-06-23T02:00:00+00:00",
                "overallStatus": "WARN",
                "catalogRowCount": 344,
                "finalReadyCount": 15,
                "nextOffset": None,
                "failedOffset": None,
            },
            checked_at="2026-06-23T00:00:00+00:00",
        )

        self.assertIn(
            "Continue public ETF catalog batches with scripts\\00631l_public_etf_catalog_batches.cmd --start-offset 15 --batch-size 1 --max-batches 1 --soft-fail.",
            payload["actionItems"],
        )

    def test_includes_public_persistence_marker_summary(self) -> None:
        payload = build_public_maintenance_status(
            deploy_drift={"overallStatus": "PASS", "warnings": [], "failures": [], "summary": {}},
            public_status={
                "overallStatus": "WARN",
                "warnings": ["ETF history ready count below minimum 200: 16"],
                "failures": [],
                "summary": {
                    "etfHistoryReadyCount": 16,
                    "minEtfReadyCount": 200,
                    "persistenceMarkerCreatedAt": "2026-06-23T05:28:27+00:00",
                    "persistenceMarkerAgeSeconds": 90,
                    "persistenceMarkerNewlyCreated": True,
                },
            },
            freshness={
                "overallStatus": "WARN",
                "warnings": ["public backend ETF history ready count is lower"],
                "failures": [],
                "summary": {"publicEtfReadyLagVsStatic": 212},
            },
            catalog_batch_state={
                "updatedAt": "2026-06-23T05:31:30+00:00",
                "overallStatus": "PASS",
                "catalogRowCount": 343,
                "finalReadyCount": 16,
                "nextOffset": 17,
                "failedOffset": None,
            },
            checked_at="2026-06-23T00:00:00+00:00",
        )

        self.assertEqual(
            payload["summary"]["publicPersistenceMarkerCreatedAt"],
            "2026-06-23T05:28:27+00:00",
        )
        self.assertEqual(payload["summary"]["publicPersistenceMarkerAgeSeconds"], 90)
        self.assertTrue(payload["summary"]["publicPersistenceMarkerNewlyCreated"])
        self.assertTrue(
            any("persistence marker" in item for item in payload["warnings"])
        )
        self.assertIn(
            "Recheck public backend status after the next deploy; the persistence marker should keep the same createdAt.",
            payload["actionItems"],
        )

    def test_warns_when_public_ready_count_regresses_below_last_batch_state(self) -> None:
        payload = build_public_maintenance_status(
            deploy_drift={"overallStatus": "PASS", "warnings": [], "failures": [], "summary": {}},
            public_status={
                "overallStatus": "WARN",
                "warnings": ["ETF history ready count below minimum 200: 15"],
                "failures": [],
                "summary": {"etfHistoryReadyCount": 15, "minEtfReadyCount": 200},
            },
            freshness={"overallStatus": "PASS", "warnings": [], "failures": [], "summary": {}},
            catalog_batch_state={
                "updatedAt": "2026-06-23T02:00:00+00:00",
                "overallStatus": "WARN",
                "catalogRowCount": 344,
                "finalReadyCount": 27,
                "nextOffset": 25,
                "failedOffset": None,
            },
            checked_at="2026-06-23T00:00:00+00:00",
        )

        self.assertEqual(payload["summary"]["catalogBatchReadyRegression"], 12)
        self.assertIn(
            "Public ETF ready count regressed from the last batch state; check Render deploy persistence before running more batches.",
            payload["warnings"],
        )
        self.assertIn(
            "Check public backend persistent data volume and redeploy status before continuing ETF catalog batches.",
            payload["actionItems"],
        )

    def test_ready_count_regression_filters_upstream_catalog_batch_actions(self) -> None:
        payload = build_public_maintenance_status(
            deploy_drift={"overallStatus": "PASS", "warnings": [], "failures": [], "summary": {}},
            public_status={
                "overallStatus": "WARN",
                "warnings": ["ETF history ready count below minimum 200: 15"],
                "failures": [],
                "summary": {"etfHistoryReadyCount": 15, "minEtfReadyCount": 200},
            },
            freshness={
                "overallStatus": "WARN",
                "warnings": ["public backend ETF history ready count is lower"],
                "failures": [],
                "actionItems": [
                    "Run public ETF catalog batches: scripts\\00631l_public_etf_catalog_batches.cmd --batch-size 1 --max-batches 1 --soft-fail"
                ],
                "summary": {"publicEtfReadyLagVsStatic": 213},
            },
            catalog_batch_state={
                "updatedAt": "2026-06-23T02:00:00+00:00",
                "overallStatus": "PASS",
                "catalogRowCount": 343,
                "finalReadyCount": 17,
                "nextOffset": 18,
                "failedOffset": None,
            },
            checked_at="2026-06-23T00:00:00+00:00",
        )

        self.assertEqual(payload["summary"]["catalogBatchReadyRegression"], 2)
        self.assertIn(
            "Check public backend persistent data volume and redeploy status before continuing ETF catalog batches.",
            payload["actionItems"],
        )
        self.assertFalse(
            any("00631l_public_etf_catalog_batches" in item for item in payload["actionItems"])
        )

    def test_persistence_warning_blocks_catalog_batch_action_items(self) -> None:
        payload = build_public_maintenance_status(
            deploy_drift={"overallStatus": "PASS", "warnings": [], "failures": [], "summary": {}},
            public_status={
                "overallStatus": "WARN",
                "warnings": [
                    "ready: data_persistence: Data directory is not writable; history/report/export persistence may fail.",
                    "ETF history ready count below minimum 200: 15",
                ],
                "failures": [],
                "summary": {"etfHistoryReadyCount": 15, "minEtfReadyCount": 200},
            },
            freshness={
                "overallStatus": "WARN",
                "warnings": ["public backend ETF history ready count is lower"],
                "failures": [],
                "summary": {"publicEtfReadyLagVsStatic": 213},
            },
            catalog_batch_state={
                "updatedAt": "2026-06-23T02:00:00+00:00",
                "overallStatus": "FAIL",
                "catalogRowCount": 344,
                "finalReadyCount": 15,
                "nextOffset": 25,
                "failedOffset": 25,
            },
            checked_at="2026-06-23T00:00:00+00:00",
        )

        self.assertIn(
            "Fix public backend persistent data volume before running ETF catalog batches.",
            payload["actionItems"],
        )
        self.assertFalse(
            any("00631l_public_etf_catalog_batches" in item for item in payload["actionItems"])
        )

    def test_readiness_failure_blocks_catalog_batch_action_items(self) -> None:
        payload = build_public_maintenance_status(
            deploy_drift={"overallStatus": "PASS", "warnings": [], "failures": [], "summary": {}},
            public_status={
                "overallStatus": "WARN",
                "warnings": [],
                "failures": [],
                "summary": {
                    "readiness": "FAIL",
                    "etfHistoryReadyCount": 15,
                    "minEtfReadyCount": 200,
                },
            },
            freshness={
                "overallStatus": "WARN",
                "warnings": ["public backend ETF history ready count is lower"],
                "failures": [],
                "summary": {"publicEtfReadyLagVsStatic": 213},
            },
            catalog_batch_state={
                "updatedAt": "2026-06-23T02:00:00+00:00",
                "overallStatus": "FAIL",
                "catalogRowCount": 344,
                "finalReadyCount": 15,
                "nextOffset": 25,
                "failedOffset": 25,
            },
            checked_at="2026-06-23T00:00:00+00:00",
        )

        self.assertIn(
            "Fix public backend readiness before running ETF catalog batches.",
            payload["actionItems"],
        )
        self.assertFalse(
            any("00631l_public_etf_catalog_batches" in item for item in payload["actionItems"])
        )

    def test_readiness_probe_blocks_batch_when_status_sample_misses_ready_failure(self) -> None:
        payload = build_public_maintenance_status(
            deploy_drift={"overallStatus": "PASS", "warnings": [], "failures": [], "summary": {}},
            public_status={
                "overallStatus": "WARN",
                "warnings": ["ETF history ready count below minimum 200: 15"],
                "failures": [],
                "summary": {"etfHistoryReadyCount": 15, "minEtfReadyCount": 200},
            },
            freshness={
                "overallStatus": "WARN",
                "warnings": ["public backend ETF history ready count is lower"],
                "failures": [],
                "actionItems": [
                    "Run public ETF catalog batches: scripts\\00631l_public_etf_catalog_batches.cmd --batch-size 1 --max-batches 1 --soft-fail"
                ],
                "summary": {"publicEtfReadyLagVsStatic": 213},
            },
            readiness_probe={
                "overallStatus": "WARN",
                "warnings": ["ready sample 0: readiness FAIL"],
                "failures": [],
                "actionItems": [
                    "Fix public backend readiness before running ETF catalog batches."
                ],
            },
            catalog_batch_state={
                "updatedAt": "2026-06-23T02:00:00+00:00",
                "overallStatus": "WARN",
                "catalogRowCount": 343,
                "finalReadyCount": 15,
                "nextOffset": 16,
                "failedOffset": None,
            },
            checked_at="2026-06-23T00:00:00+00:00",
        )

        self.assertIn(
            "Fix public backend readiness before running ETF catalog batches.",
            payload["actionItems"],
        )
        self.assertFalse(
            any("00631l_public_etf_catalog_batches" in item for item in payload["actionItems"])
        )
        self.assertTrue(any("ready sample 0" in item for item in payload["warnings"]))


if __name__ == "__main__":
    unittest.main()
