import '../models/screener_condition.dart';
import '../models/stock.dart';

abstract class StockRepository {
  Future<List<Stock>> fetchWatchlist();

  Future<Stock?> findBySymbol(String symbol);

  Future<List<Stock>> filterByCondition(ScreenerCondition condition);
}
