class StockMetric {
  const StockMetric({
    required this.qualityScore,
    required this.growthScore,
    required this.profitabilityScore,
    required this.safetyScore,
    required this.valuationScore,
    required this.trendScore,
    required this.roe,
    required this.revenueYoy,
    required this.lastYearReturn,
    required this.aboveMa200,
  });

  final int qualityScore;
  final int growthScore;
  final int profitabilityScore;
  final int safetyScore;
  final int valuationScore;
  final int trendScore;
  final double roe;
  final double revenueYoy;
  final double lastYearReturn;
  final bool aboveMa200;
}
