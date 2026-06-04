import '../models/portfolio_risk.dart';

abstract class PortfolioRepository {
  Future<PortfolioRisk> fetchMockPortfolioRisk();
}
