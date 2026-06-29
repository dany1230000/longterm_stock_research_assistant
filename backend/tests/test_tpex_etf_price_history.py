import json
import tempfile
import unittest
from datetime import date
from pathlib import Path

from backend.app.etf_price_history import EtfPriceHistoryStore
from backend.app.tpex_etf_price_history import (
    TPEX_ETF_PRICE_HISTORY_CONTRACT,
    fetch_tpex_etf_price_history,
    parse_tpex_etf_daily_history,
)
from backend.scripts.import_tpex_etf_price_history import (
    filter_official_empty_codes,
    select_tpex_import_codes,
)


class TpexEtfPriceHistoryTests(unittest.TestCase):
    def test_parse_tpex_daily_history_filters_requested_code(self) -> None:
        points = parse_tpex_etf_daily_history(
            _tpex_fixture(),
            source_url="https://www.tpex.org.tw/www/zh-tw/ETFReport/historical",
            requested_codes=["00749B"],
        )

        self.assertEqual(len(points), 1)
        self.assertEqual(points[0]["code"], "00749B")
        self.assertEqual(points[0]["name"], "凱基新興債10+")
        self.assertEqual(points[0]["date"], "2026-06-26")
        self.assertEqual(points[0]["open"], 32.26)
        self.assertEqual(points[0]["high"], 32.40)
        self.assertEqual(points[0]["low"], 32.26)
        self.assertEqual(points[0]["close"], 32.39)
        self.assertEqual(points[0]["volume"], 116)
        self.assertEqual(points[0]["volumeUnit"], "lots")
        self.assertEqual(points[0]["sourceContract"], TPEX_ETF_PRICE_HISTORY_CONTRACT)

    def test_fetch_tpex_history_groups_points_by_requested_code(self) -> None:
        requests: list[dict[str, str]] = []

        def fake_fetch(url: str, form: dict[str, str], timeout: float) -> str:
            requests.append(dict(form))
            return _tpex_fixture()

        payload = fetch_tpex_etf_price_history(
            codes=["00749B", "00750B"],
            start_date=date(2026, 6, 26),
            end_date=date(2026, 6, 26),
            url="https://example.test/tpex",
            fetcher=fake_fetch,
            timeout_seconds=1,
        )

        self.assertEqual(payload["sourceStatus"], "official")
        self.assertEqual(payload["requestedDays"], 1)
        self.assertEqual(payload["rowCount"], 2)
        self.assertEqual(requests[0]["date"], "2026/06/26")
        self.assertEqual(payload["pointsByCode"]["00749B"][0]["close"], 32.39)
        self.assertEqual(payload["pointsByCode"]["00750B"][0]["close"], 33.84)

    def test_fetch_tpex_history_reports_official_empty_days(self) -> None:
        def fake_fetch(url: str, form: dict[str, str], timeout: float) -> str:
            return json.dumps({"stat": "ok", "tables": [{"data": []}]})

        payload = fetch_tpex_etf_price_history(
            codes=["00999"],
            start_date=date(2026, 6, 26),
            end_date=date(2026, 6, 26),
            url="https://example.test/tpex",
            fetcher=fake_fetch,
            timeout_seconds=1,
        )

        self.assertEqual(payload["sourceStatus"], "unavailable")
        self.assertEqual(payload["rowCount"], 0)
        self.assertEqual(payload["warnings"], ["tpexEmptyDays=1"])

    def test_store_classifies_tpex_empty_attempt_as_official_empty(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            store = EtfPriceHistoryStore(Path(temp_dir))
            store.record_import_attempt(
                "00999",
                {
                    "attemptedAt": "2026-06-29T00:00:00+00:00",
                    "sourceStatus": "unavailable",
                    "sourceContract": "tpex_etf_price_history_import_attempt",
                    "sourceUrl": "https://example.test/tpex",
                    "requestedDays": 1,
                    "rowCount": 0,
                    "warnings": ["tpexEmptyDays=1"],
                    "errorMessage": None,
                },
            )

            status = store.status("00999", fetched_at="2026-06-29T00:00:00+00:00")

        self.assertEqual(status["gapReason"], "official_empty")
        self.assertEqual(status["sourceStatus"], "unavailable")
        self.assertIn("official ETF price-history", status["errorMessage"])

    def test_store_preserves_tpex_source_contract_on_saved_rows(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            store = EtfPriceHistoryStore(Path(temp_dir))
            points = parse_tpex_etf_daily_history(
                _tpex_fixture(),
                source_url="https://example.test/tpex",
                requested_codes=["00749B"],
            )
            store.save_points("00749B", points)
            rows = store.all("00749B")

        self.assertEqual(rows[0]["sourceContract"], TPEX_ETF_PRICE_HISTORY_CONTRACT)
        self.assertEqual(rows[0]["volumeUnit"], "lots")
        self.assertEqual(rows[0]["close"], 32.39)

    def test_tpex_import_filters_official_empty_attempts(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            store = EtfPriceHistoryStore(Path(temp_dir))
            store.record_import_attempt(
                "00749B",
                {
                    "attemptedAt": "2026-06-29T00:00:00+00:00",
                    "sourceStatus": "error",
                    "sourceUrl": "https://example.test/twse",
                    "requestedMonths": 1,
                    "rowCount": 0,
                    "warnings": ["emptyMonths=1"],
                    "errorMessage": None,
                },
            )
            store.record_import_attempt(
                "00750B",
                {
                    "attemptedAt": "2026-06-29T00:00:00+00:00",
                    "sourceStatus": "error",
                    "sourceUrl": "https://example.test/twse",
                    "requestedMonths": 0,
                    "rowCount": 0,
                    "warnings": [],
                    "errorMessage": "HTTP 500",
                },
            )

            selected = filter_official_empty_codes(["00749B", "00750B"], store)

        self.assertEqual(selected, ["00749B"])

    def test_tpex_select_codes_applies_missing_and_official_empty_filters(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            store = EtfPriceHistoryStore(Path(temp_dir))
            store.save_points("0050", [{"date": "2026-06-01", "close": 10}])
            store.record_import_attempt(
                "00749B",
                {
                    "attemptedAt": "2026-06-29T00:00:00+00:00",
                    "sourceStatus": "error",
                    "sourceUrl": "https://example.test/twse",
                    "requestedMonths": 1,
                    "rowCount": 0,
                    "warnings": ["emptyMonths=1"],
                    "errorMessage": None,
                },
            )
            args = type(
                "Args",
                (),
                {
                    "from_catalog": False,
                    "codes": "0050,00749B,00999",
                    "missing_only": True,
                    "official_empty_only": True,
                    "offset": 0,
                    "limit": 0,
                },
            )()

            selected = select_tpex_import_codes(args, store)

        self.assertEqual(selected, ["00749B"])


def _tpex_fixture() -> str:
    return json.dumps(
        {
            "date": "20260626",
            "tables": [
                {
                    "fields": [
                        "日期",
                        "證券代號",
                        "證券名稱",
                        "成交張數",
                        "成交仟元",
                        "開盤",
                        "最高",
                        "最低",
                        "收盤",
                        "漲跌",
                        "筆數",
                    ],
                    "data": [
                        [
                            "1150626",
                            "00749B",
                            "凱基新興債10+   ",
                            "116",
                            "3,756",
                            "32.26",
                            "32.40",
                            "32.26",
                            "32.39",
                            "+0.11",
                            "6",
                        ],
                        [
                            "1150626",
                            "00750B",
                            "凱基科技債10+   ",
                            "100",
                            "3,384",
                            "33.84",
                            "33.84",
                            "33.84",
                            "33.84",
                            "+0.05",
                            "3",
                        ],
                    ],
                }
            ],
            "stat": "ok",
        }
    )


if __name__ == "__main__":
    unittest.main()
