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

  Future<EtfIntradayNavHistorySummary> fetchIntradayNavHistorySummary() async {
    return EtfIntradayNavHistorySummary.empty(
      sourceStatusLabel: 'unavailable',
      status: EtfDataStatus.error,
    );
  }

  Future<EtfOperationsStatus> fetchOperationsStatus() async {
    return EtfOperationsStatus.empty(
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
    final intradayHistory = await _fetchIntradayHistorySafely();
    final operationsStatus = await _fetchOperationsStatusSafely();
    final now = DateTime.now();

    return Etf00631LLabData(
      profile: profile,
      snapshot: snapshot,
      intradayNav: intradayNav,
      futuresQuote: futuresQuote,
      holdingsHistory: history,
      intradayNavHistory: intradayHistory,
      operationsStatus: operationsStatus,
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

  Future<EtfIntradayNavHistorySummary> _fetchIntradayHistorySafely() async {
    try {
      return await fetchIntradayNavHistorySummary();
    } catch (error) {
      return EtfIntradayNavHistorySummary.empty(
        sourceStatusLabel: 'error',
        status: EtfDataStatus.error,
        errorMessage: error.toString(),
      );
    }
  }

  Future<EtfOperationsStatus> _fetchOperationsStatusSafely() async {
    try {
      return await fetchOperationsStatus();
    } catch (error) {
      return EtfOperationsStatus.empty(
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
