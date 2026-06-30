import unittest

from backend.scripts.compare_public_data_freshness_00631l import (
    compare_public_data_freshness,
    run_public_data_freshness_check,
)


class PublicDataFreshnessTests(unittest.TestCase):
    def test_dry_run_lists_read_only_checks(self) -> None:
        payload = run_public_data_freshness_check(
            public_status={"overallStatus": "PASS", "summary": {}},
            local_status={},
            static_status={},
            dry_run=True,
        )

        self.assertEqual(payload["overallStatus"], "PASS")
        self.assertTrue(payload["dryRun"])
        names = {step["name"] for step in payload["steps"]}
        self.assertIn("public_backend_status", names)
        self.assertIn("local_price_history_status", names)
        self.assertIn("static_public_status", names)

    def test_warns_when_public_backend_lags_local_history(self) -> None:
        payload = compare_public_data_freshness(
            public_status={
                "overallStatus": "PASS",
                "summary": {
                    "priceHistoryRows": 2829,
                    "priceHistoryCoverageStart": "2014-10-31",
                    "priceHistoryCoverageEnd": "2026-06-15",
                    "etfHistoryReadyCount": 15,
                },
            },
            local_status={
                "rowCount": 2833,
                "coverageStart": "2014-10-31",
                "coverageEnd": "2026-06-22",
                "sourceStatus": "cached",
            },
            static_status={
                "rowCount": 2832,
                "coverageStart": "2014-10-31",
                "coverageEnd": "2026-06-18",
                "etfPriceHistoryReadyCount": 228,
                "sourceStatus": "static_official",
            },
            checked_at="2026-06-22T14:00:00+00:00",
            max_coverage_lag_days=3,
        )

        self.assertEqual(payload["overallStatus"], "WARN")
        self.assertEqual(payload["failures"], [])
        self.assertEqual(payload["summary"]["publicCoverageLagDaysVsLocal"], 7)
        self.assertTrue(
            any("remote maintenance" in item for item in payload["actionItems"])
        )
        self.assertTrue(
            any("00631l_public_etf_catalog_batches.cmd" in item for item in payload["actionItems"])
        )
        self.assertTrue(
            any("--batch-size 1 --max-batches 1" in item for item in payload["actionItems"])
        )

    def test_passes_when_public_static_and_local_are_aligned(self) -> None:
        public = {
            "overallStatus": "PASS",
            "summary": {
                "priceHistoryRows": 2833,
                "priceHistoryCoverageStart": "2014-10-31",
                "priceHistoryCoverageEnd": "2026-06-22",
                "catalogRowCount": 228,
                "etfHistoryReadyCount": 228,
                "etfHistoryCatalogGapCount": 0,
            },
        }
        status = {
            "rowCount": 2833,
            "coverageStart": "2014-10-31",
            "coverageEnd": "2026-06-22",
            "sourceStatus": "cached",
        }
        payload = compare_public_data_freshness(
            public_status=public,
            local_status=status,
            static_status={**status, "etfPriceHistoryReadyCount": 228},
            checked_at="2026-06-22T14:00:00+00:00",
        )

        self.assertEqual(payload["overallStatus"], "PASS")
        self.assertEqual(payload["warnings"], [])
        self.assertEqual(payload["failures"], [])
        self.assertEqual(payload["summary"]["publicCatalogRowCount"], 228)
        self.assertEqual(payload["summary"]["publicEtfCatalogGapCount"], 0)

    def test_passes_when_only_public_backend_has_non_data_warning(self) -> None:
        public = {
            "overallStatus": "WARN",
            "summary": {
                "priceHistoryRows": 2833,
                "priceHistoryCoverageStart": "2014-10-31",
                "priceHistoryCoverageEnd": "2026-06-22",
                "catalogRowCount": 228,
                "etfHistoryReadyCount": 228,
                "etfHistoryCatalogGapCount": 0,
            },
        }
        status = {
            "rowCount": 2833,
            "coverageStart": "2014-10-31",
            "coverageEnd": "2026-06-22",
            "sourceStatus": "cached",
        }

        payload = compare_public_data_freshness(
            public_status=public,
            local_status=status,
            static_status={
                **status,
                "etfCatalogRowCount": 228,
                "etfPriceHistoryReadyCount": 228,
            },
            checked_at="2026-06-22T14:00:00+00:00",
        )

        self.assertEqual(payload["overallStatus"], "PASS")
        self.assertEqual(payload["warnings"], [])
        self.assertEqual(payload["failures"], [])
        self.assertEqual(payload["summary"]["publicBackendOverallStatus"], "WARN")

    def test_warns_when_public_catalog_has_unsaved_history_rows(self) -> None:
        public = {
            "overallStatus": "PASS",
            "summary": {
                "priceHistoryRows": 2833,
                "priceHistoryCoverageStart": "2014-10-31",
                "priceHistoryCoverageEnd": "2026-06-22",
                "catalogRowCount": 347,
                "etfHistoryReadyCount": 346,
                "etfHistoryCatalogGapCount": 1,
            },
        }
        status = {
            "rowCount": 2833,
            "coverageStart": "2014-10-31",
            "coverageEnd": "2026-06-22",
            "sourceStatus": "cached",
        }

        payload = compare_public_data_freshness(
            public_status=public,
            local_status=status,
            static_status={
                **status,
                "etfCatalogRowCount": 347,
                "etfPriceHistoryReadyCount": 347,
            },
            checked_at="2026-06-22T14:00:00+00:00",
        )

        self.assertEqual(payload["overallStatus"], "WARN")
        self.assertEqual(payload["summary"]["publicCatalogRowCount"], 347)
        self.assertEqual(payload["summary"]["publicEtfCatalogGapCount"], 1)
        self.assertTrue(
            any(
                "/api/etf/history/gaps?fromCatalog=true" in item
                for item in payload["actionItems"]
            )
        )


if __name__ == "__main__":
    unittest.main()
