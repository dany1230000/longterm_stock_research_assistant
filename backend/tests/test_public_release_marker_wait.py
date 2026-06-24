import unittest

from backend.scripts.wait_public_release_marker_00631l import (
    run_public_release_marker_wait,
)


class PublicReleaseMarkerWaitTests(unittest.TestCase):
    def test_wait_passes_when_release_marker_matches_expected_sha(self) -> None:
        payload = run_public_release_marker_wait(
            expected_sha="abc123",
            attempts=2,
            interval_seconds=0,
            checker=lambda **kwargs: _public_pages("abc123fff"),
        )

        self.assertEqual(payload["overallStatus"], "PASS")
        self.assertEqual(payload["failureCount"], 0)
        self.assertTrue(payload["summary"]["matchedExpectedSha"])
        self.assertEqual(payload["summary"]["latestReleaseGitSha"], "abc123fff")

    def test_wait_warns_when_release_marker_still_points_to_previous_commit(self) -> None:
        payload = run_public_release_marker_wait(
            expected_sha="new456",
            attempts=2,
            interval_seconds=0,
            checker=lambda **kwargs: _public_pages("old123fff", status="WARN"),
        )

        self.assertEqual(payload["overallStatus"], "WARN")
        self.assertEqual(payload["failureCount"], 0)
        self.assertFalse(payload["summary"]["matchedExpectedSha"])
        self.assertTrue(payload["actionItems"])

    def test_wait_retries_until_release_marker_matches(self) -> None:
        calls: list[int] = []

        def checker(**kwargs) -> dict:
            calls.append(1)
            return _public_pages("old123fff" if len(calls) == 1 else "new456fff")

        payload = run_public_release_marker_wait(
            expected_sha="new456",
            attempts=3,
            interval_seconds=0,
            checker=checker,
        )

        self.assertEqual(payload["overallStatus"], "PASS")
        self.assertEqual(len(calls), 2)
        self.assertEqual(payload["summary"]["sampleCount"], 2)

    def test_wait_fails_when_public_pages_smoke_fails(self) -> None:
        payload = run_public_release_marker_wait(
            expected_sha="abc123",
            attempts=1,
            interval_seconds=0,
            checker=lambda **kwargs: _public_pages(
                "abc123fff",
                status="FAIL",
                failures=["static payload invalid"],
            ),
        )

        self.assertEqual(payload["overallStatus"], "FAIL")
        self.assertGreater(payload["failureCount"], 0)

    def test_wait_dry_run_is_pass(self) -> None:
        payload = run_public_release_marker_wait(
            expected_sha="abc123",
            dry_run=True,
        )

        self.assertEqual(payload["overallStatus"], "PASS")
        self.assertTrue(payload["dryRun"])


def _public_pages(
    release_sha: str,
    *,
    status: str = "PASS",
    failures: list[str] | None = None,
) -> dict:
    return {
        "overallStatus": status,
        "rowCount": 2835,
        "coverageStart": "2014-10-31",
        "coverageEnd": "2026-06-24",
        "releaseTag": "00631l-lab-v5.42-public-release-wait",
        "releaseGitSha": release_sha,
        "releaseAppVersion": "5.42-public-release-wait",
        "warnings": [] if status == "PASS" else ["public release SHA differs"],
        "failures": failures or [],
    }


if __name__ == "__main__":
    unittest.main()
