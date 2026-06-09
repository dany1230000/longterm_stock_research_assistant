import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:longterm_stock_research_assistant/models/leveraged_etf_lab.dart';
import 'package:longterm_stock_research_assistant/repositories/cached_00631l_repository.dart';
import 'package:longterm_stock_research_assistant/repositories/mock_00631l_repository.dart';
import 'package:longterm_stock_research_assistant/repositories/proxy_00631l_repository.dart';
import 'package:longterm_stock_research_assistant/repositories/proxy_http_client.dart';

void main() {
  test('proxy repository maps normalized backend profile and holdings',
      () async {
    final repository = Proxy00631LRepository(
      client: _FakeProxyHttpClient({
        '/api/etf/00631l/profile': jsonEncode(_profilePayload()),
        '/api/etf/00631l/holdings': jsonEncode(_holdingsPayload()),
      }),
    );

    final profile = await repository.fetchProfile();
    final snapshot = await repository.fetchDailySnapshot();

    expect(profile.symbol, '00631L');
    expect(profile.status, EtfDataStatus.proxy);
    expect(profile.trackingIndex, '臺灣50指數');
    expect(snapshot.tradeDate, DateTime(2026, 6, 5));
    expect(snapshot.fundNetAssetValue, 189796511953);
    expect(snapshot.navPerUnit, 36.56);
    expect(snapshot.assetSummary.stock, 71056425000);
    expect(snapshot.assetSummary.futures, 306587054000);
    expect(snapshot.stockHoldings.single.code, '2330');
    expect(snapshot.futuresHoldings.single.code, 'TX');
    expect(snapshot.status, EtfDataStatus.proxy);
  });

  test('proxy repository maps intraday NAV a-k normalized payload', () async {
    final repository = Proxy00631LRepository(
      client: _FakeProxyHttpClient({
        '/api/etf/00631l/intraday-nav': jsonEncode(_intradayPayload()),
      }),
    );

    final nav = await repository.fetchIntradayNav();

    expect(nav, isNotNull);
    expect(nav!.symbol, '00631L');
    expect(nav.marketPrice, 36.72);
    expect(nav.estimatedNav, 36.56);
    expect(nav.estimatedPremiumDiscountPct, 0.44);
    expect(nav.previousBusinessDayNav, 36.30);
    expect(nav.dataDate, DateTime(2026, 6, 5));
    expect(nav.dataTime, DateTime(2026, 6, 5, 13, 30));
    expect(nav.targetType, '1');
    expect(nav.userDelayMs, 15000);
    expect(nav.sourceContract, 'twse_a_k_json');
    expect(nav.status, EtfDataStatus.proxy);
  });

  test('proxy unavailable intraday NAV returns null instead of crashing',
      () async {
    final repository = Proxy00631LRepository(
      client: _FakeProxyHttpClient({
        '/api/etf/00631l/intraday-nav': jsonEncode({
          'symbol': '00631L',
          'sourceStatus': 'unavailable',
          'errorMessage': 'not configured',
        }),
      }),
    );

    expect(await repository.fetchIntradayNav(), isNull);
  });

  test('proxy repository maps holdings history summary payload', () async {
    final repository = Proxy00631LRepository(
      client: _FakeProxyHttpClient({
        '/api/etf/00631l/holdings/history/summary':
            jsonEncode(_holdingsHistorySummaryPayload()),
      }),
    );

    final history = await repository.fetchHoldingsHistorySummary();

    expect(history.status, EtfDataStatus.cached);
    expect(history.sourceStatusLabel, 'cached');
    expect(history.points, hasLength(2));
    expect(history.points.first.tradeDate, DateTime(2026, 6, 6));
    expect(history.points.first.txWeightPct, 160.20);
    expect(history.points.first.tsmcWeightPct, 36.80);
    expect(history.points.first.cashAndMarginPct, 66.10);
    expect(history.points.first.navPerUnit, 35.12);
    expect(history.points.first.outstandingUnits, 5200000000);
  });

  test('proxy repository maps intraday NAV history summary payload', () async {
    final repository = Proxy00631LRepository(
      client: _FakeProxyHttpClient({
        '/api/etf/00631l/intraday-nav/history/summary':
            jsonEncode(_intradayHistorySummaryPayload()),
      }),
    );

    final history = await repository.fetchIntradayNavHistorySummary();

    expect(history.status, EtfDataStatus.cached);
    expect(history.sourceStatusLabel, 'cached');
    expect(history.sampleCount, 3);
    expect(history.highestPremiumDiscountPct, 0.75);
    expect(history.lowestPremiumDiscountPct, -0.20);
    expect(history.averagePremiumDiscountPct, closeTo(0.30, 0.001));
    expect(history.lastDataTime, DateTime(2026, 6, 8, 13, 31));
    expect(history.points, hasLength(2));
    expect(history.points.first.premiumDiscountPct, 0.75);
    expect(history.points.first.sourceContract, 'twse_a_k_json');
  });

  test('proxy repository maps operations status payload', () async {
    final repository = Proxy00631LRepository(
      client: _FakeProxyHttpClient({
        '/api/etf/00631l/operations/status':
            jsonEncode(_operationsStatusPayload()),
      }),
    );

    final status = await repository.fetchOperationsStatus();

    expect(status.status, EtfDataStatus.cached);
    expect(status.sourceStatusLabel, 'cached');
    expect(status.intradaySourceMode, 'auto');
    expect(status.twseIntradayNavConfigured, isTrue);
    expect(status.holdingsHistoryItemCount, 1);
    expect(status.latestHoldingTradeDate, DateTime(2026, 6, 8));
    expect(status.intradaySampleCount, 12);
    expect(status.latestIntradayDataTime, DateTime(2026, 6, 8, 13, 31));
    expect(status.envFileExists, isTrue);
    expect(status.missingEnvKeys, isEmpty);
    expect(status.exportAvailable, isTrue);
    expect(status.backupDirReady, isTrue);
    expect(status.backupAvailable, isTrue);
    expect(status.reportAvailable, isTrue);
    expect(
        status.latestExportPath, contains('00631l_holdings_history_summary'));
    expect(status.latestBackupPath, contains('00631l_local_data_backup'));
    expect(status.latestReportPath, contains('00631l_daily_report'));
    expect(status.reportOverallStatus, 'WARN');
    expect(status.reportWarningCount, 2);
    expect(status.dailyCycleStatus, 'PASS');
    expect(status.dailyCycleWarningCount, 1);
    expect(status.collectorOneShotCommand, contains('00631l_collect_snapshot'));
  });

  test('cached repository falls back to mock when proxy is down', () async {
    final repository = Cached00631LRepository(
      primary: Proxy00631LRepository(client: _FailingProxyHttpClient()),
      fallback: Mock00631LRepository(),
    );

    final data = await repository.fetchLabData();

    expect(data.profile.status, EtfDataStatus.mock);
    expect(data.snapshot.status, EtfDataStatus.mock);
    expect(data.intradayNav?.status, EtfDataStatus.mock);
    expect(data.futuresQuote.status, EtfDataStatus.mock);
    expect(data.operationsStatus.backendDisconnected, isTrue);
    expect(data.operationsStatus.backendConnectionLabel,
        'backend disconnected');
    expect(data.operationsStatus.errorMessage, contains('backend down'));
  });
}

class _FakeProxyHttpClient implements ProxyHttpClient {
  const _FakeProxyHttpClient(this.responses);

  final Map<String, String> responses;

  @override
  Future<String> getString(
    Uri uri, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final response = responses[uri.path];
    if (response == null) {
      throw StateError('missing fake response for ${uri.path}');
    }
    return response;
  }
}

class _FailingProxyHttpClient implements ProxyHttpClient {
  @override
  Future<String> getString(
    Uri uri, {
    Duration timeout = const Duration(seconds: 8),
  }) {
    throw StateError('backend down');
  }
}

Map<String, Object?> _profilePayload() {
  return {
    'symbol': '00631L',
    'fundName': '元大台灣50單日正向2倍證券投資信託基金',
    'shortName': '元大台灣50正2',
    'trackingIndex': '臺灣50指數',
    'inceptionDate': '2014-10-23',
    'listingDate': '2014-10-31',
    'distributesIncome': false,
    'riskLevel': 'RR5',
    'managementFeePercent': 1.0,
    'custodianFeePercent': 0.04,
    'leverageObjective': '追蹤臺灣50指數單日正向2倍報酬',
    'exposurePolicy': '180%-220%',
    'primaryTradingMethod': '做多臺股期貨',
    'sourceUrl':
        'https://www.yuantaetfs.com/product/detail/00631L/Basic_information',
    'sourceStatus': 'official',
    'fetchedAt': '2026-06-08T10:15:00+08:00',
    'isStale': false,
    'errorMessage': null,
  };
}

Map<String, Object?> _holdingsPayload() {
  return {
    'tradeDate': '2026-06-05',
    'fundNetAssetValue': 189796511953,
    'navPerUnit': 36.56,
    'outstandingUnits': 5190848000,
    'assetValues': {
      'stock': 71056425000,
      'etf': 0,
      'bond': 0,
      'futures': 306587054000,
    },
    'cashHoldings': [
      {'item': '保證金', 'amount': 79303829574},
      {'item': '現金', 'amount': 26950925242},
      {'item': '附買回債券', 'amount': 19950000000},
      {'item': '應收利息', 'amount': 129448503},
      {'item': '應付申購預收款', 'amount': -1758961440},
    ],
    'stockHoldings': [
      {
        'code': '2330',
        'name': '台積電',
        'quantity': 30045000,
        'weightPct': 37.44,
      },
    ],
    'futuresHoldings': [
      {
        'code': 'TX',
        'name': '臺股期貨',
        'quantity': 33895,
        'weightPct': 161.53,
        'contractMonth': '202606',
      },
    ],
    'sourceStatus': 'official',
    'sourceUrl': 'https://www.yuantaetfs.com/product/detail/00631L/ratio',
    'fetchedAt': '2026-06-08T10:15:00+08:00',
    'sourceUpdatedAt': '2026-06-05T00:00:00+08:00',
    'sourceHash': 'fixture',
    'isStale': false,
    'errorMessage': null,
  };
}

Map<String, Object?> _intradayPayload() {
  return {
    'symbol': '00631L',
    'name': '元大台灣50正2',
    'outstandingUnits': 5190848000,
    'outstandingUnitsDelta': 0,
    'marketPrice': 36.72,
    'estimatedNav': 36.56,
    'estimatedPremiumDiscountPct': 0.44,
    'previousBusinessDayNav': 36.30,
    'previousBusinessDayNavText': '36.30',
    'dataDate': '2026-06-05',
    'dataTime': '2026-06-05T13:30:00+08:00',
    'targetType': '1',
    'userDelayMs': 15000,
    'sourceStatus': 'official',
    'sourceContract': 'twse_a_k_json',
    'sourceUrl': 'fixture://twse/nav',
    'fetchedAt': '2026-06-08T10:15:00+08:00',
    'isStale': false,
    'errorMessage': null,
  };
}

Map<String, Object?> _holdingsHistorySummaryPayload() {
  return {
    'items': [
      {
        'tradeDate': '2026-06-06',
        'txWeightPct': 160.20,
        'tsmcWeightPct': 36.80,
        'stockExposurePct': 38.10,
        'futuresExposurePct': 161.40,
        'cashAndMarginPct': 66.10,
        'navPerUnit': 35.12,
        'fundNetAssetValue': 188000000000,
        'outstandingUnits': 5200000000,
        'sourceStatus': 'official',
        'sourceHash': 'fixture-2',
      },
      {
        'tradeDate': '2026-06-05',
        'txWeightPct': 161.53,
        'tsmcWeightPct': 37.44,
        'stockExposurePct': 37.44,
        'futuresExposurePct': 161.53,
        'cashAndMarginPct': 66.49,
        'navPerUnit': 36.56,
        'fundNetAssetValue': 189796511953,
        'outstandingUnits': 5190848000,
        'sourceStatus': 'official',
        'sourceHash': 'fixture-1',
      },
    ],
    'sourceStatus': 'cached',
    'sourceContract': 'local_jsonl_history_summary',
    'sourceUrl': 'local://00631l-holdings-history',
    'fetchedAt': '2026-06-08T10:15:00+08:00',
    'sourceUpdatedAt': '2026-06-06T00:00:00+08:00',
    'dataTime': '2026-06-06T00:00:00+08:00',
    'isStale': false,
    'errorMessage': null,
  };
}

Map<String, Object?> _intradayHistorySummaryPayload() {
  return {
    'items': [
      {
        'dataTime': '2026-06-08T13:31:00+08:00',
        'marketPrice': 33.8,
        'estimatedNav': 33.55,
        'premiumDiscountPct': 0.75,
        'sourceContract': 'twse_a_k_json',
      },
      {
        'dataTime': '2026-06-08T09:01:00+08:00',
        'marketPrice': 33.1,
        'estimatedNav': 33.16,
        'premiumDiscountPct': -0.20,
        'sourceContract': 'twse_a_k_json',
      },
    ],
    'sampleCount': 3,
    'highestPremiumDiscountPct': 0.75,
    'lowestPremiumDiscountPct': -0.20,
    'averagePremiumDiscountPct': 0.30,
    'firstDataTime': '2026-06-08T09:01:00+08:00',
    'lastDataTime': '2026-06-08T13:31:00+08:00',
    'latestMarketPrice': 33.8,
    'latestEstimatedNav': 33.55,
    'date': '2026-06-08',
    'sourceStatus': 'cached',
    'sourceContract': 'local_jsonl_intraday_nav_history_summary',
    'sourceUrl': 'local://00631l-intraday-nav-history',
    'fetchedAt': '2026-06-08T13:32:00+08:00',
    'sourceUpdatedAt': '2026-06-08T13:31:00+08:00',
    'dataTime': '2026-06-08T13:31:00+08:00',
    'isStale': false,
    'errorMessage': null,
  };
}

Map<String, Object?> _operationsStatusPayload() {
  return {
    'sourceStatus': 'cached',
    'sourceContract': '00631l_operations_status',
    'sourceUrl': 'local://00631l-operations-status',
    'fetchedAt': '2026-06-08T13:32:00+08:00',
    'sourceUpdatedAt': '2026-06-08T13:31:00+08:00',
    'dataTime': '2026-06-08T13:31:00+08:00',
    'isStale': false,
    'errorMessage': null,
    'config': {
      'intradaySourceMode': 'auto',
      'twseIntradayNavConfigured': true,
      'yuantaIntradayNavConfigured': true,
      'envFileExists': true,
      'missingKeys': [],
      'optionalMissingKeys': [],
      'dataDirReady': true,
      'exportDirReady': true,
      'backupDirReady': true,
      'profileCacheSeconds': 86400,
      'holdingsCacheSeconds': 600,
      'intradayNavCacheSeconds': 15,
      'holdingsHistoryPathConfigured': true,
      'intradayNavHistoryPathConfigured': true,
      'historyExportDir': 'backend/exports',
      'dailyCycleStatusPath': 'backend/data/00631l_daily_cycle_status.json',
      'backupDir': 'backend/backups',
    },
    'holdingsHistory': {
      'sourceStatus': 'cached',
      'sourceContract': 'local_jsonl_history_summary',
      'itemCount': 1,
      'latestTradeDate': '2026-06-08',
      'sourceUpdatedAt': '2026-06-08T00:00:00+08:00',
      'isStale': false,
      'errorMessage': null,
    },
    'intradayNavHistory': {
      'sourceStatus': 'cached',
      'sourceContract': 'local_jsonl_intraday_nav_history_summary',
      'sampleCount': 12,
      'latestDataTime': '2026-06-08T13:31:00+08:00',
      'date': '2026-06-08',
      'sourceUpdatedAt': '2026-06-08T13:31:00+08:00',
      'isStale': false,
      'errorMessage': null,
    },
    'export': {
      'sourceStatus': 'cached',
      'sourceContract': '00631l_history_export_status',
      'available': true,
      'outputDir': 'backend/exports',
      'latestFile': 'backend/exports/00631l_holdings_history_summary.csv',
      'latestUpdatedAt': '2026-06-08T13:35:00+08:00',
      'files': [],
      'errorMessage': null,
    },
    'backup': {
      'sourceStatus': 'cached',
      'sourceContract': '00631l_backup_status',
      'available': true,
      'backupDir': 'backend/backups',
      'latestFile':
          'backend/backups/00631l_local_data_backup_20260608_100000Z.zip',
      'latestUpdatedAt': '2026-06-08T13:36:00+08:00',
      'errorMessage': null,
    },
    'report': {
      'sourceStatus': 'cached',
      'sourceContract': '00631l_daily_markdown_report',
      'generatedAt': '2026-06-08T13:37:00+08:00',
      'reportPath': 'backend/reports/00631l_daily_report_20260608T053700Z.md',
      'overallStatus': 'WARN',
      'warningCount': 2,
      'failureCount': 0,
      'warnings': ['collect returned WARN', 'smoke returned WARN'],
      'failures': [],
      'isStale': false,
      'errorMessage': null,
    },
    'dailyCycle': {
      'sourceStatus': 'cached',
      'sourceContract': '00631l_daily_cycle_status',
      'available': true,
      'path': 'backend/data/00631l_daily_cycle_status.json',
      'overallStatus': 'PASS',
      'startedAt': '2026-06-08T13:30:00+08:00',
      'finishedAt': '2026-06-08T13:35:00+08:00',
      'warningCount': 1,
      'failureCount': 0,
      'errorMessage': null,
    },
    'statusSummary': {
      'operations': 'cached',
      'holdingsHistory': 'cached',
      'intradayHistory': 'cached',
      'export': 'cached',
      'backup': 'cached',
      'report': 'cached',
      'dailyCycle': 'cached',
      'env': 'cached',
    },
    'collector': {
      'oneShotCommand': 'scripts\\00631l_collect_snapshot.cmd --samples 1',
      'intradayCommand':
          'scripts\\00631l_collect_snapshot.cmd --skip-profile --skip-holdings --samples 20 --interval-seconds 15',
    },
  };
}
