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
                    "etfPriceHistoryRowCount": 347,
                    "etfPriceHistoryReadyCount": 230,
                    "etfPriceHistoryMissingCount": 117,
                    "etfPriceHistoryAttemptedCount": 4,
                    "etfPriceHistoryCoverageTierCounts": {
                        "long_term": 8,
                        "recent": 222,
                    },
                    "etfPriceHistoryGapReasonCounts": {
                        "official_empty": 4,
                        "not_saved": 113,
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
        self.assertEqual(payload["etfPriceHistoryRowCount"], 347)
        self.assertEqual(payload["etfPriceHistoryReadyCount"], 230)
        self.assertEqual(payload["etfPriceHistoryMissingCount"], 117)
        self.assertEqual(payload["etfPriceHistoryCompletionTotal"], 347)
        self.assertEqual(payload["etfPriceHistoryCompletionGap"], 117)
        self.assertEqual(payload["etfPriceHistoryAttemptedCount"], 4)
        self.assertEqual(payload["etfPriceHistoryUnclassifiedGapCount"], 113)
        self.assertEqual(payload["etfPriceHistoryGapReasonCounts"]["official_empty"], 4)
        self.assertEqual(payload["etfPriceHistoryGapReasonCounts"]["not_saved"], 113)
        self.assertEqual(payload["releaseTag"], "00631l-lab-v5.83-pages-missing-batch")
        self.assertEqual(payload["failures"], [])

    def test_warns_when_history_index_exceeds_catalog_snapshot(self) -> None:
        def fetch_json(url: str) -> dict[str, object]:
            if url.endswith("status.json"):
                return {"sourceStatus": "static_official", "rowCount": 2837}
            if url.endswith("manifest.json"):
                return {
                    "etfCatalogRowCount": 343,
                    "etfPriceHistoryRowCount": 345,
                    "etfPriceHistoryReadyCount": 231,
                    "etfPriceHistoryMissingCount": 114,
                }
            if url.endswith("release.json"):
                return {
                    "releaseTag": "00631l-lab-v5.97-pages-missing-probe",
                    "gitSha": "d0e87eb",
                }
            raise AssertionError(url)

        payload = run_public_static_data_check(
            "https://example.test/static",
            fetch_json=fetch_json,
        )

        self.assertEqual(payload["overallStatus"], "WARN")
        self.assertEqual(payload["etfPriceHistoryCompletionTotal"], 345)
        self.assertEqual(payload["etfPriceHistoryCompletionGap"], 114)
        self.assertTrue(any("history=345" in item for item in payload["warnings"]))

    def test_unclassified_gap_count_is_zero_when_not_saved_is_clear(self) -> None:
        def fetch_json(url: str) -> dict[str, object]:
            if url.endswith("status.json"):
                return {"sourceStatus": "static_official", "rowCount": 2837}
            if url.endswith("manifest.json"):
                return {
                    "etfCatalogRowCount": 347,
                    "etfPriceHistoryRowCount": 347,
                    "etfPriceHistoryReadyCount": 231,
                    "etfPriceHistoryMissingCount": 116,
                    "etfPriceHistoryAttemptedCount": 116,
                    "etfPriceHistoryGapReasonCounts": {
                        "official_empty": 96,
                        "source_error": 20,
                    },
                }
            if url.endswith("release.json"):
                return {
                    "releaseTag": "00631l-lab-v6.2-public-unclassified-gap",
                    "gitSha": "abc123",
                }
            raise AssertionError(url)

        payload = run_public_static_data_check(
            "https://example.test/static",
            fetch_json=fetch_json,
        )

        self.assertEqual(payload["overallStatus"], "PASS")
        self.assertEqual(payload["etfPriceHistoryUnclassifiedGapCount"], 0)

    def test_warns_when_unclassified_gap_exceeds_target(self) -> None:
        def fetch_json(url: str) -> dict[str, object]:
            if url.endswith("status.json"):
                return {"sourceStatus": "static_official", "rowCount": 2837}
            if url.endswith("manifest.json"):
                return {
                    "etfCatalogRowCount": 347,
                    "etfPriceHistoryRowCount": 347,
                    "etfPriceHistoryReadyCount": 231,
                    "etfPriceHistoryMissingCount": 116,
                    "etfPriceHistoryAttemptedCount": 114,
                    "etfPriceHistoryGapReasonCounts": {
                        "official_empty": 94,
                        "source_error": 20,
                        "not_saved": 2,
                    },
                }
            if url.endswith("release.json"):
                return {
                    "releaseTag": "00631l-lab-v6.2-public-unclassified-gap",
                    "gitSha": "abc123",
                }
            raise AssertionError(url)

        payload = run_public_static_data_check(
            "https://example.test/static",
            fetch_json=fetch_json,
            max_unclassified_gap=0,
        )

        self.assertEqual(payload["overallStatus"], "WARN")
        self.assertEqual(payload["expectedMaxUnclassifiedGap"], 0)
        self.assertTrue(any("unclassified gap" in item for item in payload["warnings"]))

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
