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
