from pathlib import Path
import unittest

from backend.app.parsers import parse_holdings, parse_intraday_nav, parse_profile, parse_yuanta_intraday_nav


FIXTURES = Path(__file__).parent / "fixtures"


class ParserTests(unittest.TestCase):
    def test_holdings_parser_extracts_official_snapshot_fields(self) -> None:
        source = (FIXTURES / "00631l_yuanta_ratio_fixture.txt").read_text(encoding="utf-8")
        snapshot = parse_holdings(
            source,
            source_url="fixture://yuanta/00631l/ratio",
            fetched_at="2026-06-08T10:15:00+00:00",
            source_status="mock",
        )

        self.assertEqual(snapshot["tradeDate"], "2026-06-05")
        self.assertEqual(snapshot["fundNetAssetValue"], 189_796_511_953)
        self.assertEqual(snapshot["navPerUnit"], 36.56)
        self.assertEqual(snapshot["outstandingUnits"], 5_190_848_000)
        self.assertEqual(snapshot["assetValues"]["stock"], 71_056_425_000)
        self.assertEqual(snapshot["assetValues"]["futures"], 306_587_054_000)

    def test_holdings_parser_extracts_lines(self) -> None:
        source = (FIXTURES / "00631l_yuanta_ratio_fixture.txt").read_text(encoding="utf-8")
        snapshot = parse_holdings(
            source,
            source_url="fixture://yuanta/00631l/ratio",
            fetched_at="2026-06-08T10:15:00+00:00",
            source_status="mock",
        )

        tsmc = snapshot["stockHoldings"][0]
        self.assertEqual(tsmc["code"], "2330")
        self.assertEqual(tsmc["name"], "台積電")
        self.assertEqual(tsmc["quantity"], 30_045_000)
        self.assertEqual(tsmc["weightPct"], 37.44)

        tx = snapshot["futuresHoldings"][0]
        self.assertEqual(tx["code"], "TX")
        self.assertEqual(tx["name"], "臺股期貨")
        self.assertEqual(tx["quantity"], 33_895)
        self.assertEqual(tx["weightPct"], 161.53)
        self.assertEqual(tx["contractMonth"], "202606")

        cash = {line["item"]: line["amount"] for line in snapshot["cashHoldings"]}
        self.assertEqual(cash["保證金"], 79_303_829_574)
        self.assertEqual(cash["現金"], 26_950_925_242)
        self.assertEqual(cash["附買回債券"], 19_950_000_000)
        self.assertEqual(cash["應收利息"], 129_448_503)
        self.assertEqual(cash["應付申購預收款"], -1_758_961_440)

    def test_intraday_nav_parser_maps_a_to_k_fields(self) -> None:
        source = (FIXTURES / "00631l_twse_intraday_nav_fixture.json").read_text(encoding="utf-8")
        nav = parse_intraday_nav(
            source,
            source_url="fixture://twse/nav",
            fetched_at="2026-06-08T10:15:00+00:00",
            source_status="mock",
        )

        self.assertEqual(nav["symbol"], "00631L")
        self.assertEqual(nav["name"], "元大台灣50正2")
        self.assertEqual(nav["outstandingUnits"], 5_190_848_000)
        self.assertEqual(nav["outstandingUnitsDelta"], 0)
        self.assertEqual(nav["marketPrice"], 36.72)
        self.assertEqual(nav["estimatedNav"], 36.56)
        self.assertEqual(nav["estimatedPremiumDiscountPct"], 0.44)
        self.assertEqual(nav["previousBusinessDayNav"], 36.30)
        self.assertEqual(nav["dataDate"], "2026-06-05")
        self.assertEqual(nav["dataTime"], "2026-06-05T13:30:00+08:00")
        self.assertEqual(nav["targetType"], "1")
        self.assertEqual(nav["userDelayMs"], 15000)
        self.assertEqual(nav["sourceContract"], "twse_a_k_json")
        self.assertEqual(nav["code"], "00631L")
        self.assertEqual(nav["premiumDiscountPct"], 0.44)

    def test_intraday_nav_parser_maps_twse_aggregated_a_to_k_feed(self) -> None:
        source = (FIXTURES / "00631l_twse_all_etf_fixture.json").read_text(encoding="utf-8")
        nav = parse_intraday_nav(
            source,
            source_url="fixture://twse/all_etf",
            fetched_at="2026-06-08T10:15:00+00:00",
            source_status="mock",
        )

        self.assertEqual(nav["symbol"], "00631L")
        self.assertEqual(nav["name"], "元大台灣50正2")
        self.assertEqual(nav["outstandingUnits"], 5_190_848_000)
        self.assertEqual(nav["outstandingUnitsDelta"], 240_000_000)
        self.assertEqual(nav["marketPrice"], 33.8)
        self.assertEqual(nav["estimatedNav"], 33.55)
        self.assertEqual(nav["premiumDiscountPct"], 0.75)
        self.assertEqual(nav["previousNav"], 36.56)
        self.assertEqual(nav["dataDate"], "2026-06-08")
        self.assertEqual(nav["dataTime"], "2026-06-08T13:31:00+08:00")
        self.assertEqual(nav["sourceContract"], "twse_a_k_json")

    def test_yuanta_inav_parser_maps_official_inav_payload(self) -> None:
        source = (FIXTURES / "00631l_yuanta_inav_fixture.json").read_text(encoding="utf-8")
        nav = parse_yuanta_intraday_nav(
            source,
            source_url="fixture://yuanta/inav",
            fetched_at="2026-06-08T10:15:00+00:00",
            source_status="mock",
        )

        self.assertEqual(nav["symbol"], "00631L")
        self.assertEqual(nav["name"], "元大台灣50正2")
        self.assertEqual(nav["outstandingUnits"], 5_190_848_000)
        self.assertIsNone(nav["outstandingUnitsDelta"])
        self.assertEqual(nav["marketPrice"], 33.8)
        self.assertEqual(nav["estimatedNav"], 33.55)
        self.assertEqual(nav["premiumDiscountPct"], 0.75)
        self.assertEqual(nav["previousNav"], 36.56)
        self.assertEqual(nav["dataDate"], "2026-06-08")
        self.assertEqual(nav["dataTime"], "2026-06-08T13:31:00+08:00")
        self.assertEqual(nav["sourceContract"], "yuanta_inav")

    def test_missing_holdings_data_returns_error_without_crashing(self) -> None:
        snapshot = parse_holdings(
            "Trade Date:",
            source_url="fixture://bad",
            fetched_at="2026-06-08T10:15:00+00:00",
        )

        self.assertEqual(snapshot["sourceStatus"], "error")
        self.assertIsNotNone(snapshot["errorMessage"])
        self.assertEqual(snapshot["stockHoldings"], [])

    def test_yuanta_profile_maintenance_page_is_unavailable(self) -> None:
        source = (
            "<title>元大投信 Yuanta ETFs | 停機公告</title>"
            "<script>window.__NUXT__={layout:\"maintenance\",routePath:\"\\u002Fmaintenance\"}</script>"
            "<main>公告： 2026/06/13(六)08:00~20:00 止將進行主機系統維護，作業期間將暫停服務。</main>"
        )
        profile = parse_profile(
            source,
            source_url="fixture://yuanta/basic",
            fetched_at="2026-06-13T00:00:00+00:00",
        )

        self.assertEqual(profile["sourceStatus"], "unavailable")
        self.assertEqual(profile["sourceContract"], "yuanta_maintenance")
        self.assertTrue(profile["isStale"])
        self.assertIn("maintenance", profile["errorMessage"])

    def test_yuanta_holdings_maintenance_page_is_unavailable(self) -> None:
        source = (
            "<title>元大投信 Yuanta ETFs | 停機公告</title>"
            "<script>window.__NUXT__={layout:\"maintenance\",routePath:\"\\u002Fmaintenance\"}</script>"
            "<main>公告： 2026/06/13(六)08:00~20:00 止將進行主機系統維護，作業期間將暫停服務。</main>"
        )
        snapshot = parse_holdings(
            source,
            source_url="fixture://yuanta/ratio",
            fetched_at="2026-06-13T00:00:00+00:00",
        )

        self.assertEqual(snapshot["sourceStatus"], "unavailable")
        self.assertEqual(snapshot["sourceContract"], "yuanta_maintenance")
        self.assertEqual(snapshot["stockHoldings"], [])
        self.assertIn("maintenance", snapshot["errorMessage"])


if __name__ == "__main__":
    unittest.main()
