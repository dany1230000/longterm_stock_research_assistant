import '../models/leveraged_etf_lab.dart';
import 'official_00631l_repository.dart';
import 'yuanta_00631l_parser.dart';

class Mock00631LRepository extends Official00631LRepository {
  Mock00631LRepository({
    DateTime Function()? clock,
  }) : _clock = clock ?? (() => DateTime(2026, 6, 8, 10, 15));

  final DateTime Function() _clock;

  @override
  Future<LeveragedEtfProfile> fetchProfile() async {
    return Yuanta00631LParser.parseProfile(
      mock00631LProfileFixture,
      lastFetchedAt: _clock(),
      status: EtfDataStatus.mock,
    );
  }

  @override
  Future<EtfDailyHoldingSnapshot> fetchDailySnapshot() async {
    return Yuanta00631LParser.parseDailyHoldingSnapshot(
      mock00631LDailyHoldingFixture,
      lastFetchedAt: _clock(),
      status: EtfDataStatus.mock,
    );
  }

  @override
  Future<EtfIntradayNav?> fetchIntradayNav() async {
    return Yuanta00631LParser.parseTwseIntradayNavJson(
      mock00631LTwseIntradayNavFixture,
      lastFetchedAt: _clock(),
      status: EtfDataStatus.mock,
    );
  }

  @override
  Future<FuturesQuote> fetchFuturesQuote() async {
    return FuturesQuote(
      symbol: 'TX',
      contractMonth: '202606',
      txPrice: 27380,
      weightedIndex: 27295.48,
      nightSessionChange: 0.35,
      status: EtfDataStatus.mock,
      lastFetchedAt: _clock(),
      sourceContract: 'mock_tx_quote',
      sourceUrl: 'mock://tx-quote',
      dataTime: _clock(),
      isStale: false,
    );
  }

  @override
  Future<EtfHoldingsHistory> fetchHoldingsHistorySummary({
    int limit = 30,
  }) async {
    return EtfHoldingsHistory.empty(
      lastFetchedAt: _clock(),
      status: EtfDataStatus.mock,
      sourceStatusLabel: 'mock',
      errorMessage: 'Mock mode has no saved holdings history.',
    );
  }

  @override
  Future<EtfIntradayNavHistorySummary> fetchIntradayNavHistorySummary() async {
    return EtfIntradayNavHistorySummary.empty(
      lastFetchedAt: _clock(),
      status: EtfDataStatus.mock,
      sourceStatusLabel: 'mock',
      errorMessage: 'Mock mode has no saved intraday NAV history.',
    );
  }

  @override
  Future<EtfOperationsStatus> fetchOperationsStatus() async {
    return EtfOperationsStatus.empty(
      lastFetchedAt: _clock(),
      status: EtfDataStatus.mock,
      sourceStatusLabel: 'mock',
      errorMessage: 'Mock mode has no collector or local history status.',
    );
  }

  @override
  Future<EtfAiAnalysisSummary> fetchAiAnalysisSummary() async {
    return EtfAiAnalysisSummary.mockFallback(now: _clock());
  }

  @override
  Future<EtfPriceHistory> fetchPriceHistory({int limit = 5000}) async {
    return fetchEtfPriceHistory('00631L', limit: limit);
  }

  @override
  Future<EtfPriceHistory> fetchEtfPriceHistory(
    String code, {
    int limit = 5000,
  }) async {
    final normalized = code.trim().toUpperCase();
    final now = _clock();
    final profile = _mockEtfHistoryProfile(normalized);
    final points = [
      EtfPriceHistoryPoint(
        date: _mockHistoryStart,
        close: profile.start,
        open: profile.start * 0.98,
        high: profile.start * 1.01,
        low: profile.start * 0.97,
        volume: profile.volume,
      ),
      EtfPriceHistoryPoint(
        date: _mockHistoryMid,
        close: profile.mid,
        open: profile.mid * 0.99,
        high: profile.mid * 1.01,
        low: profile.mid * 0.98,
        volume: profile.volume + 1200000,
      ),
      EtfPriceHistoryPoint(
        date: _mockHistoryEnd,
        close: profile.end,
        open: profile.end * 0.99,
        high: profile.end * 1.01,
        low: profile.end * 0.98,
        volume: profile.volume + 2400000,
      ),
    ].take(limit).toList(growable: false);
    return EtfPriceHistory(
      code: normalized,
      name: profile.name,
      points: points,
      status: EtfDataStatus.mock,
      sourceStatusLabel: 'mock',
      sourceUrl: 'mock://$normalized-price-history',
      lastFetchedAt: now,
      coverageStart: points.first.date,
      coverageEnd: points.last.date,
      isCompleteFromListing: false,
      errorMessage: 'Mock price history is for UI fallback only.',
    );
  }

  @override
  Future<EtfCatalog> fetchEtfCatalog() async {
    final now = _clock();
    return EtfCatalog(
      items: [
        EtfCatalogItem(
          code: '00631L',
          name: '元大台灣50正2',
          marketPrice: 35.2,
          estimatedNav: 35.1,
          premiumDiscountPct: 0.28,
          dataTime: now,
          targetType: '槓桿 ETF',
        ),
        EtfCatalogItem(
          code: '0050',
          name: '元大台灣50',
          marketPrice: 185.4,
          estimatedNav: 185.3,
          premiumDiscountPct: 0.05,
          dataTime: now,
          targetType: '台股 ETF',
        ),
        EtfCatalogItem(
          code: '006208',
          name: '富邦台50',
          marketPrice: 112.3,
          estimatedNav: 112.4,
          premiumDiscountPct: -0.09,
          dataTime: now,
          targetType: '台股 ETF',
        ),
        EtfCatalogItem(
          code: '00878',
          name: '國泰永續高股息',
          marketPrice: 22.4,
          estimatedNav: 22.42,
          premiumDiscountPct: -0.08,
          dataTime: now,
          targetType: '高股息 ETF',
        ),
      ],
      status: EtfDataStatus.mock,
      sourceStatusLabel: 'mock',
      sourceContract: 'mock_twse_all_etf_catalog',
      sourceUrl: 'mock://twse-etf-catalog',
      lastFetchedAt: now,
      sourceUpdatedAt: now,
      dataTime: now,
      isStale: false,
    );
  }

  @override
  Future<Etf00631LLabData> fetchLabData() async {
    final profile = await fetchProfile();
    final snapshot = await fetchDailySnapshot();
    final intradayNav = await fetchIntradayNav();
    final futuresQuote = await fetchFuturesQuote();
    final history = await fetchHoldingsHistorySummary();
    final intradayHistory = await fetchIntradayNavHistorySummary();
    final operationsStatus = await fetchOperationsStatus();
    final aiAnalysis = await fetchAiAnalysisSummary();
    final priceHistory = await fetchPriceHistory();
    final etfCatalog = await fetchEtfCatalog();
    final now = _clock();

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
}

final _mockHistoryStart = DateTime(2024, 1, 2);
final _mockHistoryMid = DateTime(2025, 1, 2);
final _mockHistoryEnd = DateTime(2026, 6, 8);

({String name, double start, double mid, double end, int volume})
    _mockEtfHistoryProfile(String code) {
  switch (code) {
    case '0050':
      return (
        name: '元大台灣50',
        start: 138.2,
        mid: 166.5,
        end: 185.4,
        volume: 9000000,
      );
    case '006208':
      return (
        name: '富邦台50',
        start: 82.6,
        mid: 100.8,
        end: 112.3,
        volume: 3500000,
      );
    case '00878':
      return (
        name: '國泰永續高股息',
        start: 18.1,
        mid: 21.3,
        end: 22.4,
        volume: 42000000,
      );
    case '00919':
      return (
        name: '群益台灣精選高息',
        start: 15.8,
        mid: 20.6,
        end: 24.1,
        volume: 36000000,
      );
    default:
      return (
        name: '00631L',
        start: 22.15,
        mid: 28.40,
        end: 35.20,
        volume: 18000000,
      );
  }
}

const mock00631LProfileFixture = '''
Fund Profile
Benchmark Index
臺灣50指數 〖本基金為槓桿型指數股票型基金，以追蹤臺灣50指數單日正向2倍報酬之績效表現為操作目標〗
Inception Date
2014/10/23
Listing Date
2014/10/31
Dividends
NO
Risk Level
RR5
Management Fee
1.00%
Custodian Fee
0.04%
Index Compilation Rule
50檔 〖本基金為槓桿型指數股票型基金，主要投資於國內上市股票及證券相關商品，且以做多期貨為主要交易，其整體曝險部位不得低於本基金淨資產價值之180%，且不得超過220%，詳情請參閱公開說明書〗
''';

const mock00631LDailyHoldingFixture = '''
Fund Holding
Trade Date:
2026/06/05
Fund Net Asset Value (NTD)
NTD \$189,796,511,953.00
Net Asset Value Per Unit (NTD)
NTD \$36.56
Outstanding Units (shares)
5,190,848,000
Fund Asset
Stock
NTD \$71,056,425,000
ETF
NTD \$0.00
Bond
NTD \$0.00
Futures
NTD \$306,587,054,000
Asset Holdings
Trade Date:
2026/06/05
Holdings
Cash
保證金
NTD \$79,303,829,574
現金
NTD \$26,950,925,242
附買回債券
NTD \$19,950,000,000
應收利息
NTD \$129,448,503
應付申購預收款
NTD \$-1,758,961,440
基金權重-股票
Trade Date:
2026/06/05
商品代碼
商品名稱
商品數量
商品權重
商品代碼 2330
商品名稱 台積電
商品數量 30045000
商品權重 37.44
基金權重-期貨
Trade Date:
2026/06/05
商品代碼
商品名稱
商品數量
商品權重
商品年月
商品代碼 TX
商品名稱 臺股期貨
商品數量 33895
商品權重 161.53
商品年月 202606
Yuanta Group
''';

const mock00631LTwseIntradayNavFixture = '''
{
  "msgArray": [
    {
      "a": "0050",
      "b": "元大台灣50",
      "c": "5000000000",
      "d": "0",
      "e": "210.10",
      "f": "210.20",
      "g": "-0.05",
      "h": "209.80",
      "i": "20260605",
      "j": "13:30:00",
      "k": "1"
    },
    {
      "a": "00631L",
      "b": "元大台灣50正2",
      "c": "5190848000",
      "d": "0",
      "e": "36.72",
      "f": "36.56",
      "g": "0.44",
      "h": "36.30",
      "i": "20260605",
      "j": "13:30:00",
      "k": "1"
    }
  ],
  "refURL": "https://www.yuantaetfs.com/product/detail/00631L/INav",
  "userDelay": "15000",
  "rtMessage": "OK",
  "rtCode": "0000"
}
''';
