import '../models/leveraged_etf_lab.dart';

abstract class Official00631LRepository {
  Future<LeveragedEtfProfile> fetchProfile();

  Future<EtfDailyHoldingSnapshot> fetchDailySnapshot();

  Future<EtfIntradayNav?> fetchIntradayNav();

  Future<FuturesQuote> fetchFuturesQuote();

  Future<Etf00631LLabData> fetchLabData() async {
    final profile = await fetchProfile();
    final snapshot = await fetchDailySnapshot();
    final intradayNav = await fetchIntradayNav();
    final futuresQuote = await fetchFuturesQuote();
    final now = DateTime.now();

    return Etf00631LLabData(
      profile: profile,
      snapshot: snapshot,
      intradayNav: intradayNav,
      futuresQuote: futuresQuote,
      analysis: EtfAnalysisSummary.fromSnapshot(
        snapshot: snapshot,
        intradayNav: intradayNav,
        now: now,
      ),
      lastFetchedAt: now,
    );
  }
}

class RepositoryFetchException implements Exception {
  const RepositoryFetchException(this.message);

  final String message;

  @override
  String toString() => message;
}
