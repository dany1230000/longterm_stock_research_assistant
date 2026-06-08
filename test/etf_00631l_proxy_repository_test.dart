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
