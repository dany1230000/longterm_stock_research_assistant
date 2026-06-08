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
