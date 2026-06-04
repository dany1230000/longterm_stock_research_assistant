import '../models/etf.dart';
import '../models/etf_comparison.dart';
import 'etf_repository.dart';

class MockEtfRepository implements EtfRepository {
  @override
  Future<List<Etf>> fetchEtfs() async {
    return List.unmodifiable(_mockEtfs);
  }

  @override
  Future<EtfComparison> compareEtfs(
      String leftSymbol, String rightSymbol) async {
    final left = _mockEtfs.firstWhere((etf) => etf.symbol == leftSymbol);
    final right = _mockEtfs.firstWhere((etf) => etf.symbol == rightSymbol);
    final overlapRate = left.overlapRates[right.symbol] ??
        right.overlapRates[left.symbol] ??
        _estimateOverlap(left, right);

    return EtfComparison(
      left: left,
      right: right,
      overlapRate: overlapRate,
      overlapDescription: overlapRate >= 55
          ? '兩檔 ETF 持股重疊率偏高，研究時可留意曝險是否過度集中。'
          : '兩檔 ETF 重疊率相對較低，可作為不同曝險來源的研究參考。',
    );
  }

  double _estimateOverlap(Etf left, Etf right) {
    final leftNames = left.topHoldings.map((holding) => holding.name).toSet();
    final rightNames = right.topHoldings.map((holding) => holding.name).toSet();
    final overlap = leftNames.intersection(rightNames).length;
    return overlap / leftNames.length * 100;
  }
}

const _semiHoldings = [
  EtfHolding(name: '台積電', weight: 48.2),
  EtfHolding(name: '聯發科', weight: 6.8),
  EtfHolding(name: '鴻海', weight: 4.6),
  EtfHolding(name: '台達電', weight: 3.8),
  EtfHolding(name: '廣達', weight: 2.7),
];

const _dividendHoldings = [
  EtfHolding(name: '中華電', weight: 8.2),
  EtfHolding(name: '富邦金', weight: 7.6),
  EtfHolding(name: '統一', weight: 6.4),
  EtfHolding(name: '兆豐金', weight: 5.9),
  EtfHolding(name: '台塑', weight: 4.1),
];

final _mockEtfs = <Etf>[
  const Etf(
    symbol: '0050',
    name: '元大台灣50',
    type: '市值型',
    expenseRatio: 0.43,
    distributionFrequency: '半年配',
    lastYearReturn: 24.8,
    threeYearAnnualizedReturn: 11.2,
    volatility: 18.6,
    maxDrawdown: -21.4,
    topHoldings: _semiHoldings,
    industryExposure: {'半導體': 52.4, '電子代工': 9.1, '金融': 7.8, '其他': 30.7},
    overlapRates: {
      '006208': 88,
      '00878': 34,
      '00919': 31,
      '00929': 27,
      '00631L': 91
    },
    isLeveraged: false,
  ),
  const Etf(
    symbol: '006208',
    name: '富邦台50',
    type: '市值型',
    expenseRatio: 0.34,
    distributionFrequency: '半年配',
    lastYearReturn: 24.1,
    threeYearAnnualizedReturn: 10.9,
    volatility: 18.2,
    maxDrawdown: -20.9,
    topHoldings: _semiHoldings,
    industryExposure: {'半導體': 51.8, '電子代工': 9.4, '金融': 8.0, '其他': 30.8},
    overlapRates: {
      '0050': 88,
      '00878': 33,
      '00919': 30,
      '00929': 26,
      '00631L': 89
    },
    isLeveraged: false,
  ),
  const Etf(
    symbol: '00878',
    name: '國泰永續高股息',
    type: '高股息',
    expenseRatio: 0.58,
    distributionFrequency: '季配',
    lastYearReturn: 13.7,
    threeYearAnnualizedReturn: 8.4,
    volatility: 13.2,
    maxDrawdown: -15.8,
    topHoldings: _dividendHoldings,
    industryExposure: {
      '金融': 28.5,
      '電信': 12.0,
      '食品': 8.8,
      '塑化': 7.2,
      '其他': 43.5
    },
    overlapRates: {
      '0050': 34,
      '006208': 33,
      '00919': 62,
      '00929': 48,
      '00631L': 30
    },
    isLeveraged: false,
  ),
  const Etf(
    symbol: '00919',
    name: '群益台灣精選高息',
    type: '高股息',
    expenseRatio: 0.64,
    distributionFrequency: '季配',
    lastYearReturn: 15.9,
    threeYearAnnualizedReturn: 9.1,
    volatility: 14.0,
    maxDrawdown: -16.9,
    topHoldings: _dividendHoldings,
    industryExposure: {
      '金融': 31.0,
      '電信': 10.4,
      '食品': 7.6,
      '電子': 18.8,
      '其他': 32.2
    },
    overlapRates: {
      '0050': 31,
      '006208': 30,
      '00878': 62,
      '00929': 55,
      '00631L': 28
    },
    isLeveraged: false,
  ),
  const Etf(
    symbol: '00929',
    name: '復華台灣科技優息',
    type: '科技高息',
    expenseRatio: 0.72,
    distributionFrequency: '月配',
    lastYearReturn: 12.4,
    threeYearAnnualizedReturn: 7.8,
    volatility: 15.5,
    maxDrawdown: -18.6,
    topHoldings: [
      EtfHolding(name: '聯發科', weight: 8.0),
      EtfHolding(name: '台達電', weight: 6.6),
      EtfHolding(name: '聯電', weight: 5.4),
      EtfHolding(name: '瑞昱', weight: 4.7),
      EtfHolding(name: '中華電', weight: 4.3),
    ],
    industryExposure: {'半導體': 36.0, '電子零組件': 20.0, '電信': 5.0, '其他': 39.0},
    overlapRates: {
      '0050': 27,
      '006208': 26,
      '00878': 48,
      '00919': 55,
      '00631L': 25
    },
    isLeveraged: false,
  ),
  const Etf(
    symbol: '00631L',
    name: '元大台灣50正2',
    type: '槓桿型',
    expenseRatio: 1.02,
    distributionFrequency: '不定期',
    lastYearReturn: 42.6,
    threeYearAnnualizedReturn: 15.4,
    volatility: 37.8,
    maxDrawdown: -45.2,
    topHoldings: _semiHoldings,
    industryExposure: {'半導體': 53.0, '電子代工': 9.0, '金融': 7.6, '其他': 30.4},
    overlapRates: {
      '0050': 91,
      '006208': 89,
      '00878': 30,
      '00919': 28,
      '00929': 25
    },
    isLeveraged: true,
  ),
];
