import unittest

from backend.scripts.verify_public_persistence_00631l import (
    build_public_persistence_verifier_status,
)


class PublicPersistenceVerifierTests(unittest.TestCase):
    def test_passes_when_marker_is_stable_old_and_ready_count_is_high(self) -> None:
        payload = build_public_persistence_verifier_status(
            base_url="https://example.com",
            checked_at="2026-06-23T07:00:00+00:00",
            samples=[
                {
                    "status": "PASS",
                    "markerCreatedAt": "2026-06-23T06:00:00+00:00",
                    "markerFresh": False,
                    "markerAgeSeconds": 3600,
                    "etfReadyCount": 220,
                },
                {
                    "status": "PASS",
                    "markerCreatedAt": "2026-06-23T06:00:00+00:00",
                    "markerFresh": False,
                    "markerAgeSeconds": 3630,
                    "etfReadyCount": 221,
                },
            ],
            min_marker_age_seconds=900,
            min_etf_ready_count=200,
        )

        self.assertEqual(payload["overallStatus"], "PASS")
        self.assertEqual(payload["warnings"], [])
        self.assertEqual(payload["failures"], [])
        self.assertTrue(payload["summary"]["markerCreatedAtStable"])

    def test_warns_when_marker_is_fresh(self) -> None:
        payload = build_public_persistence_verifier_status(
            base_url="https://example.com",
            checked_at="2026-06-23T07:00:00+00:00",
            samples=[
                {
                    "status": "PASS",
                    "markerCreatedAt": "2026-06-23T06:55:00+00:00",
                    "markerFresh": True,
                    "markerAgeSeconds": 300,
                    "etfReadyCount": 15,
                },
            ],
            min_marker_age_seconds=900,
            min_etf_ready_count=200,
        )

        self.assertEqual(payload["overallStatus"], "WARN")
        self.assertIn("Public persistence marker is still fresh.", payload["warnings"])
        self.assertTrue(
            any("ETF catalog batches" in item for item in payload["actionItems"])
        )

    def test_warns_when_marker_created_at_changes(self) -> None:
        payload = build_public_persistence_verifier_status(
            base_url="https://example.com",
            checked_at="2026-06-23T07:00:00+00:00",
            samples=[
                {
                    "status": "PASS",
                    "markerCreatedAt": "2026-06-23T06:00:00+00:00",
                    "markerFresh": False,
                    "markerAgeSeconds": 3600,
                    "etfReadyCount": 220,
                },
                {
                    "status": "PASS",
                    "markerCreatedAt": "2026-06-23T06:10:00+00:00",
                    "markerFresh": False,
                    "markerAgeSeconds": 3000,
                    "etfReadyCount": 220,
                },
            ],
            min_marker_age_seconds=900,
            min_etf_ready_count=200,
        )

        self.assertEqual(payload["overallStatus"], "WARN")
        self.assertFalse(payload["summary"]["markerCreatedAtStable"])
        self.assertIn(
            "Public persistence marker createdAt changed between samples.",
            payload["warnings"],
        )

    def test_failed_sample_returns_fail(self) -> None:
        payload = build_public_persistence_verifier_status(
            base_url="https://example.com",
            checked_at="2026-06-23T07:00:00+00:00",
            samples=[{"status": "FAIL", "message": "HTTP 502"}],
            min_marker_age_seconds=900,
            min_etf_ready_count=200,
        )

        self.assertEqual(payload["overallStatus"], "FAIL")
        self.assertEqual(payload["failureCount"], 1)
        self.assertTrue(payload["actionItems"])

    def test_dry_run_does_not_apply_ready_count_floor(self) -> None:
        payload = build_public_persistence_verifier_status(
            base_url="https://example.com",
            checked_at="2026-06-23T07:00:00+00:00",
            dry_run=True,
            samples=[
                {
                    "status": "PASS",
                    "markerCreatedAt": None,
                    "markerFresh": False,
                    "markerAgeSeconds": None,
                    "etfReadyCount": 0,
                },
            ],
            min_marker_age_seconds=900,
            min_etf_ready_count=200,
        )

        self.assertEqual(payload["overallStatus"], "PASS")
        self.assertEqual(payload["warnings"], [])


if __name__ == "__main__":
    unittest.main()
