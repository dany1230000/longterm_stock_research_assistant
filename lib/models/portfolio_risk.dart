import 'portfolio.dart';

class PortfolioScenario {
  const PortfolioScenario({
    required this.name,
    required this.impactPercent,
    required this.description,
  });

  final String name;
  final double impactPercent;
  final String description;

  factory PortfolioScenario.fromJson(Map<String, Object?> json) {
    return PortfolioScenario(
      name: json['name'] as String,
      impactPercent: (json['impactPercent'] as num).toDouble(),
      description: json['description'] as String,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'name': name,
      'impactPercent': impactPercent,
      'description': description,
    };
  }
}

class PortfolioRisk {
  const PortfolioRisk({
    required this.portfolio,
    required this.industryConcentration,
    required this.largestHoldingWeight,
    required this.highValuationExposure,
    required this.highVolatilityExposure,
    required this.etfWeight,
    required this.stockWeight,
    required this.alerts,
    required this.scenarios,
  });

  final Portfolio portfolio;
  final Map<String, double> industryConcentration;
  final double largestHoldingWeight;
  final double highValuationExposure;
  final double highVolatilityExposure;
  final double etfWeight;
  final double stockWeight;
  final List<String> alerts;
  final List<PortfolioScenario> scenarios;

  factory PortfolioRisk.fromJson(Map<String, Object?> json) {
    return PortfolioRisk(
      portfolio: Portfolio.fromJson(
        Map<String, Object?>.from(json['portfolio'] as Map),
      ),
      industryConcentration:
          Map<String, double>.from((json['industryConcentration'] as Map).map(
        (key, value) => MapEntry(key as String, (value as num).toDouble()),
      )),
      largestHoldingWeight: (json['largestHoldingWeight'] as num).toDouble(),
      highValuationExposure: (json['highValuationExposure'] as num).toDouble(),
      highVolatilityExposure:
          (json['highVolatilityExposure'] as num).toDouble(),
      etfWeight: (json['etfWeight'] as num).toDouble(),
      stockWeight: (json['stockWeight'] as num).toDouble(),
      alerts: (json['alerts'] as List).cast<String>(),
      scenarios: (json['scenarios'] as List)
          .map(
            (scenario) => PortfolioScenario.fromJson(
              Map<String, Object?>.from(scenario as Map),
            ),
          )
          .toList(),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'portfolio': portfolio.toJson(),
      'industryConcentration': industryConcentration,
      'largestHoldingWeight': largestHoldingWeight,
      'highValuationExposure': highValuationExposure,
      'highVolatilityExposure': highVolatilityExposure,
      'etfWeight': etfWeight,
      'stockWeight': stockWeight,
      'alerts': alerts,
      'scenarios': scenarios.map((scenario) => scenario.toJson()).toList(),
    };
  }
}
