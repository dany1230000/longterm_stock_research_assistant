class ScreenerCondition {
  const ScreenerCondition({
    this.minRoe = 12,
    this.minRevenueYoy = 5,
    this.maxPe = 30,
    this.minDividendYield = 1.5,
    this.minQualityScore = 70,
    this.requireAboveMa200 = false,
  });

  final double minRoe;
  final double minRevenueYoy;
  final double maxPe;
  final double minDividendYield;
  final double minQualityScore;
  final bool requireAboveMa200;

  ScreenerCondition copyWith({
    double? minRoe,
    double? minRevenueYoy,
    double? maxPe,
    double? minDividendYield,
    double? minQualityScore,
    bool? requireAboveMa200,
  }) {
    return ScreenerCondition(
      minRoe: minRoe ?? this.minRoe,
      minRevenueYoy: minRevenueYoy ?? this.minRevenueYoy,
      maxPe: maxPe ?? this.maxPe,
      minDividendYield: minDividendYield ?? this.minDividendYield,
      minQualityScore: minQualityScore ?? this.minQualityScore,
      requireAboveMa200: requireAboveMa200 ?? this.requireAboveMa200,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ScreenerCondition &&
        other.minRoe == minRoe &&
        other.minRevenueYoy == minRevenueYoy &&
        other.maxPe == maxPe &&
        other.minDividendYield == minDividendYield &&
        other.minQualityScore == minQualityScore &&
        other.requireAboveMa200 == requireAboveMa200;
  }

  @override
  int get hashCode => Object.hash(
        minRoe,
        minRevenueYoy,
        maxPe,
        minDividendYield,
        minQualityScore,
        requireAboveMa200,
      );
}
