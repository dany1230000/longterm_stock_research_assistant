import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/backtest_result.dart';
import '../models/journal_entry.dart';
import '../models/screener_condition.dart';
import '../models/stock.dart';
import 'backtest_repository.dart';
import 'in_memory_journal_repository.dart';
import 'journal_repository.dart';
import 'mock_backtest_repository.dart';
import 'mock_stock_repository.dart';
import 'stock_repository.dart';

final stockRepositoryProvider = Provider<StockRepository>((ref) {
  return MockStockRepository();
});

final watchlistProvider = FutureProvider<List<Stock>>((ref) {
  return ref.watch(stockRepositoryProvider).fetchWatchlist();
});

final stockDetailProvider =
    FutureProvider.family<Stock, String>((ref, symbol) async {
  final stock = await ref.watch(stockRepositoryProvider).findBySymbol(symbol);
  if (stock == null) {
    throw StateError('找不到股票資料');
  }
  return stock;
});

final screenerResultsProvider = FutureProvider.autoDispose
    .family<List<Stock>, ScreenerCondition>((ref, condition) {
  return ref.watch(stockRepositoryProvider).filterByCondition(condition);
});

final backtestRepositoryProvider = Provider<BacktestRepository>((ref) {
  return MockBacktestRepository();
});

final backtestResultProvider = FutureProvider<BacktestResult>((ref) {
  return ref.watch(backtestRepositoryProvider).fetchMockBacktest();
});

final journalRepositoryProvider = Provider<JournalRepository>((ref) {
  return InMemoryJournalRepository();
});

final journalControllerProvider =
    StateNotifierProvider<JournalController, List<JournalEntry>>((ref) {
  return JournalController(ref.watch(journalRepositoryProvider));
});

class JournalController extends StateNotifier<List<JournalEntry>> {
  JournalController(this._repository) : super(_repository.fetchEntries());

  final JournalRepository _repository;

  void addEntry(JournalEntry entry) {
    _repository.addEntry(entry);
    state = _repository.fetchEntries();
  }
}
