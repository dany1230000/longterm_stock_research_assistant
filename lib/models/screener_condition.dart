import 'risk_alert.dart';

enum ScreenerSortOption {
  qualityScore('體質分數'),
  valuationScore('估值分數'),
  growthScore('成長分數'),
  riskLevel('風險程度'),
  lastYearReturn('近一年表現');

  const ScreenerSortOption(this.label);

  final String label;
}

class ScreenerCondition {
  const ScreenerCondition({
    this.minRoe = 12,
    this.minRevenueYoy = 5,
    this.maxPe = 30,
    this.maxPb = 8,
    this.minDividendYield = 1.5,
    this.minQualityScore = 70,
    this.minGrowthScore = 55,
    this.minValuationScore = 55,
    this.maxRiskSeverity = RiskSeverity.high,
    this.requireAboveMa200 = false,
    this.industry = '全部',
    this.sortOption = ScreenerSortOption.qualityScore,
  });

  final double minRoe;
  final double minRevenueYoy;
  final double maxPe;
  final double maxPb;
  final double minDividendYield;
  final double minQualityScore;
  final double minGrowthScore;
  final double minValuationScore;
  final RiskSeverity maxRiskSeverity;
  final bool requireAboveMa200;
  final String industry;
  final ScreenerSortOption sortOption;

  ScreenerCondition copyWith({
    double? minRoe,
    double? minRevenueYoy,
    double? maxPe,
    double? maxPb,
    double? minDividendYield,
    double? minQualityScore,
    double? minGrowthScore,
    double? minValuationScore,
    RiskSeverity? maxRiskSeverity,
    bool? requireAboveMa200,
    String? industry,
    ScreenerSortOption? sortOption,
  }) {
    return ScreenerCondition(
      minRoe: minRoe ?? this.minRoe,
      minRevenueYoy: minRevenueYoy ?? this.minRevenueYoy,
      maxPe: maxPe ?? this.maxPe,
      maxPb: maxPb ?? this.maxPb,
      minDividendYield: minDividendYield ?? this.minDividendYield,
      minQualityScore: minQualityScore ?? this.minQualityScore,
      minGrowthScore: minGrowthScore ?? this.minGrowthScore,
      minValuationScore: minValuationScore ?? this.minValuationScore,
      maxRiskSeverity: maxRiskSeverity ?? this.maxRiskSeverity,
      requireAboveMa200: requireAboveMa200 ?? this.requireAboveMa200,
      industry: industry ?? this.industry,
      sortOption: sortOption ?? this.sortOption,
    );
  }

  factory ScreenerCondition.fromJson(Map<String, Object?> json) {
    return ScreenerCondition(
      minRoe: (json['minRoe'] as num?)?.toDouble() ?? 12,
      minRevenueYoy: (json['minRevenueYoy'] as num?)?.toDouble() ?? 5,
      maxPe: (json['maxPe'] as num?)?.toDouble() ?? 30,
      maxPb: (json['maxPb'] as num?)?.toDouble() ?? 8,
      minDividendYield: (json['minDividendYield'] as num?)?.toDouble() ?? 1.5,
      minQualityScore: (json['minQualityScore'] as num?)?.toDouble() ?? 70,
      minGrowthScore: (json['minGrowthScore'] as num?)?.toDouble() ?? 55,
      minValuationScore: (json['minValuationScore'] as num?)?.toDouble() ?? 55,
      maxRiskSeverity: RiskSeverity.values.firstWhere(
        (severity) => severity.name == json['maxRiskSeverity'],
        orElse: () => RiskSeverity.high,
      ),
      requireAboveMa200: json['requireAboveMa200'] as bool? ?? false,
      industry: json['industry'] as String? ?? '全部',
      sortOption: ScreenerSortOption.values.firstWhere(
        (option) => option.name == json['sortOption'],
        orElse: () => ScreenerSortOption.qualityScore,
      ),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'minRoe': minRoe,
      'minRevenueYoy': minRevenueYoy,
      'maxPe': maxPe,
      'maxPb': maxPb,
      'minDividendYield': minDividendYield,
      'minQualityScore': minQualityScore,
      'minGrowthScore': minGrowthScore,
      'minValuationScore': minValuationScore,
      'maxRiskSeverity': maxRiskSeverity.name,
      'requireAboveMa200': requireAboveMa200,
      'industry': industry,
      'sortOption': sortOption.name,
    };
  }

  @override
  bool operator ==(Object other) {
    return other is ScreenerCondition &&
        other.minRoe == minRoe &&
        other.minRevenueYoy == minRevenueYoy &&
        other.maxPe == maxPe &&
        other.maxPb == maxPb &&
        other.minDividendYield == minDividendYield &&
        other.minQualityScore == minQualityScore &&
        other.minGrowthScore == minGrowthScore &&
        other.minValuationScore == minValuationScore &&
        other.maxRiskSeverity == maxRiskSeverity &&
        other.requireAboveMa200 == requireAboveMa200 &&
        other.industry == industry &&
        other.sortOption == sortOption;
  }

  @override
  int get hashCode => Object.hash(
        minRoe,
        minRevenueYoy,
        maxPe,
        maxPb,
        minDividendYield,
        minQualityScore,
        minGrowthScore,
        minValuationScore,
        maxRiskSeverity,
        requireAboveMa200,
        industry,
        sortOption,
      );
}
