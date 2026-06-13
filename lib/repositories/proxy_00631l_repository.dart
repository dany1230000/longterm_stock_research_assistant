import 'dart:convert';

import '../models/leveraged_etf_lab.dart';
import 'official_00631l_repository.dart';
import 'proxy_http_client.dart';

class Proxy00631LRepository extends Official00631LRepository {
  Proxy00631LRepository({
    Uri? baseUri,
    ProxyHttpClient? client,
    this.timeout = const Duration(seconds: 8),
  })  : baseUri = baseUri ?? Uri.parse('http://localhost:8000'),
        _client = client ?? createProxyHttpClient();

  final Uri baseUri;
  final ProxyHttpClient _client;
  final Duration timeout;

  @override
  Future<LeveragedEtfProfile> fetchProfile() async {
    final payload = await _getJson('/api/etf/00631l/profile');
    _throwIfErrorStatus(payload, 'profile');

    return LeveragedEtfProfile(
      symbol: _string(payload['symbol'], fallback: '00631L'),
      fundName: _string(payload['fundName']),
      shortName: _string(payload['shortName']),
      trackingIndex: _string(payload['trackingIndex']),
      inceptionDate: _date(payload['inceptionDate']),
      listingDate: _date(payload['listingDate']),
      distributesIncome: payload['distributesIncome'] == true,
      riskLevel: _string(payload['riskLevel']),
      managementFeePercent: _double(payload['managementFeePercent']),
      custodianFeePercent: _double(payload['custodianFeePercent']),
      leverageObjective: _string(payload['leverageObjective']),
      exposurePolicy: _string(payload['exposurePolicy']),
      primaryTradingMethod: _string(payload['primaryTradingMethod']),
      sourceUrl: _string(payload['sourceUrl']),
      status: _status(payload),
      lastFetchedAt: _dateTime(payload['fetchedAt']) ?? DateTime.now(),
    );
  }

  @override
  Future<EtfDailyHoldingSnapshot> fetchDailySnapshot() async {
    final payload = await _getJson('/api/etf/00631l/holdings');
    _throwIfErrorStatus(payload, 'holdings');
    final assetValues = _map(payload['assetValues']);

    return EtfDailyHoldingSnapshot(
      tradeDate: _date(payload['tradeDate']),
      fundNetAssetValue: _double(payload['fundNetAssetValue']),
      navPerUnit: _double(payload['navPerUnit']),
      outstandingUnits: _int(payload['outstandingUnits']),
      assetSummary: EtfAssetSummary(
        stock: _double(assetValues['stock']),
        etf: _double(assetValues['etf']),
        bond: _double(assetValues['bond']),
        futures: _double(assetValues['futures']),
      ),
      cashHoldings: [
        for (final line in _list(payload['cashHoldings']))
          EtfCashHoldingLine(
            item: _string(_map(line)['item']),
            amount: _double(_map(line)['amount']),
          ),
      ],
      stockHoldings: [
        for (final line in _list(payload['stockHoldings']))
          EtfStockHoldingLine(
            code: _string(_map(line)['code']),
            name: _string(_map(line)['name']),
            quantity: _int(_map(line)['quantity']),
            weightPct: _double(_map(line)['weightPct']),
          ),
      ],
      futuresHoldings: [
        for (final line in _list(payload['futuresHoldings']))
          EtfFuturesHoldingLine(
            code: _string(_map(line)['code']),
            name: _string(_map(line)['name']),
            quantity: _int(_map(line)['quantity']),
            weightPct: _double(_map(line)['weightPct']),
            contractMonth: _string(_map(line)['contractMonth']),
          ),
      ],
      status: _status(payload),
      lastFetchedAt: _dateTime(payload['fetchedAt']) ?? DateTime.now(),
      sourceUpdatedAt: _wallClockDateTime(payload['sourceUpdatedAt']) ??
          _date(payload['tradeDate']),
      sourceHash: _string(payload['sourceHash']),
      errorMessage: payload['errorMessage']?.toString(),
    );
  }

  @override
  Future<EtfIntradayNav?> fetchIntradayNav() async {
    final payload = await _getJson('/api/etf/00631l/intraday-nav');
    final rawStatus = _rawStatus(payload);
    if (rawStatus == 'unavailable' || rawStatus == 'error') {
      return null;
    }

    return EtfIntradayNav(
      symbol: _string(payload['symbol'] ?? payload['code'], fallback: '00631L'),
      name: _string(payload['name']),
      outstandingUnits: _nullableInt(payload['outstandingUnits']),
      outstandingUnitsDelta: _nullableInt(payload['outstandingUnitsDelta']),
      marketPrice: _nullableDouble(payload['marketPrice']),
      estimatedNav: _nullableDouble(payload['estimatedNav']),
      estimatedPremiumDiscountPct: _nullableDouble(
          payload['estimatedPremiumDiscountPct'] ??
              payload['premiumDiscountPct']),
      previousBusinessDayNav: _nullableDouble(
          payload['previousBusinessDayNav'] ?? payload['previousNav']),
      previousBusinessDayNavText:
          _string(payload['previousBusinessDayNavText']),
      dataDate: _nullableDate(payload['dataDate']),
      dataTime: _wallClockDateTime(payload['dataTime']),
      targetType: _string(payload['targetType']),
      userDelayMs: _int(payload['userDelayMs'], fallback: 15000),
      sourceContract: payload['sourceContract']?.toString(),
      isStale: payload['isStale'] == true,
      status: _status(payload),
      lastFetchedAt: _dateTime(payload['fetchedAt']) ?? DateTime.now(),
    );
  }

  @override
  Future<FuturesQuote> fetchFuturesQuote() async {
    final payload = await _getJson('/api/etf/00631l/tx-quote');
    return FuturesQuote(
      symbol: _string(payload['symbol'], fallback: 'TX'),
      contractMonth: _string(payload['contractMonth'], fallback: 'front_month'),
      txPrice: _nullableDouble(payload['txPrice']),
      weightedIndex: _nullableDouble(payload['weightedIndex']),
      nightSessionChange: _nullableDouble(payload['nightSessionChange']),
      status: _status(payload),
      lastFetchedAt: _dateTime(payload['fetchedAt']) ?? DateTime.now(),
      sourceContract: payload['sourceContract']?.toString(),
      sourceUrl: _string(payload['sourceUrl']),
      dataTime: _wallClockDateTime(payload['dataTime']),
      isStale: payload['isStale'] == true,
      errorMessage: payload['errorMessage']?.toString(),
    );
  }

  @override
  Future<EtfHoldingsHistory> fetchHoldingsHistorySummary({
    int limit = 30,
  }) async {
    final payload = await _getJson(
      '/api/etf/00631l/holdings/history/summary?limit=$limit',
    );
    final rawStatus = _rawStatus(payload);
    final items = [
      for (final item in _list(payload['items']))
        _historyPointFromPayload(_map(item)),
    ];

    return EtfHoldingsHistory(
      points: items,
      status: _status(payload),
      sourceStatusLabel: rawStatus.isEmpty ? _status(payload).label : rawStatus,
      sourceUrl: _string(payload['sourceUrl']),
      lastFetchedAt: _dateTime(payload['fetchedAt']) ?? DateTime.now(),
      isStale: payload['isStale'] == true,
      errorMessage: payload['errorMessage']?.toString(),
    );
  }

  @override
  Future<EtfIntradayNavHistorySummary> fetchIntradayNavHistorySummary() async {
    final payload =
        await _getJson('/api/etf/00631l/intraday-nav/history/summary');
    final rawStatus = _rawStatus(payload);
    final items = [
      for (final item in _list(payload['items']))
        _intradayHistoryPointFromPayload(_map(item)),
    ];

    return EtfIntradayNavHistorySummary(
      points: items,
      sampleCount: _int(payload['sampleCount']),
      highestPremiumDiscountPct:
          _nullableDouble(payload['highestPremiumDiscountPct']),
      lowestPremiumDiscountPct:
          _nullableDouble(payload['lowestPremiumDiscountPct']),
      averagePremiumDiscountPct:
          _nullableDouble(payload['averagePremiumDiscountPct']),
      firstDataTime: _wallClockDateTime(payload['firstDataTime']),
      lastDataTime: _wallClockDateTime(payload['lastDataTime']),
      latestMarketPrice: _nullableDouble(payload['latestMarketPrice']),
      latestEstimatedNav: _nullableDouble(payload['latestEstimatedNav']),
      date: _nullableDate(payload['date']),
      status: _status(payload),
      sourceStatusLabel: rawStatus.isEmpty ? _status(payload).label : rawStatus,
      sourceUrl: _string(payload['sourceUrl']),
      lastFetchedAt: _dateTime(payload['fetchedAt']) ?? DateTime.now(),
      isStale: payload['isStale'] == true,
      errorMessage: payload['errorMessage']?.toString(),
    );
  }

  @override
  Future<EtfPriceHistory> fetchPriceHistory({int limit = 5000}) async {
    final payload =
        await _getJson('/api/etf/00631l/history/price?limit=$limit');
    final rawStatus = _rawStatus(payload);
    final items = [
      for (final item in _list(payload['items']))
        _priceHistoryPointFromPayload(_map(item)),
    ];

    return EtfPriceHistory(
      points: items,
      status: _status(payload),
      sourceStatusLabel: rawStatus.isEmpty ? _status(payload).label : rawStatus,
      sourceUrl: _string(payload['sourceUrl']),
      lastFetchedAt: _dateTime(payload['fetchedAt']) ?? DateTime.now(),
      coverageStart: _nullableDate(payload['coverageStart']),
      coverageEnd: _nullableDate(payload['coverageEnd']),
      isCompleteFromListing: payload['isCompleteFromListing'] == true,
      errorMessage: payload['errorMessage']?.toString(),
    );
  }

  @override
  Future<EtfOperationsStatus> fetchOperationsStatus() async {
    final payload = await _getJson('/api/etf/00631l/operations/status');
    final rawStatus = _rawStatus(payload);
    final config = _map(payload['config']);
    final holdings = _map(payload['holdingsHistory']);
    final intraday = _map(payload['intradayNavHistory']);
    final export = _map(payload['export']);
    final backup = _map(payload['backup']);
    final report = _map(payload['report']);
    final dailyCycle = _map(payload['dailyCycle']);
    final integrity = _map(payload['integrity']);
    final integrityHoldings = _map(integrity['holdings']);
    final priceHistory = _map(payload['priceHistory']);
    final etfCatalog = _map(payload['etfCatalog']);
    final backtest = _map(payload['backtest']);
    final position = _map(payload['position']);
    final backendHealth = _map(payload['backendHealth']);
    final dataDirectoryHealth = _map(payload['dataDirectoryHealth']);
    final persistence = _map(dataDirectoryHealth['persistence']);
    final collector = _map(payload['collector']);

    return EtfOperationsStatus(
      status: _status(payload),
      sourceStatusLabel: rawStatus.isEmpty ? _status(payload).label : rawStatus,
      sourceContract: _string(payload['sourceContract']),
      sourceUrl: _string(payload['sourceUrl']),
      lastFetchedAt: _dateTime(payload['fetchedAt']) ?? DateTime.now(),
      sourceUpdatedAt: _wallClockDateTime(payload['sourceUpdatedAt']),
      isStale: payload['isStale'] == true,
      intradaySourceMode:
          _string(config['intradaySourceMode'], fallback: 'auto'),
      twseIntradayNavConfigured: config['twseIntradayNavConfigured'] == true,
      yuantaIntradayNavConfigured:
          config['yuantaIntradayNavConfigured'] == true,
      publicApiBaseUrl: _string(
        config['publicApiBaseUrl'] ?? backendHealth['publicApiBaseUrl'],
      ),
      allowedOrigins: _stringList(
        config['allowedOrigins'] ?? backendHealth['allowedOrigins'],
      ),
      dataRoot: _string(
        config['dataDir'] ??
            dataDirectoryHealth['dataRoot'] ??
            persistence['path'],
      ),
      dataPersistenceMode: _string(
        config['dataPersistenceMode'] ?? persistence['mode'],
        fallback: 'local',
      ),
      dataPersistenceWarning:
          (config['dataPersistenceWarning'] ?? persistence['warning'])
              ?.toString(),
      dataPathWritable: persistence['writable'] == true,
      dataPathPersistent: persistence['isPersistent'] == true,
      holdingsHistoryStatus: _string(
        holdings['sourceStatus'],
        fallback: 'unavailable',
      ),
      holdingsHistoryItemCount: _int(holdings['itemCount']),
      latestHoldingTradeDate: _nullableDate(holdings['latestTradeDate']),
      intradayHistoryStatus: _string(
        intraday['sourceStatus'],
        fallback: 'unavailable',
      ),
      intradaySampleCount: _int(intraday['sampleCount']),
      latestIntradayDataTime: _wallClockDateTime(intraday['latestDataTime']),
      intradayHistoryDate: _nullableDate(intraday['date']),
      priceHistoryStatus: _string(
        priceHistory['sourceStatus'],
        fallback: 'unavailable',
      ),
      priceHistoryRows: _int(priceHistory['rowCount']),
      priceHistoryCoverageStart: _nullableDate(priceHistory['coverageStart']),
      priceHistoryCoverageEnd: _nullableDate(priceHistory['coverageEnd']),
      priceHistoryCompleteFromListing:
          priceHistory['isCompleteFromListing'] == true,
      etfCatalogStatus: _string(
        etfCatalog['sourceStatus'],
        fallback: 'unavailable',
      ),
      etfCatalogRowCount: _int(etfCatalog['rowCount']),
      etfCatalogDataTime: _wallClockDateTime(etfCatalog['dataTime']),
      backtestStatus: _string(
        backtest['sourceStatus'],
        fallback: 'unavailable',
      ),
      backtestAvailable: backtest['available'] == true,
      positionStatus: _string(
        position['sourceStatus'],
        fallback: 'local_only',
      ),
      collectorOneShotCommand: _string(
        collector['oneShotCommand'],
        fallback: 'scripts\\00631l_collect_snapshot.cmd --samples 1',
      ),
      collectorIntradayCommand: _string(
        collector['intradayCommand'],
        fallback:
            'scripts\\00631l_collect_snapshot.cmd --skip-profile --skip-holdings --samples 20 --interval-seconds 15',
      ),
      envFileExists: config['envFileExists'] == true,
      missingEnvKeys: _stringList(config['missingKeys']),
      optionalMissingEnvKeys: _stringList(config['optionalMissingKeys']),
      dataDirReady: config['dataDirReady'] == true,
      exportDirReady: config['exportDirReady'] == true,
      backupDirReady: config['backupDirReady'] == true,
      exportAvailable: export['available'] == true,
      latestExportPath: export['latestFile']?.toString(),
      latestExportUpdatedAt: _wallClockDateTime(export['latestUpdatedAt']),
      backupAvailable: backup['available'] == true,
      latestBackupPath: backup['latestFile']?.toString(),
      latestBackupUpdatedAt: _wallClockDateTime(backup['latestUpdatedAt']),
      reportAvailable: report['sourceStatus'] == 'cached',
      latestReportPath: report['reportPath']?.toString(),
      latestReportGeneratedAt: _wallClockDateTime(report['generatedAt']),
      reportOverallStatus: _string(
        report['overallStatus'],
        fallback: 'missing',
      ),
      reportWarningCount: _int(report['warningCount']),
      reportFailureCount: _int(report['failureCount']),
      dailyCycleStatus: _string(
        dailyCycle['overallStatus'],
        fallback: 'missing',
      ),
      dailyCycleStartedAt: _wallClockDateTime(dailyCycle['startedAt']),
      dailyCycleFinishedAt: _wallClockDateTime(dailyCycle['finishedAt']),
      dailyCycleWarningCount: _int(dailyCycle['warningCount']),
      dailyCycleFailureCount: _int(dailyCycle['failureCount']),
      integrityStatus: _string(
        integrity['overallStatus'],
        fallback: 'missing',
      ),
      integrityWarningCount: _int(integrity['warningCount']),
      integrityFailureCount: _int(integrity['failureCount']),
      holdingsIntegrityRecordCount: _int(integrityHoldings['recordCount']),
      holdingsMissingWeekdayCount:
          _stringList(integrityHoldings['missingWeekdays']).length,
      holdingsMissingWeekdays: [
        for (final value in _stringList(integrityHoldings['missingWeekdays']))
          if (_nullableDate(value) != null) _nullableDate(value)!,
      ],
      errorMessage: payload['errorMessage']?.toString(),
    );
  }

  @override
  Future<EtfAiAnalysisSummary> fetchAiAnalysisSummary() async {
    final payload = await _getJson('/api/etf/00631l/analysis/summary');
    final statuses = _map(payload['sourceStatuses']);
    return EtfAiAnalysisSummary(
      source: _string(payload['source'], fallback: 'rule_based'),
      sourceStatusLabel:
          _rawStatus(payload).isEmpty ? 'cached' : _rawStatus(payload),
      generatedAt: _dateTime(payload['generatedAt']) ?? DateTime.now(),
      dataTime: _wallClockDateTime(payload['dataTime']),
      readinessLevel:
          _string(payload['readinessLevel'], fallback: 'unavailable'),
      bullets: _stringList(payload['bullets']),
      actionItems: _stringList(payload['actionItems']),
      sourceStatuses: {
        for (final entry in statuses.entries)
          entry.key.toString(): entry.value?.toString() ?? '',
      },
      disclaimer: _string(payload['disclaimer'], fallback: '非買賣建議'),
      errorMessage: payload['errorMessage']?.toString(),
    );
  }

  @override
  Future<EtfCatalog> fetchEtfCatalog() async {
    final payload = await _getJson('/api/etf/catalog');
    return EtfCatalog(
      items: [
        for (final rawItem in _list(payload['items']))
          _catalogItemFromPayload(_map(rawItem)),
      ],
      status: _status(payload),
      sourceStatusLabel: _rawStatus(payload).isEmpty
          ? _status(payload).label
          : _rawStatus(payload),
      sourceContract: _string(
        payload['sourceContract'],
        fallback: 'twse_all_etf_catalog',
      ),
      sourceUrl: _string(payload['sourceUrl']),
      lastFetchedAt: _dateTime(payload['fetchedAt']) ?? DateTime.now(),
      sourceUpdatedAt: _wallClockDateTime(payload['sourceUpdatedAt']),
      dataTime: _wallClockDateTime(payload['dataTime']),
      isStale: payload['isStale'] == true,
      userDelayMs: _int(payload['userDelayMs'], fallback: 15000),
      errorMessage: payload['errorMessage']?.toString(),
    );
  }

  Future<Map<String, dynamic>> _getJson(String path) async {
    final body = await _client.getString(_resolve(path), timeout: timeout);
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw const RepositoryFetchException(
        'Proxy returned a non-object JSON payload',
      );
    }
    return decoded;
  }

  Uri _resolve(String path) {
    final base = baseUri.toString().replaceFirst(RegExp(r'/+$'), '');
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$base$normalizedPath');
  }
}

EtfCatalogItem _catalogItemFromPayload(Map<String, dynamic> payload) {
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
  );
}

EtfPriceHistoryPoint _priceHistoryPointFromPayload(
  Map<String, dynamic> payload,
) {
  return EtfPriceHistoryPoint(
    date: _date(payload['date']),
    open: _nullableDouble(payload['open']),
    high: _nullableDouble(payload['high']),
    low: _nullableDouble(payload['low']),
    close: _double(payload['close']),
    adjustedOpen: _nullableDouble(payload['adjustedOpen']),
    adjustedHigh: _nullableDouble(payload['adjustedHigh']),
    adjustedLow: _nullableDouble(payload['adjustedLow']),
    adjustedClose: _nullableDouble(payload['adjustedClose']),
    adjustmentFactor: _nullableDouble(payload['adjustmentFactor']),
    volume: _nullableInt(payload['volume']),
    nav: _nullableDouble(payload['nav']),
    premiumDiscountPct: _nullableDouble(payload['premiumDiscountPct']),
    dailyReturnPct: _nullableDouble(payload['dailyReturnPct']),
    cumulativeReturnPct: _nullableDouble(payload['cumulativeReturnPct']),
    drawdownPct: _nullableDouble(payload['drawdownPct']),
  );
}

EtfHoldingsHistoryPoint _historyPointFromPayload(Map<String, dynamic> payload) {
  return EtfHoldingsHistoryPoint(
    tradeDate: _date(payload['tradeDate']),
    txWeightPct: _double(payload['txWeightPct']),
    tsmcWeightPct: _double(payload['tsmcWeightPct']),
    stockExposurePct: _double(payload['stockExposurePct']),
    futuresExposurePct: _double(payload['futuresExposurePct']),
    cashAndMarginPct: _double(payload['cashAndMarginPct']),
    navPerUnit: _double(payload['navPerUnit']),
    fundNetAssetValue: _double(payload['fundNetAssetValue']),
    outstandingUnits: _int(payload['outstandingUnits']),
    status: _status(payload),
    sourceHash: _string(payload['sourceHash']),
  );
}

EtfIntradayNavHistoryPoint _intradayHistoryPointFromPayload(
  Map<String, dynamic> payload,
) {
  return EtfIntradayNavHistoryPoint(
    dataTime: _wallClockDateTime(payload['dataTime']) ?? DateTime(1970),
    marketPrice: _nullableDouble(payload['marketPrice']),
    estimatedNav: _nullableDouble(payload['estimatedNav']),
    premiumDiscountPct: _nullableDouble(
      payload['premiumDiscountPct'] ?? payload['estimatedPremiumDiscountPct'],
    ),
    sourceContract: payload['sourceContract']?.toString(),
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

List<String> _stringList(Object? value) {
  return [
    for (final item in _list(value))
      if (item != null) item.toString(),
  ];
}

String _rawStatus(Map<String, dynamic> payload) {
  return payload['sourceStatus']?.toString().toLowerCase() ?? '';
}

EtfDataStatus _status(Map<String, dynamic> payload) {
  switch (_rawStatus(payload)) {
    case 'cached':
      return EtfDataStatus.cached;
    case 'mock':
      return EtfDataStatus.mock;
    case 'error':
    case 'unavailable':
      return EtfDataStatus.error;
    case 'stale':
      return EtfDataStatus.stale;
    case 'official':
    case 'proxy':
      return EtfDataStatus.proxy;
    default:
      return EtfDataStatus.proxy;
  }
}

void _throwIfErrorStatus(Map<String, dynamic> payload, String endpoint) {
  final status = _rawStatus(payload);
  if (status == 'error' || status == 'unavailable') {
    final message = payload['errorMessage']?.toString() ?? status;
    throw RepositoryFetchException('00631L proxy $endpoint failed: $message');
  }
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

DateTime _date(Object? value) {
  return _nullableDate(value) ?? DateTime(1970);
}

DateTime? _nullableDate(Object? value) {
  final parsed = _wallClockDateTime(value) ?? _dateTime(value);
  if (parsed == null) {
    return null;
  }
  return DateTime(parsed.year, parsed.month, parsed.day);
}

DateTime? _dateTime(Object? value) {
  if (value == null) {
    return null;
  }
  final text = value.toString();
  if (text.isEmpty) {
    return null;
  }
  return DateTime.tryParse(text);
}

DateTime? _wallClockDateTime(Object? value) {
  if (value == null) {
    return null;
  }
  final text = value.toString();
  final match = RegExp(
    r'^(\d{4})-(\d{2})-(\d{2})(?:T|\s)(\d{2}):(\d{2}):(\d{2})',
  ).firstMatch(text);
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
