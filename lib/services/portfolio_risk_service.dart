import '../models/portfolio.dart';
import '../models/portfolio_risk.dart';

class PortfolioRiskService {
  const PortfolioRiskService();

  PortfolioRisk buildRisk(Portfolio portfolio) {
    final industryConcentration = <String, double>{};
    var etfWeight = 0.0;
    var stockWeight = 0.0;
    var highValuationExposure = 0.0;
    var highVolatilityExposure = 0.0;
    var largestHoldingWeight = 0.0;

    for (final holding in portfolio.holdings) {
      industryConcentration.update(
        holding.industry,
        (value) => value + holding.weight,
        ifAbsent: () => holding.weight,
      );
      largestHoldingWeight = holding.weight > largestHoldingWeight
          ? holding.weight
          : largestHoldingWeight;
      if (holding.assetType == PortfolioAssetType.etf) {
        etfWeight += holding.weight;
      } else {
        stockWeight += holding.weight;
      }
      highValuationExposure += holding.weight * holding.valuationExposure / 100;
      highVolatilityExposure +=
          holding.weight * holding.volatilityExposure / 100;
    }

    final alerts = <String>[
      if (industryConcentration.values.any((weight) => weight >= 35))
        '產業集中度偏高，需觀察單一產業波動對組合的影響。',
      if (largestHoldingWeight >= 25) '單一持股集中度偏高，可作為研究參考。',
      if (highValuationExposure >= 35) '高估值曝險偏高，需搭配估值分位與獲利假設觀察。',
      if (highVolatilityExposure >= 30) '高波動曝險偏高，情境模擬結果可能更敏感。',
    ];

    return PortfolioRisk(
      portfolio: portfolio,
      industryConcentration: industryConcentration,
      largestHoldingWeight: largestHoldingWeight,
      highValuationExposure: highValuationExposure,
      highVolatilityExposure: highVolatilityExposure,
      etfWeight: etfWeight,
      stockWeight: stockWeight,
      alerts: alerts,
      scenarios: const [
        PortfolioScenario(
          name: '半導體類股下跌 10%',
          impactPercent: -4.6,
          description: '半導體曝險較高時，組合淨值對此情境較敏感。',
        ),
        PortfolioScenario(
          name: '大盤下跌 10%',
          impactPercent: -7.8,
          description: '以整體風險資產同步修正作為壓力情境模擬。',
        ),
        PortfolioScenario(
          name: '高股息 ETF 修正',
          impactPercent: -2.4,
          description: '高股息 ETF 權重修正時，需觀察 ETF 與個股比例。',
        ),
        PortfolioScenario(
          name: '權值股修正',
          impactPercent: -5.1,
          description: '大型權值持股修正會影響組合波動與產業集中度。',
        ),
      ],
    );
  }
}
