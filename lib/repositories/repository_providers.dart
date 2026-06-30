import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/backtest_result.dart';
import '../models/etf.dart';
import '../models/etf_comparison.dart';
import '../models/journal_entry.dart';
import '../models/leveraged_etf_lab.dart';
import '../models/portfolio_risk.dart';
import '../models/screener_condition.dart';
import '../models/screener_preset.dart';
import '../models/stock.dart';
import 'backtest_repository.dart';
import 'cached_00631l_repository.dart';
import 'etf_repository.dart';
import 'in_memory_journal_repository.dart';
import 'in_memory_screener_preset_repository.dart';
import 'journal_repository.dart';
import 'mock_backtest_repository.dart';
import 'mock_00631l_repository.dart';
import 'mock_etf_repository.dart';
import 'mock_portfolio_repository.dart';
import 'mock_stock_repository.dart';
import 'official_00631l_repository.dart';
import 'portfolio_repository.dart';
import 'proxy_00631l_repository.dart';
import 'stock_repository.dart';
import 'screener_preset_repository.dart';
import 'static_00631l_repository.dart';

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

final official00631LRepositoryProvider =
    Provider<Official00631LRepository>((ref) {
  const useLiveProxy = bool.fromEnvironment('USE_00631L_LIVE_PROXY');
  const useStaticData = bool.fromEnvironment('USE_00631L_STATIC_DATA');
  const proxyBaseUrl = String.fromEnvironment(
    '00631L_PROXY_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );
  const staticDataBaseUrl = String.fromEnvironment(
    '00631L_STATIC_DATA_BASE_URL',
    defaultValue: '00631l-static-data',
  );
  const proxyTimeoutMs = int.fromEnvironment(
    '00631L_PROXY_TIMEOUT_MS',
    defaultValue: 8000,
  );
  const proxyTimeout = Duration(milliseconds: proxyTimeoutMs);

  if (useLiveProxy) {
    final fallback = useStaticData
        ? Cached00631LRepository(
            primary: Static00631LRepository(baseUrl: staticDataBaseUrl),
            fallback: Mock00631LRepository(),
          )
        : Mock00631LRepository();
    return Cached00631LRepository(
      primary: Proxy00631LRepository(
        baseUri: Uri.parse(proxyBaseUrl),
        timeout: proxyTimeout,
      ),
      fallback: fallback,
      primaryTimeout: proxyTimeout,
      fastPrimaryTimeout: const Duration(milliseconds: 1600),
      raceFastFallback: useStaticData,
    );
  }

  if (useStaticData) {
    return Cached00631LRepository(
      primary: Static00631LRepository(baseUrl: staticDataBaseUrl),
      fallback: Mock00631LRepository(),
    );
  }

  return Mock00631LRepository();
});

final etf00631LLabProvider = FutureProvider<Etf00631LLabData>((ref) {
  return ref.watch(official00631LRepositoryProvider).fetchLabData();
});

final etf00631LFastLabProvider = FutureProvider<Etf00631LLabData>((ref) {
  return ref.watch(official00631LRepositoryProvider).fetchFastLabData();
});

final etf00631LCatalogProvider = FutureProvider<EtfCatalog>((ref) {
  return ref.watch(official00631LRepositoryProvider).fetchEtfCatalog();
});

final selectedEtfPriceHistoryProvider =
    FutureProvider.family<EtfPriceHistory, String>((ref, code) {
  return ref.watch(official00631LRepositoryProvider).fetchEtfPriceHistory(code);
});

final etfPriceHistoryGapDetailsProvider =
    FutureProvider<EtfPriceHistoryGapDetails>((ref) {
  return ref.watch(official00631LRepositoryProvider).fetchEtfPriceHistoryGaps(
        limit: 50,
        fromCatalog: true,
      );
});

final etfHistoryComparisonProvider =
    FutureProvider.family<List<EtfPriceHistory>, String>((ref, selectedCode) {
  final repository = ref.watch(official00631LRepositoryProvider);
  final normalizedSelected = selectedCode.trim().toUpperCase();
  final codes = <String>{
    if (normalizedSelected.isNotEmpty) normalizedSelected,
    '00631L',
    '0050',
    '0056',
    '006208',
    '00692',
    '00713',
    '00757',
    '00850',
    '00878',
    '00881',
    '00919',
    '00922',
    '00923',
    '00929',
    '00940',
  }.toList(growable: false);

  return Future.wait([
    for (final code in codes)
      repository.fetchEtfPriceHistory(code).catchError(
            (Object error) => EtfPriceHistory.empty(
              code: code,
              name: code,
              status: EtfDataStatus.error,
              sourceStatusLabel: 'error',
              sourceUrl: '',
              errorMessage: error.toString(),
            ),
          ),
  ]);
});
