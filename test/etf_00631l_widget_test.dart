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
import 'package:longterm_stock_research_assistant/services/app_theme_controller.dart';

void main() {
  testWidgets('00631L lab renders stock-app style quote header',
      (tester) async {
    await _pumpLab(tester, Mock00631LRepository());

    expect(find.textContaining('ETF 研究室'), findsWidgets);
    expect(find.textContaining('00631L 正二研究室'), findsWidgets);
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
    expect(find.text('歷史回測'), findsWidgets);
    expect(find.text('持倉'), findsWidgets);
    expect(find.text('AI'), findsWidgets);
    expect(find.text('設定'), findsWidgets);
    expect(
      find.byKey(const ValueKey('00631l-symbol-search-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-top-search-button')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('00631l-section-etf')),
      findsNothing,
    );
    for (final section in const [
      'overview',
      'historyBacktest',
      'position',
      'ai',
      'settings',
    ]) {
      expect(find.byKey(ValueKey('00631l-section-$section')), findsOneWidget);
    }
    _expectNoTradingActionText();
  });

  testWidgets('top symbol pill opens ETF and stock search sheet',
      (tester) async {
    await _pumpLab(tester, Mock00631LRepository());

    await tester.tap(find.byKey(const ValueKey('00631l-symbol-search-button')));
    await tester.pumpAndSettle();

    expect(find.text('搜尋 ETF / 股票代號'), findsOneWidget);
    expect(find.textContaining('左上角代號搜尋可查 ETF catalog'), findsOneWidget);
    expect(find.text('history ready 15'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('00631l-symbol-search-field')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-symbol-search-result-00631L')),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const ValueKey('00631l-symbol-search-field')),
      '0050',
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('00631l-symbol-search-result-0050')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-symbol-history-ready-0050')),
      findsOneWidget,
    );
    expect(find.text('歷史/回測可用'), findsWidgets);

    await tester.enterText(
      find.byKey(const ValueKey('00631l-symbol-search-field')),
      '2330',
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('00631l-stock-search-result-2330')),
      findsOneWidget,
    );
    expect(find.text('台積電'), findsWidgets);
    expect(find.textContaining('股票研究資料'), findsWidgets);
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

    expect(find.textContaining('00631L 正二研究室'), findsWidgets);
    expect(find.text('核心資料'), findsOneWidget);
    expect(find.text('資料完整度'), findsNothing);
    expect(find.text('累積報酬'), findsOneWidget);
    expect(find.text('圖表與曝險'), findsNothing);
    expect(find.text('更多資料'), findsOneWidget);
    expect(find.text('完整數字比較'), findsNothing);
    expect(find.text('資料來源'), findsNothing);
    expect(find.text('近 60 日收盤'), findsOneWidget);
    expect(find.text('官方曝險'), findsOneWidget);
    expect(find.text('00631L'), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('quote header uses latest history close when live NAV is absent',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await _pumpLab(tester, _StaticHistoryOnlyRepository());

    expect(find.text('30.00'), findsWidgets);
    expect(find.textContaining('歷史收盤'), findsWidgets);
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

    expect(find.textContaining('00631L 正二研究室'), findsWidgets);
    expect(find.text('今日狀態'), findsOneWidget);
    expect(find.text('完整數字比較'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(repository.fullRequested, isFalse);
    for (final section in const [
      'overview',
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

    expect(find.textContaining('00631L 正二研究室'), findsWidgets);
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
    expect(find.textContaining('00631L 正二研究室'), findsWidgets);
    _expectNoTradingActionText();
  });

  testWidgets('history section shows price history when available',
      (tester) async {
    await _pumpLab(tester, _PriceHistoryRepository());

    await _tapSection(tester, 'historyBacktest');
    await tester.pumpAndSettle();

    expect(find.text('歷史回測'), findsWidgets);
    expect(find.textContaining('預設顯示最近 1 年'), findsOneWidget);
    expect(find.textContaining('coverage'), findsWidgets);
    expect(find.text('價格歷史'), findsOneWidget);
    expect(find.text('市價'), findsNothing);
    expect(find.text('歷史資料完整度'), findsWidgets);
    expect(find.text('區間報酬'), findsWidgets);
    expect(find.text('最近 1 年'), findsWidgets);
    expect(find.text('最近 3 年'), findsOneWidget);
    expect(find.text('全部資料'), findsOneWidget);
    expect(find.textContaining('點擊圖表可查看完整日期與數值'), findsWidgets);
    expect(find.textContaining('目前區間：2025/06/03 - 2026/06/03'), findsOneWidget);
    expect(find.textContaining('區間筆數 4'), findsOneWidget);
    expect(find.textContaining('完整筆數 5'), findsOneWidget);
    expect(find.text('目前區間價格表'), findsOneWidget);
    expect(find.text('每日 holdings history'), findsOneWidget);
    expect(find.text('回測快覽'), findsOneWidget);
    expect(find.text('回測工具'), findsNothing);
    expect(find.text('開始日期'), findsWidgets);
    expect(find.text('結束日期'), findsWidgets);
    final historyView = find.byKey(const ValueKey('00631l-history-view'));
    final startCenter = tester.getCenter(
      find.descendant(
        of: historyView,
        matching: find.byKey(const ValueKey('00631l-start-date-button')),
      ),
    );
    final endCenter = tester.getCenter(
      find.descendant(
        of: historyView,
        matching: find.byKey(const ValueKey('00631l-end-date-button')),
      ),
    );
    expect((startCenter.dy - endCenter.dy).abs(), lessThan(2));
    expect(find.byKey(const ValueKey('00631l-history-view')), findsOneWidget);
    _expectNoTradingActionText();
  });

  testWidgets('history section shows empty state without official history',
      (tester) async {
    await _pumpLab(tester, _NoHistoryRepository());

    await _tapSection(tester, 'historyBacktest');
    await tester.pumpAndSettle();

    expect(find.text('尚無 official price history'), findsWidgets);
    expect(find.text('尚無 holdings history'), findsWidgets);
  });

  testWidgets('history backtest section renders inputs and disclaimer',
      (tester) async {
    await _pumpLab(tester, _PriceHistoryRepository());

    await _tapSection(tester, 'historyBacktest');
    await tester.pumpAndSettle();

    expect(find.text('回測快覽'), findsOneWidget);
    expect(find.textContaining('回測不代表未來表現'), findsWidgets);
    expect(find.text('歷史回測'), findsWidgets);
    expect(find.text('開始日期'), findsWidgets);
    expect(find.text('結束日期'), findsWidgets);
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

    expect(find.text('本機持倉'), findsOneWidget);
    expect(find.text('持倉狀態'), findsOneWidget);
    expect(find.text('尚未輸入持倉'), findsWidgets);
    expect(find.text('輸入持倉資料'), findsOneWidget);
    expect(find.text('市價'), findsNothing);
    expect(find.text('保存本機資料'), findsOneWidget);
    expect(find.text('匯出 JSON'), findsOneWidget);
    expect(find.text('清除本機資料'), findsOneWidget);
    expect(find.textContaining('local-only'), findsWidgets);
  });

  testWidgets('top symbol search renders catalog result list', (tester) async {
    await _pumpLab(tester, Mock00631LRepository());

    await tester.tap(find.byKey(const ValueKey('00631l-symbol-search-button')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('00631l-symbol-search-field')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('00631l-symbol-search-result-00631L')),
        findsOneWidget);
    expect(
      find.byKey(const ValueKey('00631l-symbol-search-result-0050')),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const ValueKey('00631l-symbol-search-field')),
      '0050',
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('00631l-symbol-search-result-0050')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-symbol-history-ready-0050')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('00631l-symbol-search-result-00631L')),
        findsNothing);
    _expectNoTradingActionText();
  });

  testWidgets('catalog-only ETF selection shows missing history guidance',
      (tester) async {
    await _pumpLab(tester, Mock00631LRepository());

    await tester.tap(find.byKey(const ValueKey('00631l-symbol-search-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('00631l-symbol-search-field')),
      '00400A',
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('00631l-symbol-search-result-00400A')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-symbol-catalog-only-00400A')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('00631l-symbol-search-result-00400A')),
    );
    await tester.pumpAndSettle();

    expect(find.text('ETF 歷史資料尚未匯入'), findsOneWidget);
    expect(find.textContaining('請先匯入歷史價格'), findsWidgets);
    _expectNoTradingActionText();
  });

  testWidgets('selecting ETF loads selected ETF history view', (tester) async {
    await _pumpLab(tester, _PriceHistoryRepository());

    await tester.tap(find.byKey(const ValueKey('00631l-symbol-search-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('00631l-symbol-search-field')),
      '0050',
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('00631l-symbol-search-result-0050')),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(find.text('0050'), findsWidgets);
    expect(find.textContaining('元大台灣50'), findsWidgets);
    expect(find.byKey(const ValueKey('00631l-history-view')), findsOneWidget);
    expect(find.byKey(const ValueKey('00631l-backtest-view')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('00631l-etf-history-comparison')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-etf-comparison-return-chart')),
      findsOneWidget,
    );
    expect(find.text('ETF 歷史比較'), findsOneWidget);
    expect(find.text('最近 1 年'), findsWidgets);
    expect(find.text('比較檔數'), findsOneWidget);
    expect(find.text('代表'), findsWidgets);
    expect(find.text('高股息'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('00631l-etf-comparison-selected-codes')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-etf-compare-chip-0050')),
      findsOneWidget,
    );

    await tester.drag(find.byType(ListView).first, const Offset(0, -1720));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('00631l-etf-compare-chip-0050')),
    );
    await tester.pumpAndSettle();
    final selectedSummaryAfterDeselect = tester.widget<Text>(
      find.byKey(const ValueKey('00631l-etf-comparison-selected-codes')),
    );
    expect(selectedSummaryAfterDeselect.data, isNot(contains('0050')));

    await tester.tap(
      find.byKey(const ValueKey('00631l-etf-comparison-filter-dividend')),
    );
    await tester.pumpAndSettle();
    final dividendSummary = tester.widget<Text>(
      find.byKey(const ValueKey('00631l-etf-comparison-selected-codes')),
    );
    expect(dividendSummary.data, anyOf(contains('0056'), contains('00878')));
    expect(find.byKey(const ValueKey('00631l-etf-comparison-return-chart')),
        findsOneWidget);

    _expectNoTradingActionText();
  });

  testWidgets('selecting ETF switches overview position and AI context',
      (tester) async {
    await _pumpLab(tester, _PriceHistoryRepository());

    await tester.tap(find.byKey(const ValueKey('00631l-symbol-search-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('00631l-symbol-search-field')),
      '0050',
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('00631l-symbol-search-result-0050')),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    await _tapSection(tester, 'overview');
    await tester.pumpAndSettle();
    expect(find.textContaining('0050 元大台灣50'), findsWidgets);
    expect(find.text('0050 核心資料'), findsOneWidget);
    expect(find.text('官方內容物重點'), findsNothing);

    await _tapSection(tester, 'position');
    await tester.pumpAndSettle();
    expect(find.textContaining('0050'), findsWidgets);
    expect(find.textContaining('local-only'), findsWidgets);

    await _tapSection(tester, 'ai');
    await tester.pumpAndSettle();
    expect(find.text('0050 AI 快覽'), findsOneWidget);
    expect(find.textContaining('元大台灣50'), findsWidgets);
    _expectNoTradingActionText();
  });

  testWidgets('overview includes official holdings digest on phone',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await _pumpLab(tester, Mock00631LRepository());

    expect(find.byKey(const ValueKey('00631l-section-holdings')), findsNothing);
    expect(find.text('官方內容物重點'), findsOneWidget);
    expect(find.textContaining('每日官方快照'), findsOneWidget);
    expect(find.text('TX 期貨'), findsWidgets);
    expect(find.text('台積電現股'), findsOneWidget);
    expect(find.text('股票 / 期貨 / 現金'), findsOneWidget);
    expect(find.text('TX'), findsWidgets);
    expect(find.text('2330'), findsOneWidget);
    expect(find.text('MIX'), findsOneWidget);
    expect(find.byType(DataTable), findsNothing);
    for (final section in const [
      'overview',
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
    expect(find.text('今日 AI 快覽'), findsOneWidget);
    expect(find.text('今日 AI 分析摘要'), findsOneWidget);
    expect(find.text('資料狀態'), findsWidgets);
    expect(find.text('內容物重點'), findsOneWidget);
    expect(find.text('折溢價'), findsWidgets);
    expect(find.text('今日重點'), findsOneWidget);
    expect(find.text('完整資料日報'), findsOneWidget);
    expect(find.textContaining('rule_based'), findsWidgets);
    expect(find.textContaining('非買賣建議'), findsWidgets);

    await _tapSection(tester, 'settings');
    await tester.pumpAndSettle();
    expect(find.text('設定'), findsWidgets);
    expect(find.text('帳戶與偏好'), findsOneWidget);
    expect(find.text('ETF 資料狀態'), findsOneWidget);
    expect(find.text('catalog'), findsWidgets);
    expect(find.text('ETF comparison'), findsOneWidget);
    expect(find.text('ETF 資料預覽'), findsNothing);
    expect(find.text('元大台灣50正2'), findsNothing);
    expect(find.text('App 上架準備'), findsOneWidget);
    expect(find.text('資料模式與完整度'), findsOneWidget);
    expect(find.text('進階維護診斷'), findsOneWidget);
    expect(find.text('Android'), findsNothing);
    expect(find.text('iOS'), findsNothing);
    expect(find.text('隱私與支援'), findsNothing);
    expect(find.text('內容物歷史'), findsNothing);
    expect(find.text('盤中 NAV / 折溢價'), findsNothing);
    expect(find.text('TX live'), findsNothing);

    await tester.scrollUntilVisible(
      find.text('App 上架準備'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('App 上架準備'));
    await tester.pumpAndSettle();
    expect(find.text('Android'), findsOneWidget);
    expect(find.text('iOS'), findsOneWidget);
    expect(find.text('隱私與支援'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('資料模式與完整度'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('資料模式與完整度'));
    await tester.pumpAndSettle();
    expect(find.text('內容物歷史'), findsOneWidget);
    expect(find.text('盤中 NAV / 折溢價'), findsOneWidget);
    expect(find.text('TX live'), findsOneWidget);
    expect(find.text('ETF history'), findsWidgets);
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

    expect(find.textContaining('00631L 正二研究室'), findsWidgets);
    await _tapSection(tester, 'settings');
    await tester.pumpAndSettle();
    expect(find.text('設定'), findsWidgets);
    expect(find.text('進階維護診斷'), findsOneWidget);
    expect(find.textContaining('mock'), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('day and night mode toggle changes the market palette',
      (tester) async {
    await _pumpLab(tester, Mock00631LRepository());

    final initialBox =
        tester.widget<DecoratedBox>(find.byType(DecoratedBox).first);
    final initialColor = (initialBox.decoration as BoxDecoration).color;
    expect(find.text('日間模式'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('00631l-theme-toggle')));
    await tester.pumpAndSettle();

    final changedBox =
        tester.widget<DecoratedBox>(find.byType(DecoratedBox).first);
    final changedColor = (changedBox.decoration as BoxDecoration).color;
    expect(changedColor, isNot(initialColor));
    expect(find.text('夜間模式'), findsOneWidget);
    expect(find.textContaining('00631L 正二研究室'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpLab(
  WidgetTester tester,
  Official00631LRepository repository, {
  bool settle = true,
}) async {
  appThemeModeNotifier.value = ThemeMode.light;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        official00631LRepositoryProvider.overrideWithValue(repository),
      ],
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: appThemeModeNotifier,
        builder: (context, mode, _) {
          return MaterialApp(
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            themeMode: mode,
            home: const Scaffold(body: LeveragedEtf00631LScreen()),
          );
        },
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
        date: DateTime(2024, 6, 3),
        open: 20.0,
        high: 20.4,
        low: 19.8,
        close: 20.2,
        volume: 900000,
        nav: 20.1,
        premiumDiscountPct: 0.1,
      ),
      EtfPriceHistoryPoint(
        date: DateTime(2025, 6, 3),
        open: 25.0,
        high: 25.5,
        low: 24.8,
        close: 25.2,
        volume: 950000,
        nav: 25.1,
        premiumDiscountPct: 0.2,
      ),
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

  @override
  Future<EtfPriceHistory> fetchEtfPriceHistory(
    String code, {
    int limit = 5000,
  }) async {
    final normalized = code.trim().toUpperCase();
    if (normalized == '00631L') {
      return fetchPriceHistory(limit: limit);
    }
    final profile = switch (normalized) {
      '0050' => ('元大台灣50', 100.0),
      '0056' => ('元大高股息', 32.0),
      '006208' => ('富邦台50', 82.0),
      '00878' => ('國泰永續高股息', 21.0),
      '00919' => ('群益台灣精選高息', 23.0),
      _ => (normalized, 40.0),
    };
    final points = [
      EtfPriceHistoryPoint(
        date: DateTime(2025, 6, 3),
        open: profile.$2,
        high: profile.$2 * 1.01,
        low: profile.$2 * 0.99,
        close: profile.$2,
        volume: 1000000,
      ),
      EtfPriceHistoryPoint(
        date: DateTime(2026, 6, 1),
        open: profile.$2 * 1.08,
        high: profile.$2 * 1.1,
        low: profile.$2 * 1.07,
        close: profile.$2 * 1.09,
        volume: 1100000,
      ),
      EtfPriceHistoryPoint(
        date: DateTime(2026, 6, 3),
        open: profile.$2 * 1.1,
        high: profile.$2 * 1.12,
        low: profile.$2 * 1.08,
        close: profile.$2 * 1.11,
        volume: 1200000,
      ),
    ].take(limit).toList(growable: false);
    return EtfPriceHistory(
      code: normalized,
      name: profile.$1,
      points: points,
      status: EtfDataStatus.cached,
      sourceStatusLabel: 'cached',
      sourceUrl: 'local://$normalized-price-history',
      lastFetchedAt: DateTime(2026, 6, 11),
      coverageStart: points.first.date,
      coverageEnd: points.last.date,
      isCompleteFromListing: false,
    );
  }
}

class _StaticHistoryOnlyRepository extends _PriceHistoryRepository {
  @override
  Future<EtfIntradayNav?> fetchIntradayNav() async {
    return null;
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
