import '../models/etf.dart';
import '../models/etf_comparison.dart';

abstract class EtfRepository {
  Future<List<Etf>> fetchEtfs();

  Future<EtfComparison> compareEtfs(String leftSymbol, String rightSymbol);
}
