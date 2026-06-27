import unittest

from backend.scripts.guard_static_public_regression_00631l import (
    run_static_public_regression_guard,
)


class StaticPublicRegressionGuardTests(unittest.TestCase):
    def test_newer_local_static_data_passes(self) -> None:
        payload = run_static_public_regression_guard(
            local_dir="unused",
            local_status=_status("2026-06-26", 2837, 231),
            remote_status=_status("2026-06-24", 2835, 230),
        )

        self.assertEqual(payload["overallStatus"], "PASS")
        self.assertEqual(payload["failures"], [])

    def test_older_local_coverage_fails(self) -> None:
        payload = run_static_public_regression_guard(
            local_dir="unused",
            local_status=_status("2026-06-24", 2835, 231),
            remote_status=_status("2026-06-26", 2837, 231),
        )

        self.assertEqual(payload["overallStatus"], "FAIL")
        self.assertIn("localCoverageEnd 2026-06-24 is older", payload["failures"][0])

    def test_same_date_lower_rows_fails(self) -> None:
        payload = run_static_public_regression_guard(
            local_dir="unused",
            local_status=_status("2026-06-26", 2835, 231),
            remote_status=_status("2026-06-26", 2837, 231),
        )

        self.assertEqual(payload["overallStatus"], "FAIL")
        self.assertIn("local rowCount 2835 is lower", payload["failures"][0])

    def test_lower_etf_ready_count_fails(self) -> None:
        payload = run_static_public_regression_guard(
            local_dir="unused",
            local_status=_status("2026-06-26", 2837, 230),
            remote_status=_status("2026-06-26", 2837, 231),
        )

        self.assertEqual(payload["overallStatus"], "FAIL")
        self.assertIn("local ETF ready count 230 is lower", payload["failures"][0])


def _status(coverage_end: str, row_count: int, etf_ready: int):
    return {
        "coverageStart": "2014-10-31",
        "coverageEnd": coverage_end,
        "rowCount": row_count,
        "etfPriceHistoryReadyCount": etf_ready,
        "release": {
            "releaseTag": "test",
            "gitSha": "abc123",
        },
    }


if __name__ == "__main__":
    unittest.main()
