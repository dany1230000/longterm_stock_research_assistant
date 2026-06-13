import unittest
from pathlib import Path

from backend.app.etf_catalog import (
    etf_catalog_status,
    load_etf_catalog,
    parse_twse_etf_catalog,
    save_etf_catalog,
)


FIXTURES = Path(__file__).parent / "fixtures"


class EtfCatalogTests(unittest.TestCase):
    def test_parse_twse_all_etf_catalog_fixture(self) -> None:
        fixture = (FIXTURES / "00631l_twse_all_etf_fixture.json").read_text(
            encoding="utf-8"
        )

        payload = parse_twse_etf_catalog(
            fixture,
            source_url="fixture://twse/all_etf",
            fetched_at="2026-06-12T05:31:20+00:00",
        )

        self.assertEqual(payload["sourceStatus"], "official")
        self.assertEqual(payload["sourceContract"], "twse_all_etf_catalog")
        self.assertGreaterEqual(payload["rowCount"], 1)
        item = next(row for row in payload["items"] if row["code"] == "00631L")
        self.assertEqual(item["marketPrice"], 33.8)
        self.assertEqual(item["estimatedNav"], 33.55)
        self.assertEqual(item["premiumDiscountPct"], 0.75)

    def test_catalog_store_load_and_status(self) -> None:
        import tempfile

        payload = {
            "sourceStatus": "official",
            "sourceContract": "twse_all_etf_catalog",
            "sourceUrl": "fixture://twse/all_etf",
            "fetchedAt": "2026-06-12T05:31:20+00:00",
            "sourceUpdatedAt": "2026-06-12T13:31:00+08:00",
            "dataTime": "2026-06-12T13:31:00+08:00",
            "isStale": False,
            "rowCount": 1,
            "items": [{"code": "00631L", "name": "元大台灣50正2"}],
            "errorMessage": None,
        }

        with tempfile.TemporaryDirectory() as temp_dir:
            path = Path(temp_dir) / "catalog.json"
            save_etf_catalog(payload, path)
            loaded = load_etf_catalog(path, fetched_at="2026-06-12T05:32:00+00:00")
            status = etf_catalog_status(path, fetched_at="2026-06-12T05:32:00+00:00")

        self.assertEqual(loaded["sourceStatus"], "cached")
        self.assertEqual(loaded["rowCount"], 1)
        self.assertEqual(status["sourceStatus"], "cached")
        self.assertEqual(status["rowCount"], 1)


if __name__ == "__main__":
    unittest.main()
