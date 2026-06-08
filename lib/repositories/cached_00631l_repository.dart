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
  EtfHoldingsHistory? _holdingsHistoryCache;
  EtfIntradayNavHistorySummary? _intradayNavHistoryCache;
  EtfOperationsStatus? _operationsStatusCache;

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

  @override
  Future<EtfHoldingsHistory> fetchHoldingsHistorySummary({
    int limit = 30,
  }) async {
    try {
      final history = await _primary.fetchHoldingsHistorySummary(limit: limit);
      _holdingsHistoryCache = history;
      return history;
    } catch (_) {
      final cached = _holdingsHistoryCache;
      if (cached != null) {
        return _cachedHistory(cached);
      }
      return _fallback.fetchHoldingsHistorySummary(limit: limit);
    }
  }

  @override
  Future<EtfIntradayNavHistorySummary> fetchIntradayNavHistorySummary() async {
    try {
      final history = await _primary.fetchIntradayNavHistorySummary();
      _intradayNavHistoryCache = history;
      return history;
    } catch (_) {
      final cached = _intradayNavHistoryCache;
      if (cached != null) {
        return _cachedIntradayHistory(cached);
      }
      return _fallback.fetchIntradayNavHistorySummary();
    }
  }

  @override
  Future<EtfOperationsStatus> fetchOperationsStatus() async {
    try {
      final status = await _primary.fetchOperationsStatus();
      _operationsStatusCache = status;
      return status;
    } catch (_) {
      final cached = _operationsStatusCache;
      if (cached != null) {
        return _cachedOperationsStatus(cached);
      }
      return _fallback.fetchOperationsStatus();
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

EtfHoldingsHistory _cachedHistory(EtfHoldingsHistory history) {
  return EtfHoldingsHistory(
    points: history.points,
    status: EtfDataStatus.cached,
    sourceStatusLabel: 'cached',
    sourceUrl: history.sourceUrl,
    lastFetchedAt: history.lastFetchedAt,
    isStale: history.isStale,
    errorMessage: history.errorMessage,
  );
}

EtfIntradayNavHistorySummary _cachedIntradayHistory(
  EtfIntradayNavHistorySummary history,
) {
  return EtfIntradayNavHistorySummary(
    points: history.points,
    sampleCount: history.sampleCount,
    highestPremiumDiscountPct: history.highestPremiumDiscountPct,
    lowestPremiumDiscountPct: history.lowestPremiumDiscountPct,
    averagePremiumDiscountPct: history.averagePremiumDiscountPct,
    firstDataTime: history.firstDataTime,
    lastDataTime: history.lastDataTime,
    latestMarketPrice: history.latestMarketPrice,
    latestEstimatedNav: history.latestEstimatedNav,
    date: history.date,
    status: EtfDataStatus.cached,
    sourceStatusLabel: 'cached',
    sourceUrl: history.sourceUrl,
    lastFetchedAt: history.lastFetchedAt,
    isStale: history.isStale,
    errorMessage: history.errorMessage,
  );
}

EtfOperationsStatus _cachedOperationsStatus(EtfOperationsStatus status) {
  return EtfOperationsStatus(
    status: EtfDataStatus.cached,
    sourceStatusLabel: 'cached',
    sourceContract: status.sourceContract,
    sourceUrl: status.sourceUrl,
    lastFetchedAt: status.lastFetchedAt,
    sourceUpdatedAt: status.sourceUpdatedAt,
    isStale: status.isStale,
    intradaySourceMode: status.intradaySourceMode,
    twseIntradayNavConfigured: status.twseIntradayNavConfigured,
    yuantaIntradayNavConfigured: status.yuantaIntradayNavConfigured,
    holdingsHistoryStatus: status.holdingsHistoryStatus,
    holdingsHistoryItemCount: status.holdingsHistoryItemCount,
    latestHoldingTradeDate: status.latestHoldingTradeDate,
    intradayHistoryStatus: status.intradayHistoryStatus,
    intradaySampleCount: status.intradaySampleCount,
    latestIntradayDataTime: status.latestIntradayDataTime,
    intradayHistoryDate: status.intradayHistoryDate,
    collectorOneShotCommand: status.collectorOneShotCommand,
    collectorIntradayCommand: status.collectorIntradayCommand,
    errorMessage: status.errorMessage,
  );
}
