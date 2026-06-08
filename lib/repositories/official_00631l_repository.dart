import '../models/leveraged_etf_lab.dart';

abstract class Official00631LRepository {
  Future<LeveragedEtfProfile> fetchProfile();

  Future<EtfDailyHoldingSnapshot> fetchDailySnapshot();

  Future<EtfIntradayNav?> fetchIntradayNav();

  Future<FuturesQuote> fetchFuturesQuote();

  Future<EtfHoldingsHistory> fetchHoldingsHistorySummary({
    int limit = 30,
  }) async {
    return EtfHoldingsHistory.empty(
      sourceStatusLabel: 'unavailable',
      status: EtfDataStatus.error,
    );
  }

  Future<Etf00631LLabData> fetchLabData() async {
    final profile = await fetchProfile();
    final snapshot = await fetchDailySnapshot();
    final intradayNav = await fetchIntradayNav();
    final futuresQuote = await fetchFuturesQuote();
    final history = await _fetchHistorySafely();
    final now = DateTime.now();

    return Etf00631LLabData(
      profile: profile,
      snapshot: snapshot,
      intradayNav: intradayNav,
      futuresQuote: futuresQuote,
      holdingsHistory: history,
      analysis: EtfAnalysisSummary.fromSnapshot(
        snapshot: snapshot,
        intradayNav: intradayNav,
        now: now,
      ),
      lastFetchedAt: now,
    );
  }

  Future<EtfHoldingsHistory> _fetchHistorySafely() async {
    try {
      return await fetchHoldingsHistorySummary();
    } catch (error) {
      return EtfHoldingsHistory.empty(
        sourceStatusLabel: 'error',
        status: EtfDataStatus.error,
        errorMessage: error.toString(),
      );
    }
  }
}

class RepositoryFetchException implements Exception {
  const RepositoryFetchException(this.message);

  final String message;

  @override
  String toString() => message;
}
