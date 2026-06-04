import '../models/portfolio.dart';
import '../models/portfolio_risk.dart';
import '../services/portfolio_risk_service.dart';
import 'portfolio_repository.dart';

class MockPortfolioRepository implements PortfolioRepository {
  MockPortfolioRepository(
      {PortfolioRiskService service = const PortfolioRiskService()})
      : _service = service;

  final PortfolioRiskService _service;

  @override
  Future<PortfolioRisk> fetchMockPortfolioRisk() async {
    return _service.buildRisk(_mockPortfolio);
  }
}

final _mockPortfolio = Portfolio(
  id: 'mock-main',
  name: '中長線研究組合',
  updatedAt: DateTime(2026, 6, 4, 9),
  holdings: const [
    PortfolioHolding(
      symbol: '2330',
      name: '台積電',
      assetType: PortfolioAssetType.stock,
      industry: '半導體',
      weight: 24,
      valuationExposure: 78,
      volatilityExposure: 62,
    ),
    PortfolioHolding(
      symbol: '0050',
      name: '元大台灣50',
      assetType: PortfolioAssetType.etf,
      industry: '市值型 ETF',
      weight: 18,
      valuationExposure: 64,
      volatilityExposure: 52,
    ),
    PortfolioHolding(
      symbol: '00878',
      name: '國泰永續高股息',
      assetType: PortfolioAssetType.etf,
      industry: '高股息 ETF',
      weight: 16,
      valuationExposure: 48,
      volatilityExposure: 36,
    ),
    PortfolioHolding(
      symbol: '2308',
      name: '台達電',
      assetType: PortfolioAssetType.stock,
      industry: '電源與能源管理',
      weight: 14,
      valuationExposure: 61,
      volatilityExposure: 46,
    ),
    PortfolioHolding(
      symbol: '2412',
      name: '中華電',
      assetType: PortfolioAssetType.stock,
      industry: '電信服務',
      weight: 12,
      valuationExposure: 72,
      volatilityExposure: 22,
    ),
    PortfolioHolding(
      symbol: '2881',
      name: '富邦金',
      assetType: PortfolioAssetType.stock,
      industry: '金融保險',
      weight: 10,
      valuationExposure: 45,
      volatilityExposure: 38,
    ),
    PortfolioHolding(
      symbol: '1216',
      name: '統一',
      assetType: PortfolioAssetType.stock,
      industry: '食品與通路',
      weight: 6,
      valuationExposure: 52,
      volatilityExposure: 28,
    ),
  ],
);
