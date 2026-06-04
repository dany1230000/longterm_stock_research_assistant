import '../models/financial_trend.dart';
import '../models/risk_alert.dart';
import '../models/screener_condition.dart';
import '../models/stock.dart';
import '../models/stock_metric.dart';
import '../models/valuation_metric.dart';
import 'stock_repository.dart';

class MockStockRepository implements StockRepository {
  MockStockRepository();

  final List<Stock> _stocks = _mockStocks;

  @override
  Future<List<Stock>> fetchWatchlist() async {
    return List.unmodifiable(_stocks);
  }

  @override
  Future<Stock?> findBySymbol(String symbol) async {
    for (final stock in _stocks) {
      if (stock.symbol == symbol) {
        return stock;
      }
    }
    return null;
  }

  @override
  Future<List<Stock>> filterByCondition(ScreenerCondition condition) async {
    final result = _stocks.where((stock) {
      final metric = stock.metric;
      final valuation = stock.valuation;
      final maCondition = !condition.requireAboveMa200 || metric.aboveMa200;
      final industryCondition =
          condition.industry == '全部' || stock.industry == condition.industry;
      final maxSeverity = _maxRiskSeverity(stock);
      final riskCondition = _severityRank(maxSeverity) <=
          _severityRank(condition.maxRiskSeverity);
      return metric.roe >= condition.minRoe &&
          metric.revenueYoy >= condition.minRevenueYoy &&
          valuation.pe <= condition.maxPe &&
          valuation.pb <= condition.maxPb &&
          valuation.dividendYield >= condition.minDividendYield &&
          metric.qualityScore >= condition.minQualityScore &&
          metric.growthScore >= condition.minGrowthScore &&
          metric.valuationScore >= condition.minValuationScore &&
          riskCondition &&
          maCondition &&
          industryCondition;
    }).toList();

    result.sort((a, b) {
      switch (condition.sortOption) {
        case ScreenerSortOption.qualityScore:
          return b.metric.qualityScore.compareTo(a.metric.qualityScore);
        case ScreenerSortOption.valuationScore:
          return b.metric.valuationScore.compareTo(a.metric.valuationScore);
        case ScreenerSortOption.growthScore:
          return b.metric.growthScore.compareTo(a.metric.growthScore);
        case ScreenerSortOption.riskLevel:
          return _severityRank(_maxRiskSeverity(a))
              .compareTo(_severityRank(_maxRiskSeverity(b)));
        case ScreenerSortOption.lastYearReturn:
          return b.metric.lastYearReturn.compareTo(a.metric.lastYearReturn);
      }
    });
    return result;
  }

  @override
  Future<List<String>> fetchIndustries() async {
    final industries = _stocks.map((stock) => stock.industry).toSet().toList()
      ..sort();
    return ['全部', ...industries];
  }

  RiskSeverity _maxRiskSeverity(Stock stock) {
    if (stock.riskAlerts.any((alert) => alert.severity == RiskSeverity.high)) {
      return RiskSeverity.high;
    }
    if (stock.riskAlerts
        .any((alert) => alert.severity == RiskSeverity.medium)) {
      return RiskSeverity.medium;
    }
    return RiskSeverity.low;
  }

  int _severityRank(RiskSeverity severity) {
    switch (severity) {
      case RiskSeverity.low:
        return 0;
      case RiskSeverity.medium:
        return 1;
      case RiskSeverity.high:
        return 2;
    }
  }
}

const _summary =
    '這家公司近期營收與獲利資料仍具觀察價值，但估值分位、產業循環與現金流變化需要同步檢視。此內容僅作研究參考，不構成投資建議。';

final _mockStocks = <Stock>[
  Stock(
    symbol: '2330',
    name: '台積電',
    industry: '半導體製造',
    marketCap: 23800,
    latestClose: 918,
    high52Week: 1015,
    low52Week: 705,
    pricePositionDescription: '目前價格位於 52 週區間偏高位置，適合作為估值分位與產業需求同步觀察樣本。',
    lastUpdated: DateTime(2026, 6, 4, 8, 30),
    metric: const StockMetric(
      qualityScore: 88,
      growthScore: 86,
      profitabilityScore: 93,
      safetyScore: 88,
      valuationScore: 61,
      trendScore: 84,
      roe: 27.8,
      revenueYoy: 16.4,
      lastYearReturn: 28.5,
      aboveMa200: true,
    ),
    valuation: const ValuationMetric(
      pe: 24.8,
      pb: 6.2,
      dividendYield: 1.8,
      pePercentile5y: 76,
      pbPercentile5y: 82,
      rangeLabel: '歷史偏高',
    ),
    financialTrend: const FinancialTrend(
      epsLast8Quarters: [7.9, 8.1, 8.7, 9.0, 9.3, 9.8, 10.1, 10.5],
      roeLast8Quarters: [24.2, 24.6, 25.1, 25.7, 26.4, 26.9, 27.3, 27.8],
      grossMarginLast8Quarters: [
        53.2,
        53.7,
        54.0,
        54.3,
        54.5,
        54.1,
        53.9,
        54.2
      ],
      revenueYoyLast12Months: [
        8.5,
        9.1,
        10.4,
        12.8,
        14.1,
        15.2,
        16.4,
        17.0,
        16.8,
        16.3,
        15.9,
        16.4
      ],
    ),
    riskAlerts: const [
      RiskAlert(
        title: '估值分位偏高',
        severity: RiskSeverity.medium,
        description: 'PE 與 PB 分位位於五年歷史中上緣，後續需搭配獲利成長與資本支出節奏觀察。',
      ),
      RiskAlert(
        title: '價格位置接近區間上緣',
        severity: RiskSeverity.medium,
        description: '價格位階偏高時，研究假設對營收與毛利率變化較敏感。',
      ),
    ],
    tags: ['估值偏高', '趨勢良好', '現金流穩定'],
    mockSummary: _summary,
  ),
  Stock(
    symbol: '2317',
    name: '鴻海',
    industry: '電子代工',
    marketCap: 2840,
    latestClose: 196,
    high52Week: 224,
    low52Week: 132,
    pricePositionDescription: '目前價格位於 52 週區間中上緣，研究重點可放在毛利結構與新業務貢獻。',
    lastUpdated: DateTime(2026, 6, 4, 8, 28),
    metric: const StockMetric(
      qualityScore: 73,
      growthScore: 69,
      profitabilityScore: 66,
      safetyScore: 82,
      valuationScore: 78,
      trendScore: 77,
      roe: 11.8,
      revenueYoy: 6.4,
      lastYearReturn: 22.7,
      aboveMa200: true,
    ),
    valuation: const ValuationMetric(
      pe: 16.9,
      pb: 1.6,
      dividendYield: 3.2,
      pePercentile5y: 44,
      pbPercentile5y: 38,
      rangeLabel: '中性',
    ),
    financialTrend: const FinancialTrend(
      epsLast8Quarters: [2.1, 2.3, 2.2, 2.5, 2.6, 2.7, 2.8, 2.9],
      roeLast8Quarters: [10.1, 10.3, 10.5, 10.7, 11.0, 11.2, 11.5, 11.8],
      grossMarginLast8Quarters: [6.2, 6.3, 6.4, 6.6, 6.7, 6.8, 6.9, 7.0],
      revenueYoyLast12Months: [
        2.0,
        2.5,
        3.2,
        4.1,
        4.9,
        5.6,
        6.0,
        6.3,
        6.7,
        6.5,
        6.2,
        6.4
      ],
    ),
    riskAlerts: const [
      RiskAlert(
        title: '毛利率改善仍需追蹤',
        severity: RiskSeverity.medium,
        description: '獲利能力受產品組合、產能利用率與新業務貢獻影響，需搭配季度財報檢視。',
      ),
    ],
    tags: ['估值中性', '趨勢良好', '毛利率觀察'],
    mockSummary: _summary,
  ),
  Stock(
    symbol: '2454',
    name: '聯發科',
    industry: 'IC 設計',
    marketCap: 1850,
    latestClose: 1215,
    high52Week: 1340,
    low52Week: 925,
    pricePositionDescription: '目前價格位於 52 週區間中上緣，需觀察產品週期與終端需求變化。',
    lastUpdated: DateTime(2026, 6, 4, 8, 26),
    metric: const StockMetric(
      qualityScore: 80,
      growthScore: 77,
      profitabilityScore: 83,
      safetyScore: 79,
      valuationScore: 66,
      trendScore: 80,
      roe: 21.4,
      revenueYoy: 9.8,
      lastYearReturn: 18.2,
      aboveMa200: true,
    ),
    valuation: const ValuationMetric(
      pe: 22.3,
      pb: 4.8,
      dividendYield: 3.9,
      pePercentile5y: 68,
      pbPercentile5y: 61,
      rangeLabel: '中性',
    ),
    financialTrend: const FinancialTrend(
      epsLast8Quarters: [13.6, 13.2, 14.1, 14.8, 15.0, 15.4, 15.8, 16.2],
      roeLast8Quarters: [19.0, 19.3, 19.8, 20.2, 20.7, 21.0, 21.2, 21.4],
      grossMarginLast8Quarters: [
        47.1,
        47.4,
        47.0,
        47.6,
        48.0,
        48.2,
        47.9,
        48.1
      ],
      revenueYoyLast12Months: [
        4.8,
        5.3,
        6.2,
        7.1,
        7.8,
        8.6,
        9.1,
        9.5,
        10.2,
        10.0,
        9.7,
        9.8
      ],
    ),
    riskAlerts: const [
      RiskAlert(
        title: '產品週期變動需追蹤',
        severity: RiskSeverity.medium,
        description: '營收成長與終端需求關聯高，後續需持續觀察月營收與毛利率變化。',
      ),
      RiskAlert(
        title: '股利率受盈餘分配影響',
        severity: RiskSeverity.low,
        description: '殖利率為模擬資料推估，仍需搭配實際盈餘分配政策檢視。',
      ),
    ],
    tags: ['營收轉強', '股利穩定', '毛利率觀察'],
    mockSummary: _summary,
  ),
  Stock(
    symbol: '2308',
    name: '台達電',
    industry: '電源與能源管理',
    marketCap: 980,
    latestClose: 372,
    high52Week: 431,
    low52Week: 286,
    pricePositionDescription: '目前價格位於 52 週區間中上緣，研究重點可放在毛利率與能源管理需求。',
    lastUpdated: DateTime(2026, 6, 4, 8, 24),
    metric: const StockMetric(
      qualityScore: 83,
      growthScore: 82,
      profitabilityScore: 81,
      safetyScore: 85,
      valuationScore: 70,
      trendScore: 76,
      roe: 19.5,
      revenueYoy: 12.6,
      lastYearReturn: 14.9,
      aboveMa200: true,
    ),
    valuation: const ValuationMetric(
      pe: 25.6,
      pb: 5.1,
      dividendYield: 2.1,
      pePercentile5y: 64,
      pbPercentile5y: 59,
      rangeLabel: '中性',
    ),
    financialTrend: const FinancialTrend(
      epsLast8Quarters: [3.4, 3.6, 3.7, 3.9, 4.1, 4.2, 4.3, 4.5],
      roeLast8Quarters: [17.5, 17.9, 18.1, 18.4, 18.8, 19.0, 19.2, 19.5],
      grossMarginLast8Quarters: [
        29.0,
        29.4,
        29.8,
        30.2,
        30.5,
        30.7,
        30.9,
        31.2
      ],
      revenueYoyLast12Months: [
        6.1,
        6.8,
        7.9,
        8.5,
        9.4,
        10.2,
        11.1,
        11.7,
        12.3,
        12.8,
        12.4,
        12.6
      ],
    ),
    riskAlerts: const [
      RiskAlert(
        title: '估值略高於歷史中位',
        severity: RiskSeverity.low,
        description: '目前估值略高於五年中位數，需與成長率及產業需求同步檢視。',
      ),
    ],
    tags: ['營收轉強', '現金流穩定', '估值中性'],
    mockSummary: _summary,
  ),
  Stock(
    symbol: '2412',
    name: '中華電',
    industry: '電信服務',
    marketCap: 930,
    latestClose: 126,
    high52Week: 132,
    low52Week: 112,
    pricePositionDescription: '目前價格位於 52 週區間偏高位置，電信研究可著重現金流、股利政策與資本支出。',
    lastUpdated: DateTime(2026, 6, 4, 8, 22),
    metric: const StockMetric(
      qualityScore: 76,
      growthScore: 58,
      profitabilityScore: 78,
      safetyScore: 90,
      valuationScore: 58,
      trendScore: 70,
      roe: 10.6,
      revenueYoy: 3.2,
      lastYearReturn: 7.4,
      aboveMa200: true,
    ),
    valuation: const ValuationMetric(
      pe: 27.2,
      pb: 2.5,
      dividendYield: 3.6,
      pePercentile5y: 84,
      pbPercentile5y: 78,
      rangeLabel: '歷史偏高',
    ),
    financialTrend: const FinancialTrend(
      epsLast8Quarters: [1.12, 1.16, 1.18, 1.20, 1.19, 1.21, 1.23, 1.24],
      roeLast8Quarters: [9.8, 9.9, 10.0, 10.1, 10.2, 10.3, 10.5, 10.6],
      grossMarginLast8Quarters: [
        36.8,
        36.9,
        37.0,
        37.1,
        37.0,
        37.2,
        37.3,
        37.2
      ],
      revenueYoyLast12Months: [
        1.2,
        1.4,
        1.6,
        1.8,
        2.1,
        2.5,
        2.8,
        3.0,
        3.3,
        3.1,
        3.2,
        3.2
      ],
    ),
    riskAlerts: const [
      RiskAlert(
        title: '估值分位偏高',
        severity: RiskSeverity.medium,
        description: 'PE 分位高於五年中位數，穩定現金流仍需與成長幅度一起觀察。',
      ),
      RiskAlert(
        title: '成長速度有限',
        severity: RiskSeverity.low,
        description: '營收成長幅度相對溫和，研究時可納入資本支出與股利政策假設。',
      ),
    ],
    tags: ['估值偏高', '現金流穩定', '成長溫和'],
    mockSummary: _summary,
  ),
  Stock(
    symbol: '2881',
    name: '富邦金',
    industry: '金融保險',
    marketCap: 1190,
    latestClose: 84.6,
    high52Week: 91.2,
    low52Week: 62.5,
    pricePositionDescription: '目前價格位於 52 週區間中上緣，金融股研究需同步檢視利率、資產品質與股利政策。',
    lastUpdated: DateTime(2026, 6, 4, 8, 20),
    metric: const StockMetric(
      qualityScore: 72,
      growthScore: 63,
      profitabilityScore: 75,
      safetyScore: 76,
      valuationScore: 74,
      trendScore: 72,
      roe: 13.2,
      revenueYoy: 4.1,
      lastYearReturn: 12.4,
      aboveMa200: true,
    ),
    valuation: const ValuationMetric(
      pe: 13.5,
      pb: 1.35,
      dividendYield: 4.8,
      pePercentile5y: 52,
      pbPercentile5y: 49,
      rangeLabel: '中性',
    ),
    financialTrend: const FinancialTrend(
      epsLast8Quarters: [1.3, 1.4, 1.2, 1.5, 1.6, 1.7, 1.6, 1.8],
      roeLast8Quarters: [11.4, 11.8, 12.0, 12.3, 12.6, 12.9, 13.0, 13.2],
      grossMarginLast8Quarters: [
        21.0,
        21.2,
        20.8,
        21.4,
        21.7,
        21.6,
        21.8,
        22.1
      ],
      revenueYoyLast12Months: [
        1.0,
        1.4,
        1.8,
        2.2,
        2.7,
        3.2,
        3.6,
        4.0,
        4.4,
        4.2,
        4.0,
        4.1
      ],
    ),
    riskAlerts: const [
      RiskAlert(
        title: '近三個月營收成長放緩',
        severity: RiskSeverity.medium,
        description: '近期年增率呈現趨緩，需觀察利差、投資收益與保險業務變化。',
      ),
      RiskAlert(
        title: '資產品質敏感度',
        severity: RiskSeverity.low,
        description: '金融業評估需納入景氣循環與信用成本變化。',
      ),
    ],
    tags: ['營收轉弱', '股利穩定', '估值中性'],
    mockSummary: _summary,
  ),
  Stock(
    symbol: '1301',
    name: '台塑',
    industry: '塑化原料',
    marketCap: 520,
    latestClose: 72.8,
    high52Week: 87.5,
    low52Week: 63.2,
    pricePositionDescription: '目前價格位於 52 週區間中段，塑化研究需觀察利差、油價與下游需求。',
    lastUpdated: DateTime(2026, 6, 4, 8, 18),
    metric: const StockMetric(
      qualityScore: 61,
      growthScore: 52,
      profitabilityScore: 58,
      safetyScore: 68,
      valuationScore: 72,
      trendScore: 55,
      roe: 7.4,
      revenueYoy: -2.8,
      lastYearReturn: -8.6,
      aboveMa200: false,
    ),
    valuation: const ValuationMetric(
      pe: 18.4,
      pb: 1.2,
      dividendYield: 4.1,
      pePercentile5y: 37,
      pbPercentile5y: 34,
      rangeLabel: '歷史偏低',
    ),
    financialTrend: const FinancialTrend(
      epsLast8Quarters: [1.4, 1.1, 0.9, 0.7, 0.8, 0.6, 0.7, 0.8],
      roeLast8Quarters: [9.5, 8.8, 8.1, 7.6, 7.4, 7.0, 7.2, 7.4],
      grossMarginLast8Quarters: [
        12.8,
        12.2,
        11.8,
        11.3,
        11.5,
        11.0,
        11.2,
        11.6
      ],
      revenueYoyLast12Months: [
        -6.0,
        -5.4,
        -4.8,
        -4.1,
        -3.5,
        -3.2,
        -2.9,
        -2.5,
        -2.2,
        -2.6,
        -2.9,
        -2.8
      ],
    ),
    riskAlerts: const [
      RiskAlert(
        title: '營收動能仍偏弱',
        severity: RiskSeverity.high,
        description: '模擬資料顯示近 12 個月營收年增率仍為負值，需觀察產品利差與需求修復。',
      ),
      RiskAlert(
        title: '尚未站上 200 日均線',
        severity: RiskSeverity.medium,
        description: '趨勢條件仍待改善，研究時可降低趨勢分數權重的解讀強度。',
      ),
    ],
    tags: ['估值偏低', '營收轉弱', '景氣循環觀察'],
    mockSummary: _summary,
  ),
  Stock(
    symbol: '1216',
    name: '統一',
    industry: '食品與通路',
    marketCap: 450,
    latestClose: 82.3,
    high52Week: 88.0,
    low52Week: 72.6,
    pricePositionDescription: '目前價格位於 52 週區間中上緣，民生消費研究可聚焦毛利率、通路展店與現金流。',
    lastUpdated: DateTime(2026, 6, 4, 8, 16),
    metric: const StockMetric(
      qualityScore: 77,
      growthScore: 70,
      profitabilityScore: 76,
      safetyScore: 84,
      valuationScore: 65,
      trendScore: 73,
      roe: 15.4,
      revenueYoy: 7.2,
      lastYearReturn: 10.8,
      aboveMa200: true,
    ),
    valuation: const ValuationMetric(
      pe: 24.1,
      pb: 3.1,
      dividendYield: 3.0,
      pePercentile5y: 66,
      pbPercentile5y: 57,
      rangeLabel: '中性',
    ),
    financialTrend: const FinancialTrend(
      epsLast8Quarters: [1.2, 1.3, 1.4, 1.4, 1.5, 1.6, 1.5, 1.7],
      roeLast8Quarters: [13.8, 14.0, 14.2, 14.5, 14.8, 15.0, 15.2, 15.4],
      grossMarginLast8Quarters: [
        33.2,
        33.4,
        33.6,
        33.8,
        34.0,
        34.1,
        34.2,
        34.4
      ],
      revenueYoyLast12Months: [
        3.8,
        4.1,
        4.7,
        5.2,
        5.8,
        6.1,
        6.6,
        6.9,
        7.1,
        7.4,
        7.0,
        7.2
      ],
    ),
    riskAlerts: const [
      RiskAlert(
        title: '原物料成本需觀察',
        severity: RiskSeverity.low,
        description: '食品與通路業務受原物料、通路費用與消費動能影響，需搭配毛利率追蹤。',
      ),
    ],
    tags: ['營收轉強', '現金流穩定', '估值中性'],
    mockSummary: _summary,
  ),
];
