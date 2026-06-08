import 'package:flutter_test/flutter_test.dart';
import 'package:longterm_stock_research_assistant/models/leveraged_etf_lab.dart';

void main() {
  HoldingsChangeAssessment assess({
    required List<EtfHoldingsHistoryPoint> points,
    DateTime? snapshotTradeDate,
    DateTime? now,
  }) {
    return HoldingsChangeAssessment.evaluate(
      history: EtfHoldingsHistory(
        points: points,
        status: EtfDataStatus.cached,
        sourceStatusLabel: 'cached',
        sourceUrl: 'local://history',
        lastFetchedAt: DateTime(2026, 6, 9, 10, 15),
        isStale: false,
      ),
      snapshot: _snapshot(snapshotTradeDate ?? DateTime(2026, 6, 9)),
      now: now ?? DateTime(2026, 6, 9, 10, 15),
    );
  }

  test('holdings change notices require enough history', () {
    final assessment = assess(points: const []);

    expect(assessment.statusLabel, 'unavailable');
    expect(
        assessment.notices.single.level, HoldingChangeNoticeLevel.unavailable);
    expect(assessment.notices.single.title, '尚無足夠歷史紀錄');
  });

  test('holdings change notices detect TX weight change', () {
    final assessment = assess(
      points: [
        _point(DateTime(2026, 6, 9), txWeightPct: 160),
        _point(DateTime(2026, 6, 8), txWeightPct: 154),
      ],
    );

    expect(assessment.statusLabel, 'elevated');
    expect(
      assessment.notices.any((notice) => notice.title == 'TX 權重變化較大'),
      isTrue,
    );
  });

  test('holdings change notices detect TSMC weight change', () {
    final assessment = assess(
      points: [
        _point(DateTime(2026, 6, 9), tsmcWeightPct: 39),
        _point(DateTime(2026, 6, 8), tsmcWeightPct: 36.5),
      ],
    );

    expect(assessment.statusLabel, 'watch');
    expect(
      assessment.notices.any((notice) => notice.title == '台積電權重變化較大'),
      isTrue,
    );
  });

  test('holdings change notices detect cash and margin increase', () {
    final assessment = assess(
      points: [
        _point(DateTime(2026, 6, 9), cashAndMarginPct: 70),
        _point(DateTime(2026, 6, 8), cashAndMarginPct: 63),
      ],
    );

    expect(assessment.statusLabel, 'watch');
    expect(
      assessment.notices.any((notice) => notice.title == '現金與保證金比例上升'),
      isTrue,
    );
  });

  test('holdings change notices detect futures exposure change', () {
    final assessment = assess(
      points: [
        _point(DateTime(2026, 6, 9), futuresExposurePct: 172),
        _point(DateTime(2026, 6, 8), futuresExposurePct: 160),
      ],
    );

    expect(assessment.statusLabel, 'watch');
    expect(
      assessment.notices.any((notice) => notice.title == '期貨資產比例變化較大'),
      isTrue,
    );
  });

  test('holdings change notices detect total exposure outside range', () {
    final assessment = assess(
      points: [
        _point(
          DateTime(2026, 6, 9),
          stockExposurePct: 35,
          futuresExposurePct: 130,
        ),
        _point(DateTime(2026, 6, 8)),
      ],
    );

    expect(assessment.statusLabel, 'elevated');
    expect(
      assessment.notices.any((notice) => notice.title == '合計曝險超出參考區間'),
      isTrue,
    );
  });

  test('holdings change notices detect stale official holdings', () {
    final assessment = assess(
      points: [
        _point(DateTime(2026, 6, 9)),
        _point(DateTime(2026, 6, 8)),
      ],
      snapshotTradeDate: DateTime(2026, 6, 5),
      now: DateTime(2026, 6, 9, 10, 15),
    );

    expect(assessment.statusLabel, 'stale');
    expect(
      assessment.notices.any((notice) => notice.title == '官方內容物可能過期'),
      isTrue,
    );
  });
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

EtfHoldingsHistoryPoint _point(
  DateTime tradeDate, {
  double txWeightPct = 160,
  double tsmcWeightPct = 37,
  double stockExposurePct = 40,
  double futuresExposurePct = 160,
  double cashAndMarginPct = 60,
}) {
  return EtfHoldingsHistoryPoint(
    tradeDate: tradeDate,
    txWeightPct: txWeightPct,
    tsmcWeightPct: tsmcWeightPct,
    stockExposurePct: stockExposurePct,
    futuresExposurePct: futuresExposurePct,
    cashAndMarginPct: cashAndMarginPct,
    navPerUnit: 35,
    fundNetAssetValue: 100,
    outstandingUnits: 10,
    status: EtfDataStatus.proxy,
    sourceHash: tradeDate.toIso8601String(),
  );
}
