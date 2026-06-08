import 'dart:convert';

import '../models/leveraged_etf_lab.dart';
import 'mock_00631l_repository.dart';
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
  final Mock00631LRepository _mockFallback = Mock00631LRepository();

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
  Future<FuturesQuote> fetchFuturesQuote() {
    return _mockFallback.fetchFuturesQuote();
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
