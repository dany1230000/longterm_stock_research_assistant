import unittest

from backend.scripts.public_history_stability_00631l import (
    build_public_history_stability_status,
)


class PublicHistoryStabilityTests(unittest.TestCase):
    def test_warns_when_ready_count_regresses_between_samples(self) -> None:
        payload = build_public_history_stability_status(
            base_url="https://example.com",
            checked_at="2026-06-23T03:00:00+00:00",
            samples=[
                {"status": "PASS", "readyCount": 20, "rowCount": 20},
                {"status": "PASS", "readyCount": 15, "rowCount": 15},
            ],
        )

        self.assertEqual(payload["overallStatus"], "WARN")
        self.assertEqual(payload["summary"]["readyCountRegression"], 5)
        self.assertIn(
            "Public ETF ready count decreased between samples; check persistent data volume and redeploy status.",
            payload["warnings"],
        )
        self.assertTrue(
            any("persistent data volume" in item for item in payload["actionItems"])
        )

    def test_passes_when_ready_count_is_stable_or_increases(self) -> None:
        payload = build_public_history_stability_status(
            base_url="https://example.com",
            checked_at="2026-06-23T03:00:00+00:00",
            samples=[
                {"status": "PASS", "readyCount": 15, "rowCount": 15},
                {"status": "PASS", "readyCount": 17, "rowCount": 17},
            ],
        )

        self.assertEqual(payload["overallStatus"], "PASS")
        self.assertEqual(payload["summary"]["readyCountRegression"], 0)
        self.assertEqual(payload["warnings"], [])
        self.assertEqual(payload["failures"], [])

    def test_failure_sample_returns_warn_without_crashing(self) -> None:
        payload = build_public_history_stability_status(
            base_url="https://example.com",
            checked_at="2026-06-23T03:00:00+00:00",
            samples=[
                {"status": "PASS", "readyCount": 15, "rowCount": 15},
                {"status": "FAIL", "message": "HTTP 502"},
            ],
        )

        self.assertEqual(payload["overallStatus"], "WARN")
        self.assertEqual(payload["failureCount"], 0)
        self.assertTrue(payload["warnings"])


if __name__ == "__main__":
    unittest.main()
