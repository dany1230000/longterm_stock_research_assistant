import '../models/leveraged_etf_lab.dart';
import 'mock_00631l_repository.dart';
import 'official_00631l_repository.dart';

class Cached00631LRepository extends Official00631LRepository {
  Cached00631LRepository({
    required Official00631LRepository primary,
    Official00631LRepository? fallback,
  })  : _primary = primary,
        _fallback = fallback ?? Mock00631LRepository();

  final Official00631LRepository _primary;
  final Official00631LRepository _fallback;

  LeveragedEtfProfile? _profileCache;
  EtfDailyHoldingSnapshot? _snapshotCache;
  EtfIntradayNav? _intradayNavCache;
  FuturesQuote? _futuresQuoteCache;

  @override
  Future<LeveragedEtfProfile> fetchProfile() async {
    try {
      final profile = await _primary.fetchProfile();
      _profileCache = profile;
      return profile;
    } catch (_) {
      final cached = _profileCache;
      if (cached != null) {
        return _cachedProfile(cached);
      }
      return _fallback.fetchProfile();
    }
  }

  @override
  Future<EtfDailyHoldingSnapshot> fetchDailySnapshot() async {
    try {
      final snapshot = await _primary.fetchDailySnapshot();
      _snapshotCache = snapshot;
      return snapshot;
    } catch (_) {
      final cached = _snapshotCache;
      if (cached != null) {
        return _cachedSnapshot(cached);
      }
      return _fallback.fetchDailySnapshot();
    }
  }

  @override
  Future<EtfIntradayNav?> fetchIntradayNav() async {
    try {
      final intradayNav = await _primary.fetchIntradayNav();
      _intradayNavCache = intradayNav;
      return intradayNav;
    } catch (_) {
      final cached = _intradayNavCache;
      if (cached != null) {
        return _cachedIntradayNav(cached);
      }
      return _fallback.fetchIntradayNav();
    }
  }

  @override
  Future<FuturesQuote> fetchFuturesQuote() async {
    try {
      final quote = await _primary.fetchFuturesQuote();
      _futuresQuoteCache = quote;
      return quote;
    } catch (_) {
      final cached = _futuresQuoteCache;
      if (cached != null) {
        return _cachedFuturesQuote(cached);
      }
      return _fallback.fetchFuturesQuote();
    }
  }
}

LeveragedEtfProfile _cachedProfile(LeveragedEtfProfile profile) {
  return LeveragedEtfProfile(
    symbol: profile.symbol,
    fundName: profile.fundName,
    shortName: profile.shortName,
    trackingIndex: profile.trackingIndex,
    inceptionDate: profile.inceptionDate,
    listingDate: profile.listingDate,
    distributesIncome: profile.distributesIncome,
    riskLevel: profile.riskLevel,
    managementFeePercent: profile.managementFeePercent,
    custodianFeePercent: profile.custodianFeePercent,
    leverageObjective: profile.leverageObjective,
    exposurePolicy: profile.exposurePolicy,
    primaryTradingMethod: profile.primaryTradingMethod,
    sourceUrl: profile.sourceUrl,
    status: EtfDataStatus.cached,
    lastFetchedAt: profile.lastFetchedAt,
  );
}

EtfDailyHoldingSnapshot _cachedSnapshot(EtfDailyHoldingSnapshot snapshot) {
  return EtfDailyHoldingSnapshot(
    tradeDate: snapshot.tradeDate,
    fundNetAssetValue: snapshot.fundNetAssetValue,
    navPerUnit: snapshot.navPerUnit,
    outstandingUnits: snapshot.outstandingUnits,
    assetSummary: snapshot.assetSummary,
    cashHoldings: snapshot.cashHoldings,
    stockHoldings: snapshot.stockHoldings,
    futuresHoldings: snapshot.futuresHoldings,
    status: EtfDataStatus.cached,
    lastFetchedAt: snapshot.lastFetchedAt,
    sourceUpdatedAt: snapshot.sourceUpdatedAt,
    sourceHash: snapshot.sourceHash,
    errorMessage: snapshot.errorMessage,
  );
}

EtfIntradayNav _cachedIntradayNav(EtfIntradayNav nav) {
  return EtfIntradayNav(
    symbol: nav.symbol,
    name: nav.name,
    outstandingUnits: nav.outstandingUnits,
    outstandingUnitsDelta: nav.outstandingUnitsDelta,
    marketPrice: nav.marketPrice,
    estimatedNav: nav.estimatedNav,
    estimatedPremiumDiscountPct: nav.estimatedPremiumDiscountPct,
    previousBusinessDayNav: nav.previousBusinessDayNav,
    previousBusinessDayNavText: nav.previousBusinessDayNavText,
    dataDate: nav.dataDate,
    dataTime: nav.dataTime,
    targetType: nav.targetType,
    userDelayMs: nav.userDelayMs,
    sourceContract: nav.sourceContract,
    isStale: nav.isStale,
    status: EtfDataStatus.cached,
    lastFetchedAt: nav.lastFetchedAt,
  );
}

FuturesQuote _cachedFuturesQuote(FuturesQuote quote) {
  return FuturesQuote(
    symbol: quote.symbol,
    contractMonth: quote.contractMonth,
    txPrice: quote.txPrice,
    weightedIndex: quote.weightedIndex,
    nightSessionChange: quote.nightSessionChange,
    status: EtfDataStatus.cached,
    lastFetchedAt: quote.lastFetchedAt,
    errorMessage: quote.errorMessage,
  );
}
