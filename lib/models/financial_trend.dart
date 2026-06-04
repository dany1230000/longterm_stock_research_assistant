class FinancialTrend {
  const FinancialTrend({
    required this.epsLast8Quarters,
    required this.roeLast8Quarters,
    required this.grossMarginLast8Quarters,
    required this.revenueYoyLast12Months,
  });

  final List<double> epsLast8Quarters;
  final List<double> roeLast8Quarters;
  final List<double> grossMarginLast8Quarters;
  final List<double> revenueYoyLast12Months;
}
