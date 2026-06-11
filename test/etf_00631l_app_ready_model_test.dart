import 'package:flutter_test/flutter_test.dart';
import 'package:longterm_stock_research_assistant/models/leveraged_etf_lab.dart';

void main() {
  test('price history performance calculates return and drawdown', () {
    final history = EtfPriceHistory(
      points: _pricePoints,
      status: EtfDataStatus.cached,
      sourceStatusLabel: 'cached',
      sourceUrl: 'local://00631l-price-history',
      lastFetchedAt: DateTime(2026, 6, 11),
      coverageStart: DateTime(2026, 6, 1),
      coverageEnd: DateTime(2026, 6, 3),
      isCompleteFromListing: false,
    );

    final performance = history.performance;

    expect(performance.totalReturnPct, closeTo(-1.639, 0.01));
    expect(performance.maxDrawdownPct, lessThan(0));
    expect(performance.bestDailyReturnPct, greaterThan(0));
    expect(performance.worstDailyReturnPct, lessThan(0));
  });

  test('price history completeness summary uses OHLC volume and range data',
      () {
    final history = EtfPriceHistory(
      points: _richPricePoints,
      status: EtfDataStatus.cached,
      sourceStatusLabel: 'static_official',
      sourceUrl: 'local://00631l-price-history',
      lastFetchedAt: DateTime(2026, 6, 11),
      coverageStart: DateTime(2026, 6, 1),
      coverageEnd: DateTime(2026, 6, 4),
      isCompleteFromListing: true,
    );

    final summary = history.completenessSummary(trailingRows: 3);

    expect(summary.rowCount, 4);
    expect(summary.isCompleteFromListing, isTrue);
    expect(summary.latest?.close, 32.0);
    expect(summary.previous?.close, 30.0);
    expect(summary.latestCloseChange, 2.0);
    expect(summary.latestDailyReturnPct, closeTo(6.666, 0.01));
    expect(summary.trailingHighClose, 32.0);
    expect(summary.trailingLowClose, 30.0);
    expect(summary.trailingHighDate, DateTime(2026, 6, 4));
    expect(summary.hasOhlc, isTrue);
    expect(summary.hasVolume, isTrue);
    expect(summary.hasNav, isTrue);
    expect(summary.hasPremiumDiscount, isTrue);
  });

  test('backtest engine returns equity and drawdown curves', () {
    final result = const EtfBacktestEngine().run(
      request: EtfBacktestRequest(
        strategy: EtfBacktestStrategy.lumpSum,
        startDate: DateTime(2026, 6),
        endDate: DateTime(2026, 6, 3),
        initialAmount: 100000,
        monthlyAmount: 0,
        monthlyDay: 5,
        feeRatePct: 0,
      ),
      history: _pricePoints,
    );

    expect(result.sourceStatusLabel, 'calculated');
    expect(result.totalInvested, 100000);
    expect(result.equityCurve, hasLength(3));
    expect(result.drawdownCurve.last.value, lessThan(0));
  });

  test('position tracking calculates local-only summary', () {
    final summary = EtfPositionSummary.evaluate(
      input: const EtfPositionInput(
        shares: 1000,
        averageCost: 30,
        totalAssets: 100000,
        feeAndTax: 100,
      ),
      marketPrice: 33,
      dataTime: DateTime(2026, 6, 11, 10),
    );

    expect(summary.marketValue, 33000);
    expect(summary.cost, 30100);
    expect(summary.unrealizedPnl, 2900);
    expect(summary.unrealizedPnlPct, closeTo(9.63, 0.01));
    expect(summary.assetWeightPct, 33);
  });
}

final _pricePoints = [
  EtfPriceHistoryPoint(date: DateTime(2026, 6, 1), close: 30.5),
  EtfPriceHistoryPoint(date: DateTime(2026, 6, 2), close: 31.0),
  EtfPriceHistoryPoint(date: DateTime(2026, 6, 3), close: 30.0),
];

final _richPricePoints = [
  EtfPriceHistoryPoint(
    date: DateTime(2026, 6),
    open: 30,
    high: 31,
    low: 29.8,
    close: 30.5,
    volume: 1000000,
    nav: 30.4,
    premiumDiscountPct: 0.33,
  ),
  EtfPriceHistoryPoint(
    date: DateTime(2026, 6, 2),
    open: 30.6,
    high: 31.2,
    low: 30.4,
    close: 31.0,
    volume: 1100000,
    nav: 30.9,
    premiumDiscountPct: 0.32,
  ),
  EtfPriceHistoryPoint(
    date: DateTime(2026, 6, 3),
    open: 30.8,
    high: 31.1,
    low: 29.9,
    close: 30.0,
    volume: 1200000,
    nav: 30.1,
    premiumDiscountPct: -0.33,
  ),
  EtfPriceHistoryPoint(
    date: DateTime(2026, 6, 4),
    open: 30.2,
    high: 32.3,
    low: 30.0,
    close: 32.0,
    volume: 1300000,
    nav: 31.9,
    premiumDiscountPct: 0.31,
  ),
];
