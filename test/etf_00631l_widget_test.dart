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
  test('overview stays on fast data even in live proxy mode', () {
    expect(
      shouldLoad00631LFullData(
        fastReadyOrError: false,
        sectionNeedsFullData: false,
        liveProxyEnabled: true,
      ),
      isFalse,
    );
    expect(
      shouldLoad00631LFullData(
        fastReadyOrError: true,
        sectionNeedsFullData: false,
        liveProxyEnabled: false,
      ),
      isFalse,
    );
    expect(
      shouldLoad00631LFullData(
        fastReadyOrError: true,
        sectionNeedsFullData: true,
        liveProxyEnabled: false,
      ),
      isTrue,
    );
    expect(
      shouldLoad00631LFullData(
        fastReadyOrError: true,
        sectionNeedsFullData: false,
        liveProxyEnabled: true,
      ),
      isFalse,
    );
  });

  test('live core fallback uses only limited short retries', () {
    expect(liveCoreWarmupRetryLimit, 2);
    expect(liveCoreWarmupRetryInterval, const Duration(seconds: 8));
    expect(
      shouldUse00631LShortLiveRetry(
        liveProxyEnabled: true,
        hasLiveCoreData: false,
        retryCount: 0,
      ),
      isTrue,
    );
    expect(
      shouldUse00631LShortLiveRetry(
        liveProxyEnabled: true,
        hasLiveCoreData: false,
        retryCount: liveCoreWarmupRetryLimit - 1,
      ),
      isTrue,
    );
    expect(
      shouldUse00631LShortLiveRetry(
        liveProxyEnabled: true,
        hasLiveCoreData: false,
        retryCount: liveCoreWarmupRetryLimit,
      ),
      isFalse,
    );
    expect(
      shouldUse00631LShortLiveRetry(
        liveProxyEnabled: true,
        hasLiveCoreData: true,
        retryCount: 0,
      ),
      isFalse,
    );
    expect(
      shouldUse00631LShortLiveRetry(
        liveProxyEnabled: false,
        hasLiveCoreData: false,
        retryCount: 0,
      ),
      isFalse,
    );
  });

  test('live backend warmup display only applies while live details load', () {
    expect(
      shouldShow00631LLiveBackendWarmup(
        detailsLoading: true,
        liveProxyEnabled: true,
      ),
      isTrue,
    );
    expect(
      shouldShow00631LLiveBackendWarmup(
        detailsLoading: false,
        liveProxyEnabled: true,
      ),
      isFalse,
    );
    expect(
      shouldShow00631LLiveBackendWarmup(
        detailsLoading: true,
        liveProxyEnabled: false,
      ),
      isFalse,
    );
  });

  testWidgets('00631L lab renders stock-app style quote header',
      (tester) async {
    await _pumpLab(tester, Mock00631LRepository());

    expect(find.textContaining('ETF 研究室'), findsWidgets);
    expect(find.textContaining('00631L 正二研究室'), findsWidgets);
    expect(find.text('00631L 00631L'), findsNothing);
    expect(find.textContaining('00631L 元大台灣50正2'), findsNothing);
    expect(find.textContaining('元大台灣50正2'), findsNothing);
    expect(find.textContaining('行情'), findsWidgets);
    expect(find.textContaining('撣'), findsNothing);
    expect(find.textContaining('預估淨值'), findsNothing);
    expect(find.textContaining('折溢價'), findsWidgets);
    expect(find.text('核心資料'), findsNothing);
    expect(find.text('今日快覽'), findsNothing);
    expect(find.text('資料完整度'), findsNothing);
    expect(find.text('回測'), findsNothing);
    expect(find.text('可用'), findsNothing);
    expect(find.text('圖表與曝險'), findsNothing);
    expect(find.text('更多資料'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('00631l-quote-readiness-strip')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('00631l-overview-brief-panel')),
      findsNothing,
    );
    expect(find.text('完整數字比較'), findsNothing);
    expect(find.text('資料正確性'), findsNothing);
    expect(find.text('目前檔案'), findsNothing);
    expect(find.text('更多資料狀態'), findsNothing);
    expect(find.text('7 / 30 日內容物變化'), findsNothing);
    expect(find.text('內容物重點'), findsNothing);
    expect(find.text('價格欄位'), findsNothing);
    expect(find.text('分割調整'), findsNothing);
    expect(find.text('後端'), findsNothing);
    expect(find.text('覆蓋型態'), findsNothing);
    expect(find.text('ETF歷史'), findsNothing);
    expect(find.text('歷史'), findsWidgets);
    expect(find.text('近一年走勢'), findsOneWidget);
    expect(find.text('HIS'), findsNothing);
    final compactQuoteHeader =
        find.byKey(const ValueKey('00631l-main-quote-header'));
    expect(compactQuoteHeader, findsOneWidget);
    expect(
      tester.getRect(compactQuoteHeader).height,
      lessThanOrEqualTo(60),
    );
    final chartTitleTop = tester.getTopLeft(find.text('近一年走勢')).dy;
    expect(
        chartTitleTop, greaterThan(tester.getRect(compactQuoteHeader).bottom));
    expect(find.text('官方 NAV'), findsNothing);
    expect(find.text('示範'), findsWidgets);
    expect(find.textContaining('行情 · 示範'), findsWidgets);
    expect(find.textContaining('Mock 預設'), findsNothing);
    final quoteMetaStrip = find.byKey(
      const ValueKey('00631l-quote-meta-strip'),
    );
    expect(quoteMetaStrip, findsNothing);
    expect(
      find.descendant(
        of: quoteMetaStrip,
        matching: find.text('前日淨值'),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: quoteMetaStrip,
        matching: find.text('模式'),
      ),
      findsNothing,
    );
    expect(find.text('總覽'), findsWidgets);
    expect(find.text('歷史'), findsWidgets);
    expect(find.text('持倉'), findsWidgets);
    expect(find.text('AI'), findsWidgets);
    expect(find.text('帳戶'), findsWidgets);
    expect(
      find.byKey(const ValueKey('00631l-symbol-search-button')),
      findsOneWidget,
    );
    final topBar = find.byKey(const ValueKey('00631l-market-top-bar'));
    expect(topBar, findsOneWidget);
    expect(tester.getRect(topBar).height, lessThanOrEqualTo(54));
    expect(
        find.byKey(const ValueKey('00631l-market-top-title')), findsOneWidget);
    final topTitle = tester.widget<Text>(
      find.byKey(const ValueKey('00631l-market-top-title')),
    );
    expect(topTitle.style?.fontSize, greaterThanOrEqualTo(22));
    expect(topTitle.style?.fontSize, lessThanOrEqualTo(23));
    final symbolButton =
        find.byKey(const ValueKey('00631l-symbol-search-button'));
    expect(tester.getRect(symbolButton).height, greaterThanOrEqualTo(32));
    expect(tester.getRect(symbolButton).height, lessThanOrEqualTo(42));
    expect(
      find.byKey(const ValueKey('00631l-overview-daily-summary-strip')),
      findsOneWidget,
    );
    expect(
      tester
          .getRect(
            find.byKey(const ValueKey('00631l-overview-daily-summary-strip')),
          )
          .height,
      lessThanOrEqualTo(34),
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('00631l-overview-more-expansion')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('00631l-overview-more-expansion')),
    );
    await tester.pumpAndSettle();
    final quoteReadinessStrip = find.byKey(
      const ValueKey('00631l-quote-readiness-strip'),
    );
    expect(quoteReadinessStrip, findsOneWidget);
    expect(
      find.descendant(
        of: quoteReadinessStrip,
        matching: find.text('價格欄位'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: quoteReadinessStrip,
        matching: find.text('分割調整'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: quoteReadinessStrip,
        matching: find.text('後端'),
      ),
      findsNothing,
    );
    expect(find.text('資料正確性'), findsOneWidget);
    expect(find.text('更新時間'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('00631l-overview-clock-chip-TX')),
      findsOneWidget,
    );
    final txClockStatus = tester.widget<Text>(
      find.byKey(const ValueKey('00631l-overview-clock-status-TX')),
    );
    expect(txClockStatus.data, isNotNull);
    expect(txClockStatus.data!.trim(), isNotEmpty);
    expect(find.text('目前檔案'), findsOneWidget);
    expect(find.text('價格欄位'), findsWidgets);
    expect(find.text('分割調整'), findsWidgets);
    expect(find.text('覆蓋型態'), findsOneWidget);
    expect(find.text('ETF歷史'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('00631l-top-search-button')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('00631l-section-etf')),
      findsNothing,
    );
    final bottomNav = find.byKey(const ValueKey('00631l-bottom-nav'));
    expect(bottomNav, findsOneWidget);
    expect(tester.getRect(bottomNav).height, lessThanOrEqualTo(60));
    expect(
      find.descendant(of: bottomNav, matching: find.text('ETF')),
      findsNothing,
    );
    expect(
      find.descendant(of: bottomNav, matching: find.text('歷史回測')),
      findsNothing,
    );
    expect(
      find.descendant(of: bottomNav, matching: find.text('歷史')),
      findsOneWidget,
    );
    for (final section in const [
      'overview',
      'historyBacktest',
      'position',
      'ai',
      'settings',
    ]) {
      expect(find.byKey(ValueKey('00631l-section-$section')), findsOneWidget);
      expect(
        find.byKey(ValueKey('00631l-section-label-$section')),
        findsOneWidget,
      );
    }
    _expectNoTradingActionText();
  });

  testWidgets('00631L quote premium uses intraday NAV only', (tester) async {
    await _pumpLab(tester, _StaticHistoryOnlyRepository());

    final premiumBox = find.byKey(const ValueKey('00631l-quote-premium-box'));
    expect(premiumBox, findsOneWidget);
    expect(
      find.descendant(of: premiumBox, matching: find.text('unavailable')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: premiumBox, matching: find.text('+0.28%')),
      findsNothing,
    );
    _expectNoTradingActionText();
  });

  testWidgets('00631L live quote uses intraday status wording', (tester) async {
    await _pumpLab(tester, _OfficialIntradayRepository());

    expect(find.textContaining('行情 · 盤中'), findsWidgets);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('00631l-main-quote-header')),
        matching: find.text('快取'),
      ),
      findsNothing,
    );
    _expectNoTradingActionText();
  });

  testWidgets('overview TX clock labels missing quote as backend required',
      (tester) async {
    await _pumpLab(tester, _NoTxQuoteRepository());

    await tester.ensureVisible(find.text('更多資料'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('更多資料'));
    await tester.pumpAndSettle();

    final txClockStatus = tester.widget<Text>(
      find.byKey(const ValueKey('00631l-overview-clock-status-TX')),
    );
    expect(txClockStatus.data, equals('需 live backend'));
    _expectNoTradingActionText();
  });

  testWidgets('top symbol pill opens ETF and stock search sheet',
      (tester) async {
    await _pumpLab(tester, Mock00631LRepository());

    final symbolSearchButton =
        find.byKey(const ValueKey('00631l-symbol-search-button'));
    await tester.ensureVisible(symbolSearchButton);
    await tester.pumpAndSettle();
    expect(
      find.descendant(
          of: symbolSearchButton, matching: find.byIcon(Icons.search)),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: symbolSearchButton,
        matching: find.byIcon(Icons.expand_more),
      ),
      findsOneWidget,
    );
    await tester.tap(symbolSearchButton);
    await tester.pumpAndSettle();

    expect(find.text('搜尋 ETF 代號'), findsOneWidget);
    expect(find.textContaining('切換研究標的'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('00631l-symbol-current-selection-panel')),
      findsOneWidget,
    );
    expect(find.textContaining('歷史可用 15 / 16'), findsWidgets);
    expect(find.text('資料庫狀態'), findsOneWidget);
    expect(find.text('資料可用性'), findsNothing);
    await tester.tap(find.text('資料庫狀態'));
    await tester.pumpAndSettle();

    expect(find.text('資料可用性'), findsOneWidget);
    expect(find.text('可回測/比較 15 / 16'), findsOneWidget);
    expect(find.text('僅清單 1'), findsOneWidget);
    expect(find.text('資料細節'), findsOneWidget);
    await tester.tap(find.text('資料庫狀態'));
    await tester.pumpAndSettle();
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
    expect(find.textContaining('歷史可用'), findsWidgets);
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
    expect(find.text('其他研究資料'), findsOneWidget);
    expect(find.text('台積電'), findsWidgets);
    expect(find.textContaining('股票研究資料'), findsWidgets);
    _expectNoTradingActionText();
  });

  testWidgets('symbol search uses operations ETF history readiness count',
      (tester) async {
    await _pumpLab(tester, _EtfReadinessOperationsRepository());

    final selectedSearchButton =
        find.byKey(const ValueKey('00631l-symbol-search-button'));
    await tester.ensureVisible(selectedSearchButton);
    await tester.pumpAndSettle();
    await tester.tap(selectedSearchButton);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('00631l-symbol-search-ready-count-228')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-symbol-search-ready-count-15')),
      findsNothing,
    );
    _expectNoTradingActionText();
  });

  testWidgets('symbol search shows ETF data completion status', (tester) async {
    await _pumpLab(tester, _EtfReadinessOperationsRepository());

    final selectedEtfSearchButton =
        find.byKey(const ValueKey('00631l-symbol-search-button'));
    await tester.ensureVisible(selectedEtfSearchButton);
    await tester.pumpAndSettle();
    await tester.tap(selectedEtfSearchButton);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('00631l-symbol-search-database-panel')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-etf-data-completion-strip')),
      findsNothing,
    );
    expect(find.text('資料庫狀態'), findsOneWidget);
    expect(find.textContaining('歷史可用 228 / 228'), findsWidgets);
    expect(find.textContaining('缺口 0'), findsOneWidget);
    expect(find.textContaining('待補'), findsNothing);
    await tester.tap(find.text('資料庫狀態'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('00631l-etf-data-completion-strip')),
      findsOneWidget,
    );
    expect(find.text('ETF 資料庫狀態'), findsOneWidget);
    expect(find.textContaining('完成度'), findsOneWidget);
    expect(find.text('資料可用性'), findsOneWidget);
    expect(find.text('目前清單 16'), findsNothing);
    expect(find.text('統計母數 228'), findsNothing);
    expect(find.text('可回測/比較 228 / 228'), findsOneWidget);
    expect(find.text('長期資料 8'), findsNothing);
    expect(find.text('近期資料 220'), findsNothing);
    await tester.tap(find.text('資料細節'));
    await tester.pumpAndSettle();
    expect(find.text('目前清單 16'), findsOneWidget);
    expect(find.text('統計母數 228'), findsOneWidget);
    expect(find.text('長期資料 8'), findsOneWidget);
    expect(find.text('近期資料 220'), findsOneWidget);
    expect(find.textContaining('TWSE'), findsWidgets);
    expect(find.textContaining('TPEx'), findsOneWidget);
    expect(find.text('搜尋 ETF 代號'), findsOneWidget);
    _expectNoTradingActionText();
  });

  testWidgets('ETF data completion denominator includes catalog gap',
      (tester) async {
    await _pumpLab(tester, _EtfCatalogGapOperationsRepository());

    await tester.tap(find.byKey(const ValueKey('00631l-symbol-search-button')));
    await tester.pumpAndSettle();

    expect(find.text('統計母數 344'), findsNothing);
    expect(find.textContaining('歷史可用 228 / 344'), findsWidgets);
    expect(find.textContaining('待補 116'), findsOneWidget);
    expect(find.textContaining('缺口 116'), findsOneWidget);
    expect(find.text('可回測/比較 228 / 344'), findsNothing);
    await tester.tap(find.text('資料庫狀態'));
    await tester.pumpAndSettle();

    expect(find.text('可回測/比較 228 / 344'), findsOneWidget);
    expect(find.text('僅清單 116'), findsOneWidget);
    await tester.tap(find.text('資料細節'));
    await tester.pumpAndSettle();
    expect(find.text('統計母數 344'), findsOneWidget);

    await tester.tap(find.byTooltip('關閉'));
    await tester.pumpAndSettle();
    await _tapSection(tester, 'settings');
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('進階設定'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('進階設定'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('ETF 資料與比較能力'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ETF 資料與比較能力'));
    await tester.pumpAndSettle();

    expect(find.text('228 / 344'), findsWidgets);
    expect(find.text('116'), findsWidgets);
    expect(find.text('資料整理'), findsOneWidget);
    expect(find.textContaining('缺口已分類'), findsWidgets);
    expect(find.textContaining('樣本代號 尚未匯入: 00999, 00998'), findsOneWidget);
    expect(find.textContaining('排程靜態匯出'), findsOneWidget);
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
    expect(find.text('核心資料'), findsNothing);
    expect(find.text('今日快覽'), findsNothing);
    expect(find.text('資料完整度'), findsNothing);
    expect(find.text('圖表與曝險'), findsNothing);
    expect(find.text('????'), findsNothing);
    expect(find.text('完整數字比較'), findsNothing);
    expect(find.text('資料正確性'), findsNothing);
    expect(find.text('目前檔案'), findsNothing);
    expect(find.text('近一年走勢'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('00631l-overview-holdings-digest-strip')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-overview-core-metric-strip')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('00631l-overview-daily-summary-strip')),
      findsNothing,
    );
    final topBar = find.byKey(const ValueKey('00631l-market-top-bar'));
    final symbolButton =
        find.byKey(const ValueKey('00631l-symbol-search-button'));
    expect(topBar, findsOneWidget);
    expect(symbolButton, findsOneWidget);
    expect(tester.getRect(topBar).height, lessThanOrEqualTo(54));
    expect(
        find.byKey(const ValueKey('00631l-market-top-title')), findsOneWidget);
    expect(tester.getRect(symbolButton).height, lessThanOrEqualTo(42));

    final compactRibbon = find.byKey(
      const ValueKey('00631l-overview-compact-data-ribbon'),
    );
    expect(compactRibbon, findsOneWidget);
    for (final label in const ['日', '盤', '歷', '模式']) {
      expect(
        find.descendant(of: compactRibbon, matching: find.text(label)),
        findsWidgets,
      );
    }
    for (final label in const ['DAY', 'NAV', 'HIS', 'MODE']) {
      expect(
        find.descendant(of: compactRibbon, matching: find.text(label)),
        findsNothing,
      );
    }
    expect(
      find.descendant(of: compactRibbon, matching: find.text('示範')),
      findsOneWidget,
    );
    for (final label in const ['mock', 'static', 'live']) {
      expect(
        find.descendant(of: compactRibbon, matching: find.text(label)),
        findsNothing,
      );
    }
    for (final label in const ['TX', '2330']) {
      expect(
        find.descendant(of: compactRibbon, matching: find.text(label)),
        findsNothing,
      );
    }
    expect(
      find.byKey(const ValueKey('00631l-overview-market-stack')),
      findsOneWidget,
    );
    final marketStackRect = tester.getRect(
      find.byKey(const ValueKey('00631l-overview-market-stack')),
    );
    expect(marketStackRect.height, lessThanOrEqualTo(366));
    final ribbonRect = tester.getRect(compactRibbon);
    expect(ribbonRect.height, lessThanOrEqualTo(24));
    expect(
      find.byKey(const ValueKey('00631l-overview-sparkline-summary-row')),
      findsNothing,
    );
    final readinessStrip = find.byKey(
      const ValueKey('00631l-quote-readiness-strip'),
    );
    expect(readinessStrip, findsNothing);
    final firstGlanceStrip = find.byKey(
      const ValueKey('00631l-overview-first-glance-strip'),
    );
    expect(firstGlanceStrip, findsOneWidget);
    expect(
      find.byKey(const ValueKey('00631l-overview-brief-panel')),
      findsNothing,
    );
    final chartFinder = find.byKey(
      const ValueKey('00631l-overview-sparkline-chart'),
    );
    expect(chartFinder, findsOneWidget);
    final chartRect = tester.getRect(chartFinder);
    expect(chartRect.height, greaterThanOrEqualTo(54));
    expect(chartRect.height, lessThanOrEqualTo(58));
    expect(chartRect.bottom, lessThanOrEqualTo(452));
    expect(chartRect.top, lessThan(ribbonRect.top));
    expect(ribbonRect.top, greaterThan(chartRect.bottom));
    final dateStrip = find.byKey(
      const ValueKey('00631l-overview-sparkline-date-strip'),
    );
    final dateStripRect = tester.getRect(
      dateStrip,
    );
    expect(dateStripRect.height, lessThanOrEqualTo(28));
    expect(
      find.descendant(
        of: dateStrip,
        matching:
            find.byKey(const ValueKey('00631l-overview-sparkline-date-start')),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: dateStrip,
        matching:
            find.byKey(const ValueKey('00631l-overview-sparkline-date-mid')),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: dateStrip,
        matching:
            find.byKey(const ValueKey('00631l-overview-sparkline-date-end')),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: dateStrip,
        matching: find.textContaining(RegExp(r'^\d{2}/\d{2}/\d{2}$')),
      ),
      findsNWidgets(3),
    );
    final touchDetailRect = tester.getRect(
      find.byKey(const ValueKey('00631l-overview-sparkline-touch-detail')),
    );
    expect(touchDetailRect.height, lessThanOrEqualTo(34));
    expect(chartRect.bottom, lessThanOrEqualTo(dateStripRect.top));
    expect(dateStripRect.bottom, lessThanOrEqualTo(touchDetailRect.top));
    expect(
      find.descendant(
        of: find
            .byKey(const ValueKey('00631l-overview-sparkline-touch-detail')),
        matching:
            find.byKey(const ValueKey('00631l-line-chart-touch-secondary')),
      ),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('00631l-overview-exposure-compact-row')),
      findsNothing,
    );
    final mobileDailySummary = find.byKey(
      const ValueKey('00631l-overview-mobile-daily-summary-card'),
    );
    expect(mobileDailySummary, findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('00631l-overview-market-stack')),
        matching: mobileDailySummary,
      ),
      findsOneWidget,
    );
    expect(tester.getRect(mobileDailySummary).height, lessThanOrEqualTo(80));
    final aiGlance = find.byKey(
      const ValueKey('00631l-overview-ai-glance-card'),
    );
    expect(aiGlance, findsOneWidget);
    final aiRect = tester.getRect(aiGlance);
    final bottomNavRect = tester.getRect(
      find.byKey(const ValueKey('00631l-bottom-nav')),
    );
    expect(bottomNavRect.height, lessThanOrEqualTo(62));
    expect(aiRect.top, lessThan(bottomNavRect.top));
    expect(aiRect.height, lessThanOrEqualTo(76));
    final holdingsDigestRect = tester.getRect(
      find.byKey(const ValueKey('00631l-overview-holdings-digest-strip')),
    );
    final mobileDigestChips = find.byKey(
      const ValueKey('00631l-mobile-holding-digest-chip'),
    );
    expect(mobileDigestChips, findsNWidgets(3));
    for (final label in const ['TX', '2330', 'CASH']) {
      expect(
        find.descendant(
          of: find.byKey(
            const ValueKey('00631l-overview-holdings-digest-strip'),
          ),
          matching: find.text(label),
        ),
        findsOneWidget,
      );
    }
    expect(
        tester.getRect(mobileDigestChips.first).height, lessThanOrEqualTo(22));
    final mobileDailySummaryRect = tester.getRect(mobileDailySummary);
    expect(mobileDailySummaryRect.height, lessThanOrEqualTo(112));
    expect(aiRect.top, greaterThanOrEqualTo(mobileDailySummaryRect.top));
    expect(
      holdingsDigestRect.bottom,
      lessThanOrEqualTo(mobileDailySummaryRect.bottom),
    );
    expect(
      find.byKey(const ValueKey('00631l-overview-holdings-digest-title-row')),
      findsNothing,
    );
    expect(
      holdingsDigestRect.bottom,
      lessThanOrEqualTo(bottomNavRect.top - 8),
    );
    expect(
      holdingsDigestRect.bottom - marketStackRect.top,
      lessThanOrEqualTo(540),
    );
    expect(
      find.byKey(const ValueKey('00631l-overview-ai-compact-line')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-overview-daily-fact-rail')),
      findsNothing,
    );
    expect(find.text('程式操作'), findsNothing);
    expect(
      find.byKey(const ValueKey('00631l-overview-more-expansion')),
      findsNothing,
    );
    expect(find.text('Mock'), findsNothing);
    expect(find.textContaining('示範'), findsWidgets);
    expect(find.text('00631L'), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('phone tabs open distinct first-screen content', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await _pumpLab(tester, Mock00631LRepository());

    expect(
      find.byKey(const ValueKey('00631l-overview-market-stack')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-history-backtest-top-strip')),
      findsNothing,
    );

    await _tapSection(tester, 'historyBacktest');
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('00631l-history-backtest-top-strip')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-overview-market-stack')),
      findsNothing,
    );

    await _tapSection(tester, 'position');
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('00631l-position-compact-input-card')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-history-backtest-top-strip')),
      findsNothing,
    );

    await _tapSection(tester, 'ai');
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('00631l-ai-daily-briefing-hero')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-position-compact-input-card')),
      findsNothing,
    );

    await _tapSection(tester, 'settings');
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('00631l-settings-quick-summary-compact')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-ai-daily-briefing-hero')),
      findsNothing,
    );
    _expectNoTradingActionText();
  });

  testWidgets('phone first-screen density guard covers main app tabs',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await _pumpLab(tester, Mock00631LRepository());

    final marketStack =
        find.byKey(const ValueKey('00631l-overview-market-stack'));
    final bottomNav = find.byKey(const ValueKey('00631l-bottom-nav'));
    expect(marketStack, findsOneWidget);
    expect(bottomNav, findsOneWidget);
    expect(tester.getRect(marketStack).height, lessThanOrEqualTo(366));
    expect(tester.getRect(bottomNav).height, lessThanOrEqualTo(60));

    await _tapSection(tester, 'ai');
    await tester.pumpAndSettle();
    final aiHero =
        find.byKey(const ValueKey('00631l-ai-daily-briefing-hero'));
    final aiFacts = find.byKey(const ValueKey('00631l-ai-first-screen-facts'));
    expect(aiHero, findsOneWidget);
    expect(aiFacts, findsOneWidget);
    expect(tester.getRect(aiHero).height, lessThanOrEqualTo(320));
    expect(tester.getRect(aiFacts).height, lessThanOrEqualTo(64));

    await _tapSection(tester, 'position');
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('00631l-position-field-shares')),
      '1000',
    );
    await tester.enterText(
      find.byKey(const ValueKey('00631l-position-field-average-cost')),
      '120',
    );
    await tester.pumpAndSettle();
    final positionStrip =
        find.byKey(const ValueKey('00631l-position-account-strip'));
    final positionMetrics =
        find.byKey(const ValueKey('00631l-position-account-metric-grid'));
    expect(positionStrip, findsOneWidget);
    expect(positionMetrics, findsOneWidget);
    expect(tester.getRect(positionStrip).height, lessThanOrEqualTo(90));
    expect(tester.getRect(positionMetrics).height, lessThanOrEqualTo(38));

    await _tapSection(tester, 'settings');
    await tester.pumpAndSettle();
    final settingsSummary =
        find.byKey(const ValueKey('00631l-settings-quick-summary-compact'));
    final settingsPreferenceGrid =
        find.byKey(const ValueKey('00631l-settings-preference-grid'));
    expect(settingsSummary, findsOneWidget);
    expect(settingsPreferenceGrid, findsOneWidget);
    expect(tester.getRect(settingsSummary).height, lessThanOrEqualTo(112));
    expect(tester.getRect(settingsPreferenceGrid).height,
        lessThanOrEqualTo(58));
    _expectNoTradingActionText();
  });

  testWidgets('overview phone first screen keeps market order', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await _pumpLab(tester, Mock00631LRepository());

    final quoteHeader = find.byKey(const ValueKey('00631l-main-quote-header'));
    final chart = find.byKey(const ValueKey('00631l-overview-sparkline-chart'));
    final dateStrip = find.byKey(
      const ValueKey('00631l-overview-sparkline-date-strip'),
    );
    final touchDetail =
        find.byKey(const ValueKey('00631l-overview-sparkline-touch-detail'));
    final digest = find.byKey(
      const ValueKey('00631l-overview-holdings-digest-strip'),
    );
    final mobileSummary = find.byKey(
      const ValueKey('00631l-overview-mobile-daily-summary-card'),
    );
    final firstGlance = find.byKey(
      const ValueKey('00631l-overview-first-glance-strip'),
    );
    final bottomNav = find.byKey(const ValueKey('00631l-bottom-nav'));

    expect(quoteHeader, findsOneWidget);
    expect(chart, findsOneWidget);
    expect(dateStrip, findsOneWidget);
    expect(touchDetail, findsOneWidget);
    expect(digest, findsOneWidget);
    expect(mobileSummary, findsOneWidget);
    expect(firstGlance, findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('00631l-overview-market-stack')),
        matching: mobileSummary,
      ),
      findsOneWidget,
    );
    expect(bottomNav, findsOneWidget);

    final quoteRect = tester.getRect(quoteHeader);
    final chartRect = tester.getRect(chart);
    final dateRect = tester.getRect(dateStrip);
    final touchRect = tester.getRect(touchDetail);
    final digestRect = tester.getRect(digest);
    final summaryRect = tester.getRect(mobileSummary);
    final navRect = tester.getRect(bottomNav);

    expect(quoteRect.height, lessThanOrEqualTo(60));
    expect(chartRect.height, lessThanOrEqualTo(56));
    expect(quoteRect.top, lessThan(chartRect.top));
    expect(chartRect.bottom, lessThanOrEqualTo(dateRect.top));
    expect(dateRect.bottom, lessThanOrEqualTo(touchRect.top));
    expect(touchRect.bottom, lessThan(summaryRect.top));
    expect(digestRect.bottom, lessThanOrEqualTo(summaryRect.bottom));
    expect(summaryRect.bottom, lessThanOrEqualTo(navRect.top - 8));
    expect(chartRect.bottom, lessThanOrEqualTo(366));
    for (final label in const ['AI', 'TX', '2330', 'CASH']) {
      expect(
        find.descendant(of: firstGlance, matching: find.text(label)),
        findsOneWidget,
      );
    }
    expect(
      find.descendant(
        of: mobileSummary,
        matching: find.text('非買賣建議'),
      ),
      findsNothing,
    );
    _expectNoTradingActionText();
  });

  testWidgets('overview first glance uses compact status chips',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await _pumpLab(tester, _OfficialIntradayRepository());

    final firstGlance = find.byKey(
      const ValueKey('00631l-overview-first-glance-strip'),
    );
    final aiStatus =
        find.byKey(const ValueKey('00631l-overview-ai-compact-line'));
    expect(firstGlance, findsOneWidget);
    expect(aiStatus, findsOneWidget);
    expect((tester.widget<Text>(aiStatus).data ?? '').trim(), isNotEmpty);
    for (final label in const ['AI', 'TX', '2330', 'CASH']) {
      expect(
        find.descendant(of: firstGlance, matching: find.text(label)),
        findsOneWidget,
      );
    }
    _expectNoTradingActionText();
  });

  testWidgets('overview chart shows one-year label and date axis',
      (tester) async {
    await _pumpLab(tester, _PriceHistoryRepository());

    expect(find.text('近一年走勢'), findsOneWidget);
    expect(find.text('2024/06/03'), findsNothing);
    expect(find.text('2025/06/03'), findsWidgets);
    expect(find.text('2026/06/01'), findsWidgets);
    expect(find.text('2026/06/03'), findsWidgets);
    expect(find.text('\u8d77\u9ede'), findsWidgets);
    expect(find.text('\u4e2d\u6bb5'), findsWidgets);
    expect(find.text('\u6700\u65b0'), findsWidgets);
    expect(
      find.byKey(const ValueKey('00631l-overview-sparkline-date-start')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-overview-sparkline-date-mid')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-overview-sparkline-date-end')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-overview-sparkline-date-strip')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-overview-sparkline-touch-detail')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('00631l-overview-sparkline-touch-detail')),
        matching: find.text('\u65e5\u671f'),
      ),
      findsWidgets,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('00631l-overview-sparkline-touch-detail')),
        matching: find.text('\u6536\u76e4'),
      ),
      findsWidgets,
    );
    expect(
      tester
          .getRect(
            find.byKey(
                const ValueKey('00631l-overview-sparkline-touch-detail')),
          )
          .height,
      lessThanOrEqualTo(44),
    );
    expect(find.textContaining('點擊圖表可查看指定日期數值'), findsWidgets);
  });

  testWidgets(
      'overview defers ETF comparison history loading until history tab',
      (tester) async {
    final repository = _CountingEtfHistoryRepository();

    await _pumpLab(tester, repository);

    final overviewRequests = repository.etfHistoryRequests;
    expect(overviewRequests, lessThanOrEqualTo(1));
    expect(find.byKey(const ValueKey('00631l-etf-comparison-return-chart')),
        findsNothing);

    await _tapSection(tester, 'historyBacktest');
    await tester.pumpAndSettle();

    expect(repository.etfHistoryRequests, greaterThan(overviewRequests + 1));
    expect(
      find.byKey(const ValueKey('00631l-etf-comparison-chart-expansion')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('00631l-etf-comparison-return-chart')),
        findsNothing);
    await tester.ensureVisible(
      find.byKey(const ValueKey('00631l-etf-comparison-chart-expansion')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('00631l-etf-comparison-chart-expansion')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('00631l-etf-comparison-return-chart')),
        findsOneWidget);
    _expectNoTradingActionText();
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
    expect(find.textContaining('資料載入中'), findsOneWidget);
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

  testWidgets('loading shell includes compact app skeleton keys',
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

    expect(
        find.byKey(const ValueKey('00631l-loading-app-shell')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('00631l-loading-status-strip')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-loading-quote-card')),
      findsOneWidget,
    );
    expect(
      tester
          .getRect(find.byKey(const ValueKey('00631l-loading-quote-card')))
          .height,
      lessThanOrEqualTo(210),
    );
    expect(
      find.byKey(const ValueKey('00631l-loading-premium-box')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-loading-chart-skeleton')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-loading-metric-grid')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('00631l-loading-section-card')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('00631l-loading-source-rail')),
      findsOneWidget,
    );
    expect(
      tester
          .getRect(find.byKey(const ValueKey('00631l-loading-source-rail')))
          .height,
      lessThanOrEqualTo(42),
    );
    for (final label in const ['歷', '盤', '解讀']) {
      expect(find.text(label), findsWidgets);
    }
    for (final label in const ['HIS', 'LIVE']) {
      expect(find.text(label), findsNothing);
    }
  });

  testWidgets('fast startup renders first screen while details load',
      (tester) async {
    final repository = _FastStartupRepository();

    await _pumpLab(tester, repository, settle: false);
    await tester.pump();

    expect(find.textContaining('00631L 正二研究室'), findsWidgets);
    expect(find.text('核心資料'), findsNothing);
    expect(find.textContaining('背景更新中'), findsNothing);
    expect(find.text('圖表與曝險'), findsNothing);
    expect(find.text('更多資料'), findsOneWidget);
    expect(find.text('完整數字比較'), findsNothing);
    expect(find.text('7 / 30 日內容物變化'), findsNothing);
    final readinessStrip = find.byKey(
      const ValueKey('00631l-quote-readiness-strip'),
    );
    expect(readinessStrip, findsNothing);
    expect(
      find.byKey(const ValueKey('00631l-overview-brief-panel')),
      findsNothing,
    );
    await _expandOverviewMore(tester);
    expect(readinessStrip, findsOneWidget);
    expect(
      find.descendant(of: readinessStrip, matching: find.text('syncing')),
      findsNothing,
    );
    expect(
      find.descendant(of: readinessStrip, matching: find.text('checking')),
      findsNothing,
    );
    expect(
      find.descendant(of: readinessStrip, matching: find.text('loading')),
      findsNothing,
    );
    expect(
      find.descendant(of: readinessStrip, matching: find.text('daily')),
      findsNothing,
    );
    expect(
      find.descendant(of: readinessStrip, matching: find.text('backend')),
      findsNothing,
    );
    expect(
      find.descendant(of: readinessStrip, matching: find.text('pending')),
      findsNothing,
    );
    expect(
      find.descendant(of: readinessStrip, matching: find.text('P/D')),
      findsNothing,
    );
    expect(
      find.descendant(of: readinessStrip, matching: find.text('twse_a_k_json')),
      findsNothing,
    );
    expect(
      find.descendant(of: readinessStrip, matching: find.text('error')),
      findsNothing,
    );
    expect(
      find.descendant(of: readinessStrip, matching: find.text('unavailable')),
      findsNothing,
    );
    _expectNoTradingActionText();

    await repository.complete();
    await tester.pumpAndSettle();
    expect(find.textContaining('背景更新中'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('overview defers full lab data until detail tab opens',
      (tester) async {
    final repository = _FastStartupRepository();

    await _pumpLab(tester, repository);

    expect(repository.fullRequested, isFalse);
    expect(
        find.byKey(const ValueKey('00631l-section-overview')), findsOneWidget);

    await _tapSection(tester, 'historyBacktest');
    await tester.pump();

    expect(repository.fullRequested, isTrue);
    expect(find.byKey(const ValueKey('00631l-history-view')), findsWidgets);
    _expectNoTradingActionText();
  });

  testWidgets('fast startup shows unavailable for known holdings errors',
      (tester) async {
    final repository = _FastStartupNoUsableHoldingsRepository();

    await _pumpLab(tester, repository, settle: false);
    await tester.pump();

    final readinessStrip = find.byKey(
      const ValueKey('00631l-quote-readiness-strip'),
    );
    expect(readinessStrip, findsNothing);
    await _expandOverviewMore(tester);
    expect(readinessStrip, findsOneWidget);
    expect(
      find.descendant(of: readinessStrip, matching: find.text('syncing')),
      findsNothing,
    );
    expect(
      find.descendant(of: readinessStrip, matching: find.text('checking')),
      findsNothing,
    );
    expect(
      find.descendant(of: readinessStrip, matching: find.text('不可用')),
      findsWidgets,
    );
    expect(
      find.descendant(of: readinessStrip, matching: find.text('錯誤')),
      findsWidgets,
    );
    _expectNoTradingActionText();
  });

  testWidgets('fast startup localizes intraday pending state', (tester) async {
    final repository = _FastStartupNoIntradayNavRepository();

    await _pumpLab(tester, repository, settle: false);
    await tester.pump();

    final readinessStrip = find.byKey(
      const ValueKey('00631l-quote-readiness-strip'),
    );
    expect(readinessStrip, findsNothing);
    await _expandOverviewMore(tester);
    expect(readinessStrip, findsOneWidget);
    expect(find.descendant(of: readinessStrip, matching: find.text('暫無')),
        findsWidgets);
    expect(
      find.descendant(of: readinessStrip, matching: find.text('checking')),
      findsNothing,
    );
    _expectNoTradingActionText();
  });

  testWidgets('full data failure keeps fast first screen visible',
      (tester) async {
    final repository = _FastStartupRepository(completeWithError: true);

    await _pumpLab(tester, repository, settle: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    expect(find.text('核心資料'), findsNothing);
    expect(find.text('近一年走勢'), findsOneWidget);
    expect(repository.fullRequested, isFalse);
    expect(find.textContaining('fallback'), findsNothing);

    await _tapSection(tester, 'historyBacktest');
    await tester.pump();

    expect(repository.fullRequested, isTrue);
    expect(find.textContaining('fallback'), findsWidgets);
    expect(find.textContaining('00631L 正二研究室'), findsWidgets);
    _expectNoTradingActionText();
  });

  testWidgets('history section shows price history when available',
      (tester) async {
    await _pumpLab(tester, _PriceHistoryRepository());

    await _tapSection(tester, 'historyBacktest');
    await tester.pumpAndSettle();

    expect(find.text('歷史回測'), findsWidgets);
    expect(find.textContaining('預設 1 年，可調日期'), findsNothing);
    expect(
      find.byKey(const ValueKey('00631l-history-range-context')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-history-backtest-top-strip')),
      findsOneWidget,
    );
    expect(find.text('00631L 00631L'), findsNothing);
    expect(
      tester
          .getRect(
            find.byKey(const ValueKey('00631l-history-backtest-top-strip')),
          )
          .height,
      lessThanOrEqualTo(92),
    );
    expect(
      find.byKey(const ValueKey('00631l-history-top-strip-metrics')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-history-quality-expansion')),
      findsOneWidget,
    );
    expect(find.textContaining('範圍'), findsWidgets);
    expect(find.text('static_official'), findsNothing);
    expect(find.textContaining('static_official'), findsNothing);
    expect(
      find.byKey(const ValueKey('00631l-history-primary-heading')),
      findsNothing,
    );
    expect(find.text('市價'), findsNothing);
    expect(find.text('歷史資料完整度'), findsWidgets);
    expect(find.text('區間報酬'), findsWidgets);
    expect(
      find.byKey(const ValueKey('00631l-history-range-chips')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-history-range-context')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-history-date-settings-expansion')),
      findsNothing,
    );
    expect(find.text('日期區間'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('00631l-history-date-controls-visible')),
      findsOneWidget,
    );
    expect(
      tester.getTopLeft(find.text('日期區間')).dy,
      lessThan(tester.getTopLeft(find.text('收盤價').first).dy),
    );
    expect(
      find.byKey(const ValueKey('00631l-date-range-summary')),
      findsWidgets,
    );
    expect(
      find.byKey(const ValueKey('00631l-date-range-summary-mode')),
      findsWidgets,
    );
    expect(
      find.byKey(const ValueKey('00631l-date-range-summary-start')),
      findsWidgets,
    );
    expect(
      find.byKey(const ValueKey('00631l-date-range-summary-end')),
      findsWidgets,
    );
    expect(
      find.byKey(const ValueKey('00631l-history-range-1y')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<ChoiceChip>(
            find.descendant(
              of: find.byKey(const ValueKey('00631l-history-range-1y')),
              matching: find.byType(ChoiceChip),
            ),
          )
          .selected,
      isTrue,
    );
    expect(
      find.byKey(const ValueKey('00631l-history-range-3y')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-history-range-all')),
      findsOneWidget,
    );
    expect(find.textContaining('點擊圖表可查看指定日期數值'), findsWidgets);
    expect(find.textContaining('目前區間：2025/06/03 - 2026/06/03'), findsWidgets);
    expect(find.textContaining('圖表、指標與下方回測快覽'), findsWidgets);
    expect(find.text('起 2025/06/03'), findsWidgets);
    expect(find.text('中 2026/06/01'), findsWidgets);
    expect(find.text('迄 2026/06/03'), findsWidgets);
    expect(find.textContaining('區間筆數 4'), findsOneWidget);
    expect(find.textContaining('完整筆數 5'), findsOneWidget);
    expect(find.text('目前區間價格表'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('00631l-history-holdings-expansion')),
      findsOneWidget,
    );
    expect(find.text('內容物歷史'), findsOneWidget);
    expect(find.text('最近 30 筆 holdings'), findsNothing);
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
    expect(
      find.byKey(const ValueKey('00631l-line-chart-touch-detail')),
      findsWidgets,
    );
    expect(
      find.byKey(const ValueKey('00631l-chart-axis-start-label')),
      findsWidgets,
    );
    expect(
      find.byKey(const ValueKey('00631l-chart-axis-middle-label')),
      findsWidgets,
    );
    expect(
      find.byKey(const ValueKey('00631l-chart-axis-end-label')),
      findsWidgets,
    );
    expect(
      find.byKey(const ValueKey('00631l-line-chart-touch-primary')),
      findsWidgets,
    );
    expect(
      find.byKey(const ValueKey('00631l-line-chart-touch-secondary')),
      findsWidgets,
    );
    expect(
      find.byKey(const ValueKey('00631l-line-chart-touch-date')),
      findsWidgets,
    );
    expect(
      find.byKey(const ValueKey('00631l-line-chart-touch-value')),
      findsWidgets,
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('00631l-history-holdings-expansion')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('內容物歷史'));
    await tester.pumpAndSettle();
    expect(find.text('尚無內容物紀錄'), findsOneWidget);
    expect(find.byKey(const ValueKey('00631l-history-view')), findsOneWidget);
    _expectNoTradingActionText();
  });

  testWidgets('history range context wraps on phone width', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await _pumpLab(tester, _PriceHistoryRepository());

    await _tapSection(tester, 'historyBacktest');
    await tester.pumpAndSettle();

    final topStrip =
        find.byKey(const ValueKey('00631l-history-backtest-top-strip'));
    expect(topStrip, findsOneWidget);
    expect(tester.getRect(topStrip).height, lessThanOrEqualTo(70));
    expect(
      find.byKey(const ValueKey('00631l-history-top-strip-metrics')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-history-top-strip-source-badge')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-history-top-strip-contract-badge')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('00631l-history-top-strip-date-pill')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-history-top-strip-close-pill')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('00631l-history-top-strip-row-pill')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-history-top-strip-return-pill')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-history-top-strip-drawdown-pill')),
      findsOneWidget,
    );
    for (final label in const ['區間', '筆數', '報酬', '回撤']) {
      expect(
        find.descendant(of: topStrip, matching: find.text(label)),
        findsOneWidget,
      );
    }
    expect(
      find.descendant(of: topStrip, matching: find.text('1Y')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: topStrip, matching: find.text('00631L 2026/06/03')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: topStrip, matching: find.textContaining(' / ')),
      findsNothing,
    );
    expect(
      find.descendant(of: topStrip, matching: find.text('來源')),
      findsNothing,
    );

    final rangeContext =
        find.byKey(const ValueKey('00631l-history-range-context'));
    expect(rangeContext, findsOneWidget);
    expect(tester.getRect(rangeContext).height, lessThanOrEqualTo(118));
    expect(
      find.descendant(
        of: rangeContext,
        matching: find.byKey(const ValueKey('00631l-range-context-wrap')),
      ),
      findsOneWidget,
    );
    final metricStrip = find.descendant(
      of: rangeContext,
      matching: find.byKey(const ValueKey('00631l-range-context-metric-strip')),
    );
    expect(metricStrip, findsOneWidget);
    expect(tester.getRect(metricStrip).height, lessThanOrEqualTo(18));
    expect(
      find.descendant(of: metricStrip, matching: find.textContaining(' - ')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: rangeContext,
        matching: find.byKey(const ValueKey('00631l-date-range-preset-scroll')),
      ),
      findsOneWidget,
    );
    final presetStrip = find.descendant(
      of: rangeContext,
      matching: find.byKey(const ValueKey('00631l-date-range-preset-scroll')),
    );
    for (final label in const ['1 年', '3 年', '全部']) {
      expect(
        find.descendant(of: presetStrip, matching: find.text(label)),
        findsOneWidget,
      );
    }
    expect(
      find.descendant(of: presetStrip, matching: find.text('最近 1 年')),
      findsNothing,
    );
    final rangeRect = tester.getRect(rangeContext);
    for (final key in const [
      ValueKey('00631l-history-range-1y'),
      ValueKey('00631l-history-range-3y'),
      ValueKey('00631l-history-range-all'),
    ]) {
      final chipRect = tester.getRect(find.byKey(key));
      expect(chipRect.left, greaterThanOrEqualTo(rangeRect.left));
      expect(chipRect.right, lessThanOrEqualTo(rangeRect.right));
    }
    final dateControls = find.descendant(
      of: rangeContext,
      matching: find.byKey(
        const ValueKey('00631l-history-date-controls-visible'),
      ),
    );
    expect(dateControls, findsOneWidget);
    expect(tester.getRect(dateControls).height, lessThanOrEqualTo(36));
    expect(
      find.descendant(
        of: rangeContext,
        matching: find.byKey(const ValueKey('00631l-date-range-summary')),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: rangeContext,
        matching: find.byKey(const ValueKey('00631l-date-range-summary-mode')),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: rangeContext,
        matching: find.byKey(const ValueKey('00631l-range-context-scroll')),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('00631l-chart-axis-start-label')).first,
        matching: find.text('起'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('00631l-chart-axis-middle-label')).first,
        matching: find.text('中'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('00631l-chart-axis-end-label')).first,
        matching: find.text('迄'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('00631l-chart-axis-start-label')).first,
        matching: find.text('2025/06/03'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('00631l-chart-axis-end-label')).first,
        matching: find.text('2026/06/03'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('00631l-line-chart-touch-detail')).first,
        matching: find.text('2026/06/03'),
      ),
      findsOneWidget,
    );
    _expectNoTradingActionText();
  });

  testWidgets('history section shows empty state without official history',
      (tester) async {
    await _pumpLab(tester, _NoHistoryRepository());

    await _tapSection(tester, 'historyBacktest');
    await tester.pumpAndSettle();

    expect(find.text('尚無官方價格歷史'), findsWidgets);
    expect(
      find.byKey(const ValueKey('00631l-history-holdings-expansion')),
      findsOneWidget,
    );
    expect(find.text('尚無內容物紀錄'), findsNothing);
    await tester.ensureVisible(
      find.byKey(const ValueKey('00631l-history-holdings-expansion')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('內容物歷史'));
    await tester.pumpAndSettle();
    expect(find.text('尚無內容物紀錄'), findsOneWidget);
  });

  testWidgets('history sparse chart shows latest point instead of blank frame',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await _pumpLab(tester, _SparsePriceHistoryRepository());

    await _tapSection(tester, 'historyBacktest');
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('00631l-line-chart-sparse-state')),
      findsWidgets,
    );
    expect(find.textContaining('資料點不足'), findsWidgets);
    expect(find.textContaining('2026/06/08'), findsWidgets);
    _expectNoTradingActionText();
  });

  testWidgets('history backtest section renders inputs and disclaimer',
      (tester) async {
    await _pumpLab(tester, _PriceHistoryRepository());

    await _tapSection(tester, 'historyBacktest');
    await tester.pumpAndSettle();

    expect(find.text('回測快覽'), findsOneWidget);
    expect(find.textContaining('回測不代表未來表現'), findsWidgets);
    expect(find.text('歷史回測'), findsWidgets);
    expect(find.text('日期區間'), findsOneWidget);
    expect(find.text('開始日期'), findsWidgets);
    expect(find.text('結束日期'), findsWidgets);
    expect(find.textContaining('回測區間'), findsOneWidget);
    expect(find.textContaining('策略 定期定額'), findsOneWidget);
    expect(find.textContaining('樣本'), findsOneWidget);
    final backtestView = find.byKey(const ValueKey('00631l-backtest-view'));
    final comparisonPanel =
        find.byKey(const ValueKey('00631l-etf-history-comparison'));
    expect(backtestView, findsOneWidget);
    expect(comparisonPanel, findsOneWidget);
    expect(
      tester.getTopLeft(backtestView).dy,
      lessThan(tester.getTopLeft(comparisonPanel).dy),
      reason: 'Backtest controls should stay with history before ETF compare.',
    );
    expect(
      find.byKey(const ValueKey('00631l-backtest-range-chips')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-backtest-range-context')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-date-range-summary')),
      findsWidgets,
    );
    expect(find.text('日期與設定'), findsOneWidget);
    expect(find.text('金額與成本參數'), findsOneWidget);
    expect(find.text('初始金額'), findsNothing);
    final backtestAllRange =
        find.byKey(const ValueKey('00631l-backtest-range-all'));
    await tester.scrollUntilVisible(
      backtestAllRange,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(backtestAllRange);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ChoiceChip>(
            find.descendant(
              of: backtestAllRange,
              matching: find.byType(ChoiceChip),
            ),
          )
          .selected,
      isTrue,
    );
    expect(
      find.textContaining('回測區間 2024/06/03 - 2026/06/03'),
      findsOneWidget,
    );
    expect(find.text('市價'), findsNothing);
    expect(find.text('一次投入'), findsOneWidget);
    final quickResultStrip =
        find.byKey(const ValueKey('00631l-backtest-quick-result-strip'));
    expect(quickResultStrip, findsOneWidget);
    expect(
      find.descendant(of: quickResultStrip, matching: find.text('年化')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: quickResultStrip, matching: find.text('波動')),
      findsOneWidget,
    );
    await tester.ensureVisible(find.text('金額與成本參數'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('金額與成本參數'));
    await tester.pumpAndSettle();
    expect(find.text('初始金額'), findsOneWidget);
    expect(find.text('每月投入金額'), findsOneWidget);
    expect(find.text('每月日期'), findsOneWidget);
    expect(find.text('手續費率 %'), findsOneWidget);
    expect(quickResultStrip, findsOneWidget);
    expect(find.textContaining('回測不代表未來表現'), findsWidgets);
    expect(find.textContaining('非買賣建議'), findsWidgets);
    _expectNoTradingActionText();
  });

  testWidgets('position section saves local-only data controls',
      (tester) async {
    await _pumpLab(tester, Mock00631LRepository());

    await _tapSection(tester, 'position');
    await tester.pumpAndSettle();

    expect(find.text('本機持倉'), findsNothing);
    expect(find.text('持倉狀態'), findsNothing);
    expect(find.text('00631L 持倉'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('00631l-position-account-strip')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-position-account-metric-strip')),
      findsOneWidget,
    );
    final sourceExpansion =
        find.byKey(const ValueKey('00631l-position-source-expansion'));
    final sourceSummary =
        find.byKey(const ValueKey('00631l-position-source-summary-chips'));
    final sourceStrip =
        find.byKey(const ValueKey('00631l-position-source-chip-strip'));
    expect(sourceExpansion, findsOneWidget);
    expect(sourceSummary, findsNothing);
    expect(sourceStrip, findsNothing);
    expect(
      find.descendant(of: sourceSummary, matching: find.textContaining('行情')),
      findsNothing,
    );
    expect(
      find.descendant(of: sourceSummary, matching: find.textContaining('時間')),
      findsNothing,
    );
    await tester.tap(sourceExpansion);
    await tester.pumpAndSettle();
    expect(sourceStrip, findsOneWidget);
    for (final label in const ['行情來源', '歷史來源', '資料時間']) {
      expect(
        find.descendant(of: sourceStrip, matching: find.textContaining(label)),
        findsOneWidget,
      );
    }
    expect(
      find.byKey(const ValueKey('00631l-position-input-mini-header')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-position-primary-actions')),
      findsOneWidget,
    );
    final positionInputCard =
        find.byKey(const ValueKey('00631l-position-compact-input-card'));
    final positionActions =
        find.byKey(const ValueKey('00631l-position-primary-actions'));
    expect(
      tester.getTopLeft(positionInputCard).dy,
      lessThan(tester.getTopLeft(positionActions).dy),
      reason: 'Empty position flow should show inputs before actions.',
    );
    expect(find.text('未輸入'), findsWidgets);
    expect(
      find.byKey(const ValueKey('00631l-position-empty-hint-strip')),
      findsOneWidget,
    );
    expect(find.text('輸入持倉資料'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('00631l-position-compact-input-card')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-position-field-shares')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-position-field-average-cost')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-position-advanced-inputs')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-position-field-assets')),
      findsNothing,
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('00631l-position-advanced-inputs')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('00631l-position-advanced-inputs')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('00631l-position-field-assets')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-position-field-fee')),
      findsOneWidget,
    );
    expect(find.textContaining('成本'), findsWidgets);
    expect(find.text('估算細節'), findsOneWidget);
    expect(find.textContaining('資料只留在本機'), findsWidgets);
    expect(find.text('市價'), findsNothing);
    expect(
      find.byKey(const ValueKey('00631l-position-tools-panel')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('00631l-position-action-save')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-position-action-export')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('00631l-position-action-clear')),
      findsNothing,
    );

    await tester.enterText(
      find.byKey(const ValueKey('00631l-position-field-shares')),
      '1000',
    );
    await tester.enterText(
      find.byKey(const ValueKey('00631l-position-field-average-cost')),
      '120',
    );
    await tester.pumpAndSettle();
    final toolsPanel =
        find.byKey(const ValueKey('00631l-position-tools-panel'));
    expect(toolsPanel, findsOneWidget);
    expect(
      find.byKey(const ValueKey('00631l-position-tool-actions')),
      findsNothing,
    );
    await tester.ensureVisible(toolsPanel);
    await tester.pumpAndSettle();
    await tester.tap(toolsPanel);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('00631l-position-tool-actions')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-position-action-export')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-position-action-clear')),
      findsOneWidget,
    );
    expect(find.textContaining('本機保存'), findsWidgets);
  });

  testWidgets('empty position starts with input card on phone width',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await _pumpLab(tester, Mock00631LRepository());

    await _tapSection(tester, 'position');
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('00631l-position-account-strip')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('00631l-position-account-metric-strip')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('00631l-position-input-mini-header')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('00631l-position-empty-hint-strip')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('00631l-position-source-expansion')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('00631l-position-field-shares')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-position-field-average-cost')),
      findsOneWidget,
    );
    final sharesField =
        find.byKey(const ValueKey('00631l-position-field-shares'));
    final averageCostField =
        find.byKey(const ValueKey('00631l-position-field-average-cost'));
    expect(
      (tester.getTopLeft(sharesField).dy -
              tester.getTopLeft(averageCostField).dy)
          .abs(),
      lessThan(2),
      reason: 'Phone position inputs should stay in one compact row.',
    );
    expect(
      tester.getTopLeft(sharesField).dx,
      lessThan(tester.getTopLeft(averageCostField).dx),
    );
    expect(
      find.byKey(const ValueKey('00631l-position-advanced-inputs')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('00631l-position-estimate-details')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('00631l-position-local-note')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('00631l-position-action-save')),
      findsOneWidget,
    );
    expect(
      tester
          .getRect(find.byKey(const ValueKey('00631l-position-action-save')))
          .height,
      lessThanOrEqualTo(38),
    );
    expect(find.text('保存'), findsOneWidget);
    expect(find.text('保存本機資料'), findsNothing);
    expect(find.text('只保存在此裝置。'), findsNothing);
    final inputCard =
        find.byKey(const ValueKey('00631l-position-compact-input-card'));
    expect(tester.getRect(inputCard).height, lessThanOrEqualTo(160));
    expect(
      find.descendant(
        of: inputCard,
        matching: find.byKey(const ValueKey('00631l-position-action-save')),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-position-primary-actions')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('00631l-position-tools-panel')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('00631l-position-action-export')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('00631l-position-action-clear')),
      findsNothing,
    );
    _expectNoTradingActionText();
  });

  testWidgets('position phone values keep summary first without duplicate grid',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await _pumpLab(tester, Mock00631LRepository());

    await _tapSection(tester, 'position');
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('00631l-position-field-shares')),
      '1000',
    );
    await tester.enterText(
      find.byKey(const ValueKey('00631l-position-field-average-cost')),
      '120',
    );
    await tester.pumpAndSettle();

    final accountStrip =
        find.byKey(const ValueKey('00631l-position-account-strip'));
    final inputCard =
        find.byKey(const ValueKey('00631l-position-compact-input-card'));
    expect(accountStrip, findsOneWidget);
    expect(tester.getRect(accountStrip).height, lessThanOrEqualTo(90));
    expect(
      find.byKey(const ValueKey('00631l-position-account-metric-strip')),
      findsOneWidget,
    );
    expect(find.text('修改持倉'), findsOneWidget);
    expect(find.text('輸入持倉資料'), findsNothing);
    expect(find.text('工具'), findsOneWidget);
    expect(find.text('持倉工具'), findsNothing);
    expect(
      find.byKey(const ValueKey('00631l-position-primary-actions')),
      findsNothing,
    );
    expect(
      find.descendant(
        of: accountStrip,
        matching: find.byKey(const ValueKey('00631l-position-title-line')),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: accountStrip,
        matching: find.textContaining('1,000股 @'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: accountStrip,
        matching: find.byKey(const ValueKey('00631l-position-time-badge')),
      ),
      findsOneWidget,
    );
    final metricGrid =
        find.byKey(const ValueKey('00631l-position-account-metric-grid'));
    expect(metricGrid, findsOneWidget);
    expect(
      find.byKey(const ValueKey('00631l-position-account-metric-scroll')),
      findsOneWidget,
    );
    expect(tester.getRect(metricGrid).height, lessThanOrEqualTo(38));
    expect(
      tester.getTopLeft(accountStrip).dy,
      lessThan(tester.getTopLeft(inputCard).dy),
    );
    expect(
      find.byKey(const ValueKey('00631l-position-estimate-details')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('00631l-position-local-note')),
      findsNothing,
    );
    _expectNoTradingActionText();
  });

  testWidgets('backtest quick result stays compact on phone width',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await _pumpLab(tester, _PriceHistoryRepository());

    await _tapSection(tester, 'historyBacktest');
    await tester.pumpAndSettle();

    final quickResultStrip =
        find.byKey(const ValueKey('00631l-backtest-quick-result-strip'));
    await tester.scrollUntilVisible(
      quickResultStrip,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(quickResultStrip, findsOneWidget);
    expect(tester.getRect(quickResultStrip).height, lessThanOrEqualTo(78));
    expect(
      find.descendant(
        of: quickResultStrip,
        matching: find.textContaining('source'),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: quickResultStrip,
        matching: find.text('非買賣建議'),
      ),
      findsNothing,
    );
    final compactStrategyToggle = find.byKey(
      const ValueKey('00631l-backtest-strategy-toggle-compact'),
    );
    await tester.scrollUntilVisible(
      compactStrategyToggle,
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(compactStrategyToggle, findsOneWidget);
    expect(
      tester.getRect(compactStrategyToggle).height,
      lessThanOrEqualTo(34),
    );
    final parameterStrip =
        find.byKey(const ValueKey('00631l-backtest-parameter-strip'));
    await tester.scrollUntilVisible(
      parameterStrip,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(parameterStrip, findsOneWidget);
    expect(tester.getRect(parameterStrip).height, lessThanOrEqualTo(38));
    for (final label in const ['策略', '初始', '每月', '日', '成本']) {
      expect(
        find.descendant(of: parameterStrip, matching: find.text(label)),
        findsOneWidget,
      );
    }
    _expectNoTradingActionText();
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
      tester
          .getTopLeft(
            find.byKey(const ValueKey('00631l-symbol-search-result-0050')),
          )
          .dy,
      lessThan(
        tester
            .getTopLeft(
              find.byKey(const ValueKey('00631l-symbol-search-database-panel')),
            )
            .dy,
      ),
    );
    expect(
      find.byKey(const ValueKey('00631l-symbol-history-ready-0050')),
      findsOneWidget,
    );
    final result0050 =
        find.byKey(const ValueKey('00631l-symbol-search-result-0050'));
    expect(
      find.descendant(of: result0050, matching: find.text('歷史/回測可用')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: result0050,
        matching: find.byKey(
          const ValueKey('00631l-symbol-history-metadata-0050'),
        ),
      ),
      findsNothing,
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('00631l-symbol-result-details-0050')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('00631l-symbol-result-details-0050')),
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: result0050, matching: find.text('回測可用')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('00631l-symbol-search-result-00631L')),
        findsNothing);
    _expectNoTradingActionText();
  });

  testWidgets('top symbol search result stays compact on phone width',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await _pumpLab(tester, Mock00631LRepository());

    await tester.tap(find.byKey(const ValueKey('00631l-symbol-search-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('00631l-symbol-search-field')),
      '0050',
    );
    await tester.pumpAndSettle();

    final result0050 =
        find.byKey(const ValueKey('00631l-symbol-search-result-0050'));
    final detailToggle =
        find.byKey(const ValueKey('00631l-symbol-result-details-0050'));
    expect(result0050, findsOneWidget);
    expect(detailToggle, findsOneWidget);
    expect(tester.getRect(result0050).height, lessThanOrEqualTo(78));
    expect(find.textContaining('篩選'), findsNothing);
    expect(find.textContaining('僅清單'), findsNothing);
    expect(find.textContaining('待補'), findsNothing);

    await tester.tap(detailToggle);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('00631l-symbol-capability-summary-0050')),
      findsOneWidget,
    );
    _expectNoTradingActionText();
  });

  testWidgets('top symbol search lazy-loads catalog when first data omits it',
      (tester) async {
    final repository = _DeferredCatalogSearchRepository();
    await _pumpLab(tester, repository);

    expect(repository.catalogRequestCount, 0);
    await tester.tap(find.byKey(const ValueKey('00631l-symbol-search-button')));
    await tester.pumpAndSettle();

    expect(repository.catalogRequestCount, 1);
    expect(
      find.byKey(const ValueKey('00631l-symbol-search-field')),
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
    _expectNoTradingActionText();
  });

  testWidgets('top symbol search shows loading while lazy catalog resolves',
      (tester) async {
    final repository = _SlowCatalogSearchRepository();
    await _pumpLab(tester, repository);

    await tester.tap(find.byKey(const ValueKey('00631l-symbol-search-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(repository.catalogRequestCount, 1);
    expect(
      find.byKey(const ValueKey('00631l-symbol-search-catalog-loading')),
      findsOneWidget,
    );

    await repository.completeCatalog();
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('00631l-symbol-search-field')),
      '0050',
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('00631l-symbol-search-result-0050')),
      findsOneWidget,
    );
    _expectNoTradingActionText();
  });

  testWidgets('top symbol search shows error when lazy catalog fails',
      (tester) async {
    final repository = _ErrorCatalogSearchRepository();
    await _pumpLab(tester, repository);

    await tester.tap(find.byKey(const ValueKey('00631l-symbol-search-button')));
    await tester.pumpAndSettle();

    expect(repository.catalogRequestCount, 1);
    expect(
      find.byKey(const ValueKey('00631l-symbol-search-catalog-error')),
      findsOneWidget,
    );
    expect(find.text('ETF 目錄載入失敗'), findsOneWidget);
    _expectNoTradingActionText();
  });

  testWidgets('symbol search ranks code matches before name matches',
      (tester) async {
    await _pumpLab(tester, Mock00631LRepository());

    await tester.tap(find.byKey(const ValueKey('00631l-symbol-search-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('00631l-symbol-search-field')),
      '50',
    );
    await tester.pumpAndSettle();

    final codeMatch =
        find.byKey(const ValueKey('00631l-symbol-search-result-0050'));
    expect(codeMatch, findsOneWidget);
    expect(
      find.byKey(const ValueKey('00631l-symbol-search-rank-0-0050')),
      findsOneWidget,
    );
    _expectNoTradingActionText();
  });

  testWidgets('catalog-only ETF selection shows missing history guidance',
      (tester) async {
    await _pumpLab(tester, _CatalogOnlyGapReasonRepository());

    await tester.tap(find.byKey(const ValueKey('00631l-symbol-search-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('00631l-symbol-search-field')),
      '00400A',
    );
    await tester.pumpAndSettle();

    expect(
        find.byKey(const ValueKey('00631l-symbol-filter-all')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('00631l-symbol-filter-ready')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-symbol-filter-catalogOnly')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-symbol-search-result-00400A')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-symbol-filter-count-all-1-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-symbol-query-ready-count-0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-symbol-query-catalog-only-count-1')),
      findsOneWidget,
    );
    expect(find.text('歷史可用 0'), findsOneWidget);
    expect(find.text('僅清單 1'), findsWidgets);
    expect(find.textContaining('history-ready'), findsNothing);
    expect(find.textContaining('catalog-only'), findsNothing);
    expect(
      find.byKey(const ValueKey('00631l-symbol-catalog-only-00400A')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-symbol-gap-reason-00400A')),
      findsNothing,
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('00631l-symbol-result-details-00400A')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('00631l-symbol-result-details-00400A')),
    );
    await tester.pumpAndSettle();
    final catalogOnlyCapabilitySummary = tester.widget<Text>(
      find.byKey(const ValueKey('00631l-symbol-capability-summary-00400A')),
    );
    expect(catalogOnlyCapabilitySummary.data, contains('目前僅清單資料'));
    expect(catalogOnlyCapabilitySummary.data, contains('需先匯入'));
    expect(
      find.byKey(const ValueKey('00631l-symbol-gap-reason-00400A')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-symbol-capability-00400A-catalog')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('00631l-symbol-capability-00400A-history-missing'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('00631l-symbol-capability-00400A-backtest-unavailable'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('00631l-symbol-capability-00400A-ai-context-limited'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('00631l-symbol-filter-ready')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('00631l-symbol-search-result-00400A')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('00631l-symbol-filter-count-ready-0-1')),
      findsOneWidget,
    );

    await tester
        .tap(find.byKey(const ValueKey('00631l-symbol-filter-catalogOnly')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('00631l-symbol-search-result-00400A')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('00631l-symbol-filter-count-catalogOnly-1-1'),
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('00631l-symbol-search-result-00400A')),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    await _tapSection(tester, 'historyBacktest');
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('00631l-selected-etf-readiness-banner')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('00631l-selected-etf-capability-catalog-only'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('00631l-selected-etf-capability-backtest-paused'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('00631l-selected-etf-capability-compare-paused'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('00631l-selected-etf-capability-ai-limited-context'),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('00400A 僅清單資料'), findsOneWidget);
    expect(find.textContaining('尚未匯入可驗證歷史價格'), findsWidgets);

    expect(find.text('ETF 歷史資料尚未匯入'), findsOneWidget);
    expect(find.textContaining('請先匯入歷史價格'), findsWidgets);
    _expectNoTradingActionText();
  });

  testWidgets('comparison readiness shows skipped catalog-only selected ETF',
      (tester) async {
    await _pumpLab(tester, _CatalogOnlyComparisonRepository());

    await tester.tap(find.byKey(const ValueKey('00631l-symbol-search-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('00631l-symbol-search-field')),
      '00400A',
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('00631l-symbol-search-result-00400A')),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    await _tapSection(tester, 'historyBacktest');
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('00631l-etf-comparison-readiness-strip')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-etf-comparison-skipped-count-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-etf-comparison-skipped-00400A')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('00631l-etf-comparison-skipped-detail-00400A'),
      ),
      findsOneWidget,
    );
    _expectNoTradingActionText();
  });

  testWidgets('symbol search marks ETF ready from catalog history metadata',
      (tester) async {
    await _pumpLab(tester, _CatalogHistoryMetadataRepository());

    await tester.tap(find.byKey(const ValueKey('00631l-symbol-search-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('00631l-symbol-search-field')),
      '00701',
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('00631l-symbol-search-result-00701')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-symbol-history-ready-00701')),
      findsOneWidget,
    );
    expect(find.text('recent · 12 筆'), findsNothing);
    expect(
      find.byKey(const ValueKey('00631l-symbol-history-metadata-00701')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('00631l-symbol-price-basis-00701')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('00631l-symbol-catalog-only-00701')),
      findsNothing,
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('00631l-symbol-result-details-00701')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('00631l-symbol-result-details-00701')),
    );
    await tester.pumpAndSettle();
    expect(find.text('recent · 12 筆'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('00631l-symbol-history-metadata-00701')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-symbol-price-basis-00701')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-symbol-capability-00701-history')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-symbol-capability-00701-backtest')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-symbol-capability-00701-compare')),
      findsOneWidget,
    );
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
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(find.text('0050'), findsWidgets);
    expect(find.textContaining('元大台灣50'), findsWidgets);
    expect(
        find.byKey(const ValueKey('00631l-main-quote-header')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('00631l-selected-etf-usable-scope-line')),
      findsOneWidget,
    );
    await _tapSection(tester, 'historyBacktest');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('00631l-history-view')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('00631l-selected-etf-history-readiness-strip')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey(
          '00631l-selected-etf-history-strip-capability-history-ready',
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey(
          '00631l-selected-etf-history-strip-capability-backtest-ready',
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey(
          '00631l-selected-etf-history-strip-capability-compare-ready',
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey(
          '00631l-selected-etf-history-strip-capability-ai-full-context',
        ),
      ),
      findsOneWidget,
    );
    final qualityExpansion =
        find.byKey(const ValueKey('00631l-history-quality-expansion'));
    await tester.ensureVisible(qualityExpansion);
    await tester.pumpAndSettle();
    await tester.tap(qualityExpansion);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('00631l-selected-history-quality-card')),
      findsOneWidget,
    );
    expect(find.text('0050 歷史資料'), findsOneWidget);
    expect(find.text('3 筆'), findsWidgets);
    expect(find.textContaining('2025/06/03 - 2026/06/03'), findsWidgets);
    expect(find.textContaining('回測可用'), findsWidgets);
    expect(find.textContaining('盤中 NAV 限 00631L'), findsWidgets);
    expect(find.text('分割調整'), findsWidgets);
    expect(find.text('調整價可用'), findsWidgets);
    expect(find.byKey(const ValueKey('00631l-backtest-view')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('00631l-etf-history-comparison')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-etf-comparison-chart-expansion')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-etf-comparison-return-chart')),
      findsNothing,
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('00631l-etf-comparison-chart-expansion')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('00631l-etf-comparison-chart-expansion')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('00631l-etf-comparison-return-chart')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-comparison-touch-detail')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-comparison-touch-empty')),
      findsOneWidget,
    );
    expect(find.textContaining('指定資料日'), findsWidgets);
    expect(find.textContaining('附近'), findsNothing);
    expect(
      find.byKey(const ValueKey('00631l-chart-axis-start-label')),
      findsWidgets,
    );
    expect(
      find.byKey(const ValueKey('00631l-chart-axis-middle-label')),
      findsWidgets,
    );
    expect(
      find.byKey(const ValueKey('00631l-chart-axis-end-label')),
      findsWidgets,
    );
    expect(find.text('ETF 歷史比較'), findsOneWidget);
    expect(find.text('最近 1 年'), findsWidgets);
    expect(find.text('比較檔數'), findsOneWidget);
    final selectionPanel =
        find.byKey(const ValueKey('00631l-etf-comparison-selection-panel'));
    expect(selectionPanel, findsOneWidget);
    expect(find.byKey(const ValueKey('00631l-etf-compare-chip-0050')),
        findsNothing);
    expect(
      find.byKey(const ValueKey('00631l-etf-comparison-basket-expansion')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-etf-comparison-basket-context')),
      findsNothing,
    );
    await tester.tap(
      find.byKey(const ValueKey('00631l-etf-comparison-basket-expansion')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('00631l-etf-comparison-basket-context')),
      findsOneWidget,
    );
    expect(find.text('自選比較組合檢查'), findsOneWidget);
    expect(find.textContaining('共同資料區間'), findsOneWidget);
    expect(find.textContaining('固定基準'), findsOneWidget);
    final initialComparisonSummary = tester.widget<Text>(
      find.byKey(
        const ValueKey('00631l-etf-comparison-compact-summary-text'),
      ),
    );
    expect(initialComparisonSummary.data, contains('0050'));
    expect(initialComparisonSummary.data, isNot(contains('00631L')));
    expect(
      find.byKey(const ValueKey('00631l-etf-comparison-selected-codes')),
      findsNothing,
    );
    await tester.ensureVisible(selectionPanel);
    await tester.pumpAndSettle();
    await tester.tap(selectionPanel);
    await tester.pumpAndSettle();
    expect(find.text('代表'), findsWidgets);
    expect(find.text('高股息'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('00631l-etf-compare-chip-0050')),
      findsOneWidget,
    );
    final currentPageSearchButton =
        find.byKey(const ValueKey('00631l-symbol-search-button'));
    await tester.ensureVisible(currentPageSearchButton);
    await tester.pumpAndSettle();
    await tester.tap(currentPageSearchButton);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('00631l-symbol-search-field')),
      '0050',
    );
    await tester.pumpAndSettle();
    expect(find.text('目前頁面'), findsOneWidget);
    await tester.tap(find.byTooltip('關閉'));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView).first, const Offset(0, -1720));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('00631l-etf-compare-chip-0050')),
    );
    await tester.pumpAndSettle();
    final clearComparison =
        find.byKey(const ValueKey('00631l-etf-comparison-clear'));
    await tester.ensureVisible(clearComparison);
    await tester.pumpAndSettle();
    await tester.tap(clearComparison);
    await tester.pumpAndSettle();
    final compare00631L =
        find.byKey(const ValueKey('00631l-etf-compare-chip-00631L'));
    await tester.ensureVisible(compare00631L);
    await tester.pumpAndSettle();
    await tester.tap(compare00631L);
    await tester.pumpAndSettle();
    final selectedSummaryAfterDeselect = tester.widget<Text>(
      find.byKey(
        const ValueKey('00631l-etf-comparison-compact-summary-text'),
      ),
    );
    expect(selectedSummaryAfterDeselect.data, contains('00631L'));
    expect(selectedSummaryAfterDeselect.data, isNot(contains('0050')));

    await tester.ensureVisible(
      find.byKey(const ValueKey('00631l-etf-comparison-filter-dividend')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('00631l-etf-comparison-filter-dividend')),
    );
    await tester.pumpAndSettle();
    final dividendSummary = tester.widget<Text>(
      find.byKey(
        const ValueKey('00631l-etf-comparison-compact-summary-text'),
      ),
    );
    expect(dividendSummary.data, anyOf(contains('0056'), contains('00878')));
    expect(find.byKey(const ValueKey('00631l-etf-comparison-return-chart')),
        findsOneWidget);

    _expectNoTradingActionText();
  });

  testWidgets('selected ETF history distinguishes close-mirrored adjustment',
      (tester) async {
    await _pumpLab(tester, _PriceHistoryRepository());

    await tester.tap(find.byKey(const ValueKey('00631l-symbol-search-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('00631l-symbol-search-field')),
      '0056',
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('00631l-symbol-search-result-0056')),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    await _tapSection(tester, 'historyBacktest');
    await tester.pumpAndSettle();
    final qualityExpansion =
        find.byKey(const ValueKey('00631l-history-quality-expansion'));
    await tester.ensureVisible(qualityExpansion);
    await tester.pumpAndSettle();
    await tester.tap(qualityExpansion);
    await tester.pumpAndSettle();

    expect(
      find.byKey(
        const ValueKey('00631l-history-adjustment-close-mirrored'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-history-adjustment-known-split')),
      findsNothing,
    );
    _expectNoTradingActionText();
  });

  testWidgets('ETF comparison chips update the selected basket',
      (tester) async {
    await _pumpLab(tester, _PriceHistoryRepository());

    await _tapSection(tester, 'historyBacktest');
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('00631l-etf-comparison-guidance')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('00631l-etf-comparison-action-strip')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('00631l-etf-comparison-mode-summary')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('00631l-etf-comparison-compact-summary')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-etf-comparison-chart-expansion')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-etf-comparison-return-chart')),
      findsNothing,
    );
    final initialCompactSummary = tester.widget<Text>(
      find.byKey(const ValueKey('00631l-etf-comparison-compact-summary-text')),
    );
    expect(initialCompactSummary.data, contains('不設基準'));
    expect(find.textContaining('預設只看目前 ETF'), findsWidgets);
    expect(find.textContaining('資料筆數足夠才會進入圖表'), findsNothing);
    expect(find.textContaining('basket'), findsNothing);
    final selectionPanel =
        find.byKey(const ValueKey('00631l-etf-comparison-selection-panel'));
    expect(selectionPanel, findsOneWidget);
    expect(
      find.byKey(const ValueKey('00631l-etf-compare-chip-0050')),
      findsNothing,
    );
    await tester.ensureVisible(selectionPanel);
    await tester.pumpAndSettle();
    await tester.tap(selectionPanel);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('00631l-etf-comparison-action-strip')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-etf-compare-chip-0050')),
      findsOneWidget,
    );

    Text selectedLabel() => tester.widget<Text>(
          find.byKey(
            const ValueKey('00631l-etf-comparison-compact-summary-text'),
          ),
        );

    expect(selectedLabel().data, contains('00631L'));
    expect(selectedLabel().data, isNot(contains('0050')));

    final clearButton =
        find.byKey(const ValueKey('00631l-etf-comparison-clear'));
    await tester.ensureVisible(clearButton);
    await tester.pumpAndSettle();
    await tester.tap(clearButton);
    await tester.pumpAndSettle();
    expect(selectedLabel().data, contains('尚未選擇比較 ETF'));
    expect(find.textContaining('尚未選擇'), findsWidgets);
    expect(find.textContaining('尚未選擇比較 ETF'), findsWidgets);

    final chip0050 = find.byKey(const ValueKey('00631l-etf-compare-chip-0050'));
    await tester.ensureVisible(chip0050);
    await tester.pumpAndSettle();
    await tester.tap(chip0050);
    await tester.pumpAndSettle();

    expect(selectedLabel().data, contains('0050'));
    expect(selectedLabel().data, isNot(contains('00631L')));
    final compactSummaryAfter0050 = tester.widget<Text>(
      find.byKey(const ValueKey('00631l-etf-comparison-compact-summary-text')),
    );
    expect(compactSummaryAfter0050.data, contains('0050'));
    expect(compactSummaryAfter0050.data, contains('不設基準'));
    expect(compactSummaryAfter0050.data, isNot(contains('00631L')));
    await tester.tap(chip0050);
    await tester.pumpAndSettle();
    expect(selectedLabel().data, isNot(contains('0050')));
    expect(selectedLabel().data, contains('尚未選擇比較 ETF'));
    _expectNoTradingActionText();
  });

  testWidgets('ETF comparison action strip uses compact labels on phone width',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await _pumpLab(tester, _PriceHistoryRepository());
    await _tapSection(tester, 'historyBacktest');
    await tester.pumpAndSettle();

    final mobileHeader =
        find.byKey(const ValueKey('00631l-etf-comparison-mobile-header'));
    await tester.ensureVisible(mobileHeader);
    await tester.pumpAndSettle();
    expect(mobileHeader, findsOneWidget);
    expect(tester.getRect(mobileHeader).height, lessThanOrEqualTo(54));

    final compactSummary =
        find.byKey(const ValueKey('00631l-etf-comparison-compact-summary'));
    await tester.ensureVisible(compactSummary);
    await tester.pumpAndSettle();
    expect(compactSummary, findsOneWidget);
    expect(tester.getRect(compactSummary).height, lessThanOrEqualTo(72));

    final selectionPanel =
        find.byKey(const ValueKey('00631l-etf-comparison-selection-panel'));
    await tester.ensureVisible(selectionPanel);
    await tester.pumpAndSettle();
    await tester.tap(selectionPanel);
    await tester.pumpAndSettle();

    final actionStrip =
        find.byKey(const ValueKey('00631l-etf-comparison-action-strip'));
    expect(actionStrip, findsOneWidget);
    final chipScroll =
        find.byKey(const ValueKey('00631l-etf-comparison-chip-scroll'));
    expect(chipScroll, findsOneWidget);
    expect(tester.getRect(chipScroll).height, lessThanOrEqualTo(38));
    expect(tester.getRect(actionStrip).height, lessThanOrEqualTo(36));
    expect(
      find.descendant(of: actionStrip, matching: find.text('清空')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: actionStrip, matching: find.text('同類型')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: actionStrip, matching: find.text('目前')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: actionStrip, matching: find.text('清空組合')),
      findsNothing,
    );
    expect(
      find.descendant(of: actionStrip, matching: find.text('套用同類型')),
      findsNothing,
    );
    expect(
      find.descendant(of: actionStrip, matching: find.text('只看目前 ETF')),
      findsNothing,
    );

    final chartExpansion =
        find.byKey(const ValueKey('00631l-etf-comparison-chart-expansion'));
    await tester.ensureVisible(chartExpansion);
    await tester.pumpAndSettle();
    await tester.tap(chartExpansion);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('00631l-etf-comparison-return-chart')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-etf-comparison-legend-strip')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-comparison-touch-empty')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-etf-comparison-table-expansion')),
      findsOneWidget,
    );
    expect(find.text('history comparison'), findsNothing);
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
    expect(
      find.byKey(const ValueKey('00631l-selected-etf-readiness-banner')),
      findsNothing,
    );
    expect(find.textContaining('0050 元大台灣50'), findsWidgets);
    expect(find.text('0050 核心資料'), findsNothing);
    expect(
      find.byKey(const ValueKey('00631l-selected-etf-overview-digest')),
      findsOneWidget,
    );
    expect(find.text('0050 資料完整度'), findsOneWidget);
    expect(find.text('官方內容物'), findsNothing);
    expect(
      find.byKey(const ValueKey('00631l-quote-readiness-strip')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('00631l-selected-etf-coverage-line')),
      findsNothing,
    );
    await _expandOverviewMore(tester);
    expect(find.textContaining('3筆'), findsWidgets);
    expect(
      find.byKey(const ValueKey('00631l-quote-readiness-strip')),
      findsOneWidget,
    );
    for (final label in const ['價格', '歷史', '回測', '盤中 NAV']) {
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('00631l-quote-readiness-strip')),
          matching: find.text(label),
        ),
        findsOneWidget,
      );
    }
    expect(find.text('資料正確性'), findsNothing);
    expect(find.text('目前檔案'), findsNothing);
    expect(find.text('0050'), findsWidgets);
    expect(find.textContaining('2025/06/03 - 2026/06/03'), findsWidgets);
    expect(find.textContaining('行情 · 清單'), findsWidgets);
    expect(find.text('官方內容物重點'), findsNothing);
    expect(
      find.byKey(const ValueKey('00631l-selected-etf-history-readiness-strip')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('00631l-selected-etf-data-context-card')),
      findsNothing,
    );
    final overviewCoverageLine = tester.widget<Text>(
      find.byKey(const ValueKey('00631l-selected-etf-coverage-line')),
    );
    expect(overviewCoverageLine.data, contains('價格欄位'));
    expect(overviewCoverageLine.data, contains('分割調整'));
    expect(
      find.byKey(const ValueKey('00631l-quote-meta-strip')),
      findsNothing,
    );
    expect(find.text('回測可用'), findsWidgets);
    expect(find.text('盤中 NAV 限 00631L'), findsOneWidget);

    await _tapSection(tester, 'position');
    await tester.pumpAndSettle();
    expect(find.textContaining('0050'), findsWidgets);
    expect(find.textContaining('本機保存'), findsWidgets);
    expect(find.text('0050 持倉'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('00631l-position-input-mini-header')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-position-source-expansion')),
      findsOneWidget,
    );
    expect(find.textContaining('歷史來源 快取'), findsNothing);
    await tester.tap(
      find.byKey(const ValueKey('00631l-position-source-expansion')),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('行情來源'), findsWidgets);
    expect(find.textContaining('歷史來源 快取'), findsWidgets);

    await _tapSection(tester, 'ai');
    await tester.pumpAndSettle();
    expect(find.text('0050 AI 快覽'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('00631l-selected-etf-data-context-card')),
      findsOneWidget,
    );
    expect(find.textContaining('元大台灣50'), findsWidgets);
    expect(find.text('最新交易日'), findsOneWidget);
    expect(find.text('日變動'), findsOneWidget);
    expect(find.text('回撤'), findsOneWidget);
    expect(find.textContaining('價格欄位 adjustedClose'), findsWidgets);
    expect(find.textContaining('歷史 快取'), findsWidgets);
    expect(find.textContaining('筆數 3'), findsWidgets);
    expect(find.textContaining('此檔尚未建立盤中 NAV 對應'), findsWidgets);
    expect(find.textContaining('分割調整 調整價可用'), findsWidgets);
    expect(find.textContaining('近一年區間'), findsWidgets);
    expect(find.textContaining('目前位置'), findsWidgets);
    expect(find.textContaining('最新收盤較前一筆'), findsWidgets);
    expect(find.textContaining('不是盤中即時價格'), findsWidgets);
    expect(find.textContaining('回測不代表未來表現'), findsWidgets);
    expect(find.text('程式操作'), findsOneWidget);
    expect(
      find.textContaining('scripts\\00631l_import_etf_price_history.cmd'),
      findsWidgets,
    );
    expect(find.textContaining('2026/06/03'), findsWidgets);
    _expectNoTradingActionText();
  });

  testWidgets('selected ETF quote labels historical close fallback',
      (tester) async {
    await _pumpLab(tester, _CatalogWithoutQuoteRepository());

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
    expect(find.textContaining('行情 · 歷史收盤'), findsWidgets);
    expect(find.textContaining('行情 · catalog'), findsNothing);
    _expectNoTradingActionText();
  });

  testWidgets('overview includes official holdings context on phone',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await _pumpLab(tester, Mock00631LRepository());

    expect(find.byKey(const ValueKey('00631l-section-holdings')), findsNothing);
    expect(
      find.byKey(const ValueKey('00631l-overview-update-clock-strip')),
      findsNothing,
    );
    expect(
      find.byKey(
        const ValueKey('00631l-overview-holdings-digest-unavailable'),
      ),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('00631l-overview-holdings-digest-strip')),
      findsOneWidget,
    );
    final holdingsDigest = find.byKey(
      const ValueKey('00631l-overview-holdings-digest-strip'),
    );
    final holdingsDigestRect = tester.getRect(holdingsDigest);
    expect(holdingsDigestRect.height, lessThanOrEqualTo(24));
    for (final label in const ['TX', '2330', 'CASH']) {
      expect(
        find.descendant(of: holdingsDigest, matching: find.text(label)),
        findsWidgets,
      );
    }
    expect(
      find.byKey(const ValueKey('00631l-holding-digest-metric-row')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('00631l-overview-holdings-digest-title-row')),
      findsNothing,
    );

    final compactRibbon = find.byKey(
      const ValueKey('00631l-overview-compact-data-ribbon'),
    );
    expect(compactRibbon, findsOneWidget);
    final ribbonRect = tester.getRect(compactRibbon);
    expect(ribbonRect.height, lessThanOrEqualTo(28));
    for (final label in const ['日', '盤', '歷']) {
      final labelFinder = find.descendant(
        of: compactRibbon,
        matching: find.text(label),
      );
      expect(labelFinder, findsWidgets);
      expect(
        tester.getRect(labelFinder.first).right,
        lessThanOrEqualTo(ribbonRect.right),
      );
    }
    for (final label in const ['TX', '2330']) {
      expect(
        find.descendant(of: compactRibbon, matching: find.text(label)),
        findsNothing,
      );
    }

    expect(find.byType(DataTable), findsNothing);
    expect(
      find.byKey(const ValueKey('00631l-overview-more-expansion')),
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

  testWidgets('overview shows compact unavailable holdings context on phone',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await _pumpLab(tester, _NoUsableHoldingsRepository());

    expect(
      find.byKey(const ValueKey('00631l-overview-holdings-digest-strip')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-overview-first-glance-strip')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('00631l-overview-holdings-digest-unavailable'),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byKey(
          const ValueKey('00631l-overview-holdings-digest-strip'),
        ),
        matching: find.text('錯誤'),
      ),
      findsWidgets,
    );
    final compactRibbon = find.byKey(
      const ValueKey('00631l-overview-compact-data-ribbon'),
    );
    expect(compactRibbon, findsOneWidget);
    for (final label in const ['日', '盤', '歷']) {
      expect(
        find.descendant(of: compactRibbon, matching: find.text(label)),
        findsWidgets,
      );
    }
    for (final label in const ['TX', '2330']) {
      expect(
        find.descendant(of: compactRibbon, matching: find.text(label)),
        findsNothing,
      );
    }
    expect(find.text('2026/06/28'), findsNothing);
    expect(
      find.byKey(const ValueKey('00631l-overview-exposure-summary-strip')),
      findsNothing,
    );
    _expectNoTradingActionText();
  });

  testWidgets('AI and settings sections render clean status wording',
      (tester) async {
    await _pumpLab(tester, Mock00631LRepository());

    await _tapSection(tester, 'ai');
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('00631l-ai-daily-briefing-hero')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-ai-daily-detail-expansion')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-ai-first-screen-headline')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-ai-first-screen-facts')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-ai-first-screen-bullets')),
      findsOneWidget,
    );
    expect(
      tester
          .getTopLeft(
            find.byKey(const ValueKey('00631l-ai-first-screen-headline')),
          )
          .dy,
      lessThan(
        tester
            .getTopLeft(
              find.byKey(
                const ValueKey('00631l-ai-daily-briefing-disclaimer'),
              ),
            )
            .dy,
      ),
      reason: 'AI should lead with today interpretation before source details.',
    );
    expect(find.text('今日解讀'), findsWidgets);
    for (final label in const ['日', '盤', '曝險']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.descendant(
      of: find.byKey(const ValueKey('00631l-ai-first-screen-facts')),
      matching: find.text('DAY'),
    ), findsNothing);
    expect(find.descendant(
      of: find.byKey(const ValueKey('00631l-ai-first-screen-facts')),
      matching: find.text('LIVE'),
    ), findsNothing);
    expect(find.text('今日結論'), findsNothing);
    expect(find.text('HIS'), findsNothing);
    expect(find.text('今日重點'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('00631l-ai-daily-conclusion')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-ai-daily-decision-strip')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-ai-daily-briefing-bullets')),
      findsNothing,
    );
    expect(find.text('當日資料判讀'), findsOneWidget);
    expect(find.textContaining('資料時間：'), findsOneWidget);
    expect(find.textContaining('折溢價：'), findsOneWidget);
    final aiDecisionStrip =
        find.byKey(const ValueKey('00631l-ai-daily-decision-strip'));
    for (final label in const ['今日資料', '偏離判讀', '歷史資料', '後續操作']) {
      expect(
        find.descendant(of: aiDecisionStrip, matching: find.text(label)),
        findsOneWidget,
      );
    }
    final detailExpansion =
        find.byKey(const ValueKey('00631l-ai-daily-detail-expansion'));
    expect(
      tester.getTopLeft(aiDecisionStrip).dy,
      lessThan(tester.getTopLeft(detailExpansion).dy),
      reason: 'Daily AI analysis should be visible before detail expansion.',
    );
    await tester.scrollUntilVisible(
      detailExpansion,
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(detailExpansion);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -140));
    await tester.pumpAndSettle();
    await tester.tap(find.text('AI 資料細節'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('00631l-ai-daily-briefing-bullets')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-ai-today-readout')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-ai-daily-conclusion')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-ai-daily-decision-strip')),
      findsOneWidget,
    );
    final primaryActionBlock =
        find.byKey(const ValueKey('00631l-ai-primary-action-block'));
    expect(primaryActionBlock, findsOneWidget);
    expect(
      tester.getTopLeft(primaryActionBlock).dy,
      lessThan(tester.getTopLeft(detailExpansion).dy),
      reason: 'The primary program action should appear before AI details.',
    );
    expect(find.textContaining('非投資建議'), findsWidgets);
    expect(find.text('當日資料'), findsOneWidget);
    expect(find.text('價格偏離'), findsOneWidget);
    expect(find.text('結構觀察'), findsOneWidget);
    expect(find.text('今日 AI 分析摘要'), findsNothing);
    expect(find.text('重點摘要'), findsNothing);
    expect(find.text('進階 AI 明細'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('00631l-ai-today-snapshot')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('00631l-ai-daily-interpretation-card')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('00631l-ai-interpretation-matrix')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('00631l-ai-daily-brief')),
      findsNothing,
    );
    await tester.scrollUntilVisible(
      find.text('進階 AI 明細'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('進階 AI 明細'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('00631l-ai-daily-brief')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-ai-intraday-brief')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-ai-risk-brief')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-ai-interpretation-matrix')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-ai-today-snapshot')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('00631l-ai-daily-interpretation-card')),
      findsOneWidget,
    );
    expect(find.text('資料完整性'), findsOneWidget);
    expect(find.text('非買賣建議'), findsWidgets);

    expect(find.textContaining('規則分析'), findsWidgets);
    expect(find.textContaining('非買賣建議'), findsWidgets);
    expect(find.textContaining('static public mode'), findsNothing);
    expect(find.textContaining('GitHub Pages 靜態 JSON'), findsNothing);
    expect(find.textContaining('public backend proxy'), findsNothing);
    expect(find.textContaining('live intraday NAV'), findsNothing);
    expect(find.textContaining('price history'), findsNothing);
    expect(find.textContaining('official holdings'), findsNothing);
    expect(find.textContaining('rows'), findsNothing);
    expect(find.textContaining('cached'), findsNothing);
    expect(find.textContaining('static_official'), findsNothing);

    await _tapSection(tester, 'settings');
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('00631l-etf-room-readiness-panel')),
      findsNothing,
    );
    expect(find.text('帳戶'), findsWidgets);
    expect(find.text('我的總覽'), findsNothing);
    expect(find.text('帳戶與偏好'), findsOneWidget);
    expect(find.text('免登入'), findsOneWidget);
    expect(find.text('ETF 資料與比較能力'), findsNothing);
    expect(find.text('ETF 研究室完成度'), findsNothing);
    expect(find.text('公開 PWA'), findsNothing);
    expect(find.text('ETF 清單'), findsNothing);
    expect(find.text('ETF 比較'), findsNothing);
    expect(find.text('ETF 資料預覽'), findsNothing);
    expect(find.text('元大台灣50正2'), findsNothing);
    expect(find.text('App 上架準備'), findsNothing);
    expect(
      find.byKey(const ValueKey('00631l-settings-app-store-panel')),
      findsNothing,
    );
    expect(find.text('資料模式與完整度'), findsNothing);
    expect(find.text('進階維護診斷'), findsNothing);
    expect(find.text('進階設定'), findsOneWidget);
    expect(find.text('Android'), findsNothing);
    expect(find.text('iOS'), findsNothing);
    expect(find.text('隱私與支援'), findsNothing);
    expect(find.text('內容物歷史'), findsNothing);
    expect(find.text('盤中 NAV / 折溢價'), findsNothing);
    expect(find.text('台指期即時'), findsNothing);

    await tester.scrollUntilVisible(
      find.text('進階設定'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('進階設定'));
    await tester.pumpAndSettle();
    expect(find.text('ETF 資料與比較能力'), findsOneWidget);
    expect(find.text('資料模式與完整度'), findsOneWidget);
    expect(find.text('進階維護診斷'), findsOneWidget);
    expect(find.text('App 上架準備'), findsOneWidget);

    await tester.ensureVisible(find.text('ETF 資料與比較能力'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ETF 資料與比較能力'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('00631l-etf-room-readiness-panel')),
      findsOneWidget,
    );
    expect(find.text('ETF 研究室完成度'), findsOneWidget);
    expect(find.text('公開 PWA'), findsOneWidget);
    expect(find.text('ETF 清單'), findsWidgets);
    expect(find.text('ETF 比較'), findsOneWidget);

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
    expect(find.text('台指期即時'), findsOneWidget);
    expect(find.text('ETF 價格歷史'), findsWidgets);
    expect(find.textContaining('資料期間分類'), findsWidgets);
    _expectNoTradingActionText();
  });

  testWidgets('settings first screen keeps technical diagnostics advanced',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await _pumpLab(tester, Mock00631LRepository());

    await _tapSection(tester, 'settings');
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('00631l-settings-quick-summary-compact')),
      findsOneWidget,
    );
    expect(
      tester
          .getRect(
            find.byKey(const ValueKey('00631l-settings-quick-summary-compact')),
          )
          .height,
      lessThanOrEqualTo(112),
      reason: 'Settings should open with a compact account-style summary.',
    );
    final preferenceGrid =
        find.byKey(const ValueKey('00631l-settings-preference-grid'));
    final preferenceStrip =
        find.byKey(const ValueKey('00631l-settings-preference-strip'));
    final accountCard =
        find.byKey(const ValueKey('00631l-settings-preference-account'));
    final appearanceCard =
        find.byKey(const ValueKey('00631l-settings-preference-appearance'));
    final selectedEtfCard =
        find.byKey(const ValueKey('00631l-settings-preference-selected-etf'));
    final positionCard =
        find.byKey(const ValueKey('00631l-settings-preference-position'));
    expect(preferenceGrid, findsOneWidget);
    expect(preferenceStrip, findsOneWidget);
    expect(tester.getRect(preferenceGrid).height, lessThanOrEqualTo(58));
    expect(find.text('示範模式'), findsOneWidget);
    expect(find.text('示範資料'), findsOneWidget);
    expect(find.text('mock_default'), findsNothing);
    expect(find.text('static_public'), findsNothing);
    expect(find.text('帳戶與偏好'), findsNothing);
    expect(find.textContaining('一般使用者只需要看這裡'), findsNothing);
    expect(find.textContaining('目前不需要帳號或券商登入'), findsNothing);
    expect(find.textContaining('右上角可切換夜間模式'), findsNothing);
    expect(accountCard, findsOneWidget);
    expect(appearanceCard, findsOneWidget);
    expect(selectedEtfCard, findsOneWidget);
    expect(positionCard, findsOneWidget);
    expect(
      (tester.getTopLeft(accountCard).dy - tester.getTopLeft(appearanceCard).dy)
          .abs(),
      lessThan(2),
      reason:
          'Settings preference cards should use one compact horizontal row.',
    );
    expect(
      tester.getTopLeft(accountCard).dx,
      lessThan(tester.getTopLeft(appearanceCard).dx),
    );
    expect(
      (tester.getTopLeft(accountCard).dy - tester.getTopLeft(positionCard).dy)
          .abs(),
      lessThan(2),
    );
    expect(
      find.byKey(const ValueKey('00631l-etf-room-readiness-panel')),
      findsNothing,
    );
    expect(find.textContaining('目前 00631L'), findsWidgets);
    expect(find.text('進階檢查'), findsWidgets);
    expect(find.text('進階設定'), findsOneWidget);
    expect(find.text('資料模式與完整度'), findsNothing);
    expect(find.text('進階維護診斷'), findsNothing);
    expect(find.text('ETF 資料與比較能力'), findsNothing);
    expect(find.text('App 上架準備'), findsNothing);
    expect(find.text('需要處理'), findsNothing);
    expect(find.text('data path not writable'), findsNothing);
    _expectNoTradingActionText();
  });

  testWidgets('settings data mode softens backend errors on first screen',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await _pumpLab(tester, _SettingsBackendErrorRepository());

    await _tapSection(tester, 'settings');
    await tester.pumpAndSettle();

    expect(find.text('使用靜態備援'), findsWidgets);
    expect(find.text('靜態資料可用；連線細節在進階'), findsNothing);
    expect(find.text('後端錯誤'), findsNothing);
    expect(find.text('data path not writable'), findsNothing);
    _expectNoTradingActionText();
  });

  testWidgets('settings first screen shows public deploy version drift',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await _pumpLab(tester, _DeploymentDriftRepository());

    await _tapSection(tester, 'settings');
    await tester.pumpAndSettle();

    expect(find.text('version drift'), findsNothing);
    await tester.ensureVisible(find.text('進階設定'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('進階設定'));
    await tester.pumpAndSettle();
    final advancedPanel = find
        .byKey(const ValueKey('00631l-settings-advanced-maintenance-panel'));
    await tester.ensureVisible(advancedPanel);
    await tester.pumpAndSettle();
    await tester.tap(find.text('進階維護診斷'));
    await tester.pumpAndSettle();
    expect(find.text('version drift'), findsWidgets);
    _expectNoTradingActionText();
  });

  testWidgets('AI phone first screen keeps long details collapsed',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await _pumpLab(tester, Mock00631LRepository());

    await _tapSection(tester, 'ai');
    await tester.pumpAndSettle();

    final headline =
        find.byKey(const ValueKey('00631l-ai-first-screen-headline'));
    final primaryAction =
        find.byKey(const ValueKey('00631l-ai-primary-action-block'));
    final detailExpansion =
        find.byKey(const ValueKey('00631l-ai-daily-detail-expansion'));
    final fullDetailExpansion =
        find.byKey(const ValueKey('00631l-ai-full-detail-expansion'));
    final decisionStrip =
        find.byKey(const ValueKey('00631l-ai-daily-decision-strip'));
    final compactDecisionRail =
        find.byKey(const ValueKey('00631l-ai-compact-decision-rail'));
    final compactInsight =
        find.byKey(const ValueKey('00631l-ai-compact-daily-insight'));
    final compactMeta =
        find.byKey(const ValueKey('00631l-ai-compact-meta-line'));
    final compactInsightText =
        find.byKey(const ValueKey('00631l-ai-compact-daily-insight-text'));
    final compactInsightDailyText = find.descendant(
      of: compactInsight,
      matching: find.textContaining('今日資料'),
    );
    final hero = find.byKey(const ValueKey('00631l-ai-daily-briefing-hero'));

    expect(hero, findsOneWidget);
    expect(tester.getRect(hero).height, lessThanOrEqualTo(320));
    expect(headline, findsOneWidget);
    expect(primaryAction, findsOneWidget);
    expect(compactMeta, findsOneWidget);
    expect(tester.getRect(compactMeta).height, lessThanOrEqualTo(24));
    expect(
      find.descendant(
        of: compactMeta,
        matching: find.textContaining('非買賣建議'),
      ),
      findsOneWidget,
    );
    expect(detailExpansion, findsNothing);
    expect(fullDetailExpansion, findsOneWidget);
    expect(find.text('完整摘要與資料來源。'), findsOneWidget);
    expect(decisionStrip, findsNothing);
    expect(compactDecisionRail, findsOneWidget);
    for (final label in const ['資料', '偏離', '操作']) {
      expect(
        find.descendant(of: compactDecisionRail, matching: find.text(label)),
        findsOneWidget,
      );
    }
    expect(compactInsight, findsOneWidget);
    expect(compactInsightText, findsOneWidget);
    expect(compactInsightDailyText, findsOneWidget);
    expect(
      find.descendant(
        of: compactInsight,
        matching: find.textContaining('目前使用'),
      ),
      findsOneWidget,
    );
    expect(
      tester.getRect(compactInsight).height,
      lessThanOrEqualTo(72),
      reason: 'Phone AI insight should stay compact while allowing two lines.',
    );
    expect(
      find.byKey(const ValueKey('00631l-ai-compact-daily-insight-title')),
      findsOneWidget,
    );
    expect(find.text('今日解讀'), findsWidgets);
    expect(find.text('今日結論'), findsNothing);
    expect(find.textContaining('歷史'), findsWidgets);
    expect(
      find.byKey(const ValueKey('00631l-ai-first-screen-bullets')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('00631l-ai-daily-conclusion')),
      findsNothing,
    );
    expect(
      tester.getTopLeft(primaryAction).dy,
      lessThan(tester.getTopLeft(compactInsight).dy),
      reason: 'Compact AI should show the main program action before insight.',
    );
    expect(
      tester.getTopLeft(compactInsight).dy,
      lessThan(tester.getTopLeft(fullDetailExpansion).dy),
      reason: 'Compact AI should show daily insight before full details.',
    );
    expect(
      tester.getTopLeft(compactDecisionRail).dy,
      lessThan(tester.getTopLeft(fullDetailExpansion).dy),
      reason: 'Compact AI should show daily decision items before details.',
    );
    final firstScreenFacts =
        find.byKey(const ValueKey('00631l-ai-first-screen-facts'));
    expect(firstScreenFacts, findsOneWidget);
    expect(
      tester.getRect(firstScreenFacts).height,
      lessThanOrEqualTo(64),
      reason: 'Phone AI facts should stay in a compact single row.',
    );
    final dayLabel = find.descendant(
      of: firstScreenFacts,
      matching: find.text('日'),
    );
    final liveLabel = find.descendant(
      of: firstScreenFacts,
      matching: find.text('盤'),
    );
    final holdLabel = find.descendant(
      of: firstScreenFacts,
      matching: find.text('曝險'),
    );
    expect(dayLabel, findsOneWidget);
    expect(liveLabel, findsOneWidget);
    expect(holdLabel, findsOneWidget);
    expect(
      (tester.getTopLeft(dayLabel).dy - tester.getTopLeft(liveLabel).dy).abs(),
      lessThan(2),
    );
    expect(
      (tester.getTopLeft(dayLabel).dy - tester.getTopLeft(holdLabel).dy).abs(),
      lessThan(2),
    );
    _expectNoTradingActionText();
  });

  testWidgets('AI full detail panel remains available on phone width',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await _pumpLab(tester, Mock00631LRepository());

    await _tapSection(tester, 'ai');
    await tester.pumpAndSettle();

    final detailExpansion =
        find.byKey(const ValueKey('00631l-ai-full-detail-expansion'));
    await tester.scrollUntilVisible(
      detailExpansion,
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(detailExpansion);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -140));
    await tester.pumpAndSettle();
    await tester.tap(detailExpansion);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('00631l-ai-daily-brief')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('00631l-ai-intraday-brief')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('00631l-ai-risk-brief')), findsOneWidget);
    _expectNoTradingActionText();
  });

  testWidgets('settings shows ETF data library readiness', (tester) async {
    await _pumpLab(tester, _EtfReadinessOperationsRepository());

    await _tapSection(tester, 'settings');
    await tester.pumpAndSettle();

    expect(find.text('ETF 資料庫狀態'), findsNothing);
    await tester.ensureVisible(find.text('進階設定'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('進階設定'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('ETF 資料與比較能力'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ETF 資料與比較能力'));
    await tester.pumpAndSettle();

    expect(find.text('ETF 資料庫狀態'), findsOneWidget);
    expect(find.text('清單檔數'), findsOneWidget);
    expect(find.text('歷史可用'), findsOneWidget);
    expect(find.text('228 / 228'), findsOneWidget);
    expect(find.text('長期'), findsOneWidget);
    expect(find.text('8'), findsWidgets);
    expect(find.text('近期'), findsOneWidget);
    expect(find.text('220'), findsWidgets);
    expect(find.text('完成度'), findsOneWidget);
    expect(find.textContaining('缺口代表尚未有足夠資料'), findsOneWidget);
    expect(find.text('歷史可用比例'), findsOneWidget);
    expect(find.text('尚未可用'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('00631l-settings-quick-summary-compact')),
      findsOneWidget,
    );
    expect(find.text('資料補齊動作'), findsOneWidget);
    expect(find.text('資料缺口原因'), findsOneWidget);
    expect(find.textContaining('缺口明細 0'), findsOneWidget);
    expect(find.textContaining('保留歷史 0'), findsOneWidget);
    expect(
      find.textContaining(
        'scripts\\00631l_import_etf_price_history.cmd --status-only',
      ),
      findsOneWidget,
    );
    _expectNoTradingActionText();
  });

  testWidgets('settings summarizes classified ETF data gaps', (tester) async {
    await _pumpLab(tester, _EtfClassifiedGapOperationsRepository());

    await _tapSection(tester, 'settings');
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('進階設定'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('進階設定'));
    await tester.pumpAndSettle();
    final dataLibraryPanel =
        find.byKey(const ValueKey('00631l-etf-data-library-panel'));
    await tester.ensureVisible(dataLibraryPanel);
    await tester.pumpAndSettle();
    await tester.tap(dataLibraryPanel);
    await tester.pumpAndSettle();

    final readableSummary =
        find.byKey(const ValueKey('00631l-etf-library-readable-summary'));
    expect(readableSummary, findsOneWidget);
    final completionStrip =
        find.byKey(const ValueKey('00631l-etf-library-completion-strip'));
    expect(completionStrip, findsOneWidget);
    expect(
      find.descendant(of: completionStrip, matching: find.text('可用')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: completionStrip, matching: find.text('231/347')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: completionStrip, matching: find.text('官方空資料')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: completionStrip, matching: find.text('116')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: completionStrip, matching: find.text('來源待處理')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: completionStrip, matching: find.text('0')),
      findsWidgets,
    );
    expect(
      find.byKey(const ValueKey('00631l-etf-library-completion-status-text')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: readableSummary,
        matching: find.text('ETF 資料庫摘要'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: readableSummary, matching: find.text('缺口已分類')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: readableSummary,
        matching: find.textContaining('231 / 347'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: readableSummary,
        matching: find.textContaining('官方空資料 116'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: readableSummary,
        matching: find.textContaining('來源錯誤 0'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: readableSummary,
        matching: find.textContaining('未分類 0'),
      ),
      findsOneWidget,
    );
    _expectNoTradingActionText();
  });

  testWidgets('settings shows ETF price history gap detail rows',
      (tester) async {
    await _pumpLab(tester, _EtfGapDetailsRepository());

    await _tapSection(tester, 'settings');
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('進階設定'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('進階設定'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('ETF 資料與比較能力'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ETF 資料與比較能力'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('00631l-etf-gap-detail-panel')),
      findsOneWidget,
    );
    expect(find.text('ETF 缺口明細'), findsOneWidget);
    expect(find.text('00999'), findsOneWidget);
    expect(find.text('00749B'), findsOneWidget);
    expect(find.text('官方無資料'), findsWidgets);
    expect(find.text('來源錯誤'), findsWidgets);
    expect(find.text('official_empty'), findsNothing);
    expect(find.text('source_error'), findsNothing);
    expect(find.textContaining('source timeout'), findsOneWidget);
    expect(find.textContaining('缺口明細只用來檢查資料狀態'), findsOneWidget);
    _expectNoTradingActionText();
  });

  testWidgets('settings filters ETF price history gap details by reason',
      (tester) async {
    await _pumpLab(tester, _EtfGapDetailsRepository());

    await _tapSection(tester, 'settings');
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('進階設定'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('進階設定'));
    await tester.pumpAndSettle();
    final dataLibraryPanel =
        find.byKey(const ValueKey('00631l-etf-data-library-panel'));
    await tester.ensureVisible(dataLibraryPanel);
    await tester.pumpAndSettle();
    await tester.tap(dataLibraryPanel);
    await tester.pumpAndSettle();

    expect(find.text('00999'), findsOneWidget);
    expect(find.text('00749B'), findsOneWidget);

    final sourceErrorFilter =
        find.byKey(const ValueKey('00631l-etf-gap-filter-source_error'));
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -2200));
    await tester.pumpAndSettle();
    await tester.tap(sourceErrorFilter);
    await tester.pumpAndSettle();

    expect(find.text('00999'), findsNothing);
    expect(find.text('00749B'), findsOneWidget);
    expect(find.text('篩選 1 / 2'), findsOneWidget);
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
    expect(find.text('帳戶'), findsWidgets);
    expect(find.text('進階設定'), findsOneWidget);
    expect(find.text('進階維護診斷'), findsNothing);
    expect(find.textContaining('示範'), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('day and night mode toggle changes the market palette',
      (tester) async {
    await _pumpLab(tester, Mock00631LRepository());

    final initialBox =
        tester.widget<DecoratedBox>(find.byType(DecoratedBox).first);
    final initialColor = (initialBox.decoration as BoxDecoration).color;
    expect(find.text('切換夜間'), findsOneWidget);
    expect(find.text('日間模式'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('00631l-theme-toggle')));
    await tester.pumpAndSettle();

    final changedBox =
        tester.widget<DecoratedBox>(find.byType(DecoratedBox).first);
    final changedColor = (changedBox.decoration as BoxDecoration).color;
    expect(changedColor, isNot(initialColor));
    expect(find.text('切換日間'), findsOneWidget);
    expect(find.text('夜間模式'), findsNothing);
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

Future<void> _expandOverviewMore(WidgetTester tester) async {
  final finder = find.byKey(const ValueKey('00631l-overview-more-expansion'));
  await tester.ensureVisible(finder);
  await tester.pump(const Duration(milliseconds: 250));
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 300));
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
        adjustedClose: profile.$2,
        adjustmentFactor: 1.0,
        volume: 1000000,
      ),
      EtfPriceHistoryPoint(
        date: DateTime(2026, 6, 1),
        open: profile.$2 * 1.08,
        high: profile.$2 * 1.1,
        low: profile.$2 * 1.07,
        close: profile.$2 * 1.09,
        adjustedClose: profile.$2 * 1.09,
        adjustmentFactor: 1.0,
        volume: 1100000,
      ),
      EtfPriceHistoryPoint(
        date: DateTime(2026, 6, 3),
        open: profile.$2 * 1.1,
        high: profile.$2 * 1.12,
        low: profile.$2 * 1.08,
        close: profile.$2 * 1.11,
        adjustedClose: profile.$2 * 1.11,
        adjustmentFactor: 1.0,
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

class _DeferredCatalogSearchRepository extends _PriceHistoryRepository {
  int catalogRequestCount = 0;

  @override
  Future<Etf00631LLabData> fetchFastLabData() async {
    return _withoutCatalog(await Mock00631LRepository().fetchLabData());
  }

  @override
  Future<Etf00631LLabData> fetchLabData() async {
    return _withoutCatalog(await Mock00631LRepository().fetchLabData());
  }

  @override
  Future<EtfCatalog> fetchEtfCatalog() async {
    catalogRequestCount += 1;
    return Mock00631LRepository().fetchEtfCatalog();
  }

  Etf00631LLabData _withoutCatalog(Etf00631LLabData data) {
    return Etf00631LLabData(
      profile: data.profile,
      snapshot: data.snapshot,
      intradayNav: data.intradayNav,
      futuresQuote: data.futuresQuote,
      holdingsHistory: data.holdingsHistory,
      intradayNavHistory: data.intradayNavHistory,
      priceHistory: data.priceHistory,
      operationsStatus: _operationsStatusWithEtfHistory(
        readyCount: 3,
        rowCount: 3,
        catalogRowCount: 3,
        historyRowCount: 3,
        tierCounts: const {
          'long_term': 1,
          'recent': 2,
          'unavailable': 0,
          'error': 0,
        },
      ),
      analysis: data.analysis,
      aiAnalysis: data.aiAnalysis,
      etfCatalog: EtfCatalog.empty(
        status: EtfDataStatus.cached,
        sourceStatusLabel: 'deferred',
        sourceContract: 'twse_all_etf_catalog_deferred_test',
      ),
      lastFetchedAt: data.lastFetchedAt,
    );
  }
}

class _SlowCatalogSearchRepository extends _DeferredCatalogSearchRepository {
  final Completer<EtfCatalog> _catalogCompleter = Completer<EtfCatalog>();

  @override
  Future<EtfCatalog> fetchEtfCatalog() {
    catalogRequestCount += 1;
    return _catalogCompleter.future;
  }

  Future<void> completeCatalog() async {
    if (_catalogCompleter.isCompleted) {
      return;
    }
    _catalogCompleter.complete(await Mock00631LRepository().fetchEtfCatalog());
  }
}

class _ErrorCatalogSearchRepository extends _DeferredCatalogSearchRepository {
  @override
  Future<EtfCatalog> fetchEtfCatalog() {
    catalogRequestCount += 1;
    return Future<EtfCatalog>.error(StateError('catalog unavailable'));
  }
}

class _StaticHistoryOnlyRepository extends _PriceHistoryRepository {
  @override
  Future<EtfIntradayNav?> fetchIntradayNav() async {
    return null;
  }
}

class _OfficialIntradayRepository extends _PriceHistoryRepository {
  @override
  Future<EtfIntradayNav?> fetchIntradayNav() async {
    return EtfIntradayNav(
      symbol: '00631L',
      name: '元大台灣50正2',
      outstandingUnits: 120000000,
      outstandingUnitsDelta: 0,
      marketPrice: 39.0,
      estimatedNav: 38.98,
      estimatedPremiumDiscountPct: 0.08,
      previousBusinessDayNav: 38.6,
      previousBusinessDayNavText: '38.60',
      dataDate: DateTime(2026, 7, 3),
      dataTime: DateTime(2026, 7, 3, 12, 54),
      targetType: 'ETF',
      userDelayMs: 15000,
      sourceContract: 'twse_a_k_json',
      isStale: false,
      status: EtfDataStatus.official,
      lastFetchedAt: DateTime(2026, 7, 3, 12, 54, 8),
    );
  }
}

class _NoTxQuoteRepository extends _PriceHistoryRepository {
  @override
  Future<FuturesQuote> fetchFuturesQuote() async {
    final now = DateTime(2026, 6, 11, 10);
    return FuturesQuote(
      symbol: 'TX',
      contractMonth: '',
      txPrice: null,
      weightedIndex: null,
      nightSessionChange: null,
      status: EtfDataStatus.error,
      lastFetchedAt: now,
      sourceContract: 'test_no_tx_quote',
      sourceUrl: 'local://tx-unavailable',
      dataTime: null,
      isStale: true,
      errorMessage: 'TX quote unavailable in fixture.',
    );
  }
}

class _NoUsableHoldingsRepository extends _PriceHistoryRepository {
  @override
  Future<EtfDailyHoldingSnapshot> fetchDailySnapshot() async {
    final now = DateTime(2026, 6, 28);
    return EtfDailyHoldingSnapshot(
      tradeDate: now,
      fundNetAssetValue: 0,
      navPerUnit: 0,
      outstandingUnits: 0,
      assetSummary: const EtfAssetSummary(
        stock: 0,
        etf: 0,
        bond: 0,
        futures: 0,
      ),
      cashHoldings: const [],
      stockHoldings: const [],
      futuresHoldings: const [],
      status: EtfDataStatus.error,
      lastFetchedAt: now,
      sourceUpdatedAt: now,
      sourceHash: 'fixture-unavailable-holdings',
      errorMessage: 'fixture unavailable holdings',
    );
  }
}

class _CatalogOnlyComparisonRepository extends _PriceHistoryRepository {
  @override
  Future<EtfPriceHistory> fetchEtfPriceHistory(
    String code, {
    int limit = 5000,
  }) async {
    final normalized = code.trim().toUpperCase();
    if (normalized == '00400A') {
      return EtfPriceHistory.empty(
        code: normalized,
        name: normalized,
        lastFetchedAt: DateTime(2026, 6, 11),
        status: EtfDataStatus.error,
        sourceStatusLabel: 'catalog_only',
        sourceUrl: 'local://00400a-catalog-only',
        errorMessage: 'Catalog-only ETF has no imported price history.',
      );
    }
    return super.fetchEtfPriceHistory(normalized, limit: limit);
  }
}

class _CatalogOnlyGapReasonRepository extends Mock00631LRepository {
  @override
  Future<Etf00631LLabData> fetchFastLabData() {
    return fetchLabData();
  }

  @override
  Future<EtfOperationsStatus> fetchOperationsStatus() async {
    return _operationsStatusWithEtfHistory(
      readyCount: 0,
      rowCount: 1,
      catalogRowCount: 1,
      historyRowCount: 1,
      missingCount: 1,
      attemptedCount: 1,
      tierCounts: const {'unavailable': 1},
      gapReasonCounts: const {
        'official_empty': 0,
        'not_saved': 1,
        'insufficient_rows': 0,
        'validation_error': 0,
        'source_error': 0,
        'not_ready': 0,
      },
      gapReasonSamples: const {
        'not_saved': ['00400A'],
      },
    );
  }

  @override
  Future<EtfCatalog> fetchEtfCatalog() async {
    final now = DateTime(2026, 6, 11, 10);
    return EtfCatalog(
      items: [
        EtfCatalogItem(
          code: '00400A',
          name: 'Catalog Gap ETF',
          marketPrice: 14.63,
          dataTime: now,
          targetType: 'ETF',
          priceHistoryCoverageTier: 'unavailable',
          priceHistorySourceStatus: 'unavailable',
          priceHistoryGapReason: 'not_saved',
          priceHistoryLastAttemptAt: now,
        ),
      ],
      status: EtfDataStatus.cached,
      sourceStatusLabel: 'static_public_data',
      sourceContract: 'twse_all_etf_catalog_test',
      sourceUrl: 'local://catalog-gap-reason',
      lastFetchedAt: now,
      dataTime: now,
      isStale: false,
    );
  }
}

class _CatalogWithoutQuoteRepository extends _PriceHistoryRepository {
  @override
  Future<EtfCatalog> fetchEtfCatalog() async {
    final now = DateTime(2026, 6, 11, 10);
    return EtfCatalog(
      items: [
        EtfCatalogItem(
          code: '0050',
          name: '元大台灣50',
          dataTime: now,
          targetType: 'ETF',
          priceHistoryRowCount: 3,
          priceHistoryCoverageTier: 'recent',
          priceHistoryCoverageStart: DateTime(2025, 6, 3),
          priceHistoryCoverageEnd: DateTime(2026, 6, 3),
          priceHistorySourceStatus: 'cached',
        ),
      ],
      status: EtfDataStatus.cached,
      sourceStatusLabel: 'cached',
      sourceContract: 'twse_all_etf_catalog_test',
      sourceUrl: 'local://etf-catalog-without-quote',
      lastFetchedAt: now,
      dataTime: now,
      isStale: false,
    );
  }
}

class _EtfReadinessOperationsRepository extends Mock00631LRepository {
  @override
  Future<Etf00631LLabData> fetchFastLabData() {
    return fetchLabData();
  }

  @override
  Future<EtfOperationsStatus> fetchOperationsStatus() async {
    return _operationsStatusWithEtfHistory(
      readyCount: 228,
      rowCount: 228,
      tierCounts: const {
        'long_term': 8,
        'recent': 220,
        'unavailable': 0,
        'error': 0,
      },
    );
  }
}

class _EtfCatalogGapOperationsRepository extends Mock00631LRepository {
  @override
  Future<Etf00631LLabData> fetchFastLabData() {
    return fetchLabData();
  }

  @override
  Future<EtfOperationsStatus> fetchOperationsStatus() async {
    return _operationsStatusWithEtfHistory(
      readyCount: 228,
      rowCount: 228,
      catalogRowCount: 344,
      historyRowCount: 228,
      missingCount: 116,
      tierCounts: const {
        'long_term': 8,
        'recent': 220,
        'unavailable': 116,
        'error': 0,
      },
      gapReasonSamples: const {
        'not_saved': ['00999', '00998'],
      },
    );
  }
}

class _EtfClassifiedGapOperationsRepository
    extends _EtfCatalogGapOperationsRepository {
  @override
  Future<EtfOperationsStatus> fetchOperationsStatus() async {
    return _operationsStatusWithEtfHistory(
      readyCount: 231,
      rowCount: 347,
      catalogRowCount: 347,
      historyRowCount: 347,
      missingCount: 116,
      attemptedCount: 116,
      tierCounts: const {
        'long_term': 8,
        'recent': 223,
        'unavailable': 116,
        'error': 0,
      },
      gapReasonCounts: const {
        'official_empty': 116,
        'not_saved': 0,
        'insufficient_rows': 0,
        'validation_error': 0,
        'source_error': 0,
        'not_ready': 0,
      },
      gapReasonSamples: const {
        'official_empty': ['006201', '00679B', '00687B'],
      },
    );
  }
}

class _EtfGapDetailsRepository extends _EtfCatalogGapOperationsRepository {
  @override
  Future<EtfPriceHistoryGapDetails> fetchEtfPriceHistoryGaps({
    String? reason,
    int limit = 50,
    bool fromCatalog = true,
  }) async {
    final now = DateTime(2026, 6, 21, 10);
    return EtfPriceHistoryGapDetails(
      items: [
        EtfPriceHistoryGapDetail(
          code: '00999',
          name: 'Static Gap ETF',
          gapReason: 'official_empty',
          coverageTier: 'unavailable',
          rowCount: 0,
          validationFailureCount: 0,
          sourceStatus: 'error',
          sourceUrl: 'https://example.test/STOCK_DAY?stockNo=00999',
          lastAttemptAt: now,
          requestedMonths: 1,
          errorMessage: 'official empty months',
        ),
        EtfPriceHistoryGapDetail(
          code: '00749B',
          name: 'Source Error ETF',
          gapReason: 'source_error',
          coverageTier: 'error',
          rowCount: 0,
          validationFailureCount: 0,
          sourceStatus: 'error',
          sourceUrl: 'https://example.test/STOCK_DAY?stockNo=00749B',
          lastAttemptAt: now,
          requestedMonths: 1,
          errorMessage: 'source timeout',
        ),
      ],
      status: EtfDataStatus.cached,
      sourceStatusLabel: 'cached',
      sourceContract: 'twse_multi_etf_price_history_gaps',
      sourceUrl: 'local://etf-history-gaps',
      lastFetchedAt: now,
      sourceUpdatedAt: now,
      dataTime: now,
      reason: reason,
      limit: limit,
      rowCount: 2,
      returnedCount: 2,
      gapDetailCount: 2,
      gapReasonCounts: const {
        'official_empty': 1,
        'source_error': 1,
      },
      gapReasonSamples: const {
        'official_empty': ['00999'],
        'source_error': ['00749B'],
      },
    );
  }
}

class _SettingsBackendErrorRepository extends Mock00631LRepository {
  @override
  Future<Etf00631LLabData> fetchFastLabData() {
    return fetchLabData();
  }

  @override
  Future<EtfOperationsStatus> fetchOperationsStatus() async {
    return EtfOperationsStatus.empty(
      status: EtfDataStatus.error,
      sourceStatusLabel: 'error',
      errorMessage: 'backend unavailable',
    );
  }
}

class _DeploymentDriftRepository extends Mock00631LRepository {
  @override
  Future<Etf00631LLabData> fetchFastLabData() {
    return fetchLabData();
  }

  @override
  Future<EtfOperationsStatus> fetchOperationsStatus() async {
    return _operationsStatusWithEtfHistory(
      readyCount: 231,
      rowCount: 347,
      sourceStatusLabel: 'cached',
      backendAppVersion: '6.90-backend',
      backendReleaseTag: '00631l-lab-v6.90-backend',
      backendGitSha: '1111111',
      staticReleaseAppVersion: '6.94-frontend',
      staticReleaseTag: '00631l-lab-v6.94-frontend',
      staticReleaseGitSha: '2222222',
      tierCounts: const {'long_term': 8, 'recent': 223},
    );
  }
}

class _CatalogHistoryMetadataRepository extends Mock00631LRepository {
  @override
  Future<Etf00631LLabData> fetchFastLabData() {
    return fetchLabData();
  }

  @override
  Future<EtfOperationsStatus> fetchOperationsStatus() async {
    return _operationsStatusWithEtfHistory(
      readyCount: 1,
      rowCount: 1,
      tierCounts: const {'recent': 1},
    );
  }

  @override
  Future<EtfCatalog> fetchEtfCatalog() async {
    final now = DateTime(2026, 6, 11, 10);
    return EtfCatalog(
      items: [
        EtfCatalogItem(
          code: '00701',
          name: 'Metadata Ready ETF',
          marketPrice: 20.5,
          dataTime: now,
          targetType: 'ETF',
          priceHistoryRowCount: 12,
          priceHistoryCoverageTier: 'recent',
          priceHistoryCoverageStart: DateTime(2026, 1, 1),
          priceHistoryCoverageEnd: DateTime(2026, 6, 11),
          priceHistorySourceStatus: 'static_official',
          priceHistoryPriceField: 'close',
          priceHistoryAdjustmentMethod: 'none',
          priceHistoryAdjustmentEventCount: 0,
        ),
      ],
      status: EtfDataStatus.cached,
      sourceStatusLabel: 'static_official',
      sourceContract: 'twse_all_etf_catalog_static_public',
      sourceUrl: 'local://etf-catalog',
      lastFetchedAt: now,
      dataTime: now,
      isStale: false,
    );
  }
}

EtfOperationsStatus _operationsStatusWithEtfHistory({
  required int readyCount,
  required int rowCount,
  required Map<String, int> tierCounts,
  int? catalogRowCount,
  int? historyRowCount,
  int missingCount = 0,
  int attemptedCount = 0,
  int outOfCatalogCount = 0,
  String sourceStatusLabel = 'static_public_data',
  String backendAppVersion = '',
  String backendReleaseTag = '',
  String backendGitSha = '',
  String staticReleaseAppVersion = '5.42-public-release-wait',
  String staticReleaseTag = '00631l-lab-v5.42-public-release-wait',
  String staticReleaseGitSha = 'b611c2c21c031b2fea2f182a778a46776093bb3f',
  Map<String, int> gapReasonCounts = const {
    'official_empty': 0,
    'not_saved': 0,
    'insufficient_rows': 0,
    'validation_error': 0,
    'source_error': 0,
    'not_ready': 0,
  },
  Map<String, int> sourceContractCounts = const {
    'twse_stock_day_json': 200,
    'tpex_etf_historical_daily_json': 28,
  },
  Map<String, List<String>> gapReasonSamples = const {},
}) {
  final now = DateTime(2026, 6, 11, 10);
  return EtfOperationsStatus(
    status: EtfDataStatus.cached,
    sourceStatusLabel: sourceStatusLabel,
    sourceContract: '00631l_static_public_operations',
    sourceUrl: 'local://operations-status',
    lastFetchedAt: now,
    sourceUpdatedAt: now,
    isStale: false,
    intradaySourceMode: 'backend_required',
    twseIntradayNavConfigured: false,
    yuantaIntradayNavConfigured: false,
    backendAppVersion: backendAppVersion,
    backendReleaseTag: backendReleaseTag,
    backendGitSha: backendGitSha,
    staticReleaseAppVersion: staticReleaseAppVersion,
    staticReleaseTag: staticReleaseTag,
    staticReleaseGitSha: staticReleaseGitSha,
    staticReleaseBuildTime: DateTime(2026, 6, 24, 8, 1, 9),
    publicApiBaseUrl: '',
    allowedOrigins: const [],
    dataRoot: 'web/00631l-static-data',
    dataPersistenceMode: 'static_public',
    dataPersistenceWarning:
        'Static public mode has historical data only; live intraday NAV still needs backend.',
    dataPathWritable: false,
    dataPathPersistent: true,
    holdingsHistoryStatus: 'backend_required',
    holdingsHistoryItemCount: 0,
    latestHoldingTradeDate: null,
    intradayHistoryStatus: 'backend_required',
    intradaySampleCount: 0,
    latestIntradayDataTime: null,
    intradayHistoryDate: null,
    priceHistoryStatus: 'static_official',
    priceHistoryRows: 2832,
    priceHistoryCoverageStart: DateTime(2014, 10, 31),
    priceHistoryCoverageEnd: DateTime(2026, 6, 18),
    priceHistoryCompleteFromListing: true,
    etfCatalogStatus: 'static_official',
    etfCatalogRowCount: catalogRowCount ?? rowCount,
    etfCatalogDataTime: now,
    etfPriceHistoryStatus: 'static_official',
    etfPriceHistoryRowCount: historyRowCount ?? rowCount,
    etfPriceHistoryReadyCount: readyCount,
    etfPriceHistoryMissingCount: missingCount,
    etfPriceHistoryGapDetailCount: missingCount,
    etfPriceHistoryAttemptedCount: attemptedCount,
    etfPriceHistoryOutOfCatalogCount: outOfCatalogCount,
    etfPriceHistoryCoverageTierCounts: tierCounts,
    etfPriceHistorySourceContractCounts: sourceContractCounts,
    etfPriceHistoryGapReasonCounts: gapReasonCounts,
    etfPriceHistoryGapReasonSamples: gapReasonSamples,
    etfPriceHistoryDataTime: now,
    backtestStatus: 'static_official',
    backtestAvailable: true,
    positionStatus: 'local_only',
    collectorOneShotCommand: 'public backend required for live collection',
    collectorIntradayCommand: 'public backend required for live intraday NAV',
    envFileExists: false,
    missingEnvKeys: const ['PUBLIC_API_BASE_URL', 'ALLOWED_ORIGINS'],
    optionalMissingEnvKeys: const [],
    dataDirReady: true,
    exportDirReady: true,
    backupDirReady: false,
  );
}

class _SparsePriceHistoryRepository extends Mock00631LRepository {
  @override
  Future<EtfPriceHistory> fetchPriceHistory({int limit = 5000}) async {
    final points = [
      EtfPriceHistoryPoint(
        date: DateTime(2026, 6, 8),
        open: 35.0,
        high: 35.4,
        low: 34.8,
        close: 35.2,
        adjustedClose: 35.2,
        adjustmentFactor: 1.0,
        volume: 1200000,
      ),
    ];
    return EtfPriceHistory(
      points: points,
      status: EtfDataStatus.cached,
      sourceStatusLabel: 'cached',
      sourceUrl: 'local://sparse-price-history',
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

class _CountingEtfHistoryRepository extends Mock00631LRepository {
  int etfHistoryRequests = 0;

  @override
  Future<EtfPriceHistory> fetchEtfPriceHistory(
    String code, {
    int limit = 5000,
  }) {
    etfHistoryRequests += 1;
    return super.fetchEtfPriceHistory(code, limit: limit);
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
  bool fullRequested = false;
  final Completer<Etf00631LLabData> _fullCompleter =
      Completer<Etf00631LLabData>();

  @override
  Future<Etf00631LLabData> fetchFastLabData() {
    return Mock00631LRepository().fetchFastLabData();
  }

  @override
  Future<Etf00631LLabData> fetchLabData() {
    fullRequested = true;
    if (completeWithError) {
      throw const RepositoryFetchException('full fixture failure');
    }
    return _fullCompleter.future;
  }

  Future<void> complete() async {
    _fullCompleter.complete(await Mock00631LRepository().fetchLabData());
  }
}

class _FastStartupNoUsableHoldingsRepository extends _FastStartupRepository {
  @override
  Future<Etf00631LLabData> fetchFastLabData() async {
    final data = await Mock00631LRepository().fetchFastLabData();
    final snapshot = await _NoUsableHoldingsRepository().fetchDailySnapshot();
    return Etf00631LLabData(
      profile: data.profile,
      snapshot: snapshot,
      intradayNav: data.intradayNav,
      futuresQuote: data.futuresQuote,
      holdingsHistory: data.holdingsHistory,
      intradayNavHistory: data.intradayNavHistory,
      priceHistory: data.priceHistory,
      operationsStatus: data.operationsStatus,
      analysis: data.analysis,
      aiAnalysis: data.aiAnalysis,
      etfCatalog: data.etfCatalog,
      lastFetchedAt: data.lastFetchedAt,
    );
  }
}

class _FastStartupNoIntradayNavRepository extends _FastStartupRepository {
  @override
  Future<Etf00631LLabData> fetchFastLabData() async {
    final data = await Mock00631LRepository().fetchFastLabData();
    return Etf00631LLabData(
      profile: data.profile,
      snapshot: data.snapshot,
      intradayNav: null,
      futuresQuote: data.futuresQuote,
      holdingsHistory: data.holdingsHistory,
      intradayNavHistory: data.intradayNavHistory,
      priceHistory: data.priceHistory,
      operationsStatus: data.operationsStatus,
      analysis: data.analysis,
      aiAnalysis: data.aiAnalysis,
      etfCatalog: data.etfCatalog,
      lastFetchedAt: data.lastFetchedAt,
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
