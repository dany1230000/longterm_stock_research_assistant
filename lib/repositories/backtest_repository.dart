import '../models/backtest_result.dart';

abstract class BacktestRepository {
  Future<BacktestResult> fetchMockBacktest();

  Future<List<BacktestResult>> fetchStrategies();

  Future<BacktestResult> fetchStrategyById(String id);
}
