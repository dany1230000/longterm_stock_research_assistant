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


if __name__ == "__main__":
    unittest.main()
