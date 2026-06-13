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
from backend.app.static_export import export_static_00631l_data, static_export_status


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
        self.assertEqual(rows[0]["adjustedClose"], 30.5)
        self.assertEqual(rows[0]["adjustmentFactor"], 1.0)
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
            self.assertEqual(response["priceField"], "adjustedClose")

    def test_performance_summary_calculates_return_and_drawdown(self) -> None:
        rows = parse_twse_stock_day(_stock_day_fixture(), source_url="fixture://twse")
        summary = performance_summary(rows)

        self.assertAlmostEqual(summary["totalReturnPct"], -1.639344, places=4)
        self.assertLess(summary["maxDrawdownPct"], 0)
        self.assertEqual(summary["rowCount"], 3)
        self.assertEqual(summary["priceField"], "adjustedClose")

    def test_split_adjustment_prevents_false_split_drawdown(self) -> None:
        rows = parse_twse_stock_day(_split_fixture(), source_url="fixture://twse")

        self.assertEqual(rows[0]["date"], "2026-03-24")
        self.assertEqual(rows[0]["close"], 443.15)
        self.assertAlmostEqual(rows[0]["adjustedClose"], 20.143182, places=5)
        self.assertAlmostEqual(rows[0]["adjustmentFactor"], 1 / 22, places=8)
        self.assertEqual(rows[1]["date"], "2026-03-31")
        self.assertEqual(rows[1]["close"], 19.26)
        self.assertEqual(rows[1]["adjustedClose"], 19.26)

        summary = performance_summary(rows)

        self.assertGreater(summary["totalReturnPct"], -10)
        self.assertGreater(summary["maxDrawdownPct"], -10)
        self.assertEqual(summary["priceField"], "adjustedClose")

    def test_backtest_uses_split_adjusted_price(self) -> None:
        rows = parse_twse_stock_day(_split_fixture(), source_url="fixture://twse")
        result = run_backtest(
            request={
                "strategy": "lump_sum",
                "startDate": "2026-03-24",
                "endDate": "2026-03-31",
                "initialAmount": 22000,
                "monthlyAmount": 0,
                "monthlyDay": 5,
                "feeRatePct": 0,
            },
            history=rows,
        )

        self.assertEqual(result["sourceStatus"], "calculated")
        self.assertEqual(result["priceField"], "adjustedClose")
        self.assertGreater(result["totalReturnPct"], -10)

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

    def test_static_export_writes_public_json_when_history_exists(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            store = PriceHistoryStore(root / "price.jsonl")
            rows = parse_twse_stock_day(_stock_day_fixture(), source_url="fixture://twse")
            store.save_points(rows)

            result = export_static_00631l_data(
                output_dir=root / "static",
                price_history_store=store,
                strict=True,
            )

            self.assertEqual(result["overallStatus"], "PASS")
            self.assertEqual(result["rowCount"], 3)
            self.assertTrue((root / "static" / "price_history.json").exists())
            self.assertTrue((root / "static" / "performance.json").exists())
            self.assertTrue((root / "static" / "status.json").exists())
            self.assertTrue((root / "static" / "manifest.json").exists())

            status = static_export_status(root / "static")
            self.assertEqual(status["overallStatus"], "PASS")
            self.assertEqual(status["sourceStatus"], "static_official")

    def test_static_export_strict_fails_without_price_history(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            store = PriceHistoryStore(root / "price.jsonl")

            result = export_static_00631l_data(
                output_dir=root / "static",
                price_history_store=store,
                strict=True,
            )

            self.assertEqual(result["overallStatus"], "FAIL")
            self.assertEqual(result["rowCount"], 0)
            self.assertTrue(result["failures"])


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


def _split_fixture() -> str:
    return json.dumps(
        {
            "stat": "OK",
            "data": [
                ["115/03/24", "9,000,000", "4,000,000,000", "459.15", "460.95", "435.50", "443.15", "-2.35", "10,000"],
                ["115/03/31", "120,000,000", "2,400,000,000", "19.67", "19.88", "19.10", "19.26", "-0.88", "80,000"],
            ],
        }
    )


if __name__ == "__main__":
    unittest.main()
