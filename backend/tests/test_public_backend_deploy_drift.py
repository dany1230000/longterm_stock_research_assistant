import os
import unittest
from unittest.mock import patch

from backend.scripts.check_public_deploy_drift_00631l import (
    check_public_backend_deploy_drift,
    resolve_expected_release_tag,
)


class PublicBackendDeployDriftTests(unittest.TestCase):
    def test_warns_when_public_release_tag_is_behind_expected(self) -> None:
        payload = check_public_backend_deploy_drift(
            public_status={
                "overallStatus": "PASS",
                "baseUrl": "https://example.com",
                "summary": {
                    "backendVersion": "4.60-catalog-seed-fallback",
                    "releaseTag": "00631l-lab-v4.60-catalog-seed-fallback",
                    "gitSha": "oldsha",
                },
            },
            expected_release_tag="00631l-lab-v4.63-public-deploy-drift",
            expected_git_sha="newsha",
            checked_at="2026-06-23T00:00:00+00:00",
        )

        self.assertEqual(payload["overallStatus"], "WARN")
        self.assertEqual(payload["failures"], [])
        self.assertEqual(
            payload["summary"]["publicReleaseTag"],
            "00631l-lab-v4.60-catalog-seed-fallback",
        )
        self.assertEqual(
            payload["summary"]["expectedReleaseTag"],
            "00631l-lab-v4.63-public-deploy-drift",
        )
        self.assertTrue(
            any("release tag differs" in item for item in payload["warnings"])
        )
        self.assertTrue(
            any("redeploy" in item.lower() for item in payload["actionItems"])
        )

    def test_passes_when_public_release_matches_expected(self) -> None:
        payload = check_public_backend_deploy_drift(
            public_status={
                "overallStatus": "PASS",
                "baseUrl": "https://example.com",
                "summary": {
                    "backendVersion": "4.63-public-deploy-drift",
                    "releaseTag": "00631l-lab-v4.63-public-deploy-drift",
                    "gitSha": "abc123",
                },
            },
            expected_release_tag="00631l-lab-v4.63-public-deploy-drift",
            expected_git_sha="abc123",
            checked_at="2026-06-23T00:00:00+00:00",
        )

        self.assertEqual(payload["overallStatus"], "PASS")
        self.assertEqual(payload["warnings"], [])
        self.assertEqual(payload["failures"], [])

    def test_passes_when_release_tag_matches_and_public_git_sha_missing(self) -> None:
        payload = check_public_backend_deploy_drift(
            public_status={
                "overallStatus": "PASS",
                "baseUrl": "https://example.com",
                "summary": {
                    "backendVersion": "4.76-public-history-stability",
                    "releaseTag": "00631l-lab-v4.76-public-history-stability",
                    "gitSha": "",
                },
            },
            expected_release_tag="00631l-lab-v4.76-public-history-stability",
            expected_git_sha="abc123",
            checked_at="2026-06-23T00:00:00+00:00",
        )

        self.assertEqual(payload["overallStatus"], "PASS")
        self.assertEqual(payload["warnings"], [])
        self.assertEqual(payload["failures"], [])
        self.assertEqual(payload["summary"]["publicGitShaStatus"], "missing")

    def test_expected_release_tag_prefers_exact_head_tag(self) -> None:
        with patch.dict(
            os.environ,
            {"EXPECTED_00631L_RELEASE_TAG": ""},
            clear=False,
        ):
            with patch(
                "backend.scripts.check_public_deploy_drift_00631l._git_exact_release_tag",
                return_value="00631l-lab-v9.48-public-backend-drift-tag",
            ):
                self.assertEqual(
                    resolve_expected_release_tag(),
                    "00631l-lab-v9.48-public-backend-drift-tag",
                )

    def test_fails_when_public_status_check_failed(self) -> None:
        payload = check_public_backend_deploy_drift(
            public_status={
                "overallStatus": "FAIL",
                "baseUrl": "https://example.com",
                "summary": {},
                "failures": ["health: HTTP 502"],
            },
            expected_release_tag="00631l-lab-v4.63-public-deploy-drift",
            checked_at="2026-06-23T00:00:00+00:00",
        )

        self.assertEqual(payload["overallStatus"], "FAIL")
        self.assertTrue(payload["failures"])


if __name__ == "__main__":
    unittest.main()
