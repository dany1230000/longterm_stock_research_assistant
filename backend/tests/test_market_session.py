import unittest

from backend.app.market_session import intraday_market_session


class IntradayMarketSessionTests(unittest.TestCase):
    def test_regular_session_marks_recent_data_fresh(self) -> None:
        session = intraday_market_session(
            now_iso="2026-06-16T02:00:30+00:00",
            data_time_iso="2026-06-16T10:00:00+08:00",
            user_delay_ms=15000,
        )

        self.assertEqual(session["timezone"], "Asia/Taipei")
        self.assertEqual(session["phase"], "regular")
        self.assertEqual(session["phaseLabel"], "盤中更新")
        self.assertTrue(session["isTradingDay"])
        self.assertTrue(session["isRegularSession"])
        self.assertEqual(session["expectedRefreshSeconds"], 15)
        self.assertEqual(session["dataFreshness"], "fresh")
        self.assertTrue(session["isIntradayFresh"])

    def test_regular_session_marks_old_data_stale(self) -> None:
        session = intraday_market_session(
            now_iso="2026-06-16T02:10:00+00:00",
            data_time_iso="2026-06-16T10:00:00+08:00",
            user_delay_ms=15000,
        )

        self.assertEqual(session["phase"], "regular")
        self.assertEqual(session["dataFreshness"], "stale")
        self.assertFalse(session["isIntradayFresh"])
        self.assertFalse(session["isDisplayUsable"])

    def test_post_close_uses_same_day_last_data(self) -> None:
        session = intraday_market_session(
            now_iso="2026-06-16T05:40:00+00:00",
            data_time_iso="2026-06-16T13:31:00+08:00",
            user_delay_ms=15000,
        )

        self.assertEqual(session["phase"], "post_close_confirm")
        self.assertEqual(session["phaseLabel"], "收盤確認")
        self.assertEqual(session["dataFreshness"], "after_hours_last")
        self.assertTrue(session["isDisplayUsable"])
        self.assertFalse(session["isIntradayFresh"])

    def test_after_close_uses_last_same_day_data(self) -> None:
        session = intraday_market_session(
            now_iso="2026-06-16T06:30:00+00:00",
            data_time_iso="2026-06-16T13:31:00+08:00",
            user_delay_ms=15000,
        )

        self.assertEqual(session["phase"], "after_close")
        self.assertEqual(session["dataFreshness"], "after_hours_last")
        self.assertTrue(session["isDisplayUsable"])

    def test_weekend_marks_market_closed_last_data(self) -> None:
        session = intraday_market_session(
            now_iso="2026-06-20T02:00:00+00:00",
            data_time_iso="2026-06-19T13:31:00+08:00",
            user_delay_ms=15000,
        )

        self.assertEqual(session["phase"], "closed")
        self.assertFalse(session["isTradingDay"])
        self.assertEqual(session["dataFreshness"], "market_closed_last")
        self.assertTrue(session["isDisplayUsable"])

    def test_pre_open_marks_previous_trading_day_last_data_usable(self) -> None:
        session = intraday_market_session(
            now_iso="2026-06-30T19:09:00+00:00",
            data_time_iso="2026-06-30T13:31:00+08:00",
            user_delay_ms=15000,
        )

        self.assertEqual(session["phase"], "pre_open")
        self.assertEqual(session["phaseLabel"], "盤前等待")
        self.assertEqual(session["dataFreshness"], "previous_trading_day_last")
        self.assertEqual(session["dataFreshnessLabel"], "前一交易日資料")
        self.assertTrue(session["isDisplayUsable"])
        self.assertFalse(session["isIntradayFresh"])

    def test_missing_data_is_unavailable(self) -> None:
        session = intraday_market_session(
            now_iso="2026-06-16T02:00:00+00:00",
            data_time_iso=None,
            user_delay_ms=15000,
        )

        self.assertEqual(session["phase"], "regular")
        self.assertEqual(session["dataFreshness"], "unavailable")
        self.assertFalse(session["isIntradayFresh"])
