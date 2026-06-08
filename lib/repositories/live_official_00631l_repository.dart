import '../models/leveraged_etf_lab.dart';
import 'official_00631l_repository.dart';
import 'yuanta_00631l_parser.dart';

typedef OfficialSourceFetcher = Future<String> Function(Uri uri);
typedef FuturesQuoteFetcher = Future<FuturesQuote> Function();

class LiveOfficial00631LRepository extends Official00631LRepository {
  LiveOfficial00631LRepository({
    OfficialSourceFetcher? fetcher,
    FuturesQuoteFetcher? futuresQuoteFetcher,
    Uri? profileUri,
    Uri? dailySnapshotUri,
    Uri? intradayNavUri,
    this.timeout = const Duration(seconds: 8),
    this.retryLimit = 2,
  })  : _fetcher = fetcher,
        _futuresQuoteFetcher = futuresQuoteFetcher,
        _profileUri =
            profileUri ?? Uri.parse(Yuanta00631LParser.basicInformationUrl),
        _dailySnapshotUri =
            dailySnapshotUri ?? Uri.parse(Yuanta00631LParser.ratioUrl),
        _intradayNavUri = intradayNavUri;

  final OfficialSourceFetcher? _fetcher;
  final FuturesQuoteFetcher? _futuresQuoteFetcher;
  final Uri _profileUri;
  final Uri _dailySnapshotUri;
  final Uri? _intradayNavUri;
  final Duration timeout;
  final int retryLimit;

  @override
  Future<LeveragedEtfProfile> fetchProfile() async {
    final now = DateTime.now();
    final source = await _fetchText(_profileUri);
    return Yuanta00631LParser.parseProfile(
      source,
      lastFetchedAt: now,
      status: EtfDataStatus.official,
    );
  }

  @override
  Future<EtfDailyHoldingSnapshot> fetchDailySnapshot() async {
    final now = DateTime.now();
    final source = await _fetchText(_dailySnapshotUri);
    return Yuanta00631LParser.parseDailyHoldingSnapshot(
      source,
      lastFetchedAt: now,
      status: EtfDataStatus.official,
    );
  }

  @override
  Future<EtfIntradayNav?> fetchIntradayNav() async {
    final uri = _intradayNavUri;
    if (uri == null) {
      throw const RepositoryFetchException(
        '即時淨值 live endpoint 尚未設定；Flutter Web 請透過 backend/proxy 提供 TWSE 格式 JSON。',
      );
    }

    final source = await _fetchText(uri);
    return Yuanta00631LParser.parseTwseIntradayNavJson(
      source,
      lastFetchedAt: DateTime.now(),
      status: EtfDataStatus.official,
    );
  }

  @override
  Future<FuturesQuote> fetchFuturesQuote() async {
    final fetcher = _futuresQuoteFetcher;
    if (fetcher == null) {
      throw const RepositoryFetchException(
        'TX live quote endpoint 尚未設定；請由 backend/proxy 正規化後注入 FuturesQuoteFetcher。',
      );
    }
    return fetcher().timeout(timeout);
  }

  Future<String> _fetchText(Uri uri) async {
    final fetcher = _fetcher;
    if (fetcher == null) {
      throw const RepositoryFetchException(
        'LiveOfficial00631LRepository 需要注入 fetcher；避免在 Flutter Web 直接抓官方頁面造成 CORS 阻塞。',
      );
    }

    Object? lastError;
    for (var attempt = 0; attempt <= retryLimit; attempt += 1) {
      try {
        return await fetcher(uri).timeout(timeout);
      } catch (error) {
        lastError = error;
        if (attempt == retryLimit) {
          break;
        }
        await Future<void>.delayed(Duration(milliseconds: 300 * (attempt + 1)));
      }
    }

    throw RepositoryFetchException('官方來源讀取失敗：$lastError');
  }
}
