import 'package:flutter_test/flutter_test.dart';
import 'package:longterm_stock_research_assistant/models/screener_condition.dart';
import 'package:longterm_stock_research_assistant/repositories/mock_stock_repository.dart';

void main() {
  test('mock stock repository includes Taiwan research samples', () async {
    final repository = MockStockRepository();

    final stocks = await repository.fetchWatchlist();
    final symbols = stocks.map((stock) => stock.symbol).toSet();

    expect(stocks.length, greaterThanOrEqualTo(8));
    expect(
        symbols.containsAll(
            {'2330', '2317', '2454', '2308', '2412', '2881', '1301', '1216'}),
        isTrue);
  });

  test('mock screener filters by conservative research conditions', () async {
    final repository = MockStockRepository();

    final stocks = await repository.filterByCondition(
      const ScreenerCondition(
        minRoe: 15,
        minRevenueYoy: 8,
        maxPe: 30,
        minDividendYield: 1.5,
        minQualityScore: 75,
        requireAboveMa200: true,
      ),
    );

    expect(stocks, isNotEmpty);
    expect(stocks.every((stock) => stock.metric.roe >= 15), isTrue);
    expect(stocks.every((stock) => stock.metric.aboveMa200), isTrue);
  });

  test('mock app copy avoids explicit trading instruction keywords', () async {
    final repository = MockStockRepository();
    final stocks = await repository.fetchWatchlist();
    const blockedTerms = [
      '買' '進',
      '賣' '出',
      '目標' '價',
      '停損' '價',
      '保證' '獲利',
      '報' '明牌',
      '必' '買',
      '飆' '股',
      '強力' '推' '薦',
      '推' '薦' '股票',
    ];

    final combinedCopy = stocks
        .expand((stock) => [
              stock.name,
              stock.industry,
              stock.pricePositionDescription,
              stock.mockSummary,
              stock.valuation.rangeLabel,
              ...stock.tags,
              ...stock.riskAlerts
                  .expand((alert) => [alert.title, alert.description]),
            ])
        .join('\n');

    for (final term in blockedTerms) {
      expect(
        combinedCopy.contains(term),
        isFalse,
        reason: 'Blocked term found: $term',
      );
    }
  });
}
