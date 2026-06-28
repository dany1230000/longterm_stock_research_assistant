import json
import os
import subprocess
import sys
import tempfile
import unittest
from datetime import date
from pathlib import Path
from unittest.mock import patch

from backend.app.backtest import run_backtest
from backend.app.etf_price_history import EtfPriceHistoryStore
from backend.app.price_history import (
    PriceHistoryStore,
    parse_twse_stock_day,
    performance_summary,
)
from backend.app.static_export import export_static_00631l_data, static_export_status
from backend.scripts import export_static_00631l_data as export_static_script
from backend.scripts.export_static_00631l_data import (
    build_coverage_age_message,
    build_static_export_compact_response,
    build_static_export_summary_line,
    _build_release_metadata,
    _merge_etf_catalog_seed_if_needed,
    _merge_etf_price_history_seed_if_needed,
    _merge_seed_if_needed,
    _prepare_price_history_update_start,
    _resolve_multi_etf_codes,
    _seed_codes_for_multi_etf_mode,
    _version_from_release_tag,
)


class PriceHistoryAndBacktestTests(unittest.TestCase):
    def test_release_tag_to_version_uses_exact_00631l_tag(self) -> None:
        self.assertEqual(
            _version_from_release_tag("00631l-lab-v5.72-release-metadata-tags"),
            "5.72-release-metadata-tags",
        )
        self.assertEqual(_version_from_release_tag("other-tag"), "")

    def test_static_export_release_metadata_does_not_fall_back_to_old_tag(
        self,
    ) -> None:
        with patch.dict(
            os.environ,
            {
                "00631L_BACKEND_APP_VERSION": "",
                "00631L_BACKEND_RELEASE_TAG": "",
                "00631L_BACKEND_GIT_SHA": "",
                "GITHUB_SHA": "abc1234567890deadbeef",
            },
        ):
            with patch.object(
                export_static_script,
                "_git_exact_release_tag",
                return_value="",
            ):
                with patch.object(
                    export_static_script,
                    "_git_head_sha",
                    return_value="localsha",
                ):
                    metadata = _build_release_metadata()

        self.assertEqual(metadata["releaseTag"], "")
        self.assertEqual(metadata["appVersion"], "untagged-abc123456789")
        self.assertEqual(metadata["gitSha"], "abc1234567890deadbeef")

    def test_etf_catalog_seed_merges_missing_catalog_codes(self) -> None:
        notes: list[str] = []
        payload = {
            "sourceStatus": "static_official",
            "dataTime": "2026-06-12T17:09:49+08:00",
            "rowCount": 2,
            "items": [
                {"code": "0050", "name": "元大台灣50"},
                {"code": "00631L", "name": "元大台灣50正2"},
            ],
        }
        seed_payload = {
            "rowCount": 3,
            "items": [
                {"code": "0050", "name": "元大台灣50"},
                {"code": "00631L", "name": "元大台灣50正2"},
                {"code": "00999A", "name": "seed-only ETF"},
            ],
        }

        merged = _merge_etf_catalog_seed_if_needed(
            payload=payload,
            seed_payload=seed_payload,
            notes=notes,
        )

        self.assertEqual(merged["rowCount"], 3)
        self.assertEqual(
            [item["code"] for item in merged["items"]],
            ["0050", "00631L", "00999A"],
        )
        self.assertTrue(any("seedEtfCatalogMerged" in note for note in notes))

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

    def test_price_history_store_reads_seed_when_local_cache_is_empty(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            seed = PriceHistoryStore(root / "seed.jsonl")
            rows = parse_twse_stock_day(_stock_day_fixture(), source_url="fixture://seed")
            seed.save_points(rows)

            store = PriceHistoryStore(root / "price.jsonl", seed_path=seed.path)

            status = store.status_response(fetched_at="2026-06-11T00:00:00+00:00")
            response = store.price_response(limit=30, fetched_at="2026-06-11T00:00:00+00:00")

            self.assertEqual(status["sourceStatus"], "static_official")
            self.assertEqual(status["sourceUrl"], "seed://00631l-price-history")
            self.assertEqual(status["rowCount"], 3)
            self.assertEqual(status["coverageStart"], "2026-06-01")
            self.assertEqual(status["coverageEnd"], "2026-06-03")
            self.assertEqual(len(response["items"]), 3)
            self.assertEqual(response["sourceStatus"], "static_official")

    def test_price_history_store_merges_seed_with_local_cache(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            seed = PriceHistoryStore(root / "seed.jsonl")
            seed.save_points(
                parse_twse_stock_day(_stock_day_fixture(), source_url="fixture://seed")
            )
            store = PriceHistoryStore(root / "price.jsonl", seed_path=seed.path)
            store.save_points(
                parse_twse_stock_day(_stock_day_override_fixture(), source_url="fixture://local")
            )

            records = store.all()
            status = store.status_response(fetched_at="2026-06-11T00:00:00+00:00")

            self.assertEqual(status["sourceStatus"], "cached")
            self.assertEqual(status["sourceUrl"], "local+seed://00631l-price-history")
            self.assertEqual(status["rowCount"], 4)
            self.assertEqual(status["coverageStart"], "2026-06-01")
            self.assertEqual(status["coverageEnd"], "2026-06-04")
            self.assertEqual([record["date"] for record in records], [
                "2026-06-01",
                "2026-06-02",
                "2026-06-03",
                "2026-06-04",
            ])
            self.assertEqual(records[2]["close"], 33.0)
            self.assertEqual(records[2]["sourceUrl"], "fixture://local")

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
                release_metadata={
                    "appVersion": "5.39-public-release-marker",
                    "releaseTag": "00631l-lab-v5.39-public-release-marker",
                    "gitSha": "abc123fff",
                    "buildTime": "2026-06-24T08:00:00+00:00",
                },
            )

            self.assertEqual(result["overallStatus"], "PASS")
            self.assertEqual(result["rowCount"], 3)
            self.assertEqual(result["etfCatalogRowCount"], 2)
            self.assertEqual(
                result["release"]["releaseTag"],
                "00631l-lab-v5.39-public-release-marker",
            )
            self.assertTrue((root / "static" / "price_history.json").exists())
            self.assertTrue((root / "static" / "performance.json").exists())
            self.assertTrue((root / "static" / "status.json").exists())
            self.assertTrue((root / "static" / "etf_catalog.json").exists())
            self.assertTrue((root / "static" / "manifest.json").exists())
            self.assertTrue((root / "static" / "release.json").exists())
            manifest = json.loads(
                (root / "static" / "manifest.json").read_text(encoding="utf-8")
            )
            self.assertEqual(manifest["files"]["etfCatalog"], "etf_catalog.json")
            self.assertEqual(
                manifest["files"]["etfPriceHistoryGaps"],
                "etf_price_history_gaps.json",
            )
            self.assertEqual(manifest["files"]["release"], "release.json")
            self.assertEqual(
                manifest["release"]["releaseTag"],
                "00631l-lab-v5.39-public-release-marker",
            )
            release = json.loads(
                (root / "static" / "release.json").read_text(encoding="utf-8")
            )
            self.assertEqual(release["gitSha"], "abc123fff")
            catalog = json.loads(
                (root / "static" / "etf_catalog.json").read_text(encoding="utf-8")
            )
            self.assertEqual(catalog["sourceStatus"], "static_official")
            self.assertEqual(catalog["rowCount"], 2)

            status = static_export_status(root / "static")
            self.assertEqual(status["overallStatus"], "PASS")
            self.assertEqual(status["sourceStatus"], "static_official")
            self.assertEqual(status["etfCatalogRowCount"], 2)
            self.assertEqual(status["release"]["gitSha"], "abc123fff")

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

    def test_static_export_index_includes_catalog_missing_history(self) -> None:
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
                etf_price_history_codes=["0050", "00999"],
                etf_catalog_payload=_etf_catalog_payload(),
                strict=True,
                minimum_catalog_row_count=2,
            )
            index = json.loads(
                (root / "static" / "etf_price_history_index.json").read_text(
                    encoding="utf-8"
                )
            )
            gaps = json.loads(
                (root / "static" / "etf_price_history_gaps.json").read_text(
                    encoding="utf-8"
                )
            )

        self.assertEqual(result["overallStatus"], "PASS")
        self.assertEqual(result["etfPriceHistoryRowCount"], 2)
        self.assertEqual(result["etfPriceHistoryReadyCount"], 1)
        self.assertEqual(result["etfPriceHistoryGapDetailCount"], 1)
        self.assertEqual(result["etfPriceHistoryCoverageTierCounts"]["unavailable"], 1)
        self.assertEqual(result["etfPriceHistoryGapReasonSamples"]["not_saved"], ["00999"])
        self.assertEqual(index["rowCount"], 2)
        self.assertEqual(index["readyCount"], 1)
        self.assertEqual(index["gapDetailCount"], 1)
        self.assertEqual(index["gapReasonSamples"]["not_saved"], ["00999"])
        self.assertEqual(index["items"][1]["code"], "00999")
        self.assertEqual(index["items"][1]["coverageTier"], "unavailable")
        self.assertEqual(gaps["rowCount"], 1)
        self.assertEqual(gaps["reasonSamples"]["not_saved"], ["00999"])
        self.assertEqual(gaps["items"][0]["code"], "00999")
        self.assertEqual(gaps["items"][0]["gapReason"], "not_saved")

    def test_static_export_catalog_reconciles_history_index_codes(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            store = PriceHistoryStore(root / "price.jsonl")
            rows = parse_twse_stock_day(_stock_day_fixture(), source_url="fixture://twse")
            store.save_points(rows)
            etf_store = EtfPriceHistoryStore(root / "etf_history")
            etf_store.save_points("0050", rows)
            etf_store.save_points("00999A", rows)
            catalog_payload = {
                **_etf_catalog_payload(),
                "rowCount": 1,
                "items": [_etf_catalog_payload()["items"][1]],
            }

            result = export_static_00631l_data(
                output_dir=root / "static",
                price_history_store=store,
                etf_price_history_store=etf_store,
                etf_price_history_codes=["0050", "00999A"],
                etf_catalog_payload=catalog_payload,
                strict=True,
                minimum_catalog_row_count=1,
            )
            catalog = json.loads(
                (root / "static" / "etf_catalog.json").read_text(encoding="utf-8")
            )
            manifest = json.loads(
                (root / "static" / "manifest.json").read_text(encoding="utf-8")
            )

        self.assertEqual(result["etfCatalogRowCount"], 2)
        self.assertEqual(result["etfPriceHistoryOutOfCatalogCount"], 0)
        self.assertEqual(manifest["etfCatalogRowCount"], 2)
        self.assertEqual(manifest["etfPriceHistoryOutOfCatalogCount"], 0)
        self.assertEqual([item["code"] for item in catalog["items"]], ["0050", "00999A"])
        self.assertEqual(catalog["items"][1]["sourceStatus"], "static_history_index")
        self.assertTrue(
            any("historyIndexCatalogMerged=1" in item for item in result["warnings"])
        )

    def test_static_export_all_catalog_resolves_catalog_codes(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            etf_store = EtfPriceHistoryStore(Path(temp_dir) / "etf_history")
            etf_store.save_points("00757", _stock_day_fixture_points("00757"))
            warnings: list[str] = []
            notes: list[str] = []

            codes = _resolve_multi_etf_codes(
                "all-catalog",
                store=etf_store,
                catalog_payload=_etf_catalog_payload(),
                warnings=warnings,
                notes=notes,
            )

        self.assertEqual(codes[:2], ["00631L", "0050"])
        self.assertIn("00757", codes)
        self.assertEqual(warnings, [])
        self.assertTrue(any("multiEtfCodesResolved=all-catalog" in item for item in notes))

    def test_static_export_all_catalog_merges_available_seed_codes(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            seed_dir = Path(temp_dir) / "seed"
            seed_dir.mkdir()
            (seed_dir / "0050.jsonl").write_text("", encoding="utf-8")
            (seed_dir / "00878.jsonl").write_text("", encoding="utf-8")

            codes = _seed_codes_for_multi_etf_mode(
                "all-catalog",
                seed_dir=seed_dir,
            )

        self.assertEqual(codes, ["0050", "00878"])

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

    def test_static_status_derives_etf_tier_counts_from_legacy_price_files(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            static = root / "static"
            history = static / "etf_price_history"
            history.mkdir(parents=True)
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
                json.dumps({"rowCount": 2, "readyCount": 2}, sort_keys=True),
                encoding="utf-8",
            )
            (history / "0050.json").write_text(
                json.dumps(
                    {
                        "sourceStatus": "static_official",
                        "coverageStart": "2019-01-02",
                        "coverageEnd": "2026-06-15",
                        "rowCount": 1802,
                    },
                    sort_keys=True,
                ),
                encoding="utf-8",
            )
            (history / "00940.json").write_text(
                json.dumps(
                    {
                        "sourceStatus": "static_official",
                        "coverageStart": "2024-04-01",
                        "coverageEnd": "2026-06-15",
                        "rowCount": 535,
                    },
                    sort_keys=True,
                ),
                encoding="utf-8",
            )

            status = static_export_status(static)

        self.assertEqual(status["etfPriceHistoryCoverageTierCounts"]["long_term"], 1)
        self.assertEqual(status["etfPriceHistoryCoverageTierCounts"]["recent"], 1)

    def test_static_status_derives_legacy_etf_row_counts_with_tiers(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            static = root / "static"
            history = static / "etf_price_history"
            history.mkdir(parents=True)
            (static / "manifest.json").write_text(
                json.dumps(
                    {
                        "sourceStatus": "static_official",
                        "generatedAt": "2026-06-21T00:00:00+00:00",
                        "rowCount": 3,
                        "coverageStart": "2026-06-01",
                        "coverageEnd": "2026-06-03",
                        "etfPriceHistoryRowCount": 1,
                        "etfPriceHistoryReadyCount": 1,
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
            for code, start, rows in [
                ("0050", "2019-01-02", 1802),
                ("00940", "2024-04-01", 535),
            ]:
                (history / f"{code}.json").write_text(
                    json.dumps(
                        {
                            "sourceStatus": "static_official",
                            "coverageStart": start,
                            "coverageEnd": "2026-06-15",
                            "rowCount": rows,
                        },
                        sort_keys=True,
                    ),
                    encoding="utf-8",
                )

            status = static_export_status(static)

        self.assertEqual(status["etfPriceHistoryRowCount"], 2)
        self.assertEqual(status["etfPriceHistoryReadyCount"], 2)
        self.assertEqual(status["etfPriceHistoryOutOfCatalogCount"], 2)
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
                "etfPriceHistoryRowCount": 228,
                "etfPriceHistoryMissingCount": 116,
                "etfPriceHistoryGapDetailCount": 116,
                "etfPriceHistoryOutOfCatalogCount": 2,
                "etfCatalogRowCount": 344,
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
        self.assertIn("etfRows=228", line)
        self.assertIn("etfCatalogRows=344", line)
        self.assertIn("etfMissing=116", line)
        self.assertIn("etfGapDetails=116", line)
        self.assertIn("etfOutOfCatalog=2", line)
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
        self.assertIn("etfMissing=0", line)
        self.assertIn("etfGapDetails=0", line)
        self.assertIn("tiers=not_available", line)

    def test_static_export_compact_response_keeps_cli_output_short(self) -> None:
        compact = build_static_export_compact_response(
            {
                "sourceStatus": "static_official",
                "sourceContract": "00631l_static_public_data",
                "overallStatus": "PASS",
                "generatedAt": "2026-06-24T00:00:00+00:00",
                "rowCount": 2835,
                "coverageStart": "2014-10-31",
                "coverageEnd": "2026-06-24",
                "isCompleteFromListing": True,
                "etfCatalogRowCount": 345,
                "etfPriceHistoryReadyCount": 230,
                "etfPriceHistoryRowCount": 230,
                "etfPriceHistoryGapDetailCount": 114,
                "etfPriceHistoryOutOfCatalogCount": 2,
                "etfPriceHistoryCoverageTierCounts": {
                    "long_term": 8,
                    "recent": 222,
                    "unavailable": 0,
                    "error": 0,
                },
                "outputDir": "web/00631l-static-data",
                "release": {"releaseTag": "00631l-lab-test"},
                "warnings": ["seed merged", "recent import partial " + ("details;" * 40)],
                "failures": [],
                "files": {"priceHistory": "price_history.json"},
            },
            sample_size=1,
        )

        self.assertEqual(compact["rowCount"], 2835)
        self.assertEqual(compact["etfPriceHistoryReadyCount"], 230)
        self.assertEqual(compact["etfPriceHistoryOutOfCatalogCount"], 2)
        self.assertEqual(compact["etfPriceHistoryGapDetailCount"], 114)
        self.assertEqual(compact["warningCount"], 2)
        self.assertEqual(compact["warningsSample"], ["seed merged"])
        self.assertNotIn("files", compact)

        truncated = build_static_export_compact_response(
            {
                "warnings": ["recent import partial " + ("details;" * 40)],
                "failures": [],
            },
            sample_size=1,
        )
        self.assertLessEqual(len(truncated["warningsSample"][0]), 160)

    def test_static_export_coverage_age_guard(self) -> None:
        self.assertIsNone(
            build_coverage_age_message(
                "2026-06-24",
                max_age_days=7,
                today=date(2026, 6, 24),
            )
        )
        self.assertIsNone(
            build_coverage_age_message(
                "2026-06-18",
                max_age_days=7,
                today=date(2026, 6, 24),
            )
        )
        self.assertIn(
            "priceHistoryCoverageTooOld=2026-06-15",
            build_coverage_age_message(
                "2026-06-15",
                max_age_days=7,
                today=date(2026, 6, 24),
            ),
        )

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

    def test_price_history_status_script_reports_seed_history(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            seed = PriceHistoryStore(root / "seed.jsonl")
            seed.save_points(
                parse_twse_stock_day(_stock_day_fixture(), source_url="fixture://seed")
            )

            completed = subprocess.run(
                [
                    sys.executable,
                    "backend/scripts/update_00631l_price_history.py",
                    "--status-only",
                    "--path",
                    str(root / "price.jsonl"),
                    "--seed-path",
                    str(seed.path),
                ],
                cwd=Path(__file__).resolve().parents[2],
                capture_output=True,
                check=False,
                text=True,
            )

            self.assertEqual(completed.returncode, 0, completed.stderr)
            self.assertIn('"sourceStatus": "static_official"', completed.stdout)
            self.assertIn("[summary] overallStatus=PASS", completed.stdout)

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

            seed_summary = _merge_etf_price_history_seed_if_needed(
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
            self.assertEqual(result["etfPriceHistoryMissingCount"], 0)
            self.assertEqual(seed_summary["readyCount"], 1)
            self.assertEqual(seed_summary["mergedCount"], 1)
            self.assertFalse(any("seedEtfPriceHistoryMerged=0050" in item for item in warnings))

    def test_static_export_merges_seed_when_recent_etf_history_exists(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            rows = parse_twse_stock_day(_stock_day_fixture(), source_url="fixture://twse")
            seed_store = EtfPriceHistoryStore(root / "seed_etf_history")
            seed_store.save_points("0050", rows)
            etf_store = EtfPriceHistoryStore(root / "etf_history")
            etf_store.save_points("0050", rows[-1:])
            warnings: list[str] = []

            seed_summary = _merge_etf_price_history_seed_if_needed(
                store=etf_store,
                seed_dir=root / "seed_etf_history",
                codes=["0050"],
                warnings=warnings,
            )

            status = etf_store.status("0050", fetched_at="2026-06-15T00:00:00+00:00")
            self.assertEqual(status["rowCount"], 3)
            self.assertEqual(status["coverageStart"], "2026-06-01")
            self.assertEqual(seed_summary["readyCount"], 1)
            self.assertEqual(seed_summary["missingCount"], 0)
            self.assertFalse(any("seedEtfPriceHistoryMerged=0050" in item for item in warnings))

    def test_static_export_summarizes_missing_multi_etf_history_without_warning_spam(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            store = PriceHistoryStore(root / "price.jsonl")
            rows = parse_twse_stock_day(_stock_day_fixture(), source_url="fixture://twse")
            store.save_points(rows)
            etf_store = EtfPriceHistoryStore(root / "etf_history")
            etf_store.save_points("0050", rows)
            warnings: list[str] = []

            result = export_static_00631l_data(
                output_dir=root / "static",
                price_history_store=store,
                etf_price_history_store=etf_store,
                etf_price_history_codes=["0050", "00878"],
                strict=True,
                warnings=warnings,
            )

            self.assertEqual(result["overallStatus"], "PASS")
            self.assertEqual(result["etfPriceHistoryReadyCount"], 1)
            self.assertEqual(result["etfPriceHistoryMissingCount"], 1)
            self.assertEqual(result["etfPriceHistoryGapReasonCounts"]["not_saved"], 1)
            self.assertFalse(any("etfPriceHistoryMissing=00878" in item for item in result["warnings"]))


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


def _stock_day_fixture_points(code: str) -> list[dict[str, object]]:
    return [
        {
            **row,
            "code": code,
        }
        for row in parse_twse_stock_day(_stock_day_fixture(), source_url=f"fixture://{code}")
    ]


def _stock_day_override_fixture() -> str:
    return json.dumps(
        {
            "stat": "OK",
            "data": [
                ["115/06/03", "1,250,000", "41,250,000", "32.50", "33.50", "32.00", "33.00", "+3.00", "1,500"],
                ["115/06/04", "1,300,000", "43,550,000", "33.00", "34.00", "32.80", "33.50", "+0.50", "1,600"],
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
