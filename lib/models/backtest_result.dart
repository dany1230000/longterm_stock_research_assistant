class BacktestResult {
  const BacktestResult({
    required this.strategyName,
    required this.conditionSummary,
    required this.startDate,
    required this.endDate,
    required this.annualizedReturn,
    required this.maxDrawdown,
    required this.winRate,
    required this.averageHoldingDays,
    required this.benchmarkComparison,
    required this.annualReturns,
  });

  final String strategyName;
  final String conditionSummary;
  final DateTime startDate;
  final DateTime endDate;
  final double annualizedReturn;
  final double maxDrawdown;
  final double winRate;
  final int averageHoldingDays;
  final String benchmarkComparison;
  final Map<int, double> annualReturns;
}
