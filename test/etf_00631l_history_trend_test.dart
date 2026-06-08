import 'package:flutter_test/flutter_test.dart';
import 'package:longterm_stock_research_assistant/models/leveraged_etf_lab.dart';

void main() {
  test('holdings history trend summary computes day and range changes', () {
    final history = EtfHoldingsHistory(
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

    final summary = history.trendSummary();
    final tx = summary.changeLines.firstWhere(
      (line) => line.key == 'txWeightPct',
    );
    final nav = summary.changeLines.firstWhere(
      (line) => line.key == 'navPerUnit',
    );

    expect(summary.recentSeven, hasLength(2));
    expect(summary.latest?.tradeDate, DateTime(2026, 6, 6));
    expect(tx.dayOverDayChange, closeTo(6.00, 0.001));
    expect(tx.firstToLatestChange, closeTo(6.00, 0.001));
    expect(nav.dayOverDayChange, closeTo(-1.44, 0.001));
  });
}
