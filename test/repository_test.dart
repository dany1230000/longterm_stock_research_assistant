import 'package:flutter_test/flutter_test.dart';
import 'package:longterm_stock_research_assistant/models/screener_condition.dart';
import 'package:longterm_stock_research_assistant/models/screener_preset.dart';
import 'package:longterm_stock_research_assistant/models/journal_entry.dart';
import 'package:longterm_stock_research_assistant/repositories/in_memory_journal_repository.dart';
import 'package:longterm_stock_research_assistant/repositories/in_memory_screener_preset_repository.dart';
import 'package:longterm_stock_research_assistant/repositories/mock_backtest_repository.dart';
import 'package:longterm_stock_research_assistant/repositories/mock_etf_repository.dart';
import 'package:longterm_stock_research_assistant/repositories/mock_portfolio_repository.dart';
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
        maxPb: 6,
        minDividendYield: 1.5,
        minQualityScore: 75,
        minGrowthScore: 70,
        minValuationScore: 55,
        requireAboveMa200: true,
      ),
    );

    expect(stocks, isNotEmpty);
    expect(stocks.every((stock) => stock.metric.roe >= 15), isTrue);
    expect(stocks.every((stock) => stock.metric.aboveMa200), isTrue);
  });

  test('screener preset repository saves loads and deletes local presets', () {
    final repository = InMemoryScreenerPresetRepository();
    final preset = ScreenerPreset(
      id: 'preset-1',
      name: '品質研究條件',
      condition: const ScreenerCondition(minRoe: 18),
      createdAt: DateTime(2026, 6, 4),
    );

    repository.savePreset(preset);
    expect(repository.fetchPresets(), hasLength(1));
    expect(repository.fetchPresets().single.condition.minRoe, 18);

    repository.deletePreset('preset-1');
    expect(repository.fetchPresets(), isEmpty);
  });

  test('journal repository adds edits and deletes entries', () {
    final repository = InMemoryJournalRepository();
    final entry = JournalEntry(
      id: 'journal-1',
      symbol: '2330',
      stockName: '台積電',
      researchDate: DateTime(2026, 6, 4),
      topic: '財務趨勢檢視',
      researchReason: '觀察營收與毛利率。',
      observationFocus: '營收 YoY',
      riskAssumption: '估值分位偏高',
      emotionTag: EmotionTag.calm,
      reviewNote: '',
    );

    repository.addEntry(entry);
    expect(repository.fetchEntries(), hasLength(1));

    repository.updateEntry(entry.copyWith(reviewNote: '已完成檢討'));
    expect(repository.fetchEntries().single.reviewNote, '已完成檢討');

    repository.deleteEntry('journal-1');
    expect(repository.fetchEntries(), isEmpty);
  });

  test('mock strategy repository switches strategy data by id', () async {
    final repository = MockBacktestRepository();
    final strategies = await repository.fetchStrategies();
    final revenueStrategy =
        await repository.fetchStrategyById('revenue-acceleration');

    expect(strategies, hasLength(4));
    expect(revenueStrategy.strategyName, '營收轉強策略');
    expect(revenueStrategy.equityCurve, isNotEmpty);
    expect(revenueStrategy.events, isNotEmpty);
  });

  test('mock ETF repository compares ETF overlap data', () async {
    final repository = MockEtfRepository();
    final etfs = await repository.fetchEtfs();
    final comparison = await repository.compareEtfs('0050', '006208');

    expect(etfs.map((etf) => etf.symbol), containsAll(['0050', '006208']));
    expect(comparison.overlapRate, greaterThan(80));
    expect(comparison.left.topHoldings, isNotEmpty);
  });

  test('mock portfolio repository builds risk summary', () async {
    final repository = MockPortfolioRepository();
    final risk = await repository.fetchMockPortfolioRisk();

    expect(risk.portfolio.holdings, isNotEmpty);
    expect(risk.industryConcentration, isNotEmpty);
    expect(risk.scenarios, hasLength(4));
    expect(risk.etfWeight + risk.stockWeight, closeTo(100, 0.01));
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
