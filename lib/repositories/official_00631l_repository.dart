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

  Future<EtfAiAnalysisSummary> fetchAiAnalysisSummary() async {
    return EtfAiAnalysisSummary.mockFallback();
  }

  Future<EtfPriceHistory> fetchPriceHistory({int limit = 5000}) async {
    return EtfPriceHistory.empty(
      sourceStatusLabel: 'unavailable',
      status: EtfDataStatus.error,
    );
  }

  Future<EtfPriceHistory> fetchEtfPriceHistory(
    String code, {
    int limit = 5000,
  }) async {
    final normalized = code.trim().toUpperCase();
    if (normalized == '00631L') {
      return fetchPriceHistory(limit: limit);
    }
    return EtfPriceHistory.empty(
      code: normalized,
      name: normalized,
      sourceStatusLabel: 'unavailable',
      status: EtfDataStatus.error,
      errorMessage: 'Price history is unavailable for $normalized.',
    );
  }

  Future<EtfCatalog> fetchEtfCatalog() async {
    return EtfCatalog.empty(
      sourceStatusLabel: 'unavailable',
      status: EtfDataStatus.error,
    );
  }

  Future<EtfPriceHistoryGapDetails> fetchEtfPriceHistoryGaps({
    String? reason,
    int limit = 50,
    bool fromCatalog = true,
  }) async {
    return EtfPriceHistoryGapDetails.empty(
      sourceStatusLabel: 'unavailable',
      status: EtfDataStatus.error,
      reason: reason,
      limit: limit,
    );
  }

  Future<Etf00631LLabData> fetchFastLabData() async {
    final profileFuture = fetchProfile();
    final snapshotFuture = fetchDailySnapshot();
    final intradayNavFuture = _fetchIntradayNavSafely();
    final futuresQuoteFuture = fetchFuturesQuote();

    final profile = await profileFuture;
    final snapshot = await snapshotFuture;
    final intradayNav = await intradayNavFuture;
    final futuresQuote = await futuresQuoteFuture;
    final now = DateTime.now();

    return Etf00631LLabData(
      profile: profile,
      snapshot: snapshot,
      intradayNav: intradayNav,
      futuresQuote: futuresQuote,
      holdingsHistory: EtfHoldingsHistory.empty(
        lastFetchedAt: now,
        status: EtfDataStatus.cached,
        sourceStatusLabel: 'deferred',
      ),
      intradayNavHistory: EtfIntradayNavHistorySummary.empty(
        lastFetchedAt: now,
        status: EtfDataStatus.cached,
        sourceStatusLabel: 'deferred',
      ),
      priceHistory: EtfPriceHistory.empty(
        lastFetchedAt: now,
        status: EtfDataStatus.cached,
        sourceStatusLabel: 'deferred',
      ),
      operationsStatus: EtfOperationsStatus.empty(
        lastFetchedAt: now,
        status: EtfDataStatus.cached,
        sourceStatusLabel: 'deferred',
      ),
      analysis: EtfAnalysisSummary.fromSnapshot(
        snapshot: snapshot,
        intradayNav: intradayNav,
        now: now,
      ),
      aiAnalysis: EtfAiAnalysisSummary.mockFallback(now: now).asCached(),
      etfCatalog: EtfCatalog.empty(
        lastFetchedAt: now,
        status: EtfDataStatus.cached,
        sourceStatusLabel: 'deferred',
      ),
      lastFetchedAt: now,
    );
  }

  Future<Etf00631LLabData> fetchLabData() async {
    final profileFuture = fetchProfile();
    final snapshotFuture = fetchDailySnapshot();
    final intradayNavFuture = fetchIntradayNav();
    final futuresQuoteFuture = fetchFuturesQuote();
    final historyFuture = _fetchHistorySafely();
    final intradayHistoryFuture = _fetchIntradayHistorySafely();
    final operationsStatusFuture = _fetchOperationsStatusSafely();
    final aiAnalysisFuture = _fetchAiAnalysisSafely();
    final priceHistoryFuture = _fetchPriceHistorySafely();
    final etfCatalogFuture = _fetchEtfCatalogSafely();

    final profile = await profileFuture;
    final snapshot = await snapshotFuture;
    final intradayNav = await intradayNavFuture;
    final futuresQuote = await futuresQuoteFuture;
    final history = await historyFuture;
    final intradayHistory = await intradayHistoryFuture;
    final operationsStatus = await operationsStatusFuture;
    final aiAnalysis = await aiAnalysisFuture;
    final priceHistory = await priceHistoryFuture;
    final etfCatalog = await etfCatalogFuture;
    final now = DateTime.now();

    return Etf00631LLabData(
      profile: profile,
      snapshot: snapshot,
      intradayNav: intradayNav,
      futuresQuote: futuresQuote,
      holdingsHistory: history,
      intradayNavHistory: intradayHistory,
      priceHistory: priceHistory,
      operationsStatus: operationsStatus,
      analysis: EtfAnalysisSummary.fromSnapshot(
        snapshot: snapshot,
        intradayNav: intradayNav,
        now: now,
      ),
      aiAnalysis: aiAnalysis,
      etfCatalog: etfCatalog,
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

  Future<EtfIntradayNav?> _fetchIntradayNavSafely() async {
    try {
      return await fetchIntradayNav();
    } catch (_) {
      return null;
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

  Future<EtfAiAnalysisSummary> _fetchAiAnalysisSafely() async {
    try {
      return await fetchAiAnalysisSummary();
    } catch (_) {
      return EtfAiAnalysisSummary.mockFallback().asCached();
    }
  }

  Future<EtfPriceHistory> _fetchPriceHistorySafely() async {
    try {
      return await fetchPriceHistory();
    } catch (error) {
      return EtfPriceHistory.empty(
        sourceStatusLabel: 'error',
        status: EtfDataStatus.error,
        errorMessage: error.toString(),
      );
    }
  }

  Future<EtfCatalog> _fetchEtfCatalogSafely() async {
    try {
      return await fetchEtfCatalog();
    } catch (error) {
      return EtfCatalog.empty(
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
