import 'package:flutter_test/flutter_test.dart';
import 'package:longterm_stock_research_assistant/models/leveraged_etf_lab.dart';

void main() {
  group('IntradayMarketSession', () {
    test('regular session marks recent intraday NAV fresh', () {
      final session = IntradayMarketSession.evaluate(
        now: DateTime.utc(2026, 6, 16, 2, 0, 30),
        dataTime: DateTime(2026, 6, 16, 10, 0, 0),
        userDelayMs: 15000,
      );

      expect(session.phase, IntradayMarketPhase.regular);
      expect(session.phaseLabel, '盤中更新');
      expect(session.isRegularSession, isTrue);
      expect(session.dataFreshness, 'fresh');
      expect(session.isIntradayFresh, isTrue);
      expect(session.expectedRefreshSeconds, 15);
    });

    test('regular session marks old intraday NAV stale', () {
      final session = IntradayMarketSession.evaluate(
        now: DateTime.utc(2026, 6, 16, 2, 10),
        dataTime: DateTime(2026, 6, 16, 10, 0),
        userDelayMs: 15000,
      );

      expect(session.phase, IntradayMarketPhase.regular);
      expect(session.dataFreshness, 'stale');
      expect(session.isIntradayFresh, isFalse);
      expect(session.isDisplayUsable, isFalse);
    });

    test('post close uses same-day last data', () {
      final session = IntradayMarketSession.evaluate(
        now: DateTime.utc(2026, 6, 16, 5, 40),
        dataTime: DateTime(2026, 6, 16, 13, 31),
        userDelayMs: 15000,
      );

      expect(session.phase, IntradayMarketPhase.postCloseConfirm);
      expect(session.phaseLabel, '收盤確認');
      expect(session.dataFreshness, 'after_hours_last');
      expect(session.isDisplayUsable, isTrue);
      expect(session.isIntradayFresh, isFalse);
    });

    test('weekend uses market closed last data', () {
      final session = IntradayMarketSession.evaluate(
        now: DateTime.utc(2026, 6, 20, 2),
        dataTime: DateTime(2026, 6, 19, 13, 31),
        userDelayMs: 15000,
      );

      expect(session.phase, IntradayMarketPhase.closed);
      expect(session.isTradingDay, isFalse);
      expect(session.dataFreshness, 'market_closed_last');
      expect(session.isDisplayUsable, isTrue);
    });

    test('pre open labels previous trading day data explicitly', () {
      final session = IntradayMarketSession.evaluate(
        now: DateTime.utc(2026, 6, 28, 22, 0),
        dataTime: DateTime(2026, 6, 26, 13, 31),
        userDelayMs: 15000,
      );

      expect(session.phase, IntradayMarketPhase.preOpen);
      expect(session.phaseLabel, '前一交易日');
      expect(session.dataFreshness, 'previous_trading_day_last');
      expect(session.dataFreshnessLabel, '前一交易日資料');
      expect(session.isDisplayUsable, isTrue);
      expect(session.isIntradayFresh, isFalse);
    });

    test('EtfIntradayNav exposes market session from data time', () {
      final nav = EtfIntradayNav(
        symbol: '00631L',
        name: '00631L',
        outstandingUnits: null,
        outstandingUnitsDelta: null,
        marketPrice: 37.3,
        estimatedNav: 37.37,
        estimatedPremiumDiscountPct: -0.19,
        previousBusinessDayNav: 37.1,
        previousBusinessDayNavText: '37.1',
        dataDate: DateTime(2026, 6, 16),
        dataTime: DateTime(2026, 6, 16, 10, 0),
        targetType: '1',
        userDelayMs: 15000,
        sourceContract: 'twse_a_k_json',
        isStale: false,
        status: EtfDataStatus.official,
        lastFetchedAt: DateTime.utc(2026, 6, 16, 2, 0, 30),
      );

      final session = nav.marketSession(
        now: DateTime.utc(2026, 6, 16, 2, 0, 30),
      );

      expect(session.phase, IntradayMarketPhase.regular);
      expect(session.dataFreshness, 'fresh');
    });
  });
}
