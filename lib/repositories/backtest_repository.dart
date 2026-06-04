import '../models/backtest_result.dart';

abstract class BacktestRepository {
  Future<BacktestResult> fetchMockBacktest();
}
