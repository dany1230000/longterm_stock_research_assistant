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
  testWidgets('00631L lab renders summary cards', (tester) async {
    await _pumpLab(tester, Mock00631LRepository());

    expect(find.text('00631L 正二研究室'), findsOneWidget);
    expect(find.text('00631L 市價'), findsOneWidget);
    expect(find.text('預估淨值'), findsOneWidget);
    expect(find.text('折溢價 %'), findsOneWidget);
    expect(find.text('官方內容物日期'), findsOneWidget);
    expect(find.text('資料狀態'), findsOneWidget);
    expect(find.textContaining('mock'), findsWidgets);
  });

  testWidgets('00631L lab remains readable on phone width', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await _pumpLab(tester, Mock00631LRepository());

    expect(find.textContaining('twse_a_k_json'), findsWidgets);
    expect(find.textContaining('mock'), findsWidgets);

    await _scrollUntilTextVisible(tester, 'AI 分析摘要');
    expect(find.text('AI 分析摘要'), findsOneWidget);

    await _scrollUntilTextVisible(tester, 'daily collector');
    expect(find.text('daily collector'), findsOneWidget);

    await _scrollUntilTextVisible(tester, 'sourceStatus mock');
    expect(find.text('sourceStatus mock'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('00631L lab shows fallback error state', (tester) async {
    await _pumpLab(tester, _Error00631LRepository());

    expect(find.text('00631L 資料載入失敗'), findsOneWidget);
    expect(find.textContaining('即時資料暫不可用'), findsOneWidget);
    expect(find.text('重新整理'), findsOneWidget);
  });

  testWidgets('00631L lab renders mock fallback when live proxy is down',
      (tester) async {
    await _pumpLab(
      tester,
      Cached00631LRepository(
        primary: _Error00631LRepository(),
        fallback: Mock00631LRepository(),
      ),
    );

    expect(find.textContaining('mock'), findsWidgets);
    await _scrollUntilTextVisible(tester, 'backend disconnected');
    expect(find.textContaining('backend disconnected'), findsWidgets);
    expect(find.textContaining('fallback remains visible'), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('00631L lab shows mock stock and futures tables', (tester) async {
    await _pumpLab(tester, Mock00631LRepository());

    await _scrollUntilTextVisible(tester, '股票明細表');
    expect(find.text('股票明細表'), findsOneWidget);
    expect(find.text('台積電'), findsOneWidget);
    expect(find.text('37.44%'), findsWidgets);

    await _scrollUntilTextVisible(tester, '期貨明細表');
    expect(find.text('期貨明細表'), findsOneWidget);
    expect(find.text('TX'), findsWidgets);
    expect(find.text('臺股期貨'), findsOneWidget);
    expect(find.text('202606'), findsWidgets);
  });

  testWidgets('00631L lab shows non-advice status summary', (tester) async {
    await _pumpLab(tester, Mock00631LRepository());

    await _scrollUntilTextVisible(tester, '00631L 狀態總結');
    expect(find.text('00631L 狀態總結'), findsOneWidget);
    expect(find.textContaining('非買賣建議'), findsWidgets);
    _expectNoTradingActionText();
  });

  testWidgets('00631L lab shows operations collection status', (tester) async {
    await _pumpLab(tester, Mock00631LRepository());

    await _scrollUntilTextVisible(tester, '資料收集狀態');
    expect(find.text('資料收集狀態'), findsOneWidget);
    expect(find.text('daily collector'), findsOneWidget);
    expect(find.textContaining('00631l_collect_snapshot'), findsWidgets);
    expect(find.text('sourceStatus mock'), findsWidgets);
    expect(find.textContaining('backup'), findsWidgets);
    expect(find.textContaining('data + exports + backups'), findsOneWidget);
  });

  testWidgets('00631L lab shows today data status summary', (tester) async {
    await _pumpLab(tester, Mock00631LRepository());

    await _scrollUntilTextVisible(tester, '今日資料狀態');
    expect(find.text('今日資料狀態'), findsOneWidget);
    expect(find.text('每日可用狀態'), findsOneWidget);
    expect(find.text('資料更新頻率'), findsOneWidget);
    expect(find.text('每日快照'), findsOneWidget);
    expect(find.text('約 15–30 秒'), findsOneWidget);
    expect(find.text('尚未接入'), findsOneWidget);
    expect(find.text('需要處理'), findsWidgets);
    expect(find.textContaining('operations mock'), findsWidgets);
    expect(find.text('daily cycle'), findsWidgets);
    expect(find.text('daily report'), findsWidgets);
    expect(find.textContaining('report'), findsWidgets);
    expect(find.textContaining('尚未執行 daily cycle'), findsWidgets);
    expect(find.text('下一步操作提示'), findsOneWidget);
    expect(
        find.textContaining('scripts\\00631l_daily_cycle.cmd'), findsWidgets);
    expect(find.textContaining('backend\\.env.example'), findsWidgets);
    expect(find.textContaining('TWSE URL 設定或交易時段'), findsOneWidget);
    _expectNoTradingActionText();
  });

  testWidgets('00631L lab shows rule-based AI analysis summary',
      (tester) async {
    await _pumpLab(tester, _AiAnalysisFixture00631LRepository());

    await _scrollUntilTextVisible(tester, 'AI 分析摘要');
    expect(find.text('AI 分析摘要'), findsOneWidget);
    expect(find.text('source rule_based'), findsOneWidget);
    expect(find.text('sourceStatus cached'), findsWidgets);
    expect(find.text('非買賣建議'), findsWidgets);
    expect(find.textContaining('official holdings 為每日快照'), findsOneWidget);
    expect(find.textContaining('請先執行 scripts\\00631l_daily_cycle.cmd'),
        findsOneWidget);
    _expectNoTradingActionText();
  });

  testWidgets('00631L lab shows latest daily report details', (tester) async {
    await _pumpLab(tester, _ReportFixture00631LRepository());

    await _scrollUntilTextVisible(tester, '最新日報摘要');
    expect(find.text('最新日報摘要'), findsOneWidget);
    expect(find.textContaining('status WARN'), findsOneWidget);
    expect(find.text('report WARN'), findsWidgets);
    expect(find.text('warnings 2'), findsOneWidget);
    expect(find.text('failures 0'), findsOneWidget);
    expect(find.textContaining('00631l_daily_report_20260609'), findsOneWidget);
    _expectNoTradingActionText();
  });

  testWidgets('00631L lab summarizes daily readiness for usable local state',
      (tester) async {
    await _pumpLab(tester, _ReadyOperations00631LRepository());

    await _scrollUntilTextVisible(tester, '每日可用狀態');
    expect(find.text('每日可用狀態'), findsOneWidget);
    expect(find.text('可日常使用'), findsOneWidget);
    expect(find.textContaining('資料鏈與本機流程目前可日常使用'), findsOneWidget);
    expect(find.text('backend 連線'), findsOneWidget);
    expect(find.text('official holdings'), findsOneWidget);
    expect(find.text('local state'), findsOneWidget);
    _expectNoTradingActionText();
  });

  testWidgets('00631L lab shows daily holdings history when available',
      (tester) async {
    await _pumpLab(tester, _HistoryFixture00631LRepository());

    await _scrollUntilTextVisible(tester, '每日內容物歷史');
    expect(find.text('每日內容物歷史'), findsOneWidget);
    expect(find.text('權重趨勢'), findsOneWidget);
    expect(find.text('TX權重'), findsOneWidget);
    expect(find.text('TX 權重'), findsWidgets);
    expect(find.text('台積電權重'), findsWidgets);
    expect(find.text('現金與保證金'), findsWidgets);
    expect(find.text('最近 7 日摘要'), findsOneWidget);
    expect(find.text('變化摘要'), findsOneWidget);
    expect(find.text('TX 權重'), findsWidgets);
    expect(find.text('+6.00 pp'), findsWidgets);
    expect(find.text('160.20%'), findsWidgets);
    expect(find.text('36.80%'), findsWidgets);
    expect(find.text('35.12'), findsWidgets);
    expect(find.text('5,200,000,000'), findsWidgets);
  });

  testWidgets('00631L lab shows empty daily holdings history state',
      (tester) async {
    await _pumpLab(tester, Mock00631LRepository());

    await _scrollUntilTextVisible(tester, '每日內容物歷史');
    expect(find.text('每日內容物歷史'), findsOneWidget);
    expect(find.text('尚無歷史紀錄'), findsOneWidget);
    expect(find.text('sourceStatus mock'), findsOneWidget);
  });

  testWidgets('00631L lab shows holdings change notices without advice',
      (tester) async {
    await _pumpLab(tester, _HistoryFixture00631LRepository());

    await _scrollUntilTextVisible(tester, '內容物變化提醒');
    expect(find.text('內容物變化提醒'), findsOneWidget);
    expect(find.text('TX 權重變化較大'), findsOneWidget);
    expect(find.text('台積電權重變化較大'), findsOneWidget);
    expect(find.textContaining('非買賣建議'), findsWidgets);
    _expectNoTradingActionText();
  });

  testWidgets('00631L lab shows intraday NAV values and source contract',
      (tester) async {
    await _pumpLab(tester, Mock00631LRepository());

    expect(find.text('36.56'), findsWidgets);
    expect(find.text('+0.44%'), findsWidgets);
    expect(find.text('twse_a_k_json'), findsWidgets);
  });

  testWidgets('00631L lab shows intraday premium discount history',
      (tester) async {
    await _pumpLab(tester, _IntradayHistoryFixture00631LRepository());

    await _scrollUntilTextVisible(tester, '盤中折溢價歷史');
    expect(find.text('盤中折溢價歷史'), findsOneWidget);
    expect(find.text('折溢價走勢'), findsOneWidget);
    expect(find.text('最高溢價'), findsOneWidget);
    expect(find.text('最低折價'), findsOneWidget);
    expect(find.text('平均折溢價'), findsOneWidget);
    expect(find.text('折溢價 %'), findsOneWidget);
    expect(find.text('+0.75%'), findsWidgets);
    expect(find.text('-0.20%'), findsWidgets);
    expect(find.text('+0.30%'), findsOneWidget);
    _expectNoTradingActionText();
  });

  testWidgets('00631L lab shows empty intraday history state', (tester) async {
    await _pumpLab(tester, Mock00631LRepository());

    await _scrollUntilTextVisible(tester, '盤中折溢價歷史');
    expect(find.text('盤中折溢價歷史'), findsOneWidget);
    expect(find.text('尚無盤中折溢價歷史'), findsOneWidget);
    expect(find.text('sourceStatus mock'), findsWidgets);
  });

  testWidgets('00631L lab labels unavailable intraday NAV', (tester) async {
    await _pumpLab(tester, _NoIntraday00631LRepository());

    await _scrollUntilTextVisible(tester, '折溢價狀態');
    expect(find.text('sourceStatus unavailable'), findsOneWidget);
    expect(find.text('即時資料不可用'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('00631L lab labels elevated premium without advice',
      (tester) async {
    await _pumpLab(
      tester,
      _PremiumFixture00631LRepository(premiumDiscountPct: 0.75),
    );

    await _scrollUntilTextVisible(tester, '折溢價狀態');
    expect(find.text('+0.75%'), findsWidgets);
    expect(find.text('溢價偏高'), findsOneWidget);
    expect(find.textContaining('市價高於預估淨值 +0.75%'), findsOneWidget);
    expect(find.textContaining('非買賣建議'), findsWidgets);
    _expectNoTradingActionText();
  });

  testWidgets('00631L lab labels elevated discount without advice',
      (tester) async {
    await _pumpLab(
      tester,
      _PremiumFixture00631LRepository(premiumDiscountPct: -0.75),
    );

    await _scrollUntilTextVisible(tester, '折溢價狀態');
    expect(find.text('-0.75%'), findsWidgets);
    expect(find.text('折價偏深'), findsOneWidget);
    expect(find.textContaining('市價低於預估淨值 -0.75%'), findsOneWidget);
    expect(find.textContaining('非買賣建議'), findsWidgets);
    _expectNoTradingActionText();
  });

  testWidgets('00631L lab labels stale premium discount data', (tester) async {
    await _pumpLab(
      tester,
      _PremiumFixture00631LRepository(
        premiumDiscountPct: 0.75,
        isStale: true,
        status: EtfDataStatus.cached,
      ),
    );

    await _scrollUntilTextVisible(tester, '折溢價狀態');
    expect(find.text('資料可能過期'), findsWidgets);
    expect(find.textContaining('即時淨值資料可能過期'), findsOneWidget);
    expect(find.textContaining('非買賣建議'), findsWidgets);
    _expectNoTradingActionText();
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

Future<void> _scrollUntilTextVisible(WidgetTester tester, String text) async {
  final listView = find.byType(ListView);
  for (var i = 0; i < 36 && find.text(text).evaluate().isEmpty; i += 1) {
    await tester.drag(listView, const Offset(0, -360));
    await tester.pumpAndSettle();
  }
}

class _IntradayHistoryFixture00631LRepository extends Mock00631LRepository {
  @override
  Future<EtfIntradayNavHistorySummary> fetchIntradayNavHistorySummary() async {
    return EtfIntradayNavHistorySummary(
      points: [
        EtfIntradayNavHistoryPoint(
          dataTime: DateTime(2026, 6, 8, 13, 31),
          marketPrice: 33.8,
          estimatedNav: 33.55,
          premiumDiscountPct: 0.75,
          sourceContract: 'twse_a_k_json',
        ),
        EtfIntradayNavHistoryPoint(
          dataTime: DateTime(2026, 6, 8, 9, 1),
          marketPrice: 33.1,
          estimatedNav: 33.16,
          premiumDiscountPct: -0.20,
          sourceContract: 'twse_a_k_json',
        ),
      ],
      sampleCount: 3,
      highestPremiumDiscountPct: 0.75,
      lowestPremiumDiscountPct: -0.20,
      averagePremiumDiscountPct: 0.30,
      firstDataTime: DateTime(2026, 6, 8, 9, 1),
      lastDataTime: DateTime(2026, 6, 8, 13, 31),
      latestMarketPrice: 33.8,
      latestEstimatedNav: 33.55,
      date: DateTime(2026, 6, 8),
      status: EtfDataStatus.cached,
      sourceStatusLabel: 'cached',
      sourceUrl: 'local://00631l-intraday-nav-history',
      lastFetchedAt: DateTime(2026, 6, 8, 13, 32),
      isStale: false,
    );
  }
}

class _HistoryFixture00631LRepository extends Mock00631LRepository {
  @override
  Future<EtfHoldingsHistory> fetchHoldingsHistorySummary({
    int limit = 30,
  }) async {
    return EtfHoldingsHistory(
      points: [
        EtfHoldingsHistoryPoint(
          tradeDate: DateTime(2026, 6, 6),
          txWeightPct: 160.20,
          tsmcWeightPct: 36.80,
          stockExposurePct: 38.10,
          futuresExposurePct: 161.40,
          cashAndMarginPct: 66.10,
          navPerUnit: 35.12,
          fundNetAssetValue: 188000000000,
          outstandingUnits: 5200000000,
          status: EtfDataStatus.proxy,
          sourceHash: 'fixture-2',
        ),
        EtfHoldingsHistoryPoint(
          tradeDate: DateTime(2026, 6, 5),
          txWeightPct: 154.20,
          tsmcWeightPct: 34.10,
          stockExposurePct: 37.20,
          futuresExposurePct: 150.30,
          cashAndMarginPct: 60.10,
          navPerUnit: 36.56,
          fundNetAssetValue: 189796511953,
          outstandingUnits: 5190848000,
          status: EtfDataStatus.proxy,
          sourceHash: 'fixture-1',
        ),
      ],
      status: EtfDataStatus.cached,
      sourceStatusLabel: 'cached',
      sourceUrl: 'local://00631l-holdings-history',
      lastFetchedAt: DateTime(2026, 6, 8, 10, 15),
      isStale: false,
    );
  }
}

class _ReportFixture00631LRepository extends Mock00631LRepository {
  @override
  Future<EtfOperationsStatus> fetchOperationsStatus() async {
    final base = await super.fetchOperationsStatus();
    return EtfOperationsStatus(
      status: EtfDataStatus.cached,
      sourceStatusLabel: 'cached',
      sourceContract: base.sourceContract,
      sourceUrl: base.sourceUrl,
      lastFetchedAt: DateTime(2026, 6, 9, 10, 6),
      sourceUpdatedAt: DateTime(2026, 6, 9, 10, 6),
      isStale: false,
      intradaySourceMode: base.intradaySourceMode,
      twseIntradayNavConfigured: true,
      yuantaIntradayNavConfigured: true,
      holdingsHistoryStatus: 'cached',
      holdingsHistoryItemCount: 2,
      latestHoldingTradeDate: DateTime(2026, 6, 8),
      intradayHistoryStatus: 'cached',
      intradaySampleCount: 6,
      latestIntradayDataTime: DateTime(2026, 6, 9, 10, 5, 30),
      intradayHistoryDate: DateTime(2026, 6, 9),
      collectorOneShotCommand: base.collectorOneShotCommand,
      collectorIntradayCommand: base.collectorIntradayCommand,
      envFileExists: true,
      missingEnvKeys: const [],
      optionalMissingEnvKeys: const [],
      dataDirReady: true,
      exportDirReady: true,
      backupDirReady: true,
      exportAvailable: true,
      latestExportPath: 'backend/exports/00631l_holdings_history_summary.csv',
      latestExportUpdatedAt: DateTime(2026, 6, 9, 10, 4),
      backupAvailable: true,
      latestBackupPath: 'backend/backups/00631l_local_data_backup.zip',
      latestBackupUpdatedAt: DateTime(2026, 6, 9, 10, 5),
      reportAvailable: true,
      latestReportPath:
          'backend/reports/00631l_daily_report_20260609T100600Z.md',
      latestReportGeneratedAt: DateTime(2026, 6, 9, 10, 6),
      reportOverallStatus: 'WARN',
      reportWarningCount: 2,
      reportFailureCount: 0,
      dailyCycleStatus: 'PASS',
      dailyCycleStartedAt: DateTime(2026, 6, 9, 10),
      dailyCycleFinishedAt: DateTime(2026, 6, 9, 10, 6),
      dailyCycleWarningCount: 1,
      dailyCycleFailureCount: 0,
    );
  }
}

class _AiAnalysisFixture00631LRepository extends Mock00631LRepository {
  @override
  Future<EtfAiAnalysisSummary> fetchAiAnalysisSummary() async {
    return EtfAiAnalysisSummary(
      source: 'rule_based',
      sourceStatusLabel: 'cached',
      generatedAt: DateTime(2026, 6, 9, 10, 6),
      dataTime: DateTime(2026, 6, 9, 10, 5, 30),
      readinessLevel: 'attention',
      bullets: const [
        '今日資料狀態為需要觀察；此摘要只描述資料狀態與偏離程度。',
        'official holdings 為每日快照，最近日期 2026-06-09，sourceStatus cached。',
        'intraday NAV 為盤中估算資料，最近資料時間 2026-06-09T10:05:30+08:00，sourceStatus cached。',
      ],
      actionItems: const [
        '請先執行 scripts\\00631l_daily_cycle.cmd。',
      ],
      sourceStatuses: const {
        'operations': 'cached',
        'holdingsHistory': 'cached',
        'intradayNavHistory': 'cached',
      },
      disclaimer: '非買賣建議',
    );
  }
}

class _ReadyOperations00631LRepository extends Mock00631LRepository {
  @override
  Future<EtfOperationsStatus> fetchOperationsStatus() async {
    final base = await super.fetchOperationsStatus();
    return EtfOperationsStatus(
      status: EtfDataStatus.cached,
      sourceStatusLabel: 'cached',
      sourceContract: base.sourceContract,
      sourceUrl: base.sourceUrl,
      lastFetchedAt: DateTime(2026, 6, 9, 10, 6),
      sourceUpdatedAt: DateTime(2026, 6, 9, 10, 6),
      isStale: false,
      intradaySourceMode: base.intradaySourceMode,
      twseIntradayNavConfigured: true,
      yuantaIntradayNavConfigured: true,
      holdingsHistoryStatus: 'cached',
      holdingsHistoryItemCount: 8,
      latestHoldingTradeDate: DateTime(2026, 6, 9),
      intradayHistoryStatus: 'cached',
      intradaySampleCount: 16,
      latestIntradayDataTime: DateTime(2026, 6, 9, 10, 5, 30),
      intradayHistoryDate: DateTime(2026, 6, 9),
      collectorOneShotCommand: base.collectorOneShotCommand,
      collectorIntradayCommand: base.collectorIntradayCommand,
      envFileExists: true,
      missingEnvKeys: const [],
      optionalMissingEnvKeys: const [],
      dataDirReady: true,
      exportDirReady: true,
      backupDirReady: true,
      exportAvailable: true,
      latestExportPath: 'backend/exports/00631l_holdings_history_summary.csv',
      latestExportUpdatedAt: DateTime(2026, 6, 9, 10, 4),
      backupAvailable: true,
      latestBackupPath: 'backend/backups/00631l_local_data_backup.zip',
      latestBackupUpdatedAt: DateTime(2026, 6, 9, 10, 5),
      reportAvailable: true,
      latestReportPath:
          'backend/reports/00631l_daily_report_20260609T100600Z.md',
      latestReportGeneratedAt: DateTime(2026, 6, 9, 10, 6),
      reportOverallStatus: 'PASS',
      reportWarningCount: 0,
      reportFailureCount: 0,
      dailyCycleStatus: 'PASS',
      dailyCycleStartedAt: DateTime(2026, 6, 9, 10),
      dailyCycleFinishedAt: DateTime(2026, 6, 9, 10, 6),
      dailyCycleWarningCount: 0,
      dailyCycleFailureCount: 0,
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

class _NoIntraday00631LRepository extends Mock00631LRepository {
  @override
  Future<EtfIntradayNav?> fetchIntradayNav() async {
    return null;
  }
}

class _PremiumFixture00631LRepository extends Mock00631LRepository {
  _PremiumFixture00631LRepository({
    required this.premiumDiscountPct,
    this.isStale = false,
    this.status = EtfDataStatus.proxy,
  });

  final double premiumDiscountPct;
  final bool isStale;
  final EtfDataStatus status;

  @override
  Future<EtfIntradayNav?> fetchIntradayNav() async {
    final base = await super.fetchIntradayNav();
    return EtfIntradayNav(
      symbol: base!.symbol,
      name: base.name,
      outstandingUnits: base.outstandingUnits,
      outstandingUnitsDelta: base.outstandingUnitsDelta,
      marketPrice: base.marketPrice,
      estimatedNav: base.estimatedNav,
      estimatedPremiumDiscountPct: premiumDiscountPct,
      previousBusinessDayNav: base.previousBusinessDayNav,
      previousBusinessDayNavText: base.previousBusinessDayNavText,
      dataDate: base.dataDate,
      dataTime: base.dataTime,
      targetType: base.targetType,
      userDelayMs: base.userDelayMs,
      sourceContract: base.sourceContract,
      isStale: isStale,
      status: status,
      lastFetchedAt: base.lastFetchedAt,
    );
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
