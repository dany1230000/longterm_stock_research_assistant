import json
import unittest

try:
    from fastapi.testclient import TestClient
    import backend.app.main as main_module
    from backend.app.cache import TimedMemoryCache
    from backend.app.config import Settings
    import backend.app.service as service_module
    from backend.app.service import Etf00631LService
    from backend.app.taifex_tx import (
        contract_month_from_taifex_symbol,
        normalize_taifex_tx_quote,
        parse_sockjs_quote_events,
        resolve_taifex_tx_futures_symbols,
    )

    HAS_FASTAPI = True
except ModuleNotFoundError:
    HAS_FASTAPI = False


@unittest.skipUnless(HAS_FASTAPI, "FastAPI is not installed in this environment")
class TaifexTxQuoteTests(unittest.TestCase):
    def test_parse_sockjs_quote_events_and_normalize_tx_quote(self) -> None:
        futures_event = {
            "type": "quote",
            "quote": {
                "symbol": "TXFF6-F",
                "values": {
                    "55": "TXFF6-F",
                    "125": "27125",
                    "129": "27076",
                    "143": "133115",
                    "144": "20260612",
                },
            },
        }
        spot_event = {
            "type": "quote",
            "quote": {
                "symbol": "TXF-S",
                "values": {
                    "55": "TXF-S",
                    "125": "27080.5",
                    "129": "27000",
                    "143": "133115",
                    "144": "20260612",
                },
            },
        }
        line = "data: a" + json.dumps(
            [json.dumps(futures_event), json.dumps(spot_event)]
        )

        events = parse_sockjs_quote_events(line)
        quotes = {event["quote"]["symbol"]: event["quote"] for event in events}
        payload = normalize_taifex_tx_quote(
            quotes,
            futures_symbol="TXFF6-F",
            spot_symbol="TXF-S",
            source_url="fixture://taifex/rt",
            fetched_at="2026-06-12T05:31:20+00:00",
        )

        self.assertEqual(payload["sourceStatus"], "official")
        self.assertEqual(payload["sourceContract"], "taifex_sockjs_quote")
        self.assertEqual(payload["txSymbol"], "TXFF6-F")
        self.assertEqual(payload["contractMonth"], "202606")
        self.assertEqual(payload["txPrice"], 27125.0)
        self.assertEqual(payload["weightedIndex"], 27080.5)
        self.assertAlmostEqual(payload["futuresBasisPoints"], 44.5)
        self.assertAlmostEqual(payload["futuresBasisPct"], 0.1643, places=3)
        self.assertEqual(payload["dataTime"], "2026-06-12T13:31:15+08:00")
        self.assertFalse(payload["isStale"])

    def test_normalize_tx_quote_marks_old_quote_stale(self) -> None:
        futures_event = {
            "type": "quote",
            "quote": {
                "symbol": "TXFF6-F",
                "values": {
                    "55": "TXFF6-F",
                    "125": "27125",
                    "129": "27076",
                    "143": "133115",
                    "144": "20260612",
                },
            },
        }
        spot_event = {
            "type": "quote",
            "quote": {
                "symbol": "TXF-S",
                "values": {
                    "55": "TXF-S",
                    "125": "27080.5",
                    "129": "27000",
                    "143": "133115",
                    "144": "20260612",
                },
            },
        }
        quotes = {
            "TXFF6-F": futures_event["quote"],
            "TXF-S": spot_event["quote"],
        }

        payload = normalize_taifex_tx_quote(
            quotes,
            futures_symbol="TXFF6-F",
            spot_symbol="TXF-S",
            source_url="fixture://taifex/rt",
            fetched_at="2026-06-13T05:31:20+00:00",
        )

        self.assertEqual(payload["sourceStatus"], "stale")
        self.assertTrue(payload["isStale"])

    def test_resolve_front_month_symbol_before_and_after_expiry_cutoff(self) -> None:
        before_cutoff = resolve_taifex_tx_futures_symbols(
            "auto",
            fetched_at="2026-06-17T05:19:00+00:00",
        )
        after_cutoff = resolve_taifex_tx_futures_symbols(
            "auto",
            fetched_at="2026-06-17T06:31:00+00:00",
        )
        legacy_config = resolve_taifex_tx_futures_symbols(
            "TXF-P",
            fetched_at="2026-06-17T05:19:00+00:00",
        )

        self.assertEqual(before_cutoff[0], "TXFF6-F")
        self.assertEqual(after_cutoff[0], "TXFG6-F")
        self.assertEqual(legacy_config[0], "TXFF6-F")
        self.assertIn("TXFG6-F", before_cutoff)

    def test_contract_month_from_taifex_symbol(self) -> None:
        self.assertEqual(
            contract_month_from_taifex_symbol(
                "TXFF6-F",
                fetched_at="2026-06-17T05:19:00+00:00",
            ),
            "202606",
        )
        self.assertEqual(
            contract_month_from_taifex_symbol(
                "TXFG6-F",
                fetched_at="2026-06-17T06:31:00+00:00",
            ),
            "202607",
        )
        self.assertEqual(
            contract_month_from_taifex_symbol(
                "TXF-P",
                fetched_at="2026-06-17T05:19:00+00:00",
            ),
            "front_month",
        )

    def test_tx_quote_endpoint_returns_unavailable_without_config(self) -> None:
        service = Etf00631LService(
            config=Settings(taifex_tx_sockjs_url=""),
            cache=TimedMemoryCache(),
        )
        client = TestClient(main_module.create_app(app_service=service))

        response = client.get("/api/etf/00631l/tx-quote")
        self.assertEqual(response.status_code, 200)
        payload = response.json()
        self.assertEqual(payload["symbol"], "TX")
        self.assertEqual(payload["sourceStatus"], "unavailable")
        self.assertEqual(payload["sourceContract"], "taifex_sockjs_quote")

    def test_tx_quote_endpoint_uses_normalized_fetcher_result(self) -> None:
        original_fetch = service_module.fetch_taifex_tx_quote

        def fake_fetch(config, *, fetched_at):
            return {
                "symbol": "TX",
                "contractMonth": "202606",
                "txSymbol": "TXFF6-F",
                "spotSymbol": "TXF-S",
                "txPrice": 27125.0,
                "weightedIndex": 27080.5,
                "futuresBasisPoints": 44.5,
                "futuresBasisPct": 0.1643,
                "nightSessionChange": 0.18,
                "sourceStatus": "official",
                "sourceContract": "taifex_sockjs_quote",
                "sourceUrl": config.sockjs_url,
                "fetchedAt": fetched_at,
                "sourceUpdatedAt": "2026-06-12T13:31:15+08:00",
                "dataTime": "2026-06-12T13:31:15+08:00",
                "isStale": False,
                "errorMessage": None,
            }

        try:
            service_module.fetch_taifex_tx_quote = fake_fetch
            service = Etf00631LService(
                config=Settings(
                    taifex_tx_sockjs_url="fixture://taifex/rt",
                    taifex_tx_futures_symbol="auto",
                    taifex_tx_spot_symbol="TXF-S",
                ),
                cache=TimedMemoryCache(),
            )
            client = TestClient(main_module.create_app(app_service=service))

            payload = client.get("/api/etf/00631l/tx-quote").json()
            self.assertEqual(payload["sourceStatus"], "official")
            self.assertEqual(payload["sourceContract"], "taifex_sockjs_quote")
            self.assertEqual(payload["txPrice"], 27125.0)
            self.assertEqual(payload["weightedIndex"], 27080.5)
        finally:
            service_module.fetch_taifex_tx_quote = original_fetch


if __name__ == "__main__":
    unittest.main()
