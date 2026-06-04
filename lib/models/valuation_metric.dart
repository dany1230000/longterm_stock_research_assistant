class ValuationMetric {
  const ValuationMetric({
    required this.pe,
    required this.pb,
    required this.dividendYield,
    required this.pePercentile5y,
    required this.pbPercentile5y,
    required this.rangeLabel,
  });

  final double pe;
  final double pb;
  final double dividendYield;
  final int pePercentile5y;
  final int pbPercentile5y;
  final String rangeLabel;
}
