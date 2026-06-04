class EtfHolding {
  const EtfHolding({
    required this.name,
    required this.weight,
  });

  final String name;
  final double weight;

  factory EtfHolding.fromJson(Map<String, Object?> json) {
    return EtfHolding(
      name: json['name'] as String,
      weight: (json['weight'] as num).toDouble(),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'name': name,
      'weight': weight,
    };
  }
}

class Etf {
  const Etf({
    required this.symbol,
    required this.name,
    required this.type,
    required this.expenseRatio,
    required this.distributionFrequency,
    required this.lastYearReturn,
    required this.threeYearAnnualizedReturn,
    required this.volatility,
    required this.maxDrawdown,
    required this.topHoldings,
    required this.industryExposure,
    required this.overlapRates,
    required this.isLeveraged,
  });

  final String symbol;
  final String name;
  final String type;
  final double expenseRatio;
  final String distributionFrequency;
  final double lastYearReturn;
  final double threeYearAnnualizedReturn;
  final double volatility;
  final double maxDrawdown;
  final List<EtfHolding> topHoldings;
  final Map<String, double> industryExposure;
  final Map<String, double> overlapRates;
  final bool isLeveraged;

  factory Etf.fromJson(Map<String, Object?> json) {
    return Etf(
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      expenseRatio: (json['expenseRatio'] as num).toDouble(),
      distributionFrequency: json['distributionFrequency'] as String,
      lastYearReturn: (json['lastYearReturn'] as num).toDouble(),
      threeYearAnnualizedReturn:
          (json['threeYearAnnualizedReturn'] as num).toDouble(),
      volatility: (json['volatility'] as num).toDouble(),
      maxDrawdown: (json['maxDrawdown'] as num).toDouble(),
      topHoldings: (json['topHoldings'] as List)
          .map(
            (holding) => EtfHolding.fromJson(
              Map<String, Object?>.from(holding as Map),
            ),
          )
          .toList(),
      industryExposure:
          Map<String, double>.from((json['industryExposure'] as Map).map(
        (key, value) => MapEntry(key as String, (value as num).toDouble()),
      )),
      overlapRates: Map<String, double>.from((json['overlapRates'] as Map).map(
        (key, value) => MapEntry(key as String, (value as num).toDouble()),
      )),
      isLeveraged: json['isLeveraged'] as bool? ?? false,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'symbol': symbol,
      'name': name,
      'type': type,
      'expenseRatio': expenseRatio,
      'distributionFrequency': distributionFrequency,
      'lastYearReturn': lastYearReturn,
      'threeYearAnnualizedReturn': threeYearAnnualizedReturn,
      'volatility': volatility,
      'maxDrawdown': maxDrawdown,
      'topHoldings': topHoldings.map((holding) => holding.toJson()).toList(),
      'industryExposure': industryExposure,
      'overlapRates': overlapRates,
      'isLeveraged': isLeveraged,
    };
  }
}
