import json
import tempfile
import unittest
from pathlib import Path

from backend.app.backtest import run_backtest
from backend.app.price_history import (
    PriceHistoryStore,
    parse_twse_stock_day,
    performance_summary,
)


class PriceHistoryAndBacktestTests(unittest.TestCase):
    def test_twse_stock_day_parser_maps_ohlcv(self) -> None:
        rows = parse_twse_stock_day(_stock_day_fixture(), source_url="fixture://twse")

        self.assertEqual(len(rows), 3)
        self.assertEqual(rows[0]["date"], "2026-06-01")
        self.assertEqual(rows[0]["open"], 30.0)
        self.assertEqual(rows[0]["high"], 31.0)
        self.assertEqual(rows[0]["low"], 29.5)
        self.assertEqual(rows[0]["close"], 30.5)
        self.assertEqual(rows[0]["volume"], 1000000)
        self.assertEqual(rows[0]["sourceStatus"], "official")
        self.assertEqual(rows[0]["sourceContract"], "twse_stock_day_json")

    def test_price_history_store_dedupes_by_date_and_reports_status(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            store = PriceHistoryStore(Path(temp_dir) / "price.jsonl")
            rows = parse_twse_stock_day(_stock_day_fixture(), source_url="fixture://twse")

            self.assertEqual(store.save_points(rows), 3)
            self.assertEqual(store.save_points(rows), 0)

            response = store.price_response(limit=30, fetched_at="2026-06-11T00:00:00+00:00")
            self.assertEqual(response["sourceStatus"], "cached")
            self.assertEqual(response["coverageStart"], "2026-06-01")
            self.assertEqual(response["coverageEnd"], "2026-06-03")
            self.assertEqual(len(response["items"]), 3)
            self.assertIn("dailyReturnPct", response["items"][1])

    def test_performance_summary_calculates_return_and_drawdown(self) -> None:
        rows = parse_twse_stock_day(_stock_day_fixture(), source_url="fixture://twse")
        summary = performance_summary(rows)

        self.assertAlmostEqual(summary["totalReturnPct"], -1.639344, places=4)
        self.assertLess(summary["maxDrawdownPct"], 0)
        self.assertEqual(summary["rowCount"], 3)

    def test_backtest_run_returns_curve_and_non_advice_disclaimer(self) -> None:
        rows = parse_twse_stock_day(_stock_day_fixture(), source_url="fixture://twse")
        result = run_backtest(
            request={
                "strategy": "lump_sum",
                "startDate": "2026-06-01",
                "endDate": "2026-06-03",
                "initialAmount": 100000,
                "monthlyAmount": 0,
                "monthlyDay": 5,
                "feeRatePct": 0,
            },
            history=rows,
        )

        self.assertEqual(result["sourceStatus"], "calculated")
        self.assertEqual(result["totalInvested"], 100000)
        self.assertGreater(len(result["equityCurve"]), 1)
        self.assertEqual(result["disclaimer"], "回測不代表未來表現，非買賣建議")


def _stock_day_fixture() -> str:
    return json.dumps(
        {
            "stat": "OK",
            "data": [
                ["115/06/01", "1,000,000", "30,500,000", "30.00", "31.00", "29.50", "30.50", "+0.50", "1,234"],
                ["115/06/02", "1,100,000", "34,100,000", "31.00", "32.00", "30.50", "31.00", "+0.50", "1,300"],
                ["115/06/03", "1,200,000", "36,000,000", "30.50", "31.00", "29.80", "30.00", "-1.00", "1,400"],
            ],
        }
    )


if __name__ == "__main__":
    unittest.main()
