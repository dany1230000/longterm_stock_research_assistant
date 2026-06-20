import '../models/leveraged_etf_lab.dart';
import 'mock_00631l_repository.dart';
import 'official_00631l_repository.dart';

class Cached00631LRepository extends Official00631LRepository {
  Cached00631LRepository({
    required Official00631LRepository primary,
    Official00631LRepository? fallback,
    this.fastPrimaryTimeout = const Duration(milliseconds: 900),
    this.primaryTimeout = const Duration(seconds: 4),
  })  : _primary = primary,
        _fallback = fallback ?? Mock00631LRepository();

  final Official00631LRepository _primary;
  final Official00631LRepository _fallback;
  final Duration fastPrimaryTimeout;
  final Duration primaryTimeout;

  LeveragedEtfProfile? _profileCache;
  EtfDailyHoldingSnapshot? _snapshotCache;
  EtfIntradayNav? _intradayNavCache;
  FuturesQuote? _futuresQuoteCache;
  EtfHoldingsHistory? _holdingsHistoryCache;
  EtfIntradayNavHistorySummary? _intradayNavHistoryCache;
  EtfPriceHistory? _priceHistoryCache;
  final Map<String, EtfPriceHistory> _etfPriceHistoryCache = {};
  EtfOperationsStatus? _operationsStatusCache;
  EtfAiAnalysisSummary? _aiAnalysisCache;
  EtfCatalog? _etfCatalogCache;

  @override
  Future<Etf00631LLabData> fetchFastLabData() async {
    try {
      final data =
          await _primary.fetchFastLabData().timeout(fastPrimaryTimeout);
      _profileCache = data.profile;
      _snapshotCache = data.snapshot;
      _intradayNavCache = data.intradayNav;
      _futuresQuoteCache = data.futuresQuote;
      return data;
    } catch (_) {
      return _fallback.fetchFastLabData();
    }
  }

  @override
  Future<LeveragedEtfProfile> fetchProfile() async {
    try {
      final profile = await _primary.fetchProfile().timeout(primaryTimeout);
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
      final snapshot =
          await _primary.fetchDailySnapshot().timeout(primaryTimeout);
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
      final intradayNav =
          await _primary.fetchIntradayNav().timeout(primaryTimeout);
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
      final quote = await _primary.fetchFuturesQuote().timeout(primaryTimeout);
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
      final history = await _primary
          .fetchHoldingsHistorySummary(limit: limit)
          .timeout(primaryTimeout);
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
      final history = await _primary
          .fetchIntradayNavHistorySummary()
          .timeout(primaryTimeout);
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
  Future<EtfPriceHistory> fetchPriceHistory({int limit = 5000}) async {
    try {
      final history = await _primary
          .fetchPriceHistory(limit: limit)
          .timeout(primaryTimeout);
      if (!_isPriceHistoryUsable(history)) {
        try {
          final fallback =
              await _fallback.fetchPriceHistory(limit: limit).timeout(
                    primaryTimeout,
                  );
          if (_isPriceHistoryUsable(fallback)) {
            _priceHistoryCache = fallback;
            return fallback;
          }
        } catch (_) {
          // Keep the primary response below; it still carries the live error.
        }
      }
      _priceHistoryCache = history;
      return history;
    } catch (_) {
      final cached = _priceHistoryCache;
      if (cached != null) {
        return _cachedPriceHistory(cached);
      }
      return _fallback.fetchPriceHistory(limit: limit);
    }
  }

  @override
  Future<EtfPriceHistory> fetchEtfPriceHistory(
    String code, {
    int limit = 5000,
  }) async {
    final normalized = code.trim().toUpperCase();
    if (normalized == '00631L') {
      return fetchPriceHistory(limit: limit);
    }
    try {
      final history = await _primary
          .fetchEtfPriceHistory(normalized, limit: limit)
          .timeout(primaryTimeout);
      if (!_isPriceHistoryUsable(history)) {
        try {
          final fallback = await _fallback
              .fetchEtfPriceHistory(normalized, limit: limit)
              .timeout(primaryTimeout);
          if (_isPriceHistoryUsable(fallback)) {
            _etfPriceHistoryCache[normalized] = fallback;
            return fallback;
          }
        } catch (_) {
          // Keep the primary response below; it still carries the error state.
        }
      }
      _etfPriceHistoryCache[normalized] = history;
      return history;
    } catch (_) {
      final cached = _etfPriceHistoryCache[normalized];
      if (cached != null) {
        return _cachedPriceHistory(cached);
      }
      return _fallback.fetchEtfPriceHistory(normalized, limit: limit);
    }
  }

  @override
  Future<EtfOperationsStatus> fetchOperationsStatus() async {
    try {
      final status =
          await _primary.fetchOperationsStatus().timeout(primaryTimeout);
      final merged = await _operationsWithFallbackPriceHistory(status);
      _operationsStatusCache = merged;
      return merged;
    } catch (error) {
      final cached = _operationsStatusCache;
      if (cached != null) {
        return _cachedOperationsStatus(cached);
      }
      final fallback = await _fallback.fetchOperationsStatus();
      return _backendDisconnectedOperationsStatus(fallback, error);
    }
  }

  @override
  Future<EtfAiAnalysisSummary> fetchAiAnalysisSummary() async {
    try {
      final analysis =
          await _primary.fetchAiAnalysisSummary().timeout(primaryTimeout);
      _aiAnalysisCache = analysis;
      return analysis;
    } catch (_) {
      final cached = _aiAnalysisCache;
      if (cached != null) {
        return cached.asCached();
      }
      return _fallback.fetchAiAnalysisSummary();
    }
  }

  @override
  Future<EtfCatalog> fetchEtfCatalog() async {
    try {
      final catalog = await _primary.fetchEtfCatalog().timeout(primaryTimeout);
      _etfCatalogCache = catalog;
      return catalog;
    } catch (_) {
      final cached = _etfCatalogCache;
      if (cached != null) {
        return _cachedEtfCatalog(cached);
      }
      return _fallback.fetchEtfCatalog();
    }
  }

  Future<EtfOperationsStatus> _operationsWithFallbackPriceHistory(
    EtfOperationsStatus primaryStatus,
  ) async {
    if (!_needsPriceHistoryFallback(primaryStatus)) {
      return primaryStatus;
    }
    try {
      final fallbackStatus =
          await _fallback.fetchOperationsStatus().timeout(primaryTimeout);
      if (_operationsHasPriceHistory(fallbackStatus)) {
        return _mergeOperationsPriceHistory(
          primaryStatus,
          fallbackStatus,
        );
      }
    } catch (_) {
      // Keep the live operations status if the fallback status is unavailable.
    }
    return primaryStatus;
  }
}

EtfCatalog _cachedEtfCatalog(EtfCatalog catalog) {
  return EtfCatalog(
    items: catalog.items,
    status: EtfDataStatus.cached,
    sourceStatusLabel: 'cached',
    sourceContract: catalog.sourceContract,
    sourceUrl: catalog.sourceUrl,
    lastFetchedAt: catalog.lastFetchedAt,
    sourceUpdatedAt: catalog.sourceUpdatedAt,
    dataTime: catalog.dataTime,
    isStale: catalog.isStale,
    userDelayMs: catalog.userDelayMs,
    errorMessage: catalog.errorMessage,
  );
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
    txSymbol: quote.txSymbol,
    txPrice: quote.txPrice,
    weightedIndex: quote.weightedIndex,
    nightSessionChange: quote.nightSessionChange,
    status: quote.isStale ? EtfDataStatus.stale : EtfDataStatus.cached,
    lastFetchedAt: quote.lastFetchedAt,
    sourceContract: quote.sourceContract,
    sourceUrl: quote.sourceUrl,
    dataTime: quote.dataTime,
    isStale: quote.isStale,
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

EtfPriceHistory _cachedPriceHistory(EtfPriceHistory history) {
  return EtfPriceHistory(
    code: history.code,
    name: history.name,
    points: history.points,
    status: EtfDataStatus.cached,
    sourceStatusLabel: 'cached',
    sourceUrl: history.sourceUrl,
    lastFetchedAt: history.lastFetchedAt,
    coverageStart: history.coverageStart,
    coverageEnd: history.coverageEnd,
    isCompleteFromListing: history.isCompleteFromListing,
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
    publicApiBaseUrl: status.publicApiBaseUrl,
    allowedOrigins: status.allowedOrigins,
    dataRoot: status.dataRoot,
    dataPersistenceMode: status.dataPersistenceMode,
    dataPersistenceWarning: status.dataPersistenceWarning,
    dataPathWritable: status.dataPathWritable,
    dataPathPersistent: status.dataPathPersistent,
    holdingsHistoryStatus: status.holdingsHistoryStatus,
    holdingsHistoryItemCount: status.holdingsHistoryItemCount,
    latestHoldingTradeDate: status.latestHoldingTradeDate,
    intradayHistoryStatus: status.intradayHistoryStatus,
    intradaySampleCount: status.intradaySampleCount,
    latestIntradayDataTime: status.latestIntradayDataTime,
    intradayHistoryDate: status.intradayHistoryDate,
    priceHistoryStatus: status.priceHistoryStatus,
    priceHistoryRows: status.priceHistoryRows,
    priceHistoryCoverageStart: status.priceHistoryCoverageStart,
    priceHistoryCoverageEnd: status.priceHistoryCoverageEnd,
    priceHistoryCompleteFromListing: status.priceHistoryCompleteFromListing,
    etfCatalogStatus: status.etfCatalogStatus,
    etfCatalogRowCount: status.etfCatalogRowCount,
    etfCatalogDataTime: status.etfCatalogDataTime,
    etfPriceHistoryStatus: status.etfPriceHistoryStatus,
    etfPriceHistoryRowCount: status.etfPriceHistoryRowCount,
    etfPriceHistoryReadyCount: status.etfPriceHistoryReadyCount,
    etfPriceHistoryDataTime: status.etfPriceHistoryDataTime,
    backtestStatus: status.backtestStatus,
    backtestAvailable: status.backtestAvailable,
    positionStatus: status.positionStatus,
    collectorOneShotCommand: status.collectorOneShotCommand,
    collectorIntradayCommand: status.collectorIntradayCommand,
    envFileExists: status.envFileExists,
    missingEnvKeys: status.missingEnvKeys,
    optionalMissingEnvKeys: status.optionalMissingEnvKeys,
    dataDirReady: status.dataDirReady,
    exportDirReady: status.exportDirReady,
    backupDirReady: status.backupDirReady,
    exportAvailable: status.exportAvailable,
    latestExportPath: status.latestExportPath,
    latestExportUpdatedAt: status.latestExportUpdatedAt,
    backupAvailable: status.backupAvailable,
    latestBackupPath: status.latestBackupPath,
    latestBackupUpdatedAt: status.latestBackupUpdatedAt,
    reportAvailable: status.reportAvailable,
    latestReportPath: status.latestReportPath,
    latestReportGeneratedAt: status.latestReportGeneratedAt,
    reportOverallStatus: status.reportOverallStatus,
    reportWarningCount: status.reportWarningCount,
    reportFailureCount: status.reportFailureCount,
    dailyCycleStatus: status.dailyCycleStatus,
    dailyCycleStartedAt: status.dailyCycleStartedAt,
    dailyCycleFinishedAt: status.dailyCycleFinishedAt,
    dailyCycleWarningCount: status.dailyCycleWarningCount,
    dailyCycleFailureCount: status.dailyCycleFailureCount,
    integrityStatus: status.integrityStatus,
    integrityWarningCount: status.integrityWarningCount,
    integrityFailureCount: status.integrityFailureCount,
    holdingsIntegrityRecordCount: status.holdingsIntegrityRecordCount,
    holdingsMissingWeekdayCount: status.holdingsMissingWeekdayCount,
    holdingsMissingWeekdays: status.holdingsMissingWeekdays,
    errorMessage: status.errorMessage,
  );
}

EtfOperationsStatus _backendDisconnectedOperationsStatus(
  EtfOperationsStatus status,
  Object error,
) {
  return EtfOperationsStatus(
    status: EtfDataStatus.error,
    sourceStatusLabel: 'error',
    sourceContract: status.sourceContract,
    sourceUrl: status.sourceUrl,
    lastFetchedAt: DateTime.now(),
    sourceUpdatedAt: status.sourceUpdatedAt,
    isStale: true,
    intradaySourceMode: status.intradaySourceMode,
    twseIntradayNavConfigured: status.twseIntradayNavConfigured,
    yuantaIntradayNavConfigured: status.yuantaIntradayNavConfigured,
    publicApiBaseUrl: status.publicApiBaseUrl,
    allowedOrigins: status.allowedOrigins,
    dataRoot: status.dataRoot,
    dataPersistenceMode: status.dataPersistenceMode,
    dataPersistenceWarning: status.dataPersistenceWarning,
    dataPathWritable: status.dataPathWritable,
    dataPathPersistent: status.dataPathPersistent,
    holdingsHistoryStatus: status.holdingsHistoryStatus,
    holdingsHistoryItemCount: status.holdingsHistoryItemCount,
    latestHoldingTradeDate: status.latestHoldingTradeDate,
    intradayHistoryStatus: status.intradayHistoryStatus,
    intradaySampleCount: status.intradaySampleCount,
    latestIntradayDataTime: status.latestIntradayDataTime,
    intradayHistoryDate: status.intradayHistoryDate,
    priceHistoryStatus: status.priceHistoryStatus,
    priceHistoryRows: status.priceHistoryRows,
    priceHistoryCoverageStart: status.priceHistoryCoverageStart,
    priceHistoryCoverageEnd: status.priceHistoryCoverageEnd,
    priceHistoryCompleteFromListing: status.priceHistoryCompleteFromListing,
    etfCatalogStatus: status.etfCatalogStatus,
    etfCatalogRowCount: status.etfCatalogRowCount,
    etfCatalogDataTime: status.etfCatalogDataTime,
    etfPriceHistoryStatus: status.etfPriceHistoryStatus,
    etfPriceHistoryRowCount: status.etfPriceHistoryRowCount,
    etfPriceHistoryReadyCount: status.etfPriceHistoryReadyCount,
    etfPriceHistoryDataTime: status.etfPriceHistoryDataTime,
    backtestStatus: status.backtestStatus,
    backtestAvailable: status.backtestAvailable,
    positionStatus: status.positionStatus,
    collectorOneShotCommand: status.collectorOneShotCommand,
    collectorIntradayCommand: status.collectorIntradayCommand,
    envFileExists: status.envFileExists,
    missingEnvKeys: status.missingEnvKeys,
    optionalMissingEnvKeys: status.optionalMissingEnvKeys,
    dataDirReady: status.dataDirReady,
    exportDirReady: status.exportDirReady,
    backupDirReady: status.backupDirReady,
    exportAvailable: status.exportAvailable,
    latestExportPath: status.latestExportPath,
    latestExportUpdatedAt: status.latestExportUpdatedAt,
    backupAvailable: status.backupAvailable,
    latestBackupPath: status.latestBackupPath,
    latestBackupUpdatedAt: status.latestBackupUpdatedAt,
    reportAvailable: status.reportAvailable,
    latestReportPath: status.latestReportPath,
    latestReportGeneratedAt: status.latestReportGeneratedAt,
    reportOverallStatus: status.reportOverallStatus,
    reportWarningCount: status.reportWarningCount,
    reportFailureCount: status.reportFailureCount,
    dailyCycleStatus: status.dailyCycleStatus,
    dailyCycleStartedAt: status.dailyCycleStartedAt,
    dailyCycleFinishedAt: status.dailyCycleFinishedAt,
    dailyCycleWarningCount: status.dailyCycleWarningCount,
    dailyCycleFailureCount: status.dailyCycleFailureCount,
    integrityStatus: status.integrityStatus,
    integrityWarningCount: status.integrityWarningCount,
    integrityFailureCount: status.integrityFailureCount,
    holdingsIntegrityRecordCount: status.holdingsIntegrityRecordCount,
    holdingsMissingWeekdayCount: status.holdingsMissingWeekdayCount,
    holdingsMissingWeekdays: status.holdingsMissingWeekdays,
    errorMessage:
        'backend disconnected; showing mock/fallback operations status. $error',
  );
}

bool _isPriceHistoryUsable(EtfPriceHistory history) {
  return history.points.length >= 2 &&
      history.status != EtfDataStatus.error &&
      !_isUnavailableLabel(history.sourceStatusLabel);
}

bool _needsPriceHistoryFallback(EtfOperationsStatus status) {
  return status.priceHistoryRows < 2 ||
      !status.backtestAvailable ||
      _isUnavailableLabel(status.priceHistoryStatus);
}

bool _operationsHasPriceHistory(EtfOperationsStatus status) {
  return status.priceHistoryRows >= 2 &&
      status.backtestAvailable &&
      !_isUnavailableLabel(status.priceHistoryStatus);
}

bool _isUnavailableLabel(String label) {
  final normalized = label.trim().toLowerCase();
  return normalized == 'error' ||
      normalized == 'unavailable' ||
      normalized == 'mock';
}

EtfOperationsStatus _mergeOperationsPriceHistory(
  EtfOperationsStatus primary,
  EtfOperationsStatus fallback,
) {
  const note =
      'Backend price history unavailable; using static public price history.';
  final errorMessage =
      primary.errorMessage == null || primary.errorMessage!.trim().isEmpty
          ? note
          : '$note ${primary.errorMessage}';
  return EtfOperationsStatus(
    status: primary.status,
    sourceStatusLabel: primary.sourceStatusLabel,
    sourceContract: primary.sourceContract,
    sourceUrl: primary.sourceUrl,
    lastFetchedAt: primary.lastFetchedAt,
    sourceUpdatedAt: primary.sourceUpdatedAt,
    isStale: primary.isStale,
    intradaySourceMode: primary.intradaySourceMode,
    twseIntradayNavConfigured: primary.twseIntradayNavConfigured,
    yuantaIntradayNavConfigured: primary.yuantaIntradayNavConfigured,
    publicApiBaseUrl: primary.publicApiBaseUrl,
    allowedOrigins: primary.allowedOrigins,
    dataRoot: primary.dataRoot,
    dataPersistenceMode: primary.dataPersistenceMode,
    dataPersistenceWarning: primary.dataPersistenceWarning,
    dataPathWritable: primary.dataPathWritable,
    dataPathPersistent: primary.dataPathPersistent,
    holdingsHistoryStatus: primary.holdingsHistoryStatus,
    holdingsHistoryItemCount: primary.holdingsHistoryItemCount,
    latestHoldingTradeDate: primary.latestHoldingTradeDate,
    intradayHistoryStatus: primary.intradayHistoryStatus,
    intradaySampleCount: primary.intradaySampleCount,
    latestIntradayDataTime: primary.latestIntradayDataTime,
    intradayHistoryDate: primary.intradayHistoryDate,
    priceHistoryStatus: fallback.priceHistoryStatus,
    priceHistoryRows: fallback.priceHistoryRows,
    priceHistoryCoverageStart: fallback.priceHistoryCoverageStart,
    priceHistoryCoverageEnd: fallback.priceHistoryCoverageEnd,
    priceHistoryCompleteFromListing: fallback.priceHistoryCompleteFromListing,
    etfCatalogStatus: primary.etfCatalogStatus,
    etfCatalogRowCount: primary.etfCatalogRowCount,
    etfCatalogDataTime: primary.etfCatalogDataTime,
    etfPriceHistoryStatus: primary.etfPriceHistoryStatus,
    etfPriceHistoryRowCount: primary.etfPriceHistoryRowCount,
    etfPriceHistoryReadyCount: primary.etfPriceHistoryReadyCount,
    etfPriceHistoryDataTime: primary.etfPriceHistoryDataTime,
    backtestStatus: fallback.backtestStatus,
    backtestAvailable: fallback.backtestAvailable,
    positionStatus: primary.positionStatus,
    collectorOneShotCommand: primary.collectorOneShotCommand,
    collectorIntradayCommand: primary.collectorIntradayCommand,
    envFileExists: primary.envFileExists,
    missingEnvKeys: primary.missingEnvKeys,
    optionalMissingEnvKeys: primary.optionalMissingEnvKeys,
    dataDirReady: primary.dataDirReady,
    exportDirReady: primary.exportDirReady,
    backupDirReady: primary.backupDirReady,
    exportAvailable: primary.exportAvailable,
    latestExportPath: primary.latestExportPath,
    latestExportUpdatedAt: primary.latestExportUpdatedAt,
    backupAvailable: primary.backupAvailable,
    latestBackupPath: primary.latestBackupPath,
    latestBackupUpdatedAt: primary.latestBackupUpdatedAt,
    reportAvailable: primary.reportAvailable,
    latestReportPath: primary.latestReportPath,
    latestReportGeneratedAt: primary.latestReportGeneratedAt,
    reportOverallStatus: primary.reportOverallStatus,
    reportWarningCount: primary.reportWarningCount,
    reportFailureCount: primary.reportFailureCount,
    dailyCycleStatus: primary.dailyCycleStatus,
    dailyCycleStartedAt: primary.dailyCycleStartedAt,
    dailyCycleFinishedAt: primary.dailyCycleFinishedAt,
    dailyCycleWarningCount: primary.dailyCycleWarningCount,
    dailyCycleFailureCount: primary.dailyCycleFailureCount,
    integrityStatus: primary.integrityStatus,
    integrityWarningCount: primary.integrityWarningCount,
    integrityFailureCount: primary.integrityFailureCount,
    holdingsIntegrityRecordCount: primary.holdingsIntegrityRecordCount,
    holdingsMissingWeekdayCount: primary.holdingsMissingWeekdayCount,
    holdingsMissingWeekdays: primary.holdingsMissingWeekdays,
    errorMessage: errorMessage,
  );
}
