import 'dart:convert';

import '../models/leveraged_etf_lab.dart';
import 'mock_00631l_repository.dart';
import 'official_00631l_repository.dart';
import 'proxy_http_client.dart';

class Static00631LRepository extends Mock00631LRepository {
  Static00631LRepository({
    String baseUrl = '00631l-static-data',
    ProxyHttpClient? client,
    this.timeout = const Duration(seconds: 8),
  })  : baseUrl = baseUrl.replaceFirst(RegExp(r'/+$'), ''),
        _client = client ?? createProxyHttpClient();

  final String baseUrl;
  final ProxyHttpClient _client;
  final Duration timeout;

  @override
  Future<Etf00631LLabData> fetchFastLabData() async {
    final now = DateTime.now();
    final profileFuture = fetchProfile();
    final snapshotFuture = fetchDailySnapshot();
    final futuresQuoteFuture = fetchFuturesQuote();
    final priceHistoryFuture = fetchPriceHistory();
    final operationsStatusFuture = fetchOperationsStatus();
    final catalogFuture = fetchEtfCatalog();

    final profile = await profileFuture;
    final snapshot = await snapshotFuture;
    final futuresQuote = await futuresQuoteFuture;
    final priceHistory = await priceHistoryFuture;
    final operationsStatus = await operationsStatusFuture;
    final catalog = await catalogFuture;

    return Etf00631LLabData(
      profile: profile,
      snapshot: snapshot,
      intradayNav: null,
      futuresQuote: futuresQuote,
      holdingsHistory: EtfHoldingsHistory.empty(
        lastFetchedAt: now,
        status: EtfDataStatus.error,
        sourceStatusLabel: 'backend_required',
        errorMessage:
            'Static public mode does not include official holdings history.',
      ),
      intradayNavHistory: EtfIntradayNavHistorySummary.empty(
        lastFetchedAt: now,
        status: EtfDataStatus.error,
        sourceStatusLabel: 'backend_required',
        errorMessage: 'Static public mode does not include live intraday NAV.',
      ),
      priceHistory: priceHistory,
      operationsStatus: operationsStatus,
      analysis: EtfAnalysisSummary.fromSnapshot(
        snapshot: snapshot,
        intradayNav: null,
        now: now,
      ),
      aiAnalysis: _analysisFromStaticStatus(operationsStatus),
      etfCatalog: catalog,
      lastFetchedAt: now,
    );
  }

  @override
  Future<EtfDailyHoldingSnapshot> fetchDailySnapshot() async {
    final now = DateTime.now();
    return EtfDailyHoldingSnapshot(
      tradeDate: DateTime(now.year, now.month, now.day),
      fundNetAssetValue: 0,
      navPerUnit: 0,
      outstandingUnits: 0,
      assetSummary: const EtfAssetSummary(
        stock: 0,
        etf: 0,
        bond: 0,
        futures: 0,
      ),
      cashHoldings: const [],
      stockHoldings: const [],
      futuresHoldings: const [],
      status: EtfDataStatus.error,
      lastFetchedAt: now,
      sourceUpdatedAt: now,
      sourceHash: 'static-public-backend-required',
      errorMessage:
          'Static public mode does not include official daily holdings; live backend is required.',
    );
  }

  @override
  Future<EtfIntradayNav?> fetchIntradayNav() async {
    return null;
  }

  @override
  Future<FuturesQuote> fetchFuturesQuote() async {
    return FuturesQuote(
      symbol: 'TX',
      contractMonth: '',
      txSymbol: null,
      txPrice: null,
      weightedIndex: null,
      nightSessionChange: null,
      status: EtfDataStatus.error,
      lastFetchedAt: DateTime.now(),
      sourceContract: 'static_public_backend_required_tx_quote',
      sourceUrl: '',
      dataTime: null,
      isStale: true,
      errorMessage:
          'Static public mode does not include live TX quote; live backend is required.',
    );
  }

  @override
  Future<EtfHoldingsHistory> fetchHoldingsHistorySummary({
    int limit = 30,
  }) async {
    return EtfHoldingsHistory.empty(
      status: EtfDataStatus.error,
      sourceStatusLabel: 'backend_required',
      errorMessage:
          'Static public mode does not include official holdings history.',
    );
  }

  @override
  Future<EtfIntradayNavHistorySummary> fetchIntradayNavHistorySummary() async {
    return EtfIntradayNavHistorySummary.empty(
      status: EtfDataStatus.error,
      sourceStatusLabel: 'backend_required',
      errorMessage: 'Static public mode does not include live intraday NAV.',
    );
  }

  @override
  Future<EtfPriceHistory> fetchPriceHistory({int limit = 5000}) async {
    final payload = await _tryGetJson('price_history.json');
    if (payload == null) {
      return EtfPriceHistory.empty(
        status: EtfDataStatus.error,
        sourceStatusLabel: 'unavailable',
        sourceUrl: _resolve('price_history.json').toString(),
        errorMessage: 'Static public price_history.json is unavailable.',
      );
    }
    return _priceHistoryFromPayload(
      payload,
      filename: 'price_history.json',
      fallbackCode: '00631L',
      fallbackName: '00631L',
      limit: limit,
    );
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
    final filename = 'etf_price_history/$normalized.json';
    final payload = await _tryGetJson(filename);
    if (payload == null) {
      return EtfPriceHistory.empty(
        code: normalized,
        name: normalized,
        status: EtfDataStatus.error,
        sourceStatusLabel: 'unavailable',
        sourceUrl: _resolve(filename).toString(),
        errorMessage: 'Static public ETF price history is unavailable.',
      );
    }
    return _priceHistoryFromPayload(
      payload,
      filename: filename,
      fallbackCode: normalized,
      fallbackName: normalized,
      limit: limit,
    );
  }

  @override
  Future<EtfOperationsStatus> fetchOperationsStatus() async {
    final statusPayload = await _tryGetJson('status.json');
    final releasePayload = await _tryGetJson('release.json');
    final catalogPayload = await _tryGetJson('etf_catalog.json');
    final etfHistoryPayload = await _tryGetJson('etf_price_history_index.json');
    final catalogRawStatus =
        _string(catalogPayload?['sourceStatus'], fallback: 'unavailable');
    final catalogRowCount = _int(catalogPayload?['rowCount']);
    final catalogDataTime = _wallClockDateTime(
      catalogPayload?['dataTime'] ?? catalogPayload?['sourceUpdatedAt'],
    );
    final etfHistoryRawStatus =
        _string(etfHistoryPayload?['sourceStatus'], fallback: 'unavailable');
    final etfHistoryRowCount = _int(etfHistoryPayload?['rowCount']);
    final etfHistoryReadyCount = _int(etfHistoryPayload?['readyCount']);
    final etfHistoryMissingCount = _int(
      etfHistoryPayload?['missingCount'] ??
          statusPayload?['etfPriceHistoryMissingCount'],
    );
    final etfHistoryAttemptedCount = _int(
      etfHistoryPayload?['attemptedCount'] ??
          statusPayload?['etfPriceHistoryAttemptedCount'],
    );
    final etfHistoryCoverageTierCounts =
        _intMap(etfHistoryPayload?['coverageTierCounts']);
    final etfHistoryGapReasonCounts = _intMap(
      etfHistoryPayload?['gapReasonCounts'] ??
          statusPayload?['etfPriceHistoryGapReasonCounts'],
    );
    final etfHistoryDataTime = _date(etfHistoryPayload?['dataTime']) ??
        _wallClockDateTime(etfHistoryPayload?['dataTime']);
    if (statusPayload == null) {
      return _staticOperationsStatus(
        rawStatus: 'unavailable',
        rowCount: 0,
        coverageStart: null,
        coverageEnd: null,
        generatedAt: null,
        isStale: true,
        etfCatalogStatus: catalogRawStatus,
        etfCatalogRowCount: catalogRowCount,
        etfCatalogDataTime: catalogDataTime,
        etfPriceHistoryStatus: etfHistoryRawStatus,
        etfPriceHistoryRowCount: etfHistoryRowCount,
        etfPriceHistoryReadyCount: etfHistoryReadyCount,
        etfPriceHistoryMissingCount: etfHistoryMissingCount,
        etfPriceHistoryAttemptedCount: etfHistoryAttemptedCount,
        etfPriceHistoryCoverageTierCounts: etfHistoryCoverageTierCounts,
        etfPriceHistoryGapReasonCounts: etfHistoryGapReasonCounts,
        etfPriceHistoryDataTime: etfHistoryDataTime,
        staticReleaseAppVersion: _string(releasePayload?['appVersion']),
        staticReleaseTag: _string(releasePayload?['releaseTag']),
        staticReleaseGitSha: _string(releasePayload?['gitSha']),
        staticReleaseBuildTime: _dateTime(releasePayload?['buildTime']),
        errorMessage: 'Static public status.json is unavailable.',
      );
    }
    final rawStatus =
        _string(statusPayload['sourceStatus'], fallback: 'unavailable');
    final rowCount = _int(statusPayload['rowCount']);
    return _staticOperationsStatus(
      rawStatus: rawStatus,
      rowCount: rowCount,
      coverageStart: _date(statusPayload['coverageStart']),
      coverageEnd: _date(statusPayload['coverageEnd']),
      generatedAt: _dateTime(statusPayload['generatedAt']),
      isStale: statusPayload['isStale'] == true,
      isCompleteFromListing: statusPayload['isCompleteFromListing'] == true,
      etfCatalogStatus: catalogRawStatus,
      etfCatalogRowCount: catalogRowCount,
      etfCatalogDataTime: catalogDataTime,
      etfPriceHistoryStatus: etfHistoryRawStatus,
      etfPriceHistoryRowCount: etfHistoryRowCount,
      etfPriceHistoryReadyCount: etfHistoryReadyCount,
      etfPriceHistoryMissingCount: etfHistoryMissingCount,
      etfPriceHistoryAttemptedCount: etfHistoryAttemptedCount,
      etfPriceHistoryCoverageTierCounts: etfHistoryCoverageTierCounts,
      etfPriceHistoryGapReasonCounts: etfHistoryGapReasonCounts,
      etfPriceHistoryDataTime: etfHistoryDataTime,
      staticReleaseAppVersion: _string(releasePayload?['appVersion']),
      staticReleaseTag: _string(releasePayload?['releaseTag']),
      staticReleaseGitSha: _string(releasePayload?['gitSha']),
      staticReleaseBuildTime: _dateTime(releasePayload?['buildTime']),
      errorMessage: rowCount >= 2
          ? null
          : statusPayload['errorMessage']?.toString() ??
              'Static public price history has fewer than two rows.',
    );
  }

  EtfOperationsStatus _staticOperationsStatus({
    required String rawStatus,
    required int rowCount,
    required DateTime? coverageStart,
    required DateTime? coverageEnd,
    required DateTime? generatedAt,
    required bool isStale,
    bool isCompleteFromListing = false,
    String etfCatalogStatus = 'unavailable',
    int etfCatalogRowCount = 0,
    DateTime? etfCatalogDataTime,
    String etfPriceHistoryStatus = 'unavailable',
    int etfPriceHistoryRowCount = 0,
    int etfPriceHistoryReadyCount = 0,
    int etfPriceHistoryMissingCount = 0,
    int etfPriceHistoryAttemptedCount = 0,
    Map<String, int> etfPriceHistoryCoverageTierCounts = const {},
    Map<String, int> etfPriceHistoryGapReasonCounts = const {},
    DateTime? etfPriceHistoryDataTime,
    String staticReleaseAppVersion = '',
    String staticReleaseTag = '',
    String staticReleaseGitSha = '',
    DateTime? staticReleaseBuildTime,
    String? errorMessage,
  }) {
    final now = DateTime.now();
    return EtfOperationsStatus(
      status: rawStatus == 'static_official'
          ? EtfDataStatus.cached
          : EtfDataStatus.error,
      sourceStatusLabel: 'static_public_data',
      sourceContract: '00631l_static_public_operations',
      sourceUrl: _resolve('manifest.json').toString(),
      lastFetchedAt: generatedAt ?? now,
      sourceUpdatedAt: coverageEnd,
      isStale: isStale,
      staticReleaseAppVersion: staticReleaseAppVersion,
      staticReleaseTag: staticReleaseTag,
      staticReleaseGitSha: staticReleaseGitSha,
      staticReleaseBuildTime: staticReleaseBuildTime,
      intradaySourceMode: 'backend_required',
      twseIntradayNavConfigured: false,
      yuantaIntradayNavConfigured: false,
      publicApiBaseUrl: '',
      allowedOrigins: const [],
      dataRoot: 'web/00631l-static-data',
      dataPersistenceMode: 'static_public',
      dataPersistenceWarning:
          'Static public mode has historical data only; live intraday NAV still needs backend.',
      dataPathWritable: false,
      dataPathPersistent: true,
      holdingsHistoryStatus: 'backend_required',
      holdingsHistoryItemCount: 0,
      latestHoldingTradeDate: null,
      intradayHistoryStatus: 'backend_required',
      intradaySampleCount: 0,
      latestIntradayDataTime: null,
      intradayHistoryDate: null,
      priceHistoryStatus: rawStatus,
      priceHistoryRows: rowCount,
      priceHistoryCoverageStart: coverageStart,
      priceHistoryCoverageEnd: coverageEnd,
      priceHistoryCompleteFromListing: isCompleteFromListing,
      etfCatalogStatus: etfCatalogStatus,
      etfCatalogRowCount: etfCatalogRowCount,
      etfCatalogDataTime: etfCatalogDataTime,
      etfPriceHistoryStatus: etfPriceHistoryStatus,
      etfPriceHistoryRowCount: etfPriceHistoryRowCount,
      etfPriceHistoryReadyCount: etfPriceHistoryReadyCount,
      etfPriceHistoryMissingCount: etfPriceHistoryMissingCount,
      etfPriceHistoryAttemptedCount: etfPriceHistoryAttemptedCount,
      etfPriceHistoryCoverageTierCounts: etfPriceHistoryCoverageTierCounts,
      etfPriceHistoryGapReasonCounts: etfPriceHistoryGapReasonCounts,
      etfPriceHistoryDataTime: etfPriceHistoryDataTime,
      backtestStatus: rowCount >= 2 ? 'static_official' : 'unavailable',
      backtestAvailable: rowCount >= 2,
      positionStatus: 'local_only',
      collectorOneShotCommand: 'public backend required for live collection',
      collectorIntradayCommand: 'public backend required for live intraday NAV',
      envFileExists: false,
      missingEnvKeys: const ['PUBLIC_API_BASE_URL', 'ALLOWED_ORIGINS'],
      optionalMissingEnvKeys: const [],
      dataDirReady: true,
      exportDirReady: true,
      backupDirReady: false,
      exportAvailable: true,
      latestExportPath: 'web/00631l-static-data/price_history.json',
      latestExportUpdatedAt: generatedAt,
      backupAvailable: false,
      latestBackupPath: null,
      latestBackupUpdatedAt: null,
      reportAvailable: false,
      latestReportPath: null,
      latestReportGeneratedAt: null,
      reportOverallStatus: 'static_public',
      reportWarningCount: rowCount >= 2 ? 0 : 1,
      reportFailureCount: 0,
      dailyCycleStatus: 'not_available_in_static_mode',
      dailyCycleStartedAt: null,
      dailyCycleFinishedAt: null,
      dailyCycleWarningCount: 0,
      dailyCycleFailureCount: 0,
      errorMessage: errorMessage,
    );
  }

  @override
  Future<EtfAiAnalysisSummary> fetchAiAnalysisSummary() async {
    final status = await fetchOperationsStatus();
    return _analysisFromStaticStatus(status);
  }

  EtfAiAnalysisSummary _analysisFromStaticStatus(EtfOperationsStatus status) {
    final hasHistory = status.priceHistoryRows >= 2;
    return EtfAiAnalysisSummary(
      source: 'rule_based',
      sourceStatusLabel: hasHistory ? 'static_official' : 'unavailable',
      generatedAt: DateTime.now(),
      dataTime: status.priceHistoryCoverageEnd,
      readinessLevel: hasHistory ? 'attention' : 'action_needed',
      bullets: [
        'static public mode 使用 GitHub Pages 靜態 JSON 顯示歷史價格與回測資料。',
        if (hasHistory)
          '歷史價格 coverage ${_dateLabel(status.priceHistoryCoverageStart)} - ${_dateLabel(status.priceHistoryCoverageEnd)}，rows ${status.priceHistoryRows}。'
        else
          '尚無足夠 static price history，歷史與回測區會顯示資料不足。',
        'live intraday NAV、official holdings 更新與 daily cycle 仍需要 backend proxy。',
        '此摘要只解釋資料狀態與歷史資料可用性。',
      ],
      actionItems: hasHistory
          ? const ['若需要 live intraday NAV，請部署 public backend proxy。']
          : const [
              '請執行 scripts\\00631l_update_price_history.cmd。',
              '請執行 scripts\\00631l_export_static_data.cmd --update。',
            ],
      sourceStatuses: {
        'analysis': hasHistory ? 'static_official' : 'unavailable',
        'priceHistory': status.priceHistoryStatus,
        'intradayNav': 'backend_required',
        'holdingsHistory': 'backend_required',
      },
      disclaimer: '非買賣建議',
      errorMessage: status.errorMessage,
    );
  }

  @override
  Future<EtfCatalog> fetchEtfCatalog() async {
    final payload = await _tryGetJson('etf_catalog.json');
    final historyIndexPayload =
        await _tryGetJson('etf_price_history_index.json');
    final historyByCode = {
      for (final rawItem in _list(historyIndexPayload?['items']))
        _string(_map(rawItem)['code']).trim().toUpperCase(): _map(rawItem),
    };
    if (payload == null) {
      return EtfCatalog.empty(
        lastFetchedAt: DateTime.now(),
        status: EtfDataStatus.error,
        sourceStatusLabel: 'unavailable',
        sourceContract: 'twse_all_etf_catalog_static_public',
        sourceUrl: _resolve('etf_catalog.json').toString(),
        errorMessage: 'Static public etf_catalog.json is unavailable.',
      );
    }
    final rawStatus = _string(payload['sourceStatus'], fallback: 'unavailable');
    return EtfCatalog(
      items: [
        for (final rawItem in _list(payload['items']))
          _catalogItem(
            _map(rawItem),
            historyPayload: historyByCode[
                _string(_map(rawItem)['code']).trim().toUpperCase()],
          ),
      ],
      status: rawStatus == 'static_official'
          ? EtfDataStatus.cached
          : EtfDataStatus.error,
      sourceStatusLabel: rawStatus,
      sourceContract: _string(
        payload['sourceContract'],
        fallback: 'twse_all_etf_catalog_static_public',
      ),
      sourceUrl: _string(
        payload['sourceUrl'],
        fallback: _resolve('etf_catalog.json').toString(),
      ),
      lastFetchedAt:
          _dateTime(payload['generatedAt'] ?? payload['fetchedAt']) ??
              DateTime.now(),
      sourceUpdatedAt: _wallClockDateTime(payload['sourceUpdatedAt']),
      dataTime: _wallClockDateTime(payload['dataTime']),
      isStale: payload['isStale'] == true,
      userDelayMs: _int(payload['userDelayMs'], fallback: 15000),
      errorMessage: payload['errorMessage']?.toString(),
    );
  }

  Future<Map<String, dynamic>> _getJson(String filename) async {
    final body = await _client.getString(_resolve(filename), timeout: timeout);
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw RepositoryFetchException(
        'Static public data $filename is not an object',
      );
    }
    return decoded;
  }

  Future<Map<String, dynamic>?> _tryGetJson(String filename) async {
    try {
      return await _getJson(filename);
    } catch (_) {
      return null;
    }
  }

  Uri _resolve(String filename) {
    final normalized = filename.replaceFirst(RegExp(r'^/+'), '');
    return Uri.parse('$baseUrl/$normalized');
  }

  EtfPriceHistory _priceHistoryFromPayload(
    Map<String, dynamic> payload, {
    required String filename,
    required String fallbackCode,
    required String fallbackName,
    required int limit,
  }) {
    final items = [
      for (final item in _list(payload['items']).take(limit))
        _pricePoint(_map(item)),
    ];
    final rawStatus = _string(payload['sourceStatus'], fallback: 'unavailable');
    return EtfPriceHistory(
      code: _string(payload['code'], fallback: fallbackCode),
      name: _string(payload['name'], fallback: fallbackName),
      points: items,
      status: rawStatus == 'static_official' || rawStatus == 'cached'
          ? EtfDataStatus.cached
          : EtfDataStatus.error,
      sourceStatusLabel: rawStatus,
      sourceUrl: _resolve(filename).toString(),
      lastFetchedAt:
          _dateTime(payload['generatedAt'] ?? payload['fetchedAt']) ??
              DateTime.now(),
      coverageStart: _date(payload['coverageStart']),
      coverageEnd: _date(payload['coverageEnd']),
      isCompleteFromListing: payload['isCompleteFromListing'] == true,
      errorMessage: payload['errorMessage']?.toString(),
    );
  }
}

EtfCatalogItem _catalogItem(
  Map<String, dynamic> payload, {
  Map<String, dynamic>? historyPayload,
}) {
  return EtfCatalogItem(
    code: _string(payload['code']),
    name: _string(payload['name']),
    marketPrice: _nullableDouble(payload['marketPrice']),
    estimatedNav: _nullableDouble(payload['estimatedNav']),
    premiumDiscountPct: _nullableDouble(payload['premiumDiscountPct']),
    previousNav: _nullableDouble(payload['previousNav']),
    outstandingUnits: _nullableInt(payload['outstandingUnits']),
    outstandingUnitsDelta: _nullableInt(payload['outstandingUnitsDelta']),
    dataTime: _wallClockDateTime(payload['dataTime']),
    targetType: _string(payload['targetType']),
    priceHistoryRowCount: _int(historyPayload?['rowCount']),
    priceHistoryCoverageTier: _string(historyPayload?['coverageTier']),
    priceHistoryCoverageStart: _date(historyPayload?['coverageStart']),
    priceHistoryCoverageEnd: _date(historyPayload?['coverageEnd']),
    priceHistorySourceStatus: _string(historyPayload?['sourceStatus']),
  );
}

EtfPriceHistoryPoint _pricePoint(Map<String, dynamic> payload) {
  return EtfPriceHistoryPoint(
    date: _date(payload['date']) ?? DateTime(1970),
    close: _double(payload['close']),
    open: _nullableDouble(payload['open']),
    high: _nullableDouble(payload['high']),
    low: _nullableDouble(payload['low']),
    volume: _nullableInt(payload['volume']),
    adjustedOpen: _nullableDouble(payload['adjustedOpen']),
    adjustedHigh: _nullableDouble(payload['adjustedHigh']),
    adjustedLow: _nullableDouble(payload['adjustedLow']),
    adjustedClose: _nullableDouble(payload['adjustedClose']),
    adjustmentFactor: _nullableDouble(payload['adjustmentFactor']),
    nav: _nullableDouble(payload['nav']),
    premiumDiscountPct: _nullableDouble(payload['premiumDiscountPct']),
    dailyReturnPct: _nullableDouble(payload['dailyReturnPct']),
    cumulativeReturnPct: _nullableDouble(payload['cumulativeReturnPct']),
    drawdownPct: _nullableDouble(payload['drawdownPct']),
  );
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return const {};
}

List<Object?> _list(Object? value) {
  if (value is List) {
    return value.cast<Object?>();
  }
  return const [];
}

Map<String, int> _intMap(Object? value) {
  if (value is! Map) {
    return const {};
  }
  return value.map((key, item) {
    final number =
        item is num ? item.toInt() : int.tryParse(item.toString()) ?? 0;
    return MapEntry(key.toString(), number);
  });
}

String _string(Object? value, {String fallback = ''}) {
  final text = value?.toString();
  if (text == null || text.isEmpty) {
    return fallback;
  }
  return text;
}

double _double(Object? value, {double fallback = 0}) {
  return _nullableDouble(value) ?? fallback;
}

double? _nullableDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  if (value == null) {
    return null;
  }
  return double.tryParse(value.toString().replaceAll(',', '').trim());
}

int _int(Object? value, {int fallback = 0}) {
  return _nullableInt(value) ?? fallback;
}

int? _nullableInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value == null) {
    return null;
  }
  return int.tryParse(value.toString().replaceAll(',', '').trim());
}

DateTime? _date(Object? value) {
  final parsed = _dateTime(value);
  if (parsed == null) {
    return null;
  }
  return DateTime(parsed.year, parsed.month, parsed.day);
}

DateTime? _dateTime(Object? value) {
  if (value == null) {
    return null;
  }
  return DateTime.tryParse(value.toString());
}

DateTime? _wallClockDateTime(Object? value) {
  if (value == null) {
    return null;
  }
  final match = RegExp(
    r'^(\d{4})-(\d{2})-(\d{2})(?:T|\s)(\d{2}):(\d{2}):(\d{2})',
  ).firstMatch(value.toString());
  if (match == null) {
    return null;
  }
  return DateTime(
    int.parse(match.group(1)!),
    int.parse(match.group(2)!),
    int.parse(match.group(3)!),
    int.parse(match.group(4)!),
    int.parse(match.group(5)!),
    int.parse(match.group(6)!),
  );
}

String _dateLabel(DateTime? value) {
  if (value == null) {
    return 'unavailable';
  }
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year}/$month/$day';
}
