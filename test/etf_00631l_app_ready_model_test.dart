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
