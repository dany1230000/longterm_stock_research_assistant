import '../models/backtest_result.dart';
import '../models/strategy_preset.dart';
import 'backtest_repository.dart';

class MockBacktestRepository implements BacktestRepository {
  @override
  Future<BacktestResult> fetchMockBacktest() async {
    return _strategies.first;
  }

  @override
  Future<List<BacktestResult>> fetchStrategies() async {
    return List.unmodifiable(_strategies);
  }

  @override
  Future<BacktestResult> fetchStrategyById(String id) async {
    return _strategies.firstWhere(
      (strategy) => strategy.id == id,
      orElse: () => _strategies.first,
    );
  }
}

final _strategies = <BacktestResult>[
  BacktestResult(
    id: 'quality-growth',
    strategyName: '品質成長策略',
    conditionSummary: 'ROE > 15%、營收 YoY > 8%、體質分數 > 75、成長分數 > 70、站上長期均線',
    startDate: DateTime(2020),
    endDate: DateTime(2025, 12, 31),
    annualizedReturn: 12.4,
    maxDrawdown: -18.7,
    winRate: 58.2,
    averageHoldingDays: 164,
    benchmarkComparison: '模擬期間相對 0050 多 3.1 個百分點，差異僅作歷史統計觀察。',
    annualReturns: const {
      2020: 18.6,
      2021: 12.3,
      2022: -9.8,
      2023: 21.4,
      2024: 14.1,
      2025: 9.2,
    },
    equityCurve: const [100, 112, 126, 118, 139, 158, 171],
    drawdownCurve: const [0, -5.2, -8.4, -18.7, -9.1, -6.3, -4.8],
    events: [
      StrategyEvent(
        date: DateTime(2020, 4, 1),
        title: '市場波動擴大',
        description: '策略回撤擴大，品質條件降低部分波動幅度。',
      ),
      StrategyEvent(
        date: DateTime(2023, 8, 1),
        title: '成長條件改善',
        description: '營收與趨勢條件同步改善，年度統計轉強。',
      ),
    ],
  ),
  BacktestResult(
    id: 'value-dividend',
    strategyName: '低估值高股息策略',
    conditionSummary: 'PE < 18、PB < 2、殖利率 > 3%、安全分數 > 70、風險程度低於高',
    startDate: DateTime(2020),
    endDate: DateTime(2025, 12, 31),
    annualizedReturn: 8.6,
    maxDrawdown: -14.2,
    winRate: 55.4,
    averageHoldingDays: 221,
    benchmarkComparison: '模擬期間相對 0050 少 0.7 個百分點，但波動度較低。',
    annualReturns: const {
      2020: 9.4,
      2021: 11.1,
      2022: -4.2,
      2023: 8.6,
      2024: 13.0,
      2025: 6.7,
    },
    equityCurve: const [100, 108, 119, 114, 124, 139, 149],
    drawdownCurve: const [0, -3.1, -6.8, -14.2, -7.0, -4.4, -3.8],
    events: [
      StrategyEvent(
        date: DateTime(2022, 7, 1),
        title: '估值修正期',
        description: '低估值條件提供相對緩衝，但仍受市場環境影響。',
      ),
      StrategyEvent(
        date: DateTime(2024, 3, 1),
        title: '配息因子穩定',
        description: '高股息樣本年度統計較前期改善。',
      ),
    ],
  ),
  BacktestResult(
    id: 'revenue-acceleration',
    strategyName: '營收轉強策略',
    conditionSummary: '營收 YoY > 10%、近月 YoY 改善、成長分數 > 70、趨勢分數 > 65',
    startDate: DateTime(2020),
    endDate: DateTime(2025, 12, 31),
    annualizedReturn: 14.8,
    maxDrawdown: -24.6,
    winRate: 53.1,
    averageHoldingDays: 118,
    benchmarkComparison: '模擬期間相對 0050 多 5.2 個百分點，但回撤與波動也較高。',
    annualReturns: const {
      2020: 24.2,
      2021: 16.8,
      2022: -18.9,
      2023: 28.0,
      2024: 17.5,
      2025: 10.4,
    },
    equityCurve: const [100, 124, 145, 118, 151, 178, 196],
    drawdownCurve: const [0, -7.3, -10.5, -24.6, -12.2, -9.0, -6.1],
    events: [
      StrategyEvent(
        date: DateTime(2021, 10, 1),
        title: '營收動能擴散',
        description: '多個樣本符合營收改善條件，策略統計表現擴大。',
      ),
      StrategyEvent(
        date: DateTime(2022, 5, 1),
        title: '高波動情境',
        description: '成長條件對景氣預期較敏感，回撤明顯擴大。',
      ),
    ],
  ),
  BacktestResult(
    id: 'large-cap-stability',
    strategyName: '大型權值穩健策略',
    conditionSummary: '市值級距大型、體質分數 > 70、安全分數 > 75、趨勢分數 > 60',
    startDate: DateTime(2020),
    endDate: DateTime(2025, 12, 31),
    annualizedReturn: 9.7,
    maxDrawdown: -16.3,
    winRate: 60.5,
    averageHoldingDays: 245,
    benchmarkComparison: '模擬期間接近 0050，主要用於觀察大型權值樣本的穩定度。',
    annualReturns: const {
      2020: 13.5,
      2021: 9.6,
      2022: -7.1,
      2023: 16.2,
      2024: 12.0,
      2025: 7.8,
    },
    equityCurve: const [100, 113, 124, 115, 134, 150, 162],
    drawdownCurve: const [0, -4.2, -7.9, -16.3, -8.0, -5.7, -4.0],
    events: [
      StrategyEvent(
        date: DateTime(2020, 9, 1),
        title: '大型權值支撐',
        description: '大型樣本在波動期間相對穩定，仍需觀察產業集中度。',
      ),
      StrategyEvent(
        date: DateTime(2025, 1, 1),
        title: '穩健條件延續',
        description: '安全分數與趨勢條件維持，年度統計溫和改善。',
      ),
    ],
  ),
];
