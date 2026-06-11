import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:longterm_stock_research_assistant/features/leveraged_etf_lab/leveraged_etf_00631l_screen.dart';
import 'package:longterm_stock_research_assistant/models/leveraged_etf_lab.dart';
import 'package:longterm_stock_research_assistant/repositories/cached_00631l_repository.dart';
import 'package:longterm_stock_research_assistant/repositories/mock_00631l_repository.dart';
import 'package:longterm_stock_research_assistant/repositories/official_00631l_repository.dart';
import 'package:longterm_stock_research_assistant/repositories/repository_providers.dart';

void main() {
  testWidgets('00631L lab renders stock-app style quote header',
      (tester) async {
    await _pumpLab(tester, Mock00631LRepository());

    expect(find.text('00631L 正二研究室'), findsOneWidget);
    expect(find.text('市價'), findsOneWidget);
    expect(find.text('預估淨值'), findsOneWidget);
    expect(find.text('折溢價'), findsOneWidget);
    expect(find.text('市場資料'), findsOneWidget);
    expect(find.text('官方內容物'), findsWidgets);
    expect(find.text('總覽'), findsWidgets);
    expect(find.text('內容物'), findsWidgets);
    expect(find.text('歷史'), findsWidgets);
    expect(find.text('回測'), findsWidgets);
    expect(find.text('持倉'), findsWidgets);
    expect(find.text('AI 分析'), findsWidgets);
    expect(find.text('系統狀態'), findsWidgets);
    _expectNoTradingActionText();
  });

  testWidgets('00631L lab remains readable on phone width', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await _pumpLab(tester, Mock00631LRepository());

    expect(find.text('00631L 正二研究室'), findsOneWidget);
    expect(find.textContaining('frontend mock_default'), findsOneWidget);
    expect(find.text('市場資料'), findsOneWidget);
    expect(find.text('00631L ▼'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('history section shows price history when available',
      (tester) async {
    await _pumpLab(tester, _PriceHistoryRepository());

    await _tapSection(tester, 'history');
    await tester.pumpAndSettle();

    expect(find.text('價格 / 淨值歷史'), findsOneWidget);
    expect(find.text('歷史資料完整度'), findsWidgets);
    expect(find.text('累積報酬'), findsWidgets);
    expect(find.text('52 週區間'), findsWidgets);
    expect(find.text('成交量'), findsWidgets);
    expect(find.text('回撤'), findsWidgets);
    expect(find.text('2026/06/03'), findsWidgets);
    expect(find.text('每日 holdings history'), findsOneWidget);
    _expectNoTradingActionText();
  });

  testWidgets('history section shows empty state without official history',
      (tester) async {
    await _pumpLab(tester, _NoHistoryRepository());

    await _tapSection(tester, 'history');
    await tester.pumpAndSettle();

    expect(find.text('尚無 official price history'), findsWidgets);
    expect(find.text('尚無歷史紀錄'), findsWidgets);
  });

  testWidgets('backtest section renders inputs and disclaimer', (tester) async {
    await _pumpLab(tester, _PriceHistoryRepository());

    await _tapSection(tester, 'backtest');
    await tester.pumpAndSettle();

    expect(find.text('歷史回測'), findsWidgets);
    expect(find.text('一次投入'), findsOneWidget);
    expect(find.text('定期定額'), findsOneWidget);
    expect(find.text('期末市值'), findsOneWidget);
    expect(find.textContaining('回測不代表未來表現'), findsWidgets);
    expect(find.textContaining('非買賣建議'), findsWidgets);
    _expectNoTradingActionText();
  });

  testWidgets('position section saves local-only data controls',
      (tester) async {
    await _pumpLab(tester, Mock00631LRepository());

    await _tapSection(tester, 'position');
    await tester.pumpAndSettle();

    expect(find.text('持倉追蹤'), findsOneWidget);
    expect(find.text('保存本機資料'), findsOneWidget);
    expect(find.text('匯出 JSON'), findsOneWidget);
    expect(find.text('清除本機資料'), findsOneWidget);
    expect(find.textContaining('local-only'), findsOneWidget);
  });

  testWidgets('AI and system sections render clean status wording',
      (tester) async {
    await _pumpLab(tester, Mock00631LRepository());

    await _tapSection(tester, 'ai');
    await tester.pumpAndSettle();
    expect(find.text('AI 分析摘要'), findsOneWidget);
    expect(find.text('完整資料日報'), findsOneWidget);
    expect(find.textContaining('rule_based'), findsWidgets);
    expect(find.textContaining('非買賣建議'), findsWidgets);

    await _tapSection(tester, 'system');
    await tester.pumpAndSettle();
    expect(find.text('系統狀態'), findsWidgets);
    expect(find.text('backend'), findsOneWidget);
    expect(find.text('historical price'), findsOneWidget);
    expect(find.text('position local data'), findsOneWidget);
    _expectNoTradingActionText();
  });

  testWidgets('live proxy failure keeps fallback visible', (tester) async {
    await _pumpLab(
      tester,
      Cached00631LRepository(
        primary: _Error00631LRepository(),
        fallback: Mock00631LRepository(),
      ),
    );

    expect(find.text('00631L 正二研究室'), findsOneWidget);
    await _tapSection(tester, 'system');
    await tester.pumpAndSettle();
    expect(find.textContaining('backend disconnected'), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('dark mode toggle is available and does not crash',
      (tester) async {
    await _pumpLab(tester, Mock00631LRepository());

    expect(find.byIcon(Icons.dark_mode), findsOneWidget);
    await tester.tap(find.byIcon(Icons.dark_mode));
    await tester.pumpAndSettle();

    expect(find.text('00631L 正二研究室'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpLab(
  WidgetTester tester,
  Official00631LRepository repository,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        official00631LRepositoryProvider.overrideWithValue(repository),
      ],
      child: const MaterialApp(
        home: Scaffold(body: LeveragedEtf00631LScreen()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tapSection(WidgetTester tester, String sectionName) async {
  await tester.tap(find.byKey(ValueKey('00631l-section-$sectionName')));
}

class _PriceHistoryRepository extends Mock00631LRepository {
  @override
  Future<EtfPriceHistory> fetchPriceHistory({int limit = 5000}) async {
    final points = [
      EtfPriceHistoryPoint(
        date: DateTime(2026, 6, 1),
        open: 30.1,
        high: 30.9,
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
    ];
    return EtfPriceHistory(
      points: points,
      status: EtfDataStatus.cached,
      sourceStatusLabel: 'cached',
      sourceUrl: 'local://00631l-price-history',
      lastFetchedAt: DateTime(2026, 6, 11),
      coverageStart: points.first.date,
      coverageEnd: points.last.date,
      isCompleteFromListing: false,
    );
  }
}

class _NoHistoryRepository extends Mock00631LRepository {
  @override
  Future<EtfPriceHistory> fetchPriceHistory({int limit = 5000}) async {
    return EtfPriceHistory.empty(
      lastFetchedAt: DateTime(2026, 6, 11),
      status: EtfDataStatus.error,
      sourceStatusLabel: 'unavailable',
      sourceUrl: 'local://empty-price-history',
      errorMessage: 'No official price history fixture.',
    );
  }
}

class _Error00631LRepository extends Official00631LRepository {
  @override
  Future<LeveragedEtfProfile> fetchProfile() {
    throw const RepositoryFetchException('fixture failure');
  }

  @override
  Future<EtfDailyHoldingSnapshot> fetchDailySnapshot() {
    throw const RepositoryFetchException('fixture failure');
  }

  @override
  Future<EtfIntradayNav?> fetchIntradayNav() {
    throw const RepositoryFetchException('fixture failure');
  }

  @override
  Future<FuturesQuote> fetchFuturesQuote() {
    throw const RepositoryFetchException('fixture failure');
  }

  @override
  Future<Etf00631LLabData> fetchLabData() {
    throw const RepositoryFetchException('fixture failure');
  }

  @override
  Future<EtfOperationsStatus> fetchOperationsStatus() {
    throw const RepositoryFetchException('backend fixture failure');
  }
}

void _expectNoTradingActionText() {
  for (final forbidden in const [
    '\u8cb7\u9032',
    '\u8ce3\u51fa',
    '\u52a0\u78bc',
    '\u6e1b\u78bc',
    '\u9032\u5834',
    '\u51fa\u5834',
    '\u5957\u5229',
    '\u9069\u5408\u8cb7',
    '\u4fbf\u5b9c\u53ef\u4ee5\u8cb7',
    '\u592a\u8cb4\u4e0d\u8981\u8cb7',
  ]) {
    expect(find.textContaining(forbidden), findsNothing);
  }
}
