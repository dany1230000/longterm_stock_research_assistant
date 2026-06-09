import 'package:flutter_test/flutter_test.dart';
import 'package:longterm_stock_research_assistant/models/leveraged_etf_lab.dart';

void main() {
  test('status summary handles unavailable intraday NAV', () {
    final summary = _summary(intradayNav: null);

    expect(summary.level, EtfStatusSummaryLevel.unavailable);
    expect(summary.label, '資料不足');
    expect(
      summary.lines.any((line) => line.contains('即時淨值資料不可用')),
      isTrue,
    );
  });

  test('status summary handles stale official holdings', () {
    final summary = _summary(
      snapshotTradeDate: DateTime(2026, 6, 5),
      now: DateTime(2026, 6, 9, 10, 15),
    );

    expect(summary.level, EtfStatusSummaryLevel.stale);
    expect(summary.label, '資料可能過期');
  });

  test('status summary handles elevated premium discount state', () {
    final summary = _summary(
      intradayNav: _intradayNav(premiumDiscountPct: 0.75),
    );

    expect(summary.level, EtfStatusSummaryLevel.elevated);
    expect(summary.label, '偏離程度較高');
  });

  test('status summary handles normal data state', () {
    final summary = _summary(
      intradayNav: _intradayNav(premiumDiscountPct: 0.10),
    );

    expect(summary.level, EtfStatusSummaryLevel.normal);
    expect(summary.label, '資料狀態正常');
    expect(summary.lines.last, contains('非買賣建議'));
  });

  test('operations guidance describes app next steps', () {
    final status = EtfOperationsStatus.empty(
      lastFetchedAt: DateTime(2026, 6, 9, 10, 15),
    );

    expect(
      status.operationGuidanceLines,
      contains('尚未跑 daily cycle：請執行 scripts\\00631l_daily_cycle.cmd。'),
    );
    expect(
      status.operationGuidanceLines,
      contains('backend env 未設定：請參考 backend\\.env.example。'),
    );
    expect(
      status.operationGuidanceLines,
      contains('intraday NAV 目前不可用：請檢查 TWSE URL 設定或交易時段。'),
    );
    expect(
      status.operationGuidanceLines,
      contains('CSV export 不存在：可執行 scripts\\00631l_export_history.cmd。'),
    );
  });

  test('daily readiness summary reports ready daily tool state', () {
    final summary = _operationsStatus().dailyReadinessSummary;

    expect(summary.level, EtfDailyReadinessLevel.ready);
    expect(summary.label, '可日常使用');
    expect(summary.actionNeededCount, 0);
    expect(summary.checks.every((check) => check.isReady), isTrue);
  });

  test('daily readiness summary reports action items for missing local state',
      () {
    final summary = EtfOperationsStatus.empty(
      lastFetchedAt: DateTime(2026, 6, 9, 10, 15),
    ).dailyReadinessSummary;

    expect(summary.level, EtfDailyReadinessLevel.actionNeeded);
    expect(summary.label, '需要處理');
    expect(summary.actionNeededCount, greaterThan(0));
    expect(
      summary.checks.any((check) =>
          check.action?.contains(
            'backend\\.env.example',
          ) ??
          false),
      isTrue,
    );
  });

  test('daily readiness summary treats WARN reports as attention only', () {
    final summary = _operationsStatus(
      reportOverallStatus: 'WARN',
      reportWarningCount: 2,
      dailyCycleWarningCount: 1,
    ).dailyReadinessSummary;

    expect(summary.level, EtfDailyReadinessLevel.attention);
    expect(summary.label, '需要觀察');
    expect(summary.actionNeededCount, 0);
    expect(summary.attentionCount, greaterThan(0));
  });
}

EtfStatusSummary _summary({
  EtfIntradayNav? intradayNav,
  DateTime? snapshotTradeDate,
  DateTime? now,
}) {
  final resolvedNow = now ?? DateTime(2026, 6, 9, 10, 15);
  final snapshot = _snapshot(snapshotTradeDate ?? DateTime(2026, 6, 9));
  final history = _history();
  return EtfStatusSummary.evaluate(
    profile: _profile(),
    snapshot: snapshot,
    intradayNav: intradayNav,
    holdingsHistory: history,
    intradayNavHistory: EtfIntradayNavHistorySummary.empty(
      status: EtfDataStatus.cached,
      sourceStatusLabel: 'cached',
    ),
    holdingsChangeAssessment: HoldingsChangeAssessment.evaluate(
      history: history,
      snapshot: snapshot,
      now: resolvedNow,
    ),
    now: resolvedNow,
  );
}

LeveragedEtfProfile _profile() {
  return LeveragedEtfProfile(
    symbol: '00631L',
    fundName: '00631L',
    shortName: '00631L',
    trackingIndex: 'Taiwan 50',
    inceptionDate: DateTime(2014, 10, 23),
    listingDate: DateTime(2014, 10, 31),
    distributesIncome: false,
    riskLevel: 'RR5',
    managementFeePercent: 1,
    custodianFeePercent: 0.04,
    leverageObjective: '2x',
    exposurePolicy: '180%-220%',
    primaryTradingMethod: 'futures',
    sourceUrl: 'fixture://profile',
    status: EtfDataStatus.proxy,
    lastFetchedAt: DateTime(2026, 6, 9, 10, 15),
  );
}

EtfDailyHoldingSnapshot _snapshot(DateTime tradeDate) {
  return EtfDailyHoldingSnapshot(
    tradeDate: tradeDate,
    fundNetAssetValue: 100,
    navPerUnit: 10,
    outstandingUnits: 10,
    assetSummary: const EtfAssetSummary(
      stock: 40,
      etf: 0,
      bond: 0,
      futures: 160,
    ),
    cashHoldings: const [],
    stockHoldings: const [],
    futuresHoldings: const [],
    status: EtfDataStatus.proxy,
    lastFetchedAt: DateTime(2026, 6, 9, 10, 15),
    sourceUpdatedAt: tradeDate,
    sourceHash: 'snapshot',
  );
}

EtfHoldingsHistory _history() {
  return EtfHoldingsHistory(
    points: [
      _historyPoint(DateTime(2026, 6, 9)),
      _historyPoint(DateTime(2026, 6, 8)),
    ],
    status: EtfDataStatus.cached,
    sourceStatusLabel: 'cached',
    sourceUrl: 'local://history',
    lastFetchedAt: DateTime(2026, 6, 9, 10, 15),
    isStale: false,
  );
}

EtfHoldingsHistoryPoint _historyPoint(DateTime tradeDate) {
  return EtfHoldingsHistoryPoint(
    tradeDate: tradeDate,
    txWeightPct: 160,
    tsmcWeightPct: 37,
    stockExposurePct: 40,
    futuresExposurePct: 160,
    cashAndMarginPct: 60,
    navPerUnit: 35,
    fundNetAssetValue: 100,
    outstandingUnits: 10,
    status: EtfDataStatus.proxy,
    sourceHash: tradeDate.toIso8601String(),
  );
}

EtfIntradayNav _intradayNav({required double premiumDiscountPct}) {
  return EtfIntradayNav(
    symbol: '00631L',
    name: '00631L',
    outstandingUnits: 10,
    outstandingUnitsDelta: 0,
    marketPrice: 10,
    estimatedNav: 10,
    estimatedPremiumDiscountPct: premiumDiscountPct,
    previousBusinessDayNav: 10,
    previousBusinessDayNavText: '10',
    dataDate: DateTime(2026, 6, 9),
    dataTime: DateTime(2026, 6, 9, 13, 30),
    targetType: '1',
    userDelayMs: 15000,
    sourceContract: 'twse_a_k_json',
    isStale: false,
    status: EtfDataStatus.proxy,
    lastFetchedAt: DateTime(2026, 6, 9, 13, 30),
  );
}

EtfOperationsStatus _operationsStatus({
  String reportOverallStatus = 'PASS',
  int reportWarningCount = 0,
  int reportFailureCount = 0,
  int dailyCycleWarningCount = 0,
  int dailyCycleFailureCount = 0,
}) {
  return EtfOperationsStatus(
    status: EtfDataStatus.cached,
    sourceStatusLabel: 'cached',
    sourceContract: '00631l_operations_status',
    sourceUrl: 'local://operations',
    lastFetchedAt: DateTime(2026, 6, 9, 10, 15),
    sourceUpdatedAt: DateTime(2026, 6, 9, 10, 15),
    isStale: false,
    intradaySourceMode: 'auto',
    twseIntradayNavConfigured: true,
    yuantaIntradayNavConfigured: true,
    publicApiBaseUrl: 'https://api.example.com',
    allowedOrigins: const ['https://00631l.example.com'],
    dataRoot: '/data',
    dataPersistenceMode: 'persistent',
    dataPathWritable: true,
    dataPathPersistent: true,
    holdingsHistoryStatus: 'cached',
    holdingsHistoryItemCount: 5,
    latestHoldingTradeDate: DateTime(2026, 6, 9),
    intradayHistoryStatus: 'cached',
    intradaySampleCount: 12,
    latestIntradayDataTime: DateTime(2026, 6, 9, 10, 12, 30),
    intradayHistoryDate: DateTime(2026, 6, 9),
    collectorOneShotCommand: 'scripts\\00631l_collect_snapshot.cmd --samples 1',
    collectorIntradayCommand:
        'scripts\\00631l_collect_snapshot.cmd --skip-profile --skip-holdings --samples 20 --interval-seconds 15',
    envFileExists: true,
    missingEnvKeys: const [],
    optionalMissingEnvKeys: const [],
    dataDirReady: true,
    exportDirReady: true,
    backupDirReady: true,
    exportAvailable: true,
    latestExportPath: 'backend/exports/00631l_holdings_history_summary.csv',
    latestExportUpdatedAt: DateTime(2026, 6, 9, 10, 10),
    backupAvailable: true,
    latestBackupPath: 'backend/backups/00631l_local_data_backup.zip',
    latestBackupUpdatedAt: DateTime(2026, 6, 9, 10, 11),
    reportAvailable: true,
    latestReportPath: 'backend/reports/00631l_daily_report_20260609.md',
    latestReportGeneratedAt: DateTime(2026, 6, 9, 10, 12),
    reportOverallStatus: reportOverallStatus,
    reportWarningCount: reportWarningCount,
    reportFailureCount: reportFailureCount,
    dailyCycleStatus: dailyCycleFailureCount > 0 ? 'FAIL' : 'PASS',
    dailyCycleStartedAt: DateTime(2026, 6, 9, 10),
    dailyCycleFinishedAt: DateTime(2026, 6, 9, 10, 13),
    dailyCycleWarningCount: dailyCycleWarningCount,
    dailyCycleFailureCount: dailyCycleFailureCount,
  );
}
