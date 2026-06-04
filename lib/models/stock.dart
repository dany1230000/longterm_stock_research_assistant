import 'financial_trend.dart';
import 'risk_alert.dart';
import 'stock_metric.dart';
import 'valuation_metric.dart';

class Stock {
  const Stock({
    required this.symbol,
    required this.name,
    required this.industry,
    required this.marketCap,
    required this.latestClose,
    required this.high52Week,
    required this.low52Week,
    required this.pricePositionDescription,
    required this.lastUpdated,
    required this.metric,
    required this.valuation,
    required this.financialTrend,
    required this.riskAlerts,
    required this.tags,
    required this.mockSummary,
  });

  final String symbol;
  final String name;
  final String industry;
  final double marketCap;
  final double latestClose;
  final double high52Week;
  final double low52Week;
  final String pricePositionDescription;
  final DateTime lastUpdated;
  final StockMetric metric;
  final ValuationMetric valuation;
  final FinancialTrend financialTrend;
  final List<RiskAlert> riskAlerts;
  final List<String> tags;
  final String mockSummary;
}
