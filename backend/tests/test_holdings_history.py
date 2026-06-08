from pathlib import Path
import tempfile
import unittest

from backend.app.holdings_history import HoldingsHistoryStore
from backend.app.parsers import parse_holdings


FIXTURES = Path(__file__).parent / "fixtures"


class HoldingsHistoryStoreTests(unittest.TestCase):
    def test_save_official_snapshot_deduplicates_by_trade_date(self) -> None:
        source = (FIXTURES / "00631l_yuanta_ratio_fixture.txt").read_text(encoding="utf-8")
        snapshot = parse_holdings(
            source,
            source_url="fixture://yuanta/00631l/ratio",
            fetched_at="2026-06-08T10:15:00+00:00",
        )

        with tempfile.TemporaryDirectory() as temp_dir:
            store = HoldingsHistoryStore(Path(temp_dir) / "history.jsonl")

            self.assertTrue(store.save_official_snapshot(snapshot))
            self.assertFalse(store.save_official_snapshot(snapshot))
            self.assertEqual(len(store.recent(30)), 1)

            changed = dict(snapshot)
            changed["sourceHash"] = "changed-source"
            changed["navPerUnit"] = 35.12

            self.assertTrue(store.save_official_snapshot(changed))
            recent = store.recent(30)
            self.assertEqual(len(recent), 1)
            self.assertEqual(recent[0]["tradeDate"], snapshot["tradeDate"])
            self.assertEqual(recent[0]["sourceHash"], "changed-source")
            self.assertEqual(recent[0]["navPerUnit"], 35.12)

    def test_summary_contains_core_exposure_fields(self) -> None:
        source = (FIXTURES / "00631l_yuanta_ratio_fixture.txt").read_text(encoding="utf-8")
        snapshot = parse_holdings(
            source,
            source_url="fixture://yuanta/00631l/ratio",
            fetched_at="2026-06-08T10:15:00+00:00",
        )

        with tempfile.TemporaryDirectory() as temp_dir:
            store = HoldingsHistoryStore(Path(temp_dir) / "history.jsonl")
            store.save_official_snapshot(snapshot)

            payload = store.summary_response(
                limit=30,
                fetched_at="2026-06-08T10:16:00+00:00",
            )

            item = payload["items"][0]
            self.assertEqual(item["tradeDate"], "2026-06-05")
            self.assertEqual(item["txWeightPct"], 161.53)
            self.assertEqual(item["tsmcWeightPct"], 37.44)
            self.assertGreater(item["stockExposurePct"], 0)
            self.assertGreater(item["futuresExposurePct"], 0)
            self.assertGreater(item["cashAndMarginPct"], 0)


if __name__ == "__main__":
    unittest.main()
