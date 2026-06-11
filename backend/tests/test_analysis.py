import unittest

from backend.app.analysis import RuleBasedAnalysisProvider
from backend.scripts.release_check_00631l import FORBIDDEN_TERMS


class RuleBasedAnalysisTests(unittest.TestCase):
    def test_rule_based_summary_handles_complete_context(self) -> None:
        payload = RuleBasedAnalysisProvider().summarize(_context())

        self.assertEqual(payload["source"], "rule_based")
        self.assertEqual(payload["sourceStatus"], "cached")
        self.assertEqual(payload["readinessLevel"], "ready")
        self.assertEqual(payload["disclaimer"], "非買賣建議")
        self.assertGreaterEqual(len(payload["bullets"]), 3)
        self.assertIn("official", payload["sourceStatuses"]["holdingsHistory"])
        self.assertEqual(payload["actionItems"], ["目前沒有必要的程式操作；請持續確認官方資料時間。"])

    def test_rule_based_summary_returns_actions_when_data_is_missing(self) -> None:
        context = _context()
        context["operations"]["config"]["missingKeys"] = ["backend/.env"]
        context["operations"]["dailyCycle"]["sourceStatus"] = "unavailable"
        context["operations"]["dailyCycle"]["overallStatus"] = "missing"
        context["operations"]["intradayNavHistory"]["latestDataTime"] = None
        context["intradayNavHistory"]["sourceStatus"] = "unavailable"

        payload = RuleBasedAnalysisProvider().summarize(context)

        self.assertEqual(payload["readinessLevel"], "action_needed")
        self.assertTrue(
            any("scripts\\00631l_check_env.cmd" in item for item in payload["actionItems"])
        )
        self.assertTrue(
            any("scripts\\00631l_daily_cycle.cmd" in item for item in payload["actionItems"])
        )

    def test_rule_based_summary_does_not_emit_forbidden_terms(self) -> None:
        payload = RuleBasedAnalysisProvider().summarize(_context())
        text = " ".join(
            payload["bullets"]
            + payload["actionItems"]
            + [payload["disclaimer"], payload["readinessLevel"]]
        )

        for term in FORBIDDEN_TERMS:
            self.assertNotIn(term, text)


def _context() -> dict:
    return {
        "operations": {
            "sourceStatus": "cached",
            "isStale": False,
            "config": {
                "missingKeys": [],
                "twseIntradayNavConfigured": True,
            },
            "holdingsHistory": {
                "sourceStatus": "official",
                "latestTradeDate": "2026-06-09",
                "isStale": False,
            },
            "intradayNavHistory": {
                "sourceStatus": "cached",
                "latestDataTime": "2026-06-09T12:13:15+08:00",
                "isStale": False,
            },
            "dailyCycle": {
                "sourceStatus": "cached",
                "overallStatus": "PASS",
            },
            "report": {
                "sourceStatus": "cached",
                "overallStatus": "PASS",
            },
            "export": {
                "sourceStatus": "cached",
                "available": True,
            },
            "backup": {
                "sourceStatus": "cached",
                "available": True,
            },
        },
        "holdingsHistory": {
            "sourceStatus": "cached",
            "items": [
                {
                    "txWeightPct": 165.18,
                    "tsmcWeightPct": 36.72,
                    "stockExposurePct": 36.71,
                    "futuresExposurePct": 165.17,
                    "cashAndMarginPct": 68.36,
                }
            ],
        },
        "intradayNavHistory": {
            "sourceStatus": "cached",
            "averagePremiumDiscountPct": 0.17,
            "lastDataTime": "2026-06-09T12:13:15+08:00",
        },
        "priceHistory": {
            "sourceStatus": "cached",
            "rowCount": 120,
            "coverageStart": "2014-10-31",
            "coverageEnd": "2026-06-08",
            "totalReturnPct": 122.5,
            "maxDrawdownPct": -68.4,
        },
        "integrity": {
            "sourceStatus": "cached",
            "overallStatus": "PASS",
            "failureCount": 0,
            "warningCount": 0,
        },
    }


if __name__ == "__main__":
    unittest.main()
