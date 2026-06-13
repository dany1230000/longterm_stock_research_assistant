from datetime import datetime, timedelta, timezone
import unittest

from backend.scripts.smoke_00631l_live import _assess_overall


TAIPEI_TZ = timezone(timedelta(hours=8))


class SmokeLiveTests(unittest.TestCase):
    def test_basic_maintenance_is_warning_when_other_sources_are_usable(self) -> None:
        now = datetime.now(TAIPEI_TZ).replace(microsecond=0)
        payload = _assess_overall(
            {
                "yuanta_basic": {
                    "parseSuccess": False,
                    "sourceStatus": "unavailable",
                    "errorMessage": "Yuanta official page is in maintenance mode",
                },
                "yuanta_ratio": {
                    "parseSuccess": True,
                    "sourceStatus": "cached",
                    "errorMessage": "holdings live source unavailable; using cached local history",
                    "parsedTradeDate": now.date().isoformat(),
                },
                "intraday_nav": {
                    "parseSuccess": True,
                    "sourceStatus": "official",
                    "sourceContract": "twse_a_k_json",
                    "cacheStatus": "not_used_direct_fetch",
                    "marketPrice": 34.83,
                    "estimatedNav": 34.97,
                    "premiumDiscountPct": -0.4,
                    "dataTime": now.isoformat(),
                    "fetchedAt": now.isoformat(),
                },
            }
        )

        self.assertEqual(payload["overallStatus"], "WARN")
        self.assertEqual(payload["failures"], [])
        self.assertTrue(any("Basic source unavailable" in item for item in payload["warnings"]))


if __name__ == "__main__":
    unittest.main()
