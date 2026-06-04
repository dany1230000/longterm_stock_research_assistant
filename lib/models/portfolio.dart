enum PortfolioAssetType {
  stock('個股'),
  etf('ETF');

  const PortfolioAssetType(this.label);

  final String label;
}

class PortfolioHolding {
  const PortfolioHolding({
    required this.symbol,
    required this.name,
    required this.assetType,
    required this.industry,
    required this.weight,
    required this.valuationExposure,
    required this.volatilityExposure,
  });

  final String symbol;
  final String name;
  final PortfolioAssetType assetType;
  final String industry;
  final double weight;
  final double valuationExposure;
  final double volatilityExposure;

  factory PortfolioHolding.fromJson(Map<String, Object?> json) {
    return PortfolioHolding(
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      assetType: PortfolioAssetType.values.firstWhere(
        (type) => type.name == json['assetType'],
        orElse: () => PortfolioAssetType.stock,
      ),
      industry: json['industry'] as String,
      weight: (json['weight'] as num).toDouble(),
      valuationExposure: (json['valuationExposure'] as num).toDouble(),
      volatilityExposure: (json['volatilityExposure'] as num).toDouble(),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'symbol': symbol,
      'name': name,
      'assetType': assetType.name,
      'industry': industry,
      'weight': weight,
      'valuationExposure': valuationExposure,
      'volatilityExposure': volatilityExposure,
    };
  }
}

class Portfolio {
  const Portfolio({
    required this.id,
    required this.name,
    required this.holdings,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final List<PortfolioHolding> holdings;
  final DateTime updatedAt;

  factory Portfolio.fromJson(Map<String, Object?> json) {
    return Portfolio(
      id: json['id'] as String,
      name: json['name'] as String,
      holdings: (json['holdings'] as List)
          .map(
            (holding) => PortfolioHolding.fromJson(
              Map<String, Object?>.from(holding as Map),
            ),
          )
          .toList(),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'name': name,
      'holdings': holdings.map((holding) => holding.toJson()).toList(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
