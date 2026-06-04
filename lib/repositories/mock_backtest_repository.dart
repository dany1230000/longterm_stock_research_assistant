import '../models/backtest_result.dart';
import 'backtest_repository.dart';

class MockBacktestRepository implements BacktestRepository {
  @override
  Future<BacktestResult> fetchMockBacktest() async {
    return BacktestResult(
      strategyName: '品質與估值條件研究策略',
      conditionSummary:
          'ROE > 15%、近 12 個月營收 YoY > 5%、PE < 30、體質分數 > 70、站上 200 日均線',
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
    );
  }
}
