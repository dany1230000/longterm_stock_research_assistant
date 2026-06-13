import 'dart:async';

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

    expect(find.text('00631L 正二研究室'), findsWidgets);
    expect(find.textContaining('市價'), findsWidgets);
    expect(find.textContaining('預估淨值'), findsWidgets);
    expect(find.text('折溢價'), findsWidgets);
    expect(find.text('核心資料'), findsOneWidget);
    expect(find.text('資料完整度'), findsNothing);
    expect(find.text('回測'), findsNothing);
    expect(find.text('可用'), findsNothing);
    expect(find.text('圖表與曝險'), findsNothing);
    expect(find.text('更多資料'), findsOneWidget);
    expect(find.text('完整數字比較'), findsNothing);
    expect(find.text('資料來源'), findsNothing);
    expect(find.text('更多資料狀態'), findsNothing);
    expect(find.text('7 / 30 日內容物變化'), findsNothing);
    expect(find.text('內容物重點'), findsOneWidget);
    expect(find.textContaining('歷史資料'), findsWidgets);
    expect(find.text('累積報酬'), findsOneWidget);
    expect(find.text('近 60 日收盤'), findsOneWidget);
    expect(find.text('官方曝險'), findsOneWidget);
    expect(find.text('官方 NAV'), findsNothing);
    expect(find.textContaining('Mock 預設'), findsWidgets);
    expect(find.text('總覽'), findsWidgets);
    expect(find.text('內容物'), findsWidgets);
    expect(find.text('歷史回測'), findsWidgets);
    expect(find.text('持倉'), findsWidgets);
    expect(find.text('AI 分析'), findsWidgets);
    expect(find.text('設定'), findsWidgets);
    for (final section in const [
      'overview',
      'holdings',
      'historyBacktest',
      'position',
      'ai',
      'settings',
    ]) {
      expect(find.byKey(ValueKey('00631l-section-$section')), findsOneWidget);
    }
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

    expect(find.text('00631L 正二研究室'), findsWidgets);
    expect(find.text('核心資料'), findsOneWidget);
    expect(find.text('資料完整度'), findsNothing);
    expect(find.text('累積報酬'), findsOneWidget);
    expect(find.text('圖表與曝險'), findsNothing);
    expect(find.text('更多資料'), findsOneWidget);
    expect(find.text('完整數字比較'), findsNothing);
    expect(find.text('資料來源'), findsNothing);
    expect(find.text('近 60 日收盤'), findsOneWidget);
    expect(find.text('官方曝險'), findsOneWidget);
    expect(find.text('00631L ▼'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('loading state shows app shell skeleton instead of blank spinner',
      (tester) async {
    final repository = _PendingLabRepository();

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
    await tester.pump();

    expect(find.text('00631L 正二研究室'), findsWidgets);
    expect(find.text('今日狀態'), findsOneWidget);
    expect(find.text('完整數字比較'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(repository.fullRequested, isFalse);
    for (final section in const [
      'overview',
      'holdings',
      'historyBacktest',
      'position',
      'ai',
      'settings',
    ]) {
      expect(find.byKey(ValueKey('00631l-section-$section')), findsOneWidget);
    }

    await repository.complete();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('fast startup renders first screen while details load',
      (tester) async {
    final repository = _FastStartupRepository();

    await _pumpLab(tester, repository, settle: false);
    await tester.pump();

    expect(find.text('00631L 正二研究室'), findsWidgets);
    expect(find.text('核心資料'), findsOneWidget);
    expect(find.textContaining('先顯示首屏資料'), findsOneWidget);
    expect(find.text('圖表與曝險'), findsNothing);
    expect(find.text('更多資料'), findsOneWidget);
    expect(find.text('完整數字比較'), findsNothing);
    expect(find.text('7 / 30 日內容物變化'), findsNothing);
    _expectNoTradingActionText();

    await repository.complete();
    await tester.pumpAndSettle();
    expect(find.textContaining('先顯示首屏資料'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('full data failure keeps fast first screen visible',
      (tester) async {
    await _pumpLab(
      tester,
      _FastStartupRepository(completeWithError: true),
      settle: false,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    expect(find.text('核心資料'), findsOneWidget);
    expect(find.textContaining('完整資料暫時不可用'), findsOneWidget);
    expect(find.text('00631L 正二研究室'), findsWidgets);
    _expectNoTradingActionText();
  });

  testWidgets('history section shows price history when available',
      (tester) async {
    await _pumpLab(tester, _PriceHistoryRepository());

    await _tapSection(tester, 'historyBacktest');
    await tester.pumpAndSettle();

    expect(find.text('歷史快覽'), findsOneWidget);
    expect(find.textContaining('coverage'), findsWidgets);
    expect(find.text('價格 / 淨值歷史'), findsOneWidget);
    expect(find.text('市價'), findsNothing);
    expect(find.text('歷史資料完整度'), findsWidgets);
    expect(find.text('累積報酬'), findsWidgets);
    expect(find.text('最近 30 筆價格表'), findsOneWidget);
    expect(find.text('每日 holdings history'), findsOneWidget);
    expect(find.text('回測快覽'), findsNothing);
    expect(find.text('回測工具'), findsOneWidget);
    expect(find.byKey(const ValueKey('00631l-history-view')), findsOneWidget);
    _expectNoTradingActionText();
  });

  testWidgets('history section shows empty state without official history',
      (tester) async {
    await _pumpLab(tester, _NoHistoryRepository());

    await _tapSection(tester, 'historyBacktest');
    await tester.pumpAndSettle();

    expect(find.text('尚無 official price history'), findsWidgets);
    expect(find.text('尚無歷史紀錄'), findsWidgets);
  });

  testWidgets('history backtest section renders inputs and disclaimer',
      (tester) async {
    await _pumpLab(tester, _PriceHistoryRepository());

    await _tapSection(tester, 'historyBacktest');
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('回測工具'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('回測工具'));
    await tester.pumpAndSettle();

    expect(find.text('回測快覽'), findsOneWidget);
    expect(find.textContaining('回測不代表未來表現'), findsWidgets);
    expect(find.text('歷史回測'), findsWidgets);
    expect(find.text('市價'), findsNothing);
    expect(find.text('一次投入'), findsOneWidget);
    expect(find.text('定期定額'), findsWidgets);
    expect(find.text('期末市值'), findsWidgets);
    expect(find.textContaining('回測不代表未來表現'), findsWidgets);
    expect(find.textContaining('非買賣建議'), findsWidgets);
    _expectNoTradingActionText();
  });

  testWidgets('position section saves local-only data controls',
      (tester) async {
    await _pumpLab(tester, Mock00631LRepository());

    await _tapSection(tester, 'position');
    await tester.pumpAndSettle();

    expect(find.text('持倉快覽'), findsOneWidget);
    expect(find.text('持倉追蹤'), findsOneWidget);
    expect(find.text('市價'), findsNothing);
    expect(find.text('保存本機資料'), findsOneWidget);
    expect(find.text('匯出 JSON'), findsOneWidget);
    expect(find.text('清除本機資料'), findsOneWidget);
    expect(find.textContaining('local-only'), findsWidgets);
  });

  testWidgets('phone holdings tables render as readable cards', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await _pumpLab(tester, Mock00631LRepository());

    await _tapSection(tester, 'holdings');
    await tester.pumpAndSettle();

    expect(find.text('內容物快覽'), findsOneWidget);
    expect(find.textContaining('官方每日資料，不是盤中即時內容物'), findsOneWidget);
    expect(find.text('曝險比較'), findsOneWidget);
    expect(find.text('TX 期貨'), findsWidgets);
    expect(find.text('台積電現股'), findsOneWidget);
    expect(find.text('內容物歷史覆蓋'), findsOneWidget);
    expect(find.text('官方每日內容物'), findsOneWidget);
    expect(find.text('主要內容物'), findsOneWidget);
    expect(find.text('完整明細'), findsOneWidget);
    expect(find.text('完整股票明細'), findsOneWidget);
    expect(find.text('完整期貨明細'), findsOneWidget);
    expect(find.text('完整現金 / 保證金明細'), findsOneWidget);
    expect(find.text('STK'), findsWidgets);
    expect(find.text('FUT'), findsWidgets);
    expect(find.text('CASH'), findsWidgets);
    expect(find.text('股票資產'), findsWidgets);
    expect(find.text('期貨資產'), findsWidgets);
    expect(find.byType(DataTable), findsNothing);
    for (final section in const [
      'overview',
      'holdings',
      'historyBacktest',
      'position',
      'ai',
      'settings',
    ]) {
      expect(find.byKey(ValueKey('00631l-section-$section')), findsOneWidget);
    }
    _expectNoTradingActionText();
  });

  testWidgets('AI and settings sections render clean status wording',
      (tester) async {
    await _pumpLab(tester, Mock00631LRepository());

    await _tapSection(tester, 'ai');
    await tester.pumpAndSettle();
    expect(find.text('AI 快覽'), findsOneWidget);
    expect(find.text('AI 分析摘要'), findsOneWidget);
    expect(find.text('完整資料日報'), findsOneWidget);
    expect(find.textContaining('rule_based'), findsWidgets);
    expect(find.textContaining('非買賣建議'), findsWidgets);

    await _tapSection(tester, 'settings');
    await tester.pumpAndSettle();
    expect(find.text('設定'), findsWidgets);
    expect(find.text('帳戶與偏好'), findsOneWidget);
    expect(find.text('資料模式與完整度'), findsOneWidget);
    expect(find.text('進階維護診斷'), findsOneWidget);
    expect(find.text('內容物歷史'), findsNothing);
    expect(find.text('盤中 NAV / 折溢價'), findsNothing);
    expect(find.text('TX live'), findsNothing);

    await tester.drag(find.byType(ListView), const Offset(0, -220));
    await tester.pumpAndSettle();
    await tester.tap(find.text('資料模式與完整度'));
    await tester.pumpAndSettle();
    expect(find.text('內容物歷史'), findsOneWidget);
    expect(find.text('盤中 NAV / 折溢價'), findsOneWidget);
    expect(find.text('TX live'), findsOneWidget);
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

    expect(find.text('00631L 正二研究室'), findsWidgets);
    await _tapSection(tester, 'settings');
    await tester.pumpAndSettle();
    expect(find.text('設定'), findsWidgets);
    expect(find.text('進階維護診斷'), findsOneWidget);
    expect(find.textContaining('mock'), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('dark mode toggle is available and does not crash',
      (tester) async {
    await _pumpLab(tester, Mock00631LRepository());

    expect(find.byIcon(Icons.dark_mode), findsOneWidget);
    await tester.tap(find.byIcon(Icons.dark_mode));
    await tester.pumpAndSettle();

    expect(find.text('00631L 正二研究室'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpLab(
  WidgetTester tester,
  Official00631LRepository repository, {
  bool settle = true,
}) async {
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
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

Future<void> _tapSection(WidgetTester tester, String sectionName) async {
  final finder = find.byKey(ValueKey('00631l-section-$sectionName'));
  await tester.ensureVisible(finder);
  await tester.tap(finder);
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

class _PendingLabRepository extends Mock00631LRepository {
  final Completer<Etf00631LLabData> _completer = Completer<Etf00631LLabData>();
  bool fullRequested = false;

  @override
  Future<Etf00631LLabData> fetchFastLabData() {
    return _completer.future;
  }

  @override
  Future<Etf00631LLabData> fetchLabData() {
    fullRequested = true;
    return _completer.future;
  }

  Future<void> complete() async {
    _completer.complete(await Mock00631LRepository().fetchLabData());
  }
}

class _FastStartupRepository extends Mock00631LRepository {
  _FastStartupRepository({this.completeWithError = false});

  final bool completeWithError;
  final Completer<Etf00631LLabData> _fullCompleter =
      Completer<Etf00631LLabData>();

  @override
  Future<Etf00631LLabData> fetchFastLabData() {
    return Mock00631LRepository().fetchFastLabData();
  }

  @override
  Future<Etf00631LLabData> fetchLabData() {
    if (completeWithError) {
      throw const RepositoryFetchException('full fixture failure');
    }
    return _fullCompleter.future;
  }

  Future<void> complete() async {
    _fullCompleter.complete(await Mock00631LRepository().fetchLabData());
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
