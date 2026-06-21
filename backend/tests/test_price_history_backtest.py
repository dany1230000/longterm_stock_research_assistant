import json
import tempfile
import unittest
from datetime import date
from pathlib import Path

from backend.app.backtest import run_backtest
from backend.app.etf_price_history import EtfPriceHistoryStore
from backend.app.price_history import (
    PriceHistoryStore,
    parse_twse_stock_day,
    performance_summary,
)
from backend.app.static_export import export_static_00631l_data, static_export_status
from backend.scripts.export_static_00631l_data import (
    build_static_export_summary_line,
    _merge_etf_price_history_seed_if_needed,
    _merge_seed_if_needed,
    _prepare_price_history_update_start,
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

    def test_price_history_store_defaults_incremental_update_to_latest_month(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            store = PriceHistoryStore(Path(temp_dir) / "price.jsonl")
            rows = parse_twse_stock_day(_stock_day_fixture(), source_url="fixture://twse")
            store.save_points(rows)

            self.assertEqual(
                store.default_incremental_start_date(default_start=date(2014, 10, 31)),
                date(2026, 6, 1),
            )

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
                etf_catalog_payload=_etf_catalog_payload(),
                strict=True,
                minimum_catalog_row_count=2,
            )

            self.assertEqual(result["overallStatus"], "PASS")
            self.assertEqual(result["rowCount"], 3)
            self.assertEqual(result["etfCatalogRowCount"], 2)
            self.assertTrue((root / "static" / "price_history.json").exists())
            self.assertTrue((root / "static" / "performance.json").exists())
            self.assertTrue((root / "static" / "status.json").exists())
            self.assertTrue((root / "static" / "etf_catalog.json").exists())
            self.assertTrue((root / "static" / "manifest.json").exists())
            manifest = json.loads(
                (root / "static" / "manifest.json").read_text(encoding="utf-8")
            )
            self.assertEqual(manifest["files"]["etfCatalog"], "etf_catalog.json")
            catalog = json.loads(
                (root / "static" / "etf_catalog.json").read_text(encoding="utf-8")
            )
            self.assertEqual(catalog["sourceStatus"], "static_official")
            self.assertEqual(catalog["rowCount"], 2)

            status = static_export_status(root / "static")
            self.assertEqual(status["overallStatus"], "PASS")
            self.assertEqual(status["sourceStatus"], "static_official")
            self.assertEqual(status["etfCatalogRowCount"], 2)

    def test_static_export_writes_selected_etf_price_history(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            store = PriceHistoryStore(root / "price.jsonl")
            rows = parse_twse_stock_day(_stock_day_fixture(), source_url="fixture://twse")
            store.save_points(rows)
            etf_store = EtfPriceHistoryStore(root / "etf_history")
            etf_store.save_points("0050", rows)

            result = export_static_00631l_data(
                output_dir=root / "static",
                price_history_store=store,
                etf_price_history_store=etf_store,
                etf_price_history_codes=["0050"],
                etf_catalog_payload=_etf_catalog_payload(),
                strict=True,
                minimum_catalog_row_count=2,
            )

            self.assertEqual(result["overallStatus"], "PASS")
            self.assertEqual(result["etfPriceHistoryReadyCount"], 1)
            self.assertEqual(
                result["etfPriceHistoryCoverageTierCounts"]["recent"],
                1,
            )
            self.assertTrue(
                (root / "static" / "etf_price_history" / "0050.json").exists()
            )
            index = json.loads(
                (root / "static" / "etf_price_history_index.json").read_text(
                    encoding="utf-8"
                )
            )
            self.assertEqual(index["readyCount"], 1)
            self.assertEqual(index["coverageTierCounts"]["recent"], 1)
            price = json.loads(
                (root / "static" / "etf_price_history" / "0050.json").read_text(
                    encoding="utf-8"
                )
            )
            self.assertEqual(price["code"], "0050")
            self.assertEqual(price["sourceStatus"], "static_official")

    def test_static_status_reads_etf_tier_counts_from_index_fallback(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            static = root / "static"
            static.mkdir()
            (static / "manifest.json").write_text(
                json.dumps(
                    {
                        "sourceStatus": "static_official",
                        "generatedAt": "2026-06-21T00:00:00+00:00",
                        "rowCount": 3,
                        "coverageStart": "2026-06-01",
                        "coverageEnd": "2026-06-03",
                        "etfPriceHistoryRowCount": 2,
                        "etfPriceHistoryReadyCount": 2,
                        "files": {"status": "status.json"},
                        "warnings": [],
                        "failures": [],
                    },
                    sort_keys=True,
                ),
                encoding="utf-8",
            )
            (static / "status.json").write_text(
                json.dumps({"rowCount": 3}, sort_keys=True),
                encoding="utf-8",
            )
            (static / "etf_price_history_index.json").write_text(
                json.dumps(
                    {
                        "coverageTierCounts": {
                            "long_term": 1,
                            "recent": 1,
                            "unavailable": 0,
                            "error": 0,
                        },
                    },
                    sort_keys=True,
                ),
                encoding="utf-8",
            )

            status = static_export_status(static)

        self.assertEqual(status["etfPriceHistoryCoverageTierCounts"]["long_term"], 1)
        self.assertEqual(status["etfPriceHistoryCoverageTierCounts"]["recent"], 1)

    def test_static_export_summary_line_includes_etf_tier_counts(self) -> None:
        line = build_static_export_summary_line(
            {
                "overallStatus": "PASS",
                "rowCount": 2827,
                "coverageStart": "2014-10-31",
                "coverageEnd": "2026-06-11",
                "etfPriceHistoryReadyCount": 228,
                "etfPriceHistoryRowCount": 55000,
                "etfPriceHistoryCoverageTierCounts": {
                    "long_term": 8,
                    "recent": 220,
                    "unavailable": 0,
                    "error": 0,
                },
                "outputDir": "web/00631l-static-data",
            }
        )

        self.assertIn("overallStatus=PASS", line)
        self.assertIn("rows=2827", line)
        self.assertIn("coverage=2014-10-31..2026-06-11", line)
        self.assertIn("etfReady=228", line)
        self.assertIn("etfRows=55000", line)
        self.assertIn("tiers=long_term:8,recent:220,unavailable:0,error:0", line)

    def test_static_export_summary_line_does_not_infer_missing_tier_counts(self) -> None:
        line = build_static_export_summary_line(
            {
                "overallStatus": "PASS",
                "rowCount": 2827,
                "coverageStart": "2014-10-31",
                "coverageEnd": "2026-06-11",
                "etfPriceHistoryReadyCount": 15,
                "etfPriceHistoryRowCount": 15,
            }
        )

        self.assertIn("etfReady=15", line)
        self.assertIn("tiers=not_available", line)

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

    def test_static_export_strict_fails_below_minimum_row_count(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            store = PriceHistoryStore(root / "price.jsonl")
            rows = parse_twse_stock_day(_stock_day_fixture(), source_url="fixture://twse")
            store.save_points(rows[:1])

            result = export_static_00631l_data(
                output_dir=root / "static",
                price_history_store=store,
                strict=True,
                minimum_row_count=3,
            )

            self.assertEqual(result["overallStatus"], "FAIL")
            self.assertEqual(result["rowCount"], 1)
            self.assertIn("requires at least 3 rows", result["failures"][0])

    def test_static_export_seed_merge_restores_minimum_history(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            store = PriceHistoryStore(root / "price.jsonl")
            seed = PriceHistoryStore(root / "seed.jsonl")
            rows = parse_twse_stock_day(_stock_day_fixture(), source_url="fixture://twse")
            store.save_points(rows[:1])
            seed.save_points(rows)
            warnings: list[str] = []

            _merge_seed_if_needed(
                store=store,
                seed_path=seed.path,
                min_row_count=3,
                warnings=warnings,
            )
            result = export_static_00631l_data(
                output_dir=root / "static",
                price_history_store=store,
                strict=True,
                minimum_row_count=3,
                warnings=warnings,
            )

            self.assertEqual(result["overallStatus"], "PASS")
            self.assertEqual(result["rowCount"], 3)
            self.assertTrue(any("seedPriceHistoryMerged" in item for item in warnings))

    def test_static_update_start_merges_seed_before_incremental_fetch(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            store = PriceHistoryStore(root / "price.jsonl")
            seed = PriceHistoryStore(root / "seed.jsonl")
            rows = parse_twse_stock_day(_stock_day_fixture(), source_url="fixture://twse")
            seed.save_points(rows)
            warnings: list[str] = []

            start, mode = _prepare_price_history_update_start(
                store=store,
                seed_path=seed.path,
                min_row_count=3,
                warnings=warnings,
                start_date_text="",
                full_refresh=False,
                default_start=date(2014, 10, 31),
            )

            self.assertEqual(mode, "incremental")
            self.assertEqual(start, date(2026, 6, 1))
            self.assertEqual(
                store.status_response(fetched_at="2026-06-11T00:00:00+00:00")[
                    "rowCount"
                ],
                3,
            )
            self.assertTrue(any("seedPriceHistoryMerged" in item for item in warnings))

    def test_static_export_merges_seeded_multi_etf_price_history(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            store = PriceHistoryStore(root / "price.jsonl")
            rows = parse_twse_stock_day(_stock_day_fixture(), source_url="fixture://twse")
            store.save_points(rows)
            seed_store = EtfPriceHistoryStore(root / "seed_etf_history")
            seed_store.save_points("0050", rows)
            etf_store = EtfPriceHistoryStore(root / "etf_history")
            warnings: list[str] = []

            _merge_etf_price_history_seed_if_needed(
                store=etf_store,
                seed_dir=root / "seed_etf_history",
                codes=["0050"],
                warnings=warnings,
            )
            result = export_static_00631l_data(
                output_dir=root / "static",
                price_history_store=store,
                etf_price_history_store=etf_store,
                etf_price_history_codes=["0050"],
                strict=True,
                warnings=warnings,
            )

            self.assertEqual(result["overallStatus"], "PASS")
            self.assertEqual(result["etfPriceHistoryReadyCount"], 1)
            self.assertTrue(any("seedEtfPriceHistoryMerged=0050" in item for item in warnings))

    def test_static_export_merges_seed_when_recent_etf_history_exists(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            rows = parse_twse_stock_day(_stock_day_fixture(), source_url="fixture://twse")
            seed_store = EtfPriceHistoryStore(root / "seed_etf_history")
            seed_store.save_points("0050", rows)
            etf_store = EtfPriceHistoryStore(root / "etf_history")
            etf_store.save_points("0050", rows[-1:])
            warnings: list[str] = []

            _merge_etf_price_history_seed_if_needed(
                store=etf_store,
                seed_dir=root / "seed_etf_history",
                codes=["0050"],
                warnings=warnings,
            )

            status = etf_store.status("0050", fetched_at="2026-06-15T00:00:00+00:00")
            self.assertEqual(status["rowCount"], 3)
            self.assertEqual(status["coverageStart"], "2026-06-01")
            self.assertTrue(any("seedEtfPriceHistoryMerged=0050" in item for item in warnings))


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


def _etf_catalog_payload() -> dict[str, object]:
    return {
        "sourceStatus": "official",
        "sourceContract": "twse_all_etf_catalog",
        "sourceUrl": "fixture://twse/all_etf",
        "fetchedAt": "2026-06-12T05:31:20+00:00",
        "sourceUpdatedAt": "2026-06-12T13:31:00+08:00",
        "dataTime": "2026-06-12T13:31:00+08:00",
        "isStale": False,
        "userDelayMs": 15000,
        "rowCount": 2,
        "items": [
            {
                "code": "00631L",
                "name": "元大台灣50正2",
                "marketPrice": 34.83,
                "estimatedNav": 34.97,
                "premiumDiscountPct": -0.4,
                "previousNav": 33.29,
                "dataTime": "2026-06-12T13:31:00+08:00",
                "targetType": "1",
            },
            {
                "code": "0050",
                "name": "元大台灣50",
                "marketPrice": 101.95,
                "estimatedNav": 102.14,
                "premiumDiscountPct": -0.19,
                "previousNav": 99.64,
                "dataTime": "2026-06-12T13:31:00+08:00",
                "targetType": "1",
            },
        ],
        "errorMessage": None,
    }


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
