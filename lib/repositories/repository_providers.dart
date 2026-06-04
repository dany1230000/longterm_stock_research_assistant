import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/backtest_result.dart';
import '../models/etf.dart';
import '../models/etf_comparison.dart';
import '../models/journal_entry.dart';
import '../models/portfolio_risk.dart';
import '../models/screener_condition.dart';
import '../models/screener_preset.dart';
import '../models/stock.dart';
import 'backtest_repository.dart';
import 'etf_repository.dart';
import 'in_memory_journal_repository.dart';
import 'in_memory_screener_preset_repository.dart';
import 'journal_repository.dart';
import 'mock_backtest_repository.dart';
import 'mock_etf_repository.dart';
import 'mock_portfolio_repository.dart';
import 'mock_stock_repository.dart';
import 'portfolio_repository.dart';
import 'stock_repository.dart';
import 'screener_preset_repository.dart';

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

final industryOptionsProvider = FutureProvider<List<String>>((ref) {
  return ref.watch(stockRepositoryProvider).fetchIndustries();
});

final screenerPresetRepositoryProvider =
    Provider<ScreenerPresetRepository>((ref) {
  return InMemoryScreenerPresetRepository();
});

final screenerPresetControllerProvider =
    StateNotifierProvider<ScreenerPresetController, List<ScreenerPreset>>(
        (ref) {
  return ScreenerPresetController(
    ref.watch(screenerPresetRepositoryProvider),
  );
});

class ScreenerPresetController extends StateNotifier<List<ScreenerPreset>> {
  ScreenerPresetController(this._repository)
      : super(_repository.fetchPresets());

  final ScreenerPresetRepository _repository;

  void savePreset(ScreenerPreset preset) {
    _repository.savePreset(preset);
    state = _repository.fetchPresets();
  }

  void deletePreset(String id) {
    _repository.deletePreset(id);
    state = _repository.fetchPresets();
  }
}

final backtestRepositoryProvider = Provider<BacktestRepository>((ref) {
  return MockBacktestRepository();
});

final backtestResultProvider = FutureProvider<BacktestResult>((ref) {
  return ref.watch(backtestRepositoryProvider).fetchMockBacktest();
});

final strategyResultsProvider = FutureProvider<List<BacktestResult>>((ref) {
  return ref.watch(backtestRepositoryProvider).fetchStrategies();
});

final selectedStrategyIdProvider = StateProvider<String>((ref) {
  return 'quality-growth';
});

final selectedStrategyProvider = FutureProvider<BacktestResult>((ref) {
  final selectedId = ref.watch(selectedStrategyIdProvider);
  return ref.watch(backtestRepositoryProvider).fetchStrategyById(selectedId);
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

  void updateEntry(JournalEntry entry) {
    _repository.updateEntry(entry);
    state = _repository.fetchEntries();
  }

  void deleteEntry(String id) {
    _repository.deleteEntry(id);
    state = _repository.fetchEntries();
  }
}

final etfRepositoryProvider = Provider<EtfRepository>((ref) {
  return MockEtfRepository();
});

final etfListProvider = FutureProvider<List<Etf>>((ref) {
  return ref.watch(etfRepositoryProvider).fetchEtfs();
});

final selectedEtfPairProvider = StateProvider<(String, String)>((ref) {
  return ('0050', '00878');
});

final etfComparisonProvider = FutureProvider<EtfComparison>((ref) {
  final pair = ref.watch(selectedEtfPairProvider);
  return ref.watch(etfRepositoryProvider).compareEtfs(pair.$1, pair.$2);
});

final portfolioRepositoryProvider = Provider<PortfolioRepository>((ref) {
  return MockPortfolioRepository();
});

final portfolioRiskProvider = FutureProvider<PortfolioRisk>((ref) {
  return ref.watch(portfolioRepositoryProvider).fetchMockPortfolioRisk();
});
