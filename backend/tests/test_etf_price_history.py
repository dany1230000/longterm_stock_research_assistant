import json
import tempfile
import unittest
from datetime import date
from pathlib import Path

from fastapi.testclient import TestClient

from backend.app.config import Settings
from backend.app.etf_price_history import (
    DEFAULT_ETF_HISTORY_CODES,
    EtfPriceHistoryStore,
    fetch_etf_price_history,
    validate_etf_price_records,
)
from backend.app.main import create_app
from backend.app.service import Etf00631LService


class EtfPriceHistoryTests(unittest.TestCase):
    def test_default_etf_history_basket_has_representative_symbols(self) -> None:
        self.assertGreaterEqual(len(DEFAULT_ETF_HISTORY_CODES), 15)
        self.assertIn("00631L", DEFAULT_ETF_HISTORY_CODES)
        self.assertIn("0050", DEFAULT_ETF_HISTORY_CODES)
        self.assertIn("0056", DEFAULT_ETF_HISTORY_CODES)
        self.assertIn("00878", DEFAULT_ETF_HISTORY_CODES)
        self.assertIn("00940", DEFAULT_ETF_HISTORY_CODES)

    def test_multi_etf_store_keeps_non_split_etf_unadjusted(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            store = EtfPriceHistoryStore(Path(temp_dir))
            saved = store.save_points(
                "0056",
                [
                    {
                        "date": "2026-03-30",
                        "open": 100,
                        "high": 110,
                        "low": 95,
                        "close": 105,
                        "volume": 1000,
                        "sourceUrl": "fixture://0050",
                    }
                ],
            )
            rows = store.all("0056")

        self.assertEqual(saved, 1)
        self.assertEqual(rows[0]["close"], 105)
        self.assertEqual(rows[0]["adjustedClose"], 105)
        self.assertEqual(rows[0]["adjustmentFactor"], 1.0)

    def test_multi_etf_store_applies_0050_split_adjustment(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            store = EtfPriceHistoryStore(Path(temp_dir))
            saved = store.save_points(
                "0050",
                [
                    {
                        "date": "2025-06-17",
                        "open": 188,
                        "high": 190,
                        "low": 187,
                        "close": 188.64,
                        "volume": 1000,
                        "sourceUrl": "fixture://0050",
                    },
                    {
                        "date": "2025-06-18",
                        "open": 47,
                        "high": 48,
                        "low": 46,
                        "close": 47.16,
                        "volume": 4000,
                        "sourceUrl": "fixture://0050",
                    },
                ],
            )
            rows = store.all("0050")
            status = store.status(
                "0050",
                fetched_at="2026-06-14T00:00:00+00:00",
            )

        self.assertEqual(saved, 2)
        self.assertEqual(rows[0]["close"], 188.64)
        self.assertAlmostEqual(rows[0]["adjustedClose"], 47.16)
        self.assertAlmostEqual(rows[0]["adjustmentFactor"], 0.25)
        self.assertEqual(rows[1]["adjustedClose"], 47.16)
        self.assertEqual(rows[1]["adjustmentFactor"], 1.0)
        self.assertEqual(status["priceField"], "adjustedClose")
        self.assertEqual(status["validationStatus"], "PASS")

    def test_multi_etf_store_applies_00631l_split_adjustment(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            store = EtfPriceHistoryStore(Path(temp_dir))
            saved = store.save_points(
                "00631L",
                [
                    {
                        "date": "2026-03-30",
                        "open": 820,
                        "high": 825,
                        "low": 810,
                        "close": 814,
                        "volume": 1000,
                        "sourceUrl": "fixture://00631L",
                    },
                    {
                        "date": "2026-03-31",
                        "open": 37,
                        "high": 38,
                        "low": 36,
                        "close": 37,
                        "volume": 22000,
                        "sourceUrl": "fixture://00631L",
                    },
                ],
            )
            rows = store.all("00631L")
            status = store.status(
                "00631L",
                fetched_at="2026-06-14T00:00:00+00:00",
            )

        self.assertEqual(saved, 2)
        self.assertEqual(rows[0]["close"], 814)
        self.assertAlmostEqual(rows[0]["adjustedClose"], 37.0)
        self.assertAlmostEqual(rows[0]["adjustmentFactor"], 1 / 22)
        self.assertEqual(rows[1]["adjustedClose"], 37)
        self.assertEqual(rows[1]["adjustmentFactor"], 1.0)
        self.assertEqual(status["priceField"], "adjustedClose")
        self.assertEqual(status["validationStatus"], "PASS")

    def test_multi_etf_store_defaults_incremental_update_to_latest_month(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            store = EtfPriceHistoryStore(Path(temp_dir))
            store.save_points(
                "0050",
                [
                    {
                        "date": "2026-06-15",
                        "open": 50,
                        "high": 51,
                        "low": 49,
                        "close": 50.5,
                        "volume": 1000,
                        "sourceUrl": "fixture://0050",
                    }
                ],
            )

            self.assertEqual(
                store.default_incremental_start_date(
                    "0050",
                    default_start=date(2019, 1, 1),
                ),
                date(2026, 6, 1),
            )

    def test_multi_etf_validation_catches_missing_split_adjustment(self) -> None:
        validation = validate_etf_price_records(
            "00631L",
            [
                {
                    "date": "2026-03-30",
                    "open": 820,
                    "high": 825,
                    "low": 810,
                    "close": 814,
                    "adjustedOpen": 820,
                    "adjustedHigh": 825,
                    "adjustedLow": 810,
                    "adjustedClose": 814,
                    "adjustmentFactor": 1.0,
                    "volume": 1000,
                },
                {
                    "date": "2026-03-31",
                    "open": 37,
                    "high": 38,
                    "low": 36,
                    "close": 37,
                    "adjustedOpen": 37,
                    "adjustedHigh": 38,
                    "adjustedLow": 36,
                    "adjustedClose": 37,
                    "adjustmentFactor": 1.0,
                    "volume": 22000,
                },
            ],
        )

        self.assertEqual(validation["overallStatus"], "FAIL")
        self.assertGreater(validation["failureCount"], 0)
        self.assertIn("pre-split adjustmentFactor", validation["failures"][0])

    def test_normalize_saved_records_rewrites_stale_adjusted_fields(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            store = EtfPriceHistoryStore(Path(temp_dir))
            path = store.path_for("0050")
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(
                json.dumps(
                    {
                        "code": "0050",
                        "date": "2025-06-17",
                        "open": 188,
                        "high": 190,
                        "low": 187,
                        "close": 188.64,
                        "adjustedOpen": 188,
                        "adjustedHigh": 190,
                        "adjustedLow": 187,
                        "adjustedClose": 188.64,
                        "adjustmentFactor": 1.0,
                        "volume": 1000,
                        "sourceUrl": "fixture://0050",
                    },
                    sort_keys=True,
                )
                + "\n",
                encoding="utf-8",
            )

            normalized_rows = store.normalize_saved_records("0050")
            rows = [
                json.loads(line)
                for line in path.read_text(encoding="utf-8").splitlines()
            ]

        self.assertEqual(normalized_rows, 1)
        self.assertAlmostEqual(rows[0]["adjustedClose"], 47.16)
        self.assertAlmostEqual(rows[0]["adjustmentFactor"], 0.25)

    def test_fetch_etf_price_history_uses_requested_symbol(self) -> None:
        urls: list[str] = []

        def fake_fetch(url: str, timeout: float) -> str:
            urls.append(url)
            return _stock_day_fixture()

        payload = fetch_etf_price_history(
            code="0050",
            fetcher=fake_fetch,
            url_template="https://example.test/STOCK_DAY?stockNo={symbol}&date={yyyymmdd}",
            start_date=__import__("datetime").date(2026, 6, 1),
            end_date=__import__("datetime").date(2026, 6, 30),
            timeout_seconds=1,
        )

        self.assertEqual(payload["sourceStatus"], "official")
        self.assertIn("stockNo=0050", urls[0])
        self.assertEqual(payload["rowCount"], 3)

    def test_fetch_etf_price_history_applies_00631l_split(self) -> None:
        def fake_fetch(url: str, timeout: float) -> str:
            return _stock_day_split_fixture()

        payload = fetch_etf_price_history(
            code="00631L",
            fetcher=fake_fetch,
            url_template="https://example.test/STOCK_DAY?stockNo={symbol}&date={yyyymmdd}",
            start_date=__import__("datetime").date(2026, 3, 1),
            end_date=__import__("datetime").date(2026, 3, 31),
            timeout_seconds=1,
        )

        self.assertEqual(payload["sourceStatus"], "official")
        self.assertEqual(payload["rowCount"], 2)
        self.assertAlmostEqual(payload["points"][0]["adjustedClose"], 37.0)
        self.assertEqual(payload["points"][1]["adjustedClose"], 37.0)

    def test_fetch_etf_price_history_rewrites_legacy_00631l_template(self) -> None:
        urls: list[str] = []

        def fake_fetch(url: str, timeout: float) -> str:
            urls.append(url)
            return _stock_day_fixture()

        payload = fetch_etf_price_history(
            code="00878",
            fetcher=fake_fetch,
            url_template="https://example.test/STOCK_DAY?stockNo=00631L&date={yyyymmdd}",
            start_date=__import__("datetime").date(2026, 6, 1),
            end_date=__import__("datetime").date(2026, 6, 30),
            timeout_seconds=1,
        )

        self.assertEqual(payload["sourceStatus"], "official")
        self.assertIn("stockNo=00878", urls[0])
        self.assertNotIn("stockNo=00631L", urls[0])

    def test_index_response_lists_saved_etf_histories(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            store = EtfPriceHistoryStore(Path(temp_dir))
            store.save_points("0050", _points("0050"))
            store.save_points("00878", _points("00878"))
            payload = store.index_response(fetched_at="2026-06-14T00:00:00+00:00")

        self.assertEqual(payload["sourceStatus"], "cached")
        self.assertEqual(payload["rowCount"], 2)
        self.assertEqual(payload["readyCount"], 2)
        self.assertEqual([item["code"] for item in payload["items"]], ["0050", "00878"])

    def test_endpoints_update_and_read_multi_etf_history(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            config = Settings(
                twse_price_history_url_template=(
                    "https://example.test/STOCK_DAY?stockNo={symbol}&date={yyyymmdd}"
                ),
                etf_price_history_dir=str(Path(temp_dir) / "etf_history"),
            )
            service = Etf00631LService(
                config=config,
                fetcher=lambda url, timeout: _stock_day_fixture(),
                etf_price_history_store=EtfPriceHistoryStore(
                    Path(temp_dir) / "etf_history"
                ),
            )
            client = TestClient(create_app(app_config=config, app_service=service))

            update = client.post(
                "/api/etf/history/update",
                params={
                    "codes": "0056,00878",
                    "startDate": "2026-06-01",
                    "endDate": "2026-06-30",
                },
            )
            status = client.get("/api/etf/history/status")
            price = client.get("/api/etf/history/price", params={"code": "0056"})

        self.assertEqual(update.status_code, 200)
        self.assertEqual(update.json()["sourceStatus"], "cached")
        self.assertEqual(status.status_code, 200)
        self.assertEqual(status.json()["readyCount"], 2)
        self.assertEqual(price.status_code, 200)
        self.assertEqual(price.json()["code"], "0056")
        self.assertEqual(price.json()["rowCount"], 3)
        self.assertEqual(price.json()["validation"]["overallStatus"], "PASS")


def _points(code: str) -> list[dict[str, object]]:
    return [
        {
            "code": code,
            "date": "2026-06-01",
            "open": 10,
            "high": 11,
            "low": 9,
            "close": 10,
            "volume": 1000,
            "sourceUrl": f"fixture://{code}",
        },
        {
            "code": code,
            "date": "2026-06-02",
            "open": 10,
            "high": 12,
            "low": 10,
            "close": 11,
            "volume": 1100,
            "sourceUrl": f"fixture://{code}",
        },
    ]


def _stock_day_fixture() -> str:
    return json.dumps(
        {
            "stat": "OK",
            "data": [
                [
                    "115/06/01",
                    "1,000,000",
                    "30,500,000",
                    "30.00",
                    "31.00",
                    "29.50",
                    "30.50",
                    "+0.50",
                    "1,234",
                ],
                [
                    "115/06/02",
                    "1,100,000",
                    "34,100,000",
                    "31.00",
                    "32.00",
                    "30.50",
                    "31.00",
                    "+0.50",
                    "1,300",
                ],
                [
                    "115/06/03",
                    "1,200,000",
                    "36,000,000",
                    "30.50",
                    "31.00",
                    "29.80",
                    "30.00",
                    "-1.00",
                    "1,400",
                ],
            ],
        }
    )


def _stock_day_split_fixture() -> str:
    return json.dumps(
        {
            "stat": "OK",
            "data": [
                [
                    "115/03/30",
                    "1,000,000",
                    "814,000,000",
                    "820.00",
                    "825.00",
                    "810.00",
                    "814.00",
                    "-6.00",
                    "1,234",
                ],
                [
                    "115/03/31",
                    "22,000,000",
                    "814,000,000",
                    "37.00",
                    "38.00",
                    "36.00",
                    "37.00",
                    "-777.00",
                    "1,300",
                ],
            ],
        }
    )


if __name__ == "__main__":
    unittest.main()
