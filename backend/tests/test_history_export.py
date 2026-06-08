from pathlib import Path
import csv
import tempfile
import unittest

from backend.app.history_export import export_00631l_history
from backend.app.holdings_history import HoldingsHistoryStore
from backend.app.intraday_nav_history import IntradayNavHistoryStore
from backend.app.parsers import parse_holdings, parse_intraday_nav


FIXTURES = Path(__file__).parent / "fixtures"


class HistoryExportTests(unittest.TestCase):
    def test_exports_holdings_and_intraday_history_to_csv(self) -> None:
        holdings_source = (FIXTURES / "00631l_yuanta_ratio_fixture.txt").read_text(
            encoding="utf-8"
        )
        intraday_source = (FIXTURES / "00631l_twse_all_etf_fixture.json").read_text(
            encoding="utf-8"
        )

        with tempfile.TemporaryDirectory() as temp_dir:
            temp_path = Path(temp_dir)
            holdings_path = temp_path / "holdings.jsonl"
            intraday_path = temp_path / "intraday.jsonl"
            output_dir = temp_path / "exports"

            HoldingsHistoryStore(holdings_path).save_official_snapshot(
                parse_holdings(
                    holdings_source,
                    source_url="fixture://yuanta/ratio",
                    fetched_at="2026-06-08T01:00:00+00:00",
                )
            )
            IntradayNavHistoryStore(intraday_path).save_official_nav(
                parse_intraday_nav(
                    intraday_source,
                    source_url="fixture://twse/all_etf",
                    fetched_at="2026-06-08T01:01:00+00:00",
                )
            )

            payload = export_00631l_history(
                holdings_history_path=holdings_path,
                intraday_history_path=intraday_path,
                output_dir=output_dir,
            )

            self.assertEqual(payload["sourceStatus"], "cached")
            self.assertEqual(payload["holdingsRowCount"], 1)
            self.assertEqual(payload["intradayRowCount"], 1)

            holdings_rows = _read_csv(Path(payload["holdingsOutputPath"]))
            self.assertEqual(holdings_rows[0]["tradeDate"], "2026-06-05")
            self.assertEqual(holdings_rows[0]["txWeightPct"], "161.53")
            self.assertEqual(holdings_rows[0]["tsmcWeightPct"], "37.44")
            self.assertIn("stockExposurePct", holdings_rows[0])
            self.assertIn("futuresExposurePct", holdings_rows[0])
            self.assertIn("cashAndMarginPct", holdings_rows[0])
            self.assertGreater(float(holdings_rows[0]["stockExposurePct"]), 0)
            self.assertGreater(float(holdings_rows[0]["futuresExposurePct"]), 0)
            self.assertGreater(float(holdings_rows[0]["cashAndMarginPct"]), 0)

            intraday_rows = _read_csv(Path(payload["intradayOutputPath"]))
            self.assertEqual(intraday_rows[0]["dataDate"], "2026-06-08")
            self.assertEqual(intraday_rows[0]["sourceContract"], "twse_a_k_json")
            self.assertEqual(intraday_rows[0]["premiumDiscountPct"], "0.75")
            metadata_path = Path(payload["metadataOutputPath"])
            self.assertTrue(metadata_path.exists())
            self.assertEqual(payload["totalRowCount"], 2)
            self.assertEqual(
                payload["sourceHistoryRange"]["holdingsStartDate"],
                "2026-06-05",
            )


def _read_csv(path: Path) -> list[dict[str, str]]:
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        return list(csv.DictReader(handle))


if __name__ == "__main__":
    unittest.main()
