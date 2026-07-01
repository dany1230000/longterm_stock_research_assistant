import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:longterm_stock_research_assistant/models/leveraged_etf_lab.dart';
import 'package:longterm_stock_research_assistant/repositories/yuanta_00631l_parser.dart';

void main() {
  final fetchedAt = DateTime(2026, 6, 8, 10, 15);

  test('parses Yuanta 00631L daily holding fixture', () {
    final source = File('test/fixtures/00631l_yuanta_ratio_fixture.txt')
        .readAsStringSync();
    final snapshot = Yuanta00631LParser.parseDailyHoldingSnapshot(
      source,
      lastFetchedAt: fetchedAt,
      status: EtfDataStatus.mock,
    );

    expect(snapshot.tradeDate, DateTime(2026, 6, 5));
    expect(snapshot.fundNetAssetValue, 189796511953);
    expect(snapshot.navPerUnit, 36.56);
    expect(snapshot.outstandingUnits, 5190848000);
    expect(snapshot.assetSummary.stock, 71056425000);
    expect(snapshot.assetSummary.futures, 306587054000);
  });

  test('parses stock futures and cash holding lines', () {
    final source = File('test/fixtures/00631l_yuanta_ratio_fixture.txt')
        .readAsStringSync();
    final snapshot = Yuanta00631LParser.parseDailyHoldingSnapshot(
      source,
      lastFetchedAt: fetchedAt,
      status: EtfDataStatus.mock,
    );

    final tsmc = snapshot.stockHoldings.single;
    expect(tsmc.code, '2330');
    expect(tsmc.name, '台積電');
    expect(tsmc.quantity, 30045000);
    expect(tsmc.weightPct, 37.44);

    final tx = snapshot.futuresHoldings.single;
    expect(tx.code, 'TX');
    expect(tx.name, '臺股期貨');
    expect(tx.quantity, 33895);
    expect(tx.weightPct, 161.53);
    expect(tx.contractMonth, '202606');

    final cashItems = snapshot.cashHoldings.map((line) => line.item).toSet();
    expect(
      cashItems.containsAll({
        '保證金',
        '現金',
        '附買回債券',
        '應收利息',
        '應付申購預收款',
      }),
      isTrue,
    );
    expect(
      snapshot.cashHoldings
          .singleWhere((line) => line.item == '應付申購預收款')
          .amount,
      -1758961440,
    );
  });

  test('maps TWSE intraday NAV JSON a-k fields for 00631L', () {
    final source = File('test/fixtures/00631l_twse_intraday_nav_fixture.json')
        .readAsStringSync();
    final nav = Yuanta00631LParser.parseTwseIntradayNavJson(
      source,
      lastFetchedAt: fetchedAt,
      status: EtfDataStatus.mock,
    );

    expect(nav, isNotNull);
    expect(nav!.symbol, '00631L');
    expect(nav.name, '元大台灣50正2');
    expect(nav.outstandingUnits, 5190848000);
    expect(nav.outstandingUnitsDelta, 0);
    expect(nav.marketPrice, 36.72);
    expect(nav.estimatedNav, 36.56);
    expect(nav.estimatedPremiumDiscountPct, 0.44);
    expect(nav.previousBusinessDayNav, 36.30);
    expect(nav.dataDate, DateTime(2026, 6, 5));
    expect(nav.dataTime, DateTime(2026, 6, 5, 13, 30));
    expect(nav.targetType, '1');
    expect(nav.userDelayMs, 15000);
    expect(nav.sourceContract, 'twse_a_k_json');
  });

  test('derives TWSE intraday premium when a-k g field is blank', () {
    final source = File('test/fixtures/00631l_twse_intraday_nav_fixture.json')
        .readAsStringSync();
    final payload = jsonDecode(source) as Map<String, dynamic>;
    final msgArray = payload['msgArray'] as List<dynamic>;
    for (final row in msgArray.whereType<Map<String, dynamic>>()) {
      if (row['a'] == '00631L') {
        row['e'] = '39.60';
        row['f'] = '39.48';
        row['g'] = '';
      }
    }

    final nav = Yuanta00631LParser.parseTwseIntradayNavJson(
      jsonEncode(payload),
      lastFetchedAt: fetchedAt,
      status: EtfDataStatus.mock,
    );

    expect(nav, isNotNull);
    expect(nav!.estimatedPremiumDiscountPct, closeTo(0.30, 0.001));
    expect(nav.resolvedPremiumDiscountPct, closeTo(0.30, 0.001));
  });

  test('EtfIntradayNav resolves premium from market price and estimated NAV',
      () {
    final nav = EtfIntradayNav(
      symbol: '00631L',
      name: '00631L',
      outstandingUnits: null,
      outstandingUnitsDelta: null,
      marketPrice: 39.48,
      estimatedNav: 39.48,
      estimatedPremiumDiscountPct: null,
      previousBusinessDayNav: null,
      previousBusinessDayNavText: '',
      dataDate: DateTime(2026, 7),
      dataTime: DateTime(2026, 7, 1, 13, 30, 45),
      targetType: '1',
      userDelayMs: 15000,
      sourceContract: 'twse_a_k_json',
      isStale: false,
      status: EtfDataStatus.official,
      lastFetchedAt: fetchedAt,
    );

    expect(nav.resolvedPremiumDiscountPct, closeTo(0, 0.001));
    expect(nav.premiumDiscountAssessment.level, PremiumDiscountLevel.normal);
  });

  test('missing source data does not crash parsers', () {
    final snapshot = Yuanta00631LParser.parseDailyHoldingSnapshot(
      'Trade Date:',
      lastFetchedAt: fetchedAt,
    );
    final nav = Yuanta00631LParser.parseTwseIntradayNavJson(
      '{"msgArray":[],"userDelay":"15000"}',
      lastFetchedAt: fetchedAt,
    );

    expect(snapshot.status, EtfDataStatus.error);
    expect(snapshot.errorMessage, isNotNull);
    expect(nav, isNull);
  });
}
