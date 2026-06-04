import '../models/stock.dart';

class ResearchSummaryService {
  const ResearchSummaryService();

  String buildPlainLanguageSummary(Stock stock) {
    return stock.mockSummary;
  }
}
