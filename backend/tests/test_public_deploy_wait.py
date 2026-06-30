import unittest

from backend.scripts.wait_public_deploy_00631l import build_public_deploy_wait_status


class PublicDeployWaitTests(unittest.TestCase):
    def test_passes_when_a_later_sample_matches_expected_release_tag(self) -> None:
        payload = build_public_deploy_wait_status(
            base_url="https://example.com",
            checked_at="2026-06-23T04:00:00+00:00",
            expected_release_tag="00631l-lab-v4.78-public-deploy-wait",
            samples=[
                {
                    "overallStatus": "WARN",
                    "summary": {
                        "publicReleaseTag": "00631l-lab-v4.77-deploy-drift-gitsha-noise",
                        "expectedReleaseTag": "00631l-lab-v4.78-public-deploy-wait",
                    },
                    "warnings": ["release tag differs"],
                    "failures": [],
                },
                {
                    "overallStatus": "PASS",
                    "summary": {
                        "publicReleaseTag": "00631l-lab-v4.78-public-deploy-wait",
                        "expectedReleaseTag": "00631l-lab-v4.78-public-deploy-wait",
                    },
                    "warnings": [],
                    "failures": [],
                },
            ],
        )

        self.assertEqual(payload["overallStatus"], "PASS")
        self.assertEqual(payload["summary"]["matchedReleaseTag"], True)
        self.assertEqual(payload["summary"]["sampleCount"], 2)
        self.assertEqual(payload["warnings"], [])
        self.assertEqual(payload["summary"]["freshness"], {})

    def test_warns_when_expected_release_tag_never_matches(self) -> None:
        payload = build_public_deploy_wait_status(
            base_url="https://example.com",
            checked_at="2026-06-23T04:00:00+00:00",
            expected_release_tag="00631l-lab-v4.78-public-deploy-wait",
            samples=[
                {
                    "overallStatus": "WARN",
                    "summary": {
                        "publicReleaseTag": "00631l-lab-v4.77-deploy-drift-gitsha-noise",
                        "expectedReleaseTag": "00631l-lab-v4.78-public-deploy-wait",
                    },
                    "warnings": ["release tag differs"],
                    "failures": [],
                }
            ],
        )

        self.assertEqual(payload["overallStatus"], "WARN")
        self.assertEqual(payload["summary"]["matchedReleaseTag"], False)
        self.assertTrue(payload["warnings"])
        self.assertTrue(any("public backend deploy" in item for item in payload["actionItems"]))

    def test_warns_when_release_matches_but_public_data_is_stale(self) -> None:
        payload = build_public_deploy_wait_status(
            base_url="https://example.com",
            checked_at="2026-06-23T04:00:00+00:00",
            expected_release_tag="00631l-lab-v9.53-post-deploy-freshness",
            samples=[
                {
                    "overallStatus": "PASS",
                    "summary": {
                        "publicReleaseTag": "00631l-lab-v9.53-post-deploy-freshness",
                        "expectedReleaseTag": "00631l-lab-v9.53-post-deploy-freshness",
                    },
                    "warnings": [],
                    "failures": [],
                }
            ],
            freshness_status={
                "overallStatus": "WARN",
                "summary": {
                    "publicCoverageEnd": "2026-06-26",
                    "localCoverageEnd": "2026-06-30",
                    "staticCoverageEnd": "2026-06-30",
                    "publicCoverageLagDaysVsStatic": 4,
                    "publicCatalogRowCount": 343,
                    "staticCatalogRowCount": 347,
                    "publicEtfHistoryReadyCount": 346,
                    "staticEtfHistoryReadyCount": 347,
                    "publicEtfCatalogGapCount": 0,
                },
                "warnings": ["public backend lags static data"],
                "failures": [],
                "actionItems": [
                    "Run remote maintenance: scripts\\00631l_remote_maintenance.cmd --mode daily"
                ],
            },
        )

        self.assertEqual(payload["overallStatus"], "WARN")
        self.assertEqual(payload["summary"]["matchedReleaseTag"], True)
        self.assertEqual(payload["summary"]["freshness"]["overallStatus"], "WARN")
        self.assertEqual(
            payload["summary"]["freshness"]["publicCoverageLagDaysVsStatic"],
            4,
        )
        self.assertTrue(
            any("remote maintenance" in item for item in payload["actionItems"])
        )


if __name__ == "__main__":
    unittest.main()
