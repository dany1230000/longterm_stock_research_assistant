import unittest

from backend.scripts.check_public_static_data_00631l import (
    run_public_static_data_check,
)


class PublicStaticDataCheckTests(unittest.TestCase):
    def test_merges_status_manifest_and_release_metadata(self) -> None:
        def fetch_json(url: str) -> dict[str, object]:
            if url.endswith("status.json"):
                return {
                    "sourceStatus": "static_official",
                    "rowCount": 2837,
                    "coverageStart": "2014-10-31",
                    "coverageEnd": "2026-06-26",
                }
            if url.endswith("manifest.json"):
                return {
                    "etfCatalogRowCount": 347,
                    "etfPriceHistoryReadyCount": 230,
                    "etfPriceHistoryMissingCount": 117,
                    "etfPriceHistoryCoverageTierCounts": {
                        "long_term": 8,
                        "recent": 222,
                    },
                }
            if url.endswith("release.json"):
                return {
                    "releaseTag": "00631l-lab-v5.83-pages-missing-batch",
                    "appVersion": "5.83-pages-missing-batch",
                    "gitSha": "180fd42",
                }
            raise AssertionError(url)

        payload = run_public_static_data_check(
            "https://example.test/static",
            fetch_json=fetch_json,
        )

        self.assertEqual(payload["overallStatus"], "PASS")
        self.assertEqual(payload["sourceStatus"], "static_official")
        self.assertEqual(payload["rowCount"], 2837)
        self.assertEqual(payload["etfCatalogRowCount"], 347)
        self.assertEqual(payload["etfPriceHistoryReadyCount"], 230)
        self.assertEqual(payload["etfPriceHistoryMissingCount"], 117)
        self.assertEqual(payload["releaseTag"], "00631l-lab-v5.83-pages-missing-batch")
        self.assertEqual(payload["failures"], [])

    def test_expected_release_mismatch_is_warning_by_default(self) -> None:
        def fetch_json(url: str) -> dict[str, object]:
            if url.endswith("status.json"):
                return {"sourceStatus": "static_official", "rowCount": 2837}
            if url.endswith("manifest.json"):
                return {
                    "etfCatalogRowCount": 347,
                    "etfPriceHistoryReadyCount": 230,
                }
            if url.endswith("release.json"):
                return {
                    "releaseTag": "00631l-lab-v5.83-pages-missing-batch",
                    "gitSha": "180fd42f0863d84de7d1f97060a8c566c19c7fdc",
                }
            raise AssertionError(url)

        payload = run_public_static_data_check(
            "https://example.test/static",
            fetch_json=fetch_json,
            expected_release_tag="00631l-lab-v5.84-public-static-check",
            expected_sha="cccc52b",
        )

        self.assertEqual(payload["overallStatus"], "WARN")
        self.assertFalse(payload["releaseMatchesExpected"])
        self.assertEqual(payload["failures"], [])
        self.assertTrue(any("releaseTag" in item for item in payload["warnings"]))
        self.assertTrue(any("gitSha" in item for item in payload["warnings"]))

    def test_expected_release_mismatch_can_be_strict_failure(self) -> None:
        def fetch_json(url: str) -> dict[str, object]:
            if url.endswith("status.json"):
                return {"sourceStatus": "static_official", "rowCount": 2837}
            if url.endswith("manifest.json"):
                return {
                    "etfCatalogRowCount": 347,
                    "etfPriceHistoryReadyCount": 230,
                }
            if url.endswith("release.json"):
                return {
                    "releaseTag": "00631l-lab-v5.83-pages-missing-batch",
                    "gitSha": "180fd42f0863d84de7d1f97060a8c566c19c7fdc",
                }
            raise AssertionError(url)

        payload = run_public_static_data_check(
            "https://example.test/static",
            fetch_json=fetch_json,
            expected_release_tag="00631l-lab-v5.84-public-static-check",
            strict_release=True,
        )

        self.assertEqual(payload["overallStatus"], "FAIL")
        self.assertFalse(payload["releaseMatchesExpected"])
        self.assertTrue(any("releaseTag" in item for item in payload["failures"]))

    def test_reports_missing_manifest_as_failure(self) -> None:
        def fetch_json(url: str) -> dict[str, object]:
            if url.endswith("status.json"):
                return {"sourceStatus": "static_official", "rowCount": 2837}
            raise RuntimeError("not found")

        payload = run_public_static_data_check(
            "https://example.test/static",
            fetch_json=fetch_json,
        )

        self.assertEqual(payload["overallStatus"], "FAIL")
        self.assertTrue(any("manifest.json" in item for item in payload["failures"]))


if __name__ == "__main__":
    unittest.main()
