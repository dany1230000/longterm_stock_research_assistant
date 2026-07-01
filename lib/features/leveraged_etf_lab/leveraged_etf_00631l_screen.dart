import 'dart:async';
import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/leveraged_etf_lab.dart';
import '../../models/stock.dart';
import '../../repositories/repository_providers.dart';
import '../../services/app_theme_controller.dart';
import '../../services/position_store.dart';
import '../../shared/utils/formatters.dart';

const _use00631LLiveProxy = bool.fromEnvironment('USE_00631L_LIVE_PROXY');
const _use00631LStaticData = bool.fromEnvironment('USE_00631L_STATIC_DATA');
const _proxyBaseUrl00631l = String.fromEnvironment(
  '00631L_PROXY_BASE_URL',
  defaultValue: 'http://localhost:8000',
);
const _staticDataBaseUrl00631l = String.fromEnvironment(
  '00631L_STATIC_DATA_BASE_URL',
  defaultValue: '00631l-static-data',
);

const _etfHistoryReadyCodes = {
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
};

const _knownSplitAdjustedEtfCodes = {
  '0050',
  '00631L',
};

class LeveragedEtf00631LScreen extends ConsumerStatefulWidget {
  const LeveragedEtf00631LScreen({super.key});

  @override
  ConsumerState<LeveragedEtf00631LScreen> createState() =>
      _LeveragedEtf00631LScreenState();
}

class _LeveragedEtf00631LScreenState
    extends ConsumerState<LeveragedEtf00631LScreen> {
  Timer? _refreshTimer;
  int? _scheduledRefreshSeconds;
  int _liveCoreRetryCount = 0;
  DateTime? _lastFullRefreshAt;
  _LabSection _section = _LabSection.overview;
  String _selectedEtfCode = '00631L';

  @override
  void initState() {
    super.initState();
    _scheduleRefreshTimer(force: true);
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fastValue = ref.watch(etf00631LFastLabProvider);
    final shouldLoadFullData = shouldLoad00631LFullData(
      fastReadyOrError: fastValue.hasValue || fastValue.hasError,
      sectionNeedsFullData: _section.needsFullData,
      liveProxyEnabled: _use00631LLiveProxy,
    );
    final fullValue = shouldLoadFullData
        ? ref.watch(etf00631LLabProvider)
        : const AsyncValue<Etf00631LLabData>.loading();
    final displayData = fullValue.valueOrNull ?? fastValue.valueOrNull;
    final useEmbeddedPriceHistory = _selectedEtfCode == '00631L';
    final selectedHistoryValue = useEmbeddedPriceHistory
        ? null
        : ref.watch(selectedEtfPriceHistoryProvider(_selectedEtfCode));
    final shouldLoadComparison = _section == _LabSection.historyBacktest;
    final comparisonHistoriesValue = shouldLoadComparison
        ? ref.watch(etfHistoryComparisonProvider(_selectedEtfCode))
        : const AsyncValue<List<EtfPriceHistory>>.data([]);
    final gapDetailsValue = _section == _LabSection.settings
        ? ref.watch(etfPriceHistoryGapDetailsProvider)
        : null;
    final detailsLoading =
        shouldLoadFullData && !fullValue.hasValue && fullValue.isLoading;
    final detailsError =
        shouldLoadFullData && fullValue.hasError && !fullValue.hasValue
            ? fullValue.error.toString()
            : null;
    return SafeArea(
      child: displayData == null
          ? _buildInitialState(fastValue, fullValue)
          : Builder(
              builder: (context) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    if (has00631LLiveCoreData(displayData)) {
                      _liveCoreRetryCount = 0;
                    }
                    _scheduleRefreshTimer(data: displayData);
                  }
                });
                return _LabContent(
                  data: displayData,
                  selectedEtfCode: _selectedEtfCode,
                  selectedPriceHistory: useEmbeddedPriceHistory
                      ? displayData.priceHistory
                      : selectedHistoryValue?.valueOrNull,
                  selectedPriceHistoryLoading:
                      selectedHistoryValue?.isLoading ?? false,
                  selectedPriceHistoryError:
                      selectedHistoryValue?.hasError == true
                          ? selectedHistoryValue?.error
                          : null,
                  comparisonHistories:
                      comparisonHistoriesValue.valueOrNull ?? const [],
                  comparisonHistoriesLoading:
                      comparisonHistoriesValue.isLoading,
                  comparisonHistoriesError: comparisonHistoriesValue.hasError
                      ? comparisonHistoriesValue.error
                      : null,
                  gapDetailsValue: gapDetailsValue,
                  selectedSection: _section,
                  detailsLoading: detailsLoading,
                  detailsError: detailsError,
                  onSectionChanged: (section) =>
                      setState(() => _section = section),
                  onEtfSelected: _selectEtf,
                  onRefresh: _refreshLabData,
                );
              },
            ),
    );
  }

  Widget _buildInitialState(
    AsyncValue<Etf00631LLabData> fastValue,
    AsyncValue<Etf00631LLabData> fullValue,
  ) {
    if (fastValue.hasError && fullValue.hasError) {
      return _ErrorState(
        error: fastValue.error ?? fullValue.error ?? 'Unknown loading error',
        onRefresh: _refreshLabData,
      );
    }
    return _LabLoadingShell(onRefresh: _refreshLabData);
  }

  void _refreshLabData() {
    ref.invalidate(etf00631LFastLabProvider);
    ref.invalidate(etf00631LLabProvider);
    ref.invalidate(selectedEtfPriceHistoryProvider(_selectedEtfCode));
    ref.invalidate(etfPriceHistoryGapDetailsProvider);
    _liveCoreRetryCount = 0;
    _lastFullRefreshAt = DateTime.now();
    _scheduleRefreshTimer(force: true);
  }

  void _refreshFastData() {
    final current = ref.read(etf00631LFastLabProvider).valueOrNull;
    if (has00631LLiveCoreData(current)) {
      _liveCoreRetryCount = 0;
    } else if (_use00631LLiveProxy &&
        _liveCoreRetryCount < liveCoreWarmupRetryLimit) {
      _liveCoreRetryCount += 1;
    }
    ref.invalidate(etf00631LFastLabProvider);
    final now = DateTime.now();
    if (_section.needsFullData && _shouldRefreshFullData(now)) {
      ref.invalidate(etf00631LLabProvider);
      if (_selectedEtfCode != '00631L') {
        ref.invalidate(selectedEtfPriceHistoryProvider(_selectedEtfCode));
      }
      _lastFullRefreshAt = now;
    }
    _scheduleRefreshTimer(force: true);
  }

  bool _shouldRefreshFullData(DateTime now) {
    final last = _lastFullRefreshAt;
    if (last == null) {
      return true;
    }
    final fastData = ref.read(etf00631LFastLabProvider).valueOrNull;
    final session = fastData?.intradayNav?.marketSession(now: now);
    final threshold = _use00631LLiveProxy && session?.isRegularSession == true
        ? const Duration(minutes: 1)
        : const Duration(minutes: 10);
    return now.difference(last) >= threshold;
  }

  void _scheduleRefreshTimer({
    Etf00631LLabData? data,
    bool force = false,
  }) {
    final interval = _refreshInterval(data);
    final seconds = interval.inSeconds;
    if (!force &&
        _refreshTimer?.isActive == true &&
        _scheduledRefreshSeconds == seconds) {
      return;
    }
    _refreshTimer?.cancel();
    _scheduledRefreshSeconds = seconds;
    _refreshTimer = Timer(interval, () {
      if (mounted) {
        _refreshFastData();
      }
    });
  }

  Duration _refreshInterval(Etf00631LLabData? data) {
    if (!_use00631LLiveProxy) {
      return const Duration(minutes: 5);
    }
    if (shouldUse00631LShortLiveRetry(
      liveProxyEnabled: _use00631LLiveProxy,
      hasLiveCoreData: has00631LLiveCoreData(data),
      retryCount: _liveCoreRetryCount,
    )) {
      return const Duration(seconds: 2);
    }
    final nav = data?.intradayNav;
    final session = nav?.marketSession() ??
        IntradayMarketSession.evaluate(sourceAvailable: false);
    final seconds = session.nextRefreshSeconds.clamp(15, 300).toInt();
    return Duration(seconds: seconds);
  }

  void _selectEtf(String code) {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) {
      return;
    }
    setState(() {
      _selectedEtfCode = normalized;
      _section = _LabSection.overview;
    });
  }
}

const liveCoreWarmupRetryLimit = 15;

enum _LabSection {
  overview('總覽', Icons.dashboard_outlined),
  historyBacktest('歷史回測', Icons.query_stats_outlined),
  position('持倉', Icons.account_balance_wallet_outlined),
  ai('AI', Icons.psychology_alt_outlined),
  settings('我的', Icons.manage_accounts_outlined);

  const _LabSection(this.label, this.icon);
  final String label;
  final IconData icon;

  bool get needsFullData {
    switch (this) {
      case _LabSection.overview:
      case _LabSection.position:
        return false;
      case _LabSection.historyBacktest:
      case _LabSection.ai:
      case _LabSection.settings:
        return true;
    }
  }
}

const _bottomLabSections = [
  _LabSection.overview,
  _LabSection.historyBacktest,
  _LabSection.position,
  _LabSection.ai,
  _LabSection.settings,
];

class _LabContent extends StatelessWidget {
  const _LabContent({
    required this.data,
    required this.selectedEtfCode,
    required this.selectedPriceHistory,
    required this.selectedPriceHistoryLoading,
    required this.selectedPriceHistoryError,
    required this.comparisonHistories,
    required this.comparisonHistoriesLoading,
    required this.comparisonHistoriesError,
    required this.gapDetailsValue,
    required this.selectedSection,
    required this.detailsLoading,
    required this.detailsError,
    required this.onSectionChanged,
    required this.onEtfSelected,
    required this.onRefresh,
  });

  final Etf00631LLabData data;
  final String selectedEtfCode;
  final EtfPriceHistory? selectedPriceHistory;
  final bool selectedPriceHistoryLoading;
  final Object? selectedPriceHistoryError;
  final List<EtfPriceHistory> comparisonHistories;
  final bool comparisonHistoriesLoading;
  final Object? comparisonHistoriesError;
  final AsyncValue<EtfPriceHistoryGapDetails>? gapDetailsValue;
  final _LabSection selectedSection;
  final bool detailsLoading;
  final String? detailsError;
  final ValueChanged<_LabSection> onSectionChanged;
  final ValueChanged<String> onEtfSelected;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final selectedEtf = _SelectedEtfViewData.from(
      data: data,
      selectedEtfCode: selectedEtfCode,
      selectedPriceHistory: selectedPriceHistory,
    );
    final showDetailsLoadState = detailsError != null ||
        (detailsLoading && !_hasUsableFirstScreenData(data, selectedEtf));
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: appThemeModeNotifier,
      builder: (context, themeMode, _) {
        return Theme(
          data: _marketTheme(context, themeMode),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 720;
              final horizontalPadding =
                  constraints.maxWidth < 520 ? 12.0 : 18.0;
              final shellBackground = _marketBackground(context);
              return DecoratedBox(
                decoration: BoxDecoration(color: shellBackground),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          6,
                          horizontalPadding,
                          isCompact ? 84 : 92,
                        ),
                        children: [
                          Align(
                            alignment: Alignment.topCenter,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1180),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _MarketTopBar(
                                    data: data,
                                    selectedEtfCode: selectedEtfCode,
                                    selectedEtfName: selectedEtf.name,
                                    onEtfSelected: onEtfSelected,
                                    onRefresh: onRefresh,
                                  ),
                                  const SizedBox(height: 8),
                                  if (showDetailsLoadState) ...[
                                    _DetailsLoadStateStrip(
                                      isLoading: detailsLoading,
                                      errorMessage: detailsError,
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                  _sectionWidget(data, selectedEtf),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _MarketBottomNav(
                      selected: selectedSection,
                      onChanged: onSectionChanged,
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  bool _hasUsableFirstScreenData(
    Etf00631LLabData data,
    _SelectedEtfViewData selectedEtf,
  ) {
    final history = selectedEtf.priceHistory.completenessSummary();
    final hasContext =
        history.rowCount >= 2 || _hasUsableHoldingsSnapshot(data.snapshot);
    return selectedEtf.marketPrice != null && hasContext;
  }

  Widget _sectionWidget(
    Etf00631LLabData data,
    _SelectedEtfViewData selectedEtf,
  ) {
    switch (selectedSection) {
      case _LabSection.overview:
        return _OverviewSection(
          data: data,
          selectedEtf: selectedEtf,
        );
      case _LabSection.historyBacktest:
        return _HistoryBacktestSection(
          data: data,
          selectedEtfCode: selectedEtfCode,
          selectedPriceHistory: selectedPriceHistory,
          selectedPriceHistoryLoading: selectedPriceHistoryLoading,
          selectedPriceHistoryError: selectedPriceHistoryError,
          comparisonHistories: comparisonHistories,
          comparisonHistoriesLoading: comparisonHistoriesLoading,
          comparisonHistoriesError: comparisonHistoriesError,
          selectedEtf: selectedEtf,
        );
      case _LabSection.position:
        return _PositionSection(data: data, selectedEtf: selectedEtf);
      case _LabSection.ai:
        return _AiSectionV2(data: data, selectedEtf: selectedEtf);
      case _LabSection.settings:
        return _SettingsSection(
          data: data,
          selectedEtf: selectedEtf,
          gapDetailsValue: gapDetailsValue,
        );
    }
  }
}

bool shouldLoad00631LFullData({
  required bool fastReadyOrError,
  required bool sectionNeedsFullData,
  required bool liveProxyEnabled,
}) {
  return fastReadyOrError && sectionNeedsFullData;
}

bool shouldUse00631LShortLiveRetry({
  required bool liveProxyEnabled,
  required bool hasLiveCoreData,
  required int retryCount,
}) {
  return liveProxyEnabled &&
      !hasLiveCoreData &&
      retryCount < liveCoreWarmupRetryLimit;
}

bool has00631LLiveCoreData(Etf00631LLabData? data) {
  if (data == null) {
    return false;
  }
  final snapshotStatus = data.snapshot.status;
  final hasSnapshot = _hasUsableHoldingsSnapshot(data.snapshot) &&
      snapshotStatus != EtfDataStatus.mock &&
      snapshotStatus != EtfDataStatus.error;
  final nav = data.intradayNav;
  final hasNav = nav != null &&
      nav.status != EtfDataStatus.mock &&
      nav.status != EtfDataStatus.error &&
      (nav.marketPrice != null || nav.estimatedNav != null);
  return hasSnapshot && hasNav;
}

class _SelectedEtfViewData {
  const _SelectedEtfViewData({
    required this.code,
    required this.name,
    required this.priceHistory,
    required this.catalogItem,
    required this.is00631L,
    required this.marketPrice,
    required this.estimatedNav,
    required this.premiumDiscountPct,
    required this.previousNav,
    required this.dataTime,
    required this.sourceStatusLabel,
  });

  factory _SelectedEtfViewData.from({
    required Etf00631LLabData data,
    required String selectedEtfCode,
    required EtfPriceHistory? selectedPriceHistory,
  }) {
    final normalized = selectedEtfCode.trim().toUpperCase().isEmpty
        ? '00631L'
        : selectedEtfCode.trim().toUpperCase();
    final catalogItem = _catalogItemByCode(data.etfCatalog, normalized);
    final is00631L = normalized == '00631L';
    final history = selectedPriceHistory ??
        (is00631L
            ? data.priceHistory
            : EtfPriceHistory.empty(
                code: normalized,
                name: catalogItem?.displayName ?? normalized,
                status: EtfDataStatus.error,
                sourceStatusLabel: 'loading',
                sourceUrl: '',
                lastFetchedAt: DateTime.now(),
                errorMessage: '選取的 ETF 價格歷史載入中。',
              ));
    final summary = history.completenessSummary();
    final nav = is00631L ? data.intradayNav : null;
    final historyName = history.name.trim();
    final profileName = data.profile.fundName.trim();
    final name = is00631L && (historyName.isEmpty || historyName == normalized)
        ? (profileName.isEmpty || profileName == normalized
            ? '元大台灣50正2'
            : profileName)
        : historyName.isNotEmpty
            ? historyName
            : catalogItem?.displayName ??
                (is00631L ? data.profile.fundName : normalized);
    final marketPrice = is00631L
        ? nav?.marketPrice ?? summary.latest?.close ?? catalogItem?.marketPrice
        : catalogItem?.marketPrice ?? summary.latest?.close;
    final estimatedNav = nav?.estimatedNav ?? catalogItem?.estimatedNav;
    final premiumDiscountPct = nav?.resolvedPremiumDiscountPct ??
        catalogItem?.resolvedPremiumDiscountPct;
    final previousNav = nav?.previousBusinessDayNav ?? catalogItem?.previousNav;
    final dataTime = is00631L
        ? nav?.dataTime ?? summary.latest?.date ?? catalogItem?.dataTime
        : catalogItem?.dataTime ?? summary.latest?.date;
    final sourceStatusLabel = nav?.status.label ??
        (is00631L
            ? history.sourceStatusLabel
            : catalogItem == null
                ? history.sourceStatusLabel
                : data.etfCatalog.sourceStatusLabel);
    return _SelectedEtfViewData(
      code: normalized,
      name: name,
      priceHistory: history,
      catalogItem: catalogItem,
      is00631L: is00631L,
      marketPrice: marketPrice,
      estimatedNav: estimatedNav,
      premiumDiscountPct: premiumDiscountPct,
      previousNav: previousNav,
      dataTime: dataTime,
      sourceStatusLabel: sourceStatusLabel,
    );
  }

  final String code;
  final String name;
  final EtfPriceHistory priceHistory;
  final EtfCatalogItem? catalogItem;
  final bool is00631L;
  final double? marketPrice;
  final double? estimatedNav;
  final double? premiumDiscountPct;
  final double? previousNav;
  final DateTime? dataTime;
  final String sourceStatusLabel;

  EtfPriceHistoryCompletenessSummary get historySummary =>
      priceHistory.completenessSummary();

  bool get hasImportedHistory =>
      historySummary.rowCount >= 2 ||
      (catalogItem != null && _catalogItemHasImportedEtfHistory(catalogItem!));

  String get readinessLabel {
    if (is00631L) {
      return '00631L 完整研究室';
    }
    return hasImportedHistory ? '歷史與回測可用' : '僅清單資料';
  }

  String get readinessDetail {
    final summary = historySummary;
    if (is00631L) {
      return '00631L 已接官方每日內容物、盤中 NAV、歷史與回測資料。';
    }
    if (hasImportedHistory) {
      return '$code 已載入 ${formatInteger(summary.rowCount)} 筆歷史價格，區間 ${_dateOrDash(summary.coverageStart)} - ${_dateOrDash(summary.coverageEnd)}。';
    }
    return '$code 目前只有 ETF 清單欄位，尚未匯入可驗證歷史價格。';
  }

  String get readinessAction {
    if (is00631L) {
      return '保持每日流程與靜態匯出更新。';
    }
    if (hasImportedHistory) {
      return '可查看歷史、回測與自選比較；內容物資料仍以 00631L 為主。';
    }
    return '若要啟用歷史與回測，請先匯入該 ETF 價格歷史。';
  }

  List<_SelectedEtfCapabilityBadge> get capabilityBadges {
    final ready = hasImportedHistory;
    return [
      _SelectedEtfCapabilityBadge(
        keySuffix: ready ? 'history-ready' : 'catalog-only',
        label: ready ? '歷史可用' : '僅清單資料',
      ),
      _SelectedEtfCapabilityBadge(
        keySuffix: ready ? 'backtest-ready' : 'backtest-paused',
        label: ready ? '回測可用' : '回測暫停',
      ),
      _SelectedEtfCapabilityBadge(
        keySuffix: ready ? 'compare-ready' : 'compare-paused',
        label: ready ? '比較可用' : '比較暫停',
      ),
      _SelectedEtfCapabilityBadge(
        keySuffix: ready ? 'ai-full-context' : 'ai-limited-context',
        label: ready ? 'AI 完整資料' : 'AI 有限資料',
      ),
    ];
  }

  String get historyCoverageText {
    final summary = historySummary;
    return '${_dateOrDash(summary.coverageStart)} - ${_dateOrDash(summary.coverageEnd)}';
  }

  String get priceFieldLabel {
    final summary = historySummary;
    return summary.hasAdjustedClose ? 'adjustedClose' : 'close';
  }

  String get adjustmentContextLabel {
    final summary = historySummary;
    if (summary.hasNonUnitAdjustment) {
      return '有調整因子';
    }
    if (summary.hasAdjustedClose) {
      return '使用調整價';
    }
    return '未標示調整';
  }

  String get backtestReadinessLabel {
    return hasImportedHistory ? '回測可用' : '回測未開';
  }

  String get liveNavScopeLabel {
    return is00631L ? '盤中 NAV 後端' : '盤中 NAV 限 00631L';
  }
}

class _SelectedEtfCapabilityBadge {
  const _SelectedEtfCapabilityBadge({
    required this.keySuffix,
    required this.label,
  });

  final String keySuffix;
  final String label;
}

class _DetailsLoadStateStrip extends StatelessWidget {
  const _DetailsLoadStateStrip({
    required this.isLoading,
    required this.errorMessage,
  });

  final bool isLoading;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasError = errorMessage != null;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: hasError
            ? theme.colorScheme.errorContainer.withValues(alpha: 0.24)
            : _marketPanelColor(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: hasError
              ? theme.colorScheme.error.withValues(alpha: 0.32)
              : _marketBorderColor(context),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            if (isLoading)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(
                Icons.info_outline,
                size: 16,
                color: hasError
                    ? theme.colorScheme.error
                    : _marketMutedTextColor(context),
              ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                hasError ? '完整資料暫不可用，已保留 fallback。' : '背景更新中，已先顯示可用資料。',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: hasError
                      ? theme.colorScheme.error
                      : _marketMutedTextColor(context),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LabLoadingShell extends StatelessWidget {
  const _LabLoadingShell({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _marketTheme(context),
      child: DecoratedBox(
        key: const ValueKey('00631l-loading-app-shell'),
        decoration: BoxDecoration(color: _marketBackground(context)),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
                children: [
                  Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1180),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _MarketTopBar(onRefresh: onRefresh),
                          const SizedBox(height: 8),
                          const _LoadingStatusStrip(),
                          const SizedBox(height: 8),
                          const _LoadingQuoteCard(),
                          const SizedBox(height: 8),
                          const _LoadingSectionCard(title: '準備首頁資料'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _MarketBottomNav(
              selected: _LabSection.overview,
              onChanged: (_) {},
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingStatusStrip extends StatelessWidget {
  const _LoadingStatusStrip();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      key: const ValueKey('00631l-loading-status-strip'),
      decoration: BoxDecoration(
        color: _marketPanelAltColor(context),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _marketBorderColor(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Row(
          children: [
            const _StatusPill(label: 'static / live check'),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '正在載入首頁資料',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _marketMutedTextColor(context),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingQuoteCard extends StatelessWidget {
  const _LoadingQuoteCard();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const ValueKey('00631l-loading-quote-card'),
      decoration: BoxDecoration(
        color: _marketPanelColor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _marketBorderColor(context)),
      ),
      child: const Padding(
        padding: EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _LoadingBar(width: 92, height: 20),
            SizedBox(height: 12),
            _LoadingBar(width: 156, height: 36),
            SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _LoadingBar(width: 96, height: 34),
                _LoadingBar(width: 96, height: 34),
                _LoadingBar(width: 108, height: 34),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingSectionCard extends StatelessWidget {
  const _LoadingSectionCard({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const ValueKey('00631l-loading-section-card'),
      decoration: BoxDecoration(
        color: _marketPanelColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _marketBorderColor(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: _marketTextColor(context),
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 12),
            const _LoadingBar(width: double.infinity, height: 16),
            const SizedBox(height: 8),
            const _LoadingBar(width: 220, height: 16),
          ],
        ),
      ),
    );
  }
}

class _LoadingBar extends StatelessWidget {
  const _LoadingBar({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _marketMutedTextColor(context).withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _MarketTopBar extends StatelessWidget {
  const _MarketTopBar({
    this.data,
    this.selectedEtfCode = '00631L',
    this.selectedEtfName = '00631L 正二研究室',
    this.onEtfSelected,
    required this.onRefresh,
  });

  final Etf00631LLabData? data;
  final String selectedEtfCode;
  final String selectedEtfName;
  final ValueChanged<String>? onEtfSelected;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final normalizedCode = selectedEtfCode.trim().toUpperCase();
    final subtitle = normalizedCode == '00631L'
        ? '00631L 正二研究室'
        : selectedEtfName.trim().isEmpty
            ? '$normalizedCode ETF 研究室'
            : selectedEtfName.trim();
    return SizedBox(
      height: 56,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showModeBadge = constraints.maxWidth >= 500;
          return Row(
            children: [
              _MarketIndexPill(
                label: selectedEtfCode,
                onTap: data == null
                    ? null
                    : () => _showSymbolSearchSheet(
                          context,
                          data!,
                          selectedEtfCode: selectedEtfCode,
                          onEtfSelected: onEtfSelected,
                        ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ETF 研究室',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: _marketTextColor(context),
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                        height: 1.08,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: _marketMutedTextColor(context),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                        height: 1.08,
                      ),
                    ),
                  ],
                ),
              ),
              if (showModeBadge) ...[
                _CompactTextBadge(label: _frontendDataModeDisplay),
                const SizedBox(width: 4),
              ],
              IconButton(
                tooltip: '重新整理',
                onPressed: onRefresh,
                color: _marketTextColor(context),
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.refresh, size: 21),
              ),
              const _ThemeToggleButton(compact: true),
            ],
          );
        },
      ),
    );
  }
}

class _MarketIndexPill extends StatelessWidget {
  const _MarketIndexPill({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '搜尋 ETF 或股票代號',
      child: InkWell(
        key: const ValueKey('00631l-symbol-search-button'),
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF2D6B4B),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFF67C58B)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 5),
                const Icon(Icons.search, color: Colors.white, size: 15),
                const SizedBox(width: 3),
                const Icon(Icons.expand_more, color: Colors.white, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _showSymbolSearchSheet(
  BuildContext context,
  Etf00631LLabData data, {
  required String selectedEtfCode,
  ValueChanged<String>? onEtfSelected,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: _marketPanelColor(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (sheetContext) {
      return _SymbolSearchSheet(
        data: data,
        selectedEtfCode: selectedEtfCode,
        onEtfSelected: onEtfSelected,
      );
    },
  );
}

class _SymbolSearchSheet extends ConsumerStatefulWidget {
  const _SymbolSearchSheet({
    required this.data,
    required this.selectedEtfCode,
    this.onEtfSelected,
  });

  final Etf00631LLabData data;
  final String selectedEtfCode;
  final ValueChanged<String>? onEtfSelected;

  @override
  ConsumerState<_SymbolSearchSheet> createState() => _SymbolSearchSheetState();
}

enum _SymbolSearchHistoryFilter {
  all('全部'),
  ready('歷史可用'),
  catalogOnly('未匯入歷史');

  const _SymbolSearchHistoryFilter(this.label);

  final String label;
}

class _SymbolSearchSheetState extends ConsumerState<_SymbolSearchSheet> {
  final _controller = TextEditingController();
  _SymbolSearchHistoryFilter _historyFilter = _SymbolSearchHistoryFilter.all;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _controller.text.trim().toLowerCase();
    final catalogAsync = ref.watch(etf00631LCatalogProvider);
    final loadedCatalog = catalogAsync.valueOrNull;
    final catalog = loadedCatalog?.hasData == true
        ? loadedCatalog!
        : widget.data.etfCatalog;
    final catalogLoading = catalogAsync.isLoading && !catalog.hasData;
    final catalogError = catalogAsync.hasError && !catalog.hasData;
    final stocksAsync = ref.watch(watchlistProvider);
    final readyHistoryCount = _searchReadyHistoryCount(widget.data);
    final catalogRowCount = catalog.hasData
        ? catalog.rowCount
        : widget.data.operationsStatus.etfCatalogRowCount;
    final effectiveCatalogRowCount = _effectiveEtfCatalogRows(
      status: widget.data.operationsStatus,
      loadedCatalogRows: catalogRowCount,
    );
    final historyTotal = _etfDataCompletionTotal(
      status: widget.data.operationsStatus,
      catalogRows: effectiveCatalogRowCount,
    );
    final historyGap =
        (historyTotal - readyHistoryCount).clamp(0, historyTotal).toInt();
    final baseItems = query.isEmpty
        ? catalog.focusItems
        : _rankedSymbolSearchItems([
            for (final item in catalog.items)
              if (_catalogSearchText(item).contains(query)) item,
          ], query);
    final items = [
      for (final item in baseItems)
        if (_symbolSearchFilterIncludes(_historyFilter, item)) item,
    ];
    final queryReadyCount =
        baseItems.where(_catalogItemHasImportedEtfHistory).length;
    final queryCatalogOnlyCount = baseItems.length - queryReadyCount;
    final visibleItems = items.take(30).toList(growable: false);
    final stockItems = query.isEmpty
        ? const <Stock>[]
        : stocksAsync.maybeWhen(
            data: (stocks) => [
              for (final stock in stocks)
                if (_stockSearchText(stock).contains(query)) stock,
            ].take(12).toList(growable: false),
            orElse: () => const <Stock>[],
          );
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(14, 12, 14, 14 + bottomInset),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 620),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '搜尋 ETF 代號',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: _marketTextColor(context),
                                  fontWeight: FontWeight.w900,
                                ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '輸入 ETF 代號或名稱；選取 ETF 後切換研究標的。股票結果會放在其他研究資料。',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: _marketMutedTextColor(context),
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: '關閉',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('00631l-symbol-search-field'),
              controller: _controller,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: '清除搜尋',
                        onPressed: () {
                          _controller.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.close),
                      ),
                labelText: '輸入代號或名稱',
                hintText: '00631L、0050、00878',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            _StatusWrap(
              labels: [
                '篩選 ${_historyFilter.label}',
                if (query.isEmpty)
                  '熱門清單'
                else
                  'ETF ${formatInteger(items.length)} / ${formatInteger(baseItems.length)}',
                '歷史可用 ${formatInteger(readyHistoryCount)} / ${formatInteger(historyTotal)}',
                if (historyGap > 0) '待補 ${formatInteger(historyGap)}',
                if (query.isNotEmpty) '歷史可用 ${formatInteger(queryReadyCount)}',
                if (query.isNotEmpty)
                  '僅清單 ${formatInteger(queryCatalogOnlyCount)}',
                if (query.isNotEmpty) '個股 ${stockItems.length}',
              ],
            ),
            KeyedSubtree(
              key: ValueKey(
                '00631l-symbol-filter-count-${_historyFilter.name}-${items.length}-${baseItems.length}',
              ),
              child: const SizedBox.shrink(),
            ),
            KeyedSubtree(
              key: ValueKey(
                '00631l-symbol-query-ready-count-$queryReadyCount',
              ),
              child: const SizedBox.shrink(),
            ),
            KeyedSubtree(
              key: ValueKey(
                '00631l-symbol-query-catalog-only-count-$queryCatalogOnlyCount',
              ),
              child: const SizedBox.shrink(),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final filter in _SymbolSearchHistoryFilter.values) ...[
                    ChoiceChip(
                      key: ValueKey('00631l-symbol-filter-${filter.name}'),
                      label: Text(filter.label),
                      selected: _historyFilter == filter,
                      onSelected: (_) =>
                          setState(() => _historyFilter = filter),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),
            KeyedSubtree(
              key: ValueKey(
                '00631l-symbol-search-ready-count-$readyHistoryCount',
              ),
              child: const SizedBox.shrink(),
            ),
            for (final (index, item) in visibleItems.take(5).indexed)
              KeyedSubtree(
                key: ValueKey(
                  '00631l-symbol-search-rank-$index-${item.code}',
                ),
                child: const SizedBox.shrink(),
              ),
            Flexible(
              child: visibleItems.isEmpty && stockItems.isEmpty
                  ? catalogLoading
                      ? const _SymbolSearchLoadingPanel()
                      : catalogError
                          ? const _EmptyPanel(
                              key: ValueKey(
                                '00631l-symbol-search-catalog-error',
                              ),
                              title: 'ETF 目錄載入失敗',
                              message: '請稍後重新開啟搜尋；目前仍保留已載入的資料狀態。',
                            )
                          : _EmptyPanel(
                              title: '查無代號',
                              message: query.isEmpty
                                  ? 'ETF 清單暫無明細。'
                                  : '目前沒有符合的 ETF 或內建股票研究資料。',
                            )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: visibleItems.length +
                          (stockItems.isEmpty ? 0 : 1) +
                          stockItems.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        if (index < visibleItems.length) {
                          final item = visibleItems[index];
                          return _SymbolSearchResultTile(
                            item: item,
                            selected: item.code == widget.selectedEtfCode,
                            onSelected: widget.onEtfSelected,
                          );
                        }
                        final stockSectionIndex = index - visibleItems.length;
                        if (stockItems.isNotEmpty && stockSectionIndex == 0) {
                          return Padding(
                            key: const ValueKey(
                              '00631l-stock-search-section-label',
                            ),
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              '其他研究資料',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    color: _marketMutedTextColor(context),
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0,
                                  ),
                            ),
                          );
                        }
                        final stock = stockItems[
                            stockSectionIndex - (stockItems.isEmpty ? 0 : 1)];
                        return _StockSearchResultTile(stock: stock);
                      },
                    ),
            ),
            const SizedBox(height: 8),
            _CompactExpansionPanel(
              key: const ValueKey('00631l-symbol-search-database-panel'),
              title: '資料庫狀態',
              subtitle:
                  '歷史可用 ${formatInteger(readyHistoryCount)} / ${formatInteger(historyTotal)}；缺口 ${formatInteger(historyGap)}。',
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 170),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _StatusWrap(
                        labels: [
                          '清單 ${formatInteger(catalogRowCount)}',
                          '目前結果 未匯入歷史 ${formatInteger(queryCatalogOnlyCount)}',
                        ],
                      ),
                      const SizedBox(height: 8),
                      _SymbolSearchDataCompletionStrip(
                        key: const ValueKey('00631l-etf-data-completion-strip'),
                        data: widget.data,
                        catalogRowCount: catalogRowCount,
                        readyHistoryCount: readyHistoryCount,
                      ),
                      const SizedBox(height: 8),
                      _SymbolSearchReadinessNotice(
                        data: widget.data,
                        catalogRowCount: catalogRowCount,
                        readyHistoryCount: readyHistoryCount,
                        visibleReadyCount: queryReadyCount,
                        visibleCatalogOnlyCount: queryCatalogOnlyCount,
                        hasQuery: query.isNotEmpty,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SymbolSearchLoadingPanel extends StatelessWidget {
  const _SymbolSearchLoadingPanel();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      key: const ValueKey('00631l-symbol-search-catalog-loading'),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: theme.colorScheme.surfaceContainerHighest,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'ETF 目錄載入中，請稍候。',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SymbolSearchDataCompletionStrip extends StatelessWidget {
  const _SymbolSearchDataCompletionStrip({
    super.key,
    required this.data,
    required this.catalogRowCount,
    required this.readyHistoryCount,
  });

  final Etf00631LLabData data;
  final int catalogRowCount;
  final int readyHistoryCount;

  @override
  Widget build(BuildContext context) {
    final status = data.operationsStatus;
    final effectiveCatalogRowCount = _effectiveEtfCatalogRows(
      status: status,
      loadedCatalogRows: catalogRowCount,
    );
    final historyTotal = _etfDataCompletionTotal(
      status: status,
      catalogRows: effectiveCatalogRowCount,
    );
    final readyRatio =
        historyTotal <= 0 ? 0.0 : readyHistoryCount / historyTotal * 100;
    final gap =
        (historyTotal - readyHistoryCount).clamp(0, historyTotal).toInt();
    final tiers = status.etfPriceHistoryCoverageTierCounts;
    final longTerm = tiers['long_term'] ?? 0;
    final recent = tiers['recent'] ?? 0;
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: _marketPanelAltColor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _marketBorderColor(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'ETF 資料庫狀態',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: _marketTextColor(context),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  '完成度 ${formatNullablePercent(readyRatio)}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: _marketMutedTextColor(context),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _StatusWrap(
              labels: [
                '歷史可用 ${formatInteger(readyHistoryCount)} / ${formatInteger(historyTotal)}',
                '缺口 ${formatInteger(gap)}',
              ],
            ),
            const SizedBox(height: 8),
            _CompactExpansionPanel(
              title: '資料細節',
              subtitle: '顯示 ETF 清單、歷史匯入狀態與期間分類。',
              child: _StatusWrap(
                labels: [
                  '目前清單 ${formatInteger(catalogRowCount)}',
                  if (effectiveCatalogRowCount != catalogRowCount)
                    '統計母數 ${formatInteger(effectiveCatalogRowCount)}',
                  '清單來源 ${_sourceStatusBadgeLabel(status.etfCatalogStatus)}',
                  '歷史來源 ${_sourceStatusBadgeLabel(status.etfPriceHistoryStatus)}',
                  _etfHistorySourceContractDetail(status),
                  '長期資料 ${formatInteger(longTerm)}',
                  '近期資料 ${formatInteger(recent)}',
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SymbolSearchReadinessNotice extends StatelessWidget {
  const _SymbolSearchReadinessNotice({
    required this.data,
    required this.catalogRowCount,
    required this.readyHistoryCount,
    required this.visibleReadyCount,
    required this.visibleCatalogOnlyCount,
    required this.hasQuery,
  });

  final Etf00631LLabData data;
  final int catalogRowCount;
  final int readyHistoryCount;
  final int visibleReadyCount;
  final int visibleCatalogOnlyCount;
  final bool hasQuery;

  @override
  Widget build(BuildContext context) {
    final status = data.operationsStatus;
    final effectiveCatalogRowCount = _effectiveEtfCatalogRows(
      status: status,
      loadedCatalogRows: catalogRowCount,
    );
    final historyTotal = _etfDataCompletionTotal(
      status: status,
      catalogRows: effectiveCatalogRowCount,
    );
    final missingCount = status.etfPriceHistoryMissingCount > 0
        ? status.etfPriceHistoryMissingCount
        : (historyTotal - readyHistoryCount).clamp(0, historyTotal).toInt();
    final unclassified =
        status.etfPriceHistoryGapReasonCounts['not_saved'] ?? 0;
    final gapStatus = missingCount <= 0
        ? '全部可用'
        : unclassified > 0
            ? '仍有未分類缺口 ${formatInteger(unclassified)}'
            : '缺口已分類';
    final theme = Theme.of(context);

    return Container(
      key: const ValueKey('00631l-compact-quote-header'),
      decoration: BoxDecoration(
        color: _marketPanelColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _marketBorderColor(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '資料可用性',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: _marketTextColor(context),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _CompactTextBadge(label: gapStatus),
              ],
            ),
            const SizedBox(height: 6),
            _StatusWrap(
              labels: [
                '可回測/比較 ${formatInteger(readyHistoryCount)} / ${formatInteger(historyTotal)}',
                if (missingCount > 0) '僅清單 ${formatInteger(missingCount)}',
                if (missingCount > 0) _etfGapReasonCompactLabel(status),
                if (hasQuery) '本次可用 ${formatInteger(visibleReadyCount)}',
                if (hasQuery) '本次僅清單 ${formatInteger(visibleCatalogOnlyCount)}',
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StockSearchResultTile extends StatelessWidget {
  const _StockSearchResultTile({required this.stock});

  final Stock stock;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      key: ValueKey('00631l-stock-search-result-${stock.symbol}'),
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        final router = GoRouter.of(context);
        Navigator.of(context).pop();
        router.push('/stocks/${stock.symbol}');
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _marketPanelAltColor(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _marketBorderColor(context)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _MiniStatusBadge(label: stock.symbol),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stock.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: _marketTextColor(context),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${stock.industry} / 股票研究資料',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _marketMutedTextColor(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const _MiniStatusBadge(label: 'STOCK'),
            ],
          ),
        ),
      ),
    );
  }
}

class _SymbolSearchResultTile extends StatelessWidget {
  const _SymbolSearchResultTile({
    required this.item,
    required this.selected,
    this.onSelected,
  });

  final EtfCatalogItem item;
  final bool selected;
  final ValueChanged<String>? onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final readiness = _etfHistoryReadiness(item);
    final hasHistory = readiness.hasHistory;
    final historyMetadataLabel = _etfHistoryMetadataLabel(item);
    final missingReasonLabel = _etfHistoryMissingReasonLabel(item);
    final priceBasisLabel = _etfHistoryPriceBasisLabel(item);
    final dataSummary = _symbolSearchDataSummary(item);
    final capabilitySummary = _symbolSearchCapabilitySummary(
      item,
      readiness,
    );
    final visibleCapabilityKeys = <String>{
      'live-nav',
      'live-nav-scope',
    };
    return InkWell(
      key: ValueKey('00631l-symbol-search-result-${item.code}'),
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.of(context).pop();
        onSelected?.call(item.code);
        final message = selected
            ? '${item.code} 已在目前頁面。'
            : readiness.snackMessage(item.code);
        messenger.showSnackBar(SnackBar(content: Text(message)));
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected
              ? _marketBlue.withValues(alpha: 0.16)
              : _marketPanelAltColor(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? _marketBlue : _marketBorderColor(context),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _MiniStatusBadge(label: item.code),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: _marketTextColor(context),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Wrap(
                      spacing: 6,
                      runSpacing: 5,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          item.targetType.isEmpty ? 'ETF 清單' : item.targetType,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: _marketMutedTextColor(context),
                          ),
                        ),
                        KeyedSubtree(
                          key: ValueKey(
                            hasHistory
                                ? '00631l-symbol-history-ready-${item.code}'
                                : '00631l-symbol-catalog-only-${item.code}',
                          ),
                          child: _CompactTextBadge(
                            label: readiness.badgeLabel,
                          ),
                        ),
                        if (historyMetadataLabel.isNotEmpty)
                          _CompactTextBadge(label: historyMetadataLabel),
                        if (priceBasisLabel.isNotEmpty)
                          KeyedSubtree(
                            key: ValueKey(
                              '00631l-symbol-price-basis-${item.code}',
                            ),
                            child: _CompactTextBadge(label: priceBasisLabel),
                          ),
                        if (missingReasonLabel.isNotEmpty)
                          KeyedSubtree(
                            key: ValueKey(
                              '00631l-symbol-gap-reason-${item.code}',
                            ),
                            child: _CompactTextBadge(
                              label: missingReasonLabel,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      capabilitySummary,
                      key: ValueKey(
                        '00631l-symbol-capability-summary-${item.code}',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: _marketTextColor(context),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dataSummary,
                      key: ValueKey('00631l-symbol-data-summary-${item.code}'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: _marketMutedTextColor(context),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                    ),
                    if (readiness.capabilities.any(
                      (capability) =>
                          visibleCapabilityKeys.contains(capability.key),
                    )) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 5,
                        runSpacing: 5,
                        children: [
                          for (final capability in readiness.capabilities)
                            if (visibleCapabilityKeys.contains(capability.key))
                              KeyedSubtree(
                                key: ValueKey(
                                  '00631l-symbol-capability-${item.code}-${capability.key}',
                                ),
                                child: _CompactTextBadge(
                                  label: capability.label,
                                ),
                              ),
                        ],
                      ),
                    ],
                    for (final capability in readiness.capabilities)
                      if (!visibleCapabilityKeys.contains(capability.key))
                        KeyedSubtree(
                          key: ValueKey(
                            '00631l-symbol-capability-${item.code}-${capability.key}',
                          ),
                          child: const SizedBox.shrink(),
                        ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _price(item.marketPrice),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: _marketTextColor(context),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    selected ? '目前頁面' : readiness.trailingLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: _marketMutedTextColor(context),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactTextBadge extends StatelessWidget {
  const _CompactTextBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _marketPanelAltColor(context),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _marketBorderColor(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: _marketMutedTextColor(context),
                fontWeight: FontWeight.w900,
              ),
        ),
      ),
    );
  }
}

// ignore: unused_element
class _MarketSentimentStrip extends StatelessWidget {
  const _MarketSentimentStrip({required this.data});

  final Etf00631LLabData data;

  @override
  Widget build(BuildContext context) {
    final nav = data.intradayNav;
    final premiumAssessment = PremiumDiscountAssessment.evaluate(
      premiumDiscountPct: nav?.resolvedPremiumDiscountPct,
      sourceStatus: nav?.status ?? EtfDataStatus.error,
      isStale: nav?.isStale ?? true,
    );
    final statusSummary = data.statusSummary;
    return Container(
      decoration: BoxDecoration(
        color: _marketPanelColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _marketBorderColor(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              '市場資料',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: _marketTextColor(context),
                    fontWeight: FontWeight.w900,
                  ),
            ),
            _MarketSignalPill(
              icon: Icons.verified_outlined,
              label: 'holdings ${data.snapshot.status.label}',
              color: _marketGreen,
            ),
            _MarketSignalPill(
              icon: _levelIcon(premiumAssessment.level),
              label: premiumAssessment.label,
              color: _levelColor(
                  Theme.of(context).colorScheme, premiumAssessment.level),
            ),
            _MarketSignalPill(
              icon: Icons.health_and_safety_outlined,
              label: statusSummary.label,
              color: _marketBlue,
            ),
          ],
        ),
      ),
    );
  }
}

class _MarketSignalPill extends StatelessWidget {
  const _MarketSignalPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 17),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactQuoteHeader extends StatelessWidget {
  const _CompactQuoteHeader({
    required this.data,
    required this.selectedEtf,
  });

  final Etf00631LLabData data;
  final _SelectedEtfViewData selectedEtf;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final quotePremiumDiscountPct = selectedEtf.is00631L
        ? data.intradayNav?.resolvedPremiumDiscountPct
        : selectedEtf.premiumDiscountPct;
    final premiumAssessment = PremiumDiscountAssessment.evaluate(
      premiumDiscountPct: quotePremiumDiscountPct,
      sourceStatus: selectedEtf.is00631L
          ? data.intradayNav?.status ?? EtfDataStatus.error
          : data.etfCatalog.status,
      isStale: selectedEtf.is00631L
          ? data.intradayNav?.isStale ?? true
          : data.etfCatalog.isStale,
    );
    final premiumColor = _levelColor(
      theme.colorScheme,
      premiumAssessment.level,
    );
    final history = selectedEtf.priceHistory.completenessSummary();
    final latestHistoryPoint = history.latest;
    final quoteValue = selectedEtf.marketPrice ?? latestHistoryPoint?.close;
    final quoteStatus = selectedEtf.sourceStatusLabel;
    final quoteName = selectedEtf.is00631L ? '元大台灣50正2' : selectedEtf.name;
    final usesLiveQuote =
        selectedEtf.is00631L && data.intradayNav?.marketPrice != null;
    final usesCatalogQuote =
        !selectedEtf.is00631L && selectedEtf.catalogItem?.marketPrice != null;
    final usesHistoryQuote = !usesLiveQuote &&
        !usesCatalogQuote &&
        latestHistoryPoint != null &&
        quoteValue == latestHistoryPoint.close;
    final quoteStatusDisplay = usesCatalogQuote
        ? '清單'
        : usesHistoryQuote
            ? '歷史收盤'
            : _statusDisplay(quoteStatus);
    final marketSession = selectedEtf.is00631L
        ? data.intradayNav?.marketSession() ??
            IntradayMarketSession.evaluate(sourceAvailable: false)
        : null;
    final quoteCaptionDisplay = usesLiveQuote && selectedEtf.dataTime != null
        ? '市價 · ${marketSession!.phaseLabel} ${_sourceTimeText(selectedEtf.dataTime!)}'
        : usesCatalogQuote && selectedEtf.catalogItem?.dataTime != null
            ? '市價 · 清單 ${formatTaiwanDateTimeSeconds(selectedEtf.catalogItem!.dataTime!)}'
            : usesHistoryQuote
                ? '市價 · 歷史收盤 ${formatTaiwanDate(latestHistoryPoint.date)}'
                : selectedEtf.dataTime == null
                    ? '市價 · 盤中資料暫無'
                    : '市價 · ${_statusDisplay(quoteStatus)} ${formatTaiwanDateTimeSeconds(selectedEtf.dataTime!)}';

    return Container(
      key: const ValueKey('00631l-main-quote-header'),
      decoration: BoxDecoration(
        color: _marketPanelColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _marketBorderColor(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 5, 8, 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${selectedEtf.code} $quoteName',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: _marketMutedTextColor(context),
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0,
                              ),
                            ),
                          ),
                          _CompactTextBadge(
                            label: quoteStatusDisplay,
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _price(quoteValue),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: _marketTextColor(context),
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        quoteCaptionDisplay,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _marketMutedTextColor(context),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _CompactPremiumBox(
                  value: formatSignedNullablePercent(quotePremiumDiscountPct),
                  label: _premiumLabel(premiumAssessment),
                  color: premiumColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuoteReadinessItem {
  const _QuoteReadinessItem({
    required this.label,
    required this.value,
    required this.caption,
  });

  final String label;
  final String value;
  final String caption;
}

class _QuoteReadinessStrip extends StatelessWidget {
  const _QuoteReadinessStrip({
    required this.data,
    required this.selectedEtf,
  });

  final Etf00631LLabData data;
  final _SelectedEtfViewData selectedEtf;

  @override
  Widget build(BuildContext context) {
    final nav = data.intradayNav;
    final price = selectedEtf.priceHistory.completenessSummary();
    final latestHolding = _hasUsableHoldingsSnapshot(data.snapshot)
        ? _latestHoldingsDate(data)
        : null;
    final navTime = nav?.dataTime;
    final snapshotStatus = _sourceStatusBadgeLabel(data.snapshot.status.label);
    final navStatus = _sourceStatusBadgeLabel(nav?.status.label);
    final latestSelectedPoint = price.latest;
    final splitAdjustmentLabel = _priceAdjustmentConfidenceLabel(
      selectedEtf.code,
      selectedEtf.historySummary,
    );
    final items = selectedEtf.is00631L
        ? [
            _QuoteReadinessItem(
              label: '內容物',
              value: latestHolding == null
                  ? '不可用'
                  : _summaryMonthDay(latestHolding),
              caption: snapshotStatus,
            ),
            _QuoteReadinessItem(
              label: '盤中 NAV',
              value: navTime == null ? '暫無' : _summaryTimeMinute(navTime),
              caption: navStatus,
            ),
            _QuoteReadinessItem(
              label: '價格欄位',
              value: selectedEtf.priceFieldLabel,
              caption: price.rowCount >= 2
                  ? '${formatInteger(price.rowCount)}筆'
                  : '尚無歷史',
            ),
            _QuoteReadinessItem(
              label: '分割調整',
              value: splitAdjustmentLabel,
              caption: selectedEtf.historyCoverageText,
            ),
          ]
        : [
            _QuoteReadinessItem(
              label: '價格',
              value: latestSelectedPoint == null
                  ? _price(selectedEtf.marketPrice)
                  : _summaryMonthDay(latestSelectedPoint.date),
              caption: _sourceStatusBadgeLabel(selectedEtf.sourceStatusLabel),
            ),
            _QuoteReadinessItem(
              label: '歷史',
              value: price.rowCount >= 2
                  ? '${formatInteger(price.rowCount)}筆'
                  : '尚無',
              caption: _summaryCoverageCompactYears(price),
            ),
            _QuoteReadinessItem(
              label: '回測',
              value: selectedEtf.backtestReadinessLabel,
              caption: selectedEtf.priceFieldLabel,
            ),
            _QuoteReadinessItem(
              label: '盤中 NAV',
              value: selectedEtf.is00631L ? '可用' : '未接',
              caption: selectedEtf.liveNavScopeLabel,
            ),
          ];

    return DecoratedBox(
      key: const ValueKey('00631l-quote-readiness-strip'),
      decoration: BoxDecoration(
        color: _marketPanelAltColor(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _marketBorderColor(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
        child: Row(
          children: [
            for (var index = 0; index < items.length; index++) ...[
              Expanded(child: _QuoteReadinessChip(item: items[index])),
              if (index != items.length - 1) const SizedBox(width: 3),
            ],
          ],
        ),
      ),
    );
  }
}

class _SelectedEtfOverviewDigest extends StatelessWidget {
  const _SelectedEtfOverviewDigest({required this.selectedEtf});

  final _SelectedEtfViewData selectedEtf;

  @override
  Widget build(BuildContext context) {
    final history = selectedEtf.historySummary;
    final latest = history.latest;
    final splitAdjustmentLabel = _priceAdjustmentConfidenceLabel(
      selectedEtf.code,
      history,
    );
    final readinessText = selectedEtf.hasImportedHistory
        ? '${selectedEtf.code} 可用於歷史、回測、比較與 AI context；${selectedEtf.liveNavScopeLabel}。'
        : '${selectedEtf.code} 目前僅清單資料；歷史、回測與比較需先匯入價格歷史。';
    final items = [
      _QuoteReadinessItem(
        label: '最新',
        value: _price(latest?.performanceClose ?? selectedEtf.marketPrice),
        caption: latest == null
            ? _sourceStatusBadgeLabel(selectedEtf.sourceStatusLabel)
            : _summaryMonthDay(latest.date),
      ),
      _QuoteReadinessItem(
        label: '歷史',
        value: history.rowCount >= 2
            ? '${formatInteger(history.rowCount)}筆'
            : '尚無',
        caption: _summaryCoverageCompactYears(history),
      ),
      _QuoteReadinessItem(
        label: '價格基礎',
        value: selectedEtf.priceFieldLabel,
        caption: splitAdjustmentLabel,
      ),
      _QuoteReadinessItem(
        label: '回測',
        value: selectedEtf.backtestReadinessLabel,
        caption: selectedEtf.hasImportedHistory ? '可選日期' : '缺歷史',
      ),
    ];

    return DecoratedBox(
      key: const ValueKey('00631l-selected-etf-overview-digest'),
      decoration: BoxDecoration(
        color: _marketPanelColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _marketBorderColor(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(9, 8, 9, 9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _MiniStatusBadge(
                  label: selectedEtf.hasImportedHistory ? 'READY' : 'DATA',
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${selectedEtf.code} 資料完整度',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: _marketTextColor(context),
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                _CompactTextBadge(
                  label: _sourceStatusBadgeLabel(
                    selectedEtf.priceHistory.sourceStatusLabel,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                for (var index = 0; index < items.length; index++) ...[
                  Expanded(child: _QuoteReadinessChip(item: items[index])),
                  if (index != items.length - 1) const SizedBox(width: 3),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Text(
              readinessText,
              key: const ValueKey('00631l-selected-etf-usable-scope-line'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: _marketMutedTextColor(context),
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuoteReadinessChip extends StatelessWidget {
  const _QuoteReadinessChip({required this.item});

  final _QuoteReadinessItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          item.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(
            color: _marketMutedTextColor(context),
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
            height: 1,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Expanded(
              flex: item.caption.trim().isEmpty ? 1 : 2,
              child: Text(
                item.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: _marketTextColor(context),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                  height: 1,
                ),
              ),
            ),
            if (item.caption.trim().isNotEmpty) ...[
              const SizedBox(width: 3),
              Expanded(
                flex: 3,
                child: Text(
                  item.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: _marketMutedTextColor(context),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                    height: 1,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _CompactPremiumBox extends StatelessWidget {
  const _CompactPremiumBox({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      key: const ValueKey('00631l-quote-premium-box'),
      constraints: const BoxConstraints(minWidth: 88, maxWidth: 108),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.46)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '折溢價',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: _marketMutedTextColor(context),
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: _marketTextColor(context),
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 1),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverviewActionRow extends StatelessWidget {
  const _OverviewActionRow({required this.data});

  final Etf00631LLabData data;

  @override
  Widget build(BuildContext context) {
    final history = data.holdingsHistory.trendSummary();
    final latest = history.latest;
    final label = latest == null
        ? '內容物紀錄尚未累積'
        : 'holdings ${formatTaiwanDate(latest.tradeDate)} | TX ${formatNullablePercent(latest.txWeightPct)} | 台積電 ${formatNullablePercent(latest.tsmcWeightPct)}';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _marketPanelAltColor(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _marketBorderColor(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            const _MiniStatusBadge(label: 'DAY'),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _marketTextColor(context),
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _historyChangeSubtitle(EtfHoldingsHistoryTrendSummary history) {
  final latest = history.latest;
  if (latest == null) {
    return '尚無每日流程累積資料；不補假資料。';
  }
  return 'latest ${formatTaiwanDate(latest.tradeDate)}，TX ${formatNullablePercent(latest.txWeightPct)}，台積電 ${formatNullablePercent(latest.tsmcWeightPct)}。';
}

// ignore: unused_element
class _QuoteHeader extends StatelessWidget {
  const _QuoteHeader({
    required this.data,
    required this.onRefresh,
  });

  final Etf00631LLabData data;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final nav = data.intradayNav;
    final premiumAssessment = PremiumDiscountAssessment.evaluate(
      premiumDiscountPct: nav?.resolvedPremiumDiscountPct,
      sourceStatus: nav?.status ?? EtfDataStatus.error,
      isStale: nav?.isStale ?? true,
    );
    final color = _levelColor(theme.colorScheme, premiumAssessment.level);
    final headerBackground = colorScheme.brightness == Brightness.dark
        ? colorScheme.surfaceContainerHighest
        : const Color(0xFF0F172A);
    final headerForeground = colorScheme.brightness == Brightness.dark
        ? colorScheme.onSurface
        : Colors.white;
    final mutedForeground = headerForeground.withValues(alpha: 0.72);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: headerBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.brightness == Brightness.dark
              ? colorScheme.outlineVariant
              : Colors.transparent,
        ),
        boxShadow: [
          if (colorScheme.brightness == Brightness.light)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 620;
                  final headerTitle = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ETF 研究室',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: headerForeground,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0,
                                ),
                              ),
                              Text(
                                '00631L 正二研究室',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: mutedForeground,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0,
                                ),
                              ),
                            ],
                          ),
                          _HeaderPill(
                            label: _frontendDataMode,
                            foreground: headerForeground,
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '00631L 是第一個完整研究室；公開 PWA、歷史回測、持倉與 AI 摘要已可日常使用。',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: mutedForeground,
                          height: 1.35,
                        ),
                      ),
                    ],
                  );
                  final actions = Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton.filled(
                        tooltip: '重新整理',
                        onPressed: onRefresh,
                        style: IconButton.styleFrom(
                          backgroundColor:
                              headerForeground.withValues(alpha: 0.12),
                          foregroundColor: headerForeground,
                        ),
                        icon: const Icon(Icons.refresh),
                      ),
                    ],
                  );
                  return compact
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            headerTitle,
                            const SizedBox(height: 10),
                            actions,
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: headerTitle),
                            const SizedBox(width: 12),
                            actions,
                          ],
                        );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 620;
                  final quote = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _price(nav?.marketPrice),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.displaySmall?.copyWith(
                          color: headerForeground,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            '市價',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: mutedForeground,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          _HeaderPill(
                            label: nav?.status.label ?? 'unavailable',
                            foreground: headerForeground,
                          ),
                          if (nav?.sourceContract != null)
                            _HeaderPill(
                              label: nav!.sourceContract!,
                              foreground: headerForeground,
                            ),
                        ],
                      ),
                    ],
                  );
                  final premiumBox = DecoratedBox(
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: color.withValues(alpha: 0.42)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '折溢價',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: mutedForeground,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formatSignedNullablePercent(
                              nav?.resolvedPremiumDiscountPct,
                            ),
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: headerForeground,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _premiumLabel(premiumAssessment),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: mutedForeground,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                  return compact
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            quote,
                            const SizedBox(height: 12),
                            premiumBox,
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(child: quote),
                            SizedBox(width: 210, child: premiumBox),
                          ],
                        );
                },
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.brightness == Brightness.dark
                    ? colorScheme.surface.withValues(alpha: 0.42)
                    : Colors.white.withValues(alpha: 0.08),
                border: Border(
                  top: BorderSide(
                    color: headerForeground.withValues(alpha: 0.12),
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 620;
                    return GridView.count(
                      crossAxisCount: compact ? 2 : 4,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: compact ? 1.22 : 2.05,
                      children: [
                        _QuoteStatTile(
                          label: '預估淨值',
                          value: _price(nav?.estimatedNav),
                          caption: '盤中估算資料',
                          foreground: headerForeground,
                        ),
                        _QuoteStatTile(
                          label: '前日淨值',
                          value: _price(nav?.previousBusinessDayNav),
                          caption: '官方揭露欄位',
                          foreground: headerForeground,
                        ),
                        _QuoteStatTile(
                          label: '資料時間',
                          value: nav?.dataTime == null
                              ? 'unavailable'
                              : formatTimeSeconds(nav!.dataTime!),
                          caption: nav?.dataDate == null
                              ? 'intraday unavailable'
                              : formatTaiwanDate(nav!.dataDate!),
                          foreground: headerForeground,
                        ),
                        _QuoteStatTile(
                          label: '發行單位',
                          value: nav?.outstandingUnits == null
                              ? _compactNumber(data.snapshot.outstandingUnits)
                              : _compactNumber(nav!.outstandingUnits!),
                          caption: 'units',
                          foreground: headerForeground,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: _StatusWrap(
                labels: [
                  '核心 ${_coreDataStatusLabel(data)}',
                  '內容物 ${_sourceStatusBadgeLabel(data.snapshot.status.label)}',
                  '盤中 ${_sourceStatusBadgeLabel(nav?.status.label)}',
                  '歷史 ${_sourceStatusBadgeLabel(data.priceHistory.sourceStatusLabel)}',
                  '前端 $_frontendDataModeLabel',
                  if (_use00631LLiveProxy)
                    '後端 ${data.operationsStatus.publicApiBaseUrl.isEmpty ? _proxyBaseUrl00631l : data.operationsStatus.publicApiBaseUrl}',
                  if (_use00631LLiveProxy)
                    '檢查 ${_dateTimeOrDash(data.operationsStatus.lastFetchedAt)}',
                  if (_use00631LStaticData) '靜態 $_staticDataBaseUrl00631l',
                  if (_use00631LStaticData)
                    '筆數 ${data.operationsStatus.priceHistoryRows}',
                  if (_use00631LStaticData)
                    '產生 ${_dateTimeOrDash(data.operationsStatus.latestExportUpdatedAt ?? data.priceHistory.lastFetchedAt)}',
                  '連線 ${data.operationsStatus.backendConnectionLabel}',
                ],
                onDark: colorScheme.brightness == Brightness.light,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withValues(alpha: 0.40)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(_levelIcon(premiumAssessment.level), color: color),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${_premiumDescription(premiumAssessment)} 非買賣建議。',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: headerForeground,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String get _frontendDataMode {
  if (_use00631LLiveProxy) {
    return 'live_proxy';
  }
  if (_use00631LStaticData) {
    return 'static_public';
  }
  return 'mock_default';
}

String get _frontendDataModeLabel {
  if (_use00631LLiveProxy) {
    return '即時後端';
  }
  if (_use00631LStaticData) {
    return '公開靜態';
  }
  return '示範資料';
}

String get _frontendDataModeDisplay {
  if (_use00631LLiveProxy) {
    return 'Live 後端';
  }
  if (_use00631LStaticData) {
    return '公開靜態';
  }
  return 'Mock 預設';
}

String _coreDataStatusLabel(Etf00631LLabData data) {
  final snapshotLabel = data.snapshot.status.label;
  if (!_isMockOrErrorStatus(snapshotLabel)) {
    return snapshotLabel;
  }
  final navLabel = data.intradayNav?.status.label;
  if (navLabel != null && !_isMockOrErrorStatus(navLabel)) {
    return navLabel;
  }
  final historyLabel = data.priceHistory.sourceStatusLabel;
  if (data.priceHistory.points.length >= 2 &&
      !_isMockOrErrorStatus(historyLabel)) {
    return historyLabel;
  }
  return data.status.label;
}

bool _isMockOrErrorStatus(String label) {
  final normalized = label.trim().toLowerCase();
  return normalized == 'mock' ||
      normalized == 'error' ||
      normalized == 'unavailable';
}

String _statusDisplay(String? rawStatus) {
  final value = rawStatus?.trim();
  switch (value) {
    case 'official':
      return '官方';
    case 'cached':
      return '快取';
    case 'mock':
      return '示範';
    case 'error':
      return '錯誤';
    case 'stale':
      return '過期';
    case 'unavailable':
    case null:
    case '':
      return '暫無';
    case 'static_official':
      return '靜態官方';
    case 'static_public_data':
    case 'static_public':
      return '公開靜態';
    case 'backend_required':
      return '需後端';
    case 'deferred':
      return '待載入';
    case 'live_proxy':
      return '即時後端';
    case 'mock_default':
      return '示範預設';
    case 'backend disconnected':
    case '後端未連線':
      return '後端未連線';
    case 'backend connected':
    case '後端可連線':
      return '後端已連線';
  }
  return value;
}

String _sourceStatusBadgeLabel(String? rawStatus) {
  final value = rawStatus?.trim();
  switch (value) {
    case 'official':
      return '官方';
    case 'cached':
      return '快取';
    case 'mock':
    case 'mock_default':
      return '示範';
    case 'error':
      return '錯誤';
    case 'stale':
      return '過期';
    case 'unavailable':
    case null:
    case '':
      return '不可用';
    case 'static_official':
      return '靜態官方';
    case 'static_public_data':
    case 'static_public':
      return '公開靜態';
    case 'backend_required':
      return '需後端';
    case 'deferred':
      return '稍後載入';
    case 'live_proxy':
      return '即時後端';
    case 'local_only':
    case 'local-only':
      return '本機保存';
    case 'PASS':
    case 'pass':
    case 'OK':
    case 'ok':
      return '正常';
    case 'WARN':
    case 'warn':
      return '需留意';
    case 'FAIL':
    case 'fail':
      return '異常';
    case 'rule_based':
      return '規則分析';
  }
  return value;
}

String _aiDisplayText(String text) {
  var value = text;
  const literalReplacements = {
    'official holdings': '官方每日內容物',
    'live intraday NAV': '盤中 NAV',
    'intraday NAV': '盤中 NAV',
    'price history': '價格歷史',
    'static public mode': '公開靜態模式',
    'GitHub Pages 靜態 JSON': '公開靜態資料',
    'public backend proxy': '公開後端',
    'sourceStatus': '來源狀態',
    'readiness': '整體狀態',
    'rule_based': '規則分析',
    'static_official': '靜態官方',
    'static_public_data': '公開靜態資料',
  };
  for (final entry in literalReplacements.entries) {
    value = value.replaceAll(entry.key, entry.value);
  }
  final wordReplacements = {
    'holdings': '內容物',
    'history': '歷史',
    'coverage': '資料區間',
    'rows': '筆',
    'cached': '快取',
    'backend': '後端',
    'source': '來源',
    'unavailable': '不可用',
    'error': '錯誤',
    'official': '官方',
    'mock': '示範',
  };
  for (final entry in wordReplacements.entries) {
    value = value.replaceAll(
      RegExp('\\b${RegExp.escape(entry.key)}\\b', caseSensitive: false),
      entry.value,
    );
  }
  return value;
}

class _HeaderPill extends StatelessWidget {
  const _HeaderPill({
    required this.label,
    required this.foreground,
  });

  final String label;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: foreground.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w800,
              ),
        ),
      ),
    );
  }
}

class _QuoteStatTile extends StatelessWidget {
  const _QuoteStatTile({
    required this.label,
    required this.value,
    required this.caption,
    required this.foreground,
  });

  final String label;
  final String value;
  final String caption;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: foreground.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: foreground.withValues(alpha: 0.72),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: foreground.withValues(alpha: 0.66),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeToggleButton extends StatelessWidget {
  const _ThemeToggleButton({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: appThemeModeNotifier,
      builder: (context, mode, _) {
        final isDark = mode == ThemeMode.dark;
        final nextMode = isDark ? ThemeMode.light : ThemeMode.dark;
        final label = isDark ? '切換日間' : '切換夜間';
        return Tooltip(
          message: isDark ? '切換到日間模式' : '切換到夜間模式',
          child: InkWell(
            key: const ValueKey('00631l-theme-toggle'),
            borderRadius: BorderRadius.circular(999),
            onTap: () => setAppThemeMode(nextMode),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: _marketPanelAltColor(context),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: _marketBorderColor(context)),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 8 : 10,
                  vertical: compact ? 6 : 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isDark ? Icons.light_mode_outlined : Icons.dark_mode,
                      size: 17,
                      color: _marketTextColor(context),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      label,
                      key: ValueKey(
                        isDark
                            ? '00631l-theme-dark-label'
                            : '00631l-theme-light-label',
                      ),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: _marketTextColor(context),
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MarketBottomNav extends StatelessWidget {
  const _MarketBottomNav({
    required this.selected,
    required this.onChanged,
  });

  final _LabSection selected;
  final ValueChanged<_LabSection> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth / _bottomLabSections.length)
            .clamp(48.0, 96.0)
            .toDouble();
        return DecoratedBox(
          key: const ValueKey('00631l-bottom-nav'),
          decoration: BoxDecoration(
            color: _marketNavColor(context),
            border: Border(
              top: BorderSide(color: _marketBorderColor(context)),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 72,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final section in _bottomLabSections)
                    _MarketBottomNavItem(
                      section: section,
                      selected: section == selected,
                      width: itemWidth,
                      onTap: () => onChanged(section),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MarketBottomNavItem extends StatelessWidget {
  const _MarketBottomNavItem({
    required this.section,
    required this.selected,
    required this.width,
    required this.onTap,
  });

  final _LabSection section;
  final bool selected;
  final double width;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? _marketBlue : _marketMutedTextColor(context);
    return InkWell(
      key: ValueKey('00631l-section-${section.name}'),
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: selected ? 34 : 24,
                height: 28,
                decoration: BoxDecoration(
                  color: selected
                      ? _marketBlue.withValues(alpha: 0.16)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(section.icon, color: color, size: 21),
              ),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  section.label,
                  maxLines: 1,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: color,
                        fontWeight:
                            selected ? FontWeight.w900 : FontWeight.w700,
                        letterSpacing: 0,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverviewSection extends StatelessWidget {
  const _OverviewSection({
    required this.data,
    required this.selectedEtf,
  });

  final Etf00631LLabData data;
  final _SelectedEtfViewData selectedEtf;

  @override
  Widget build(BuildContext context) {
    final history = data.holdingsHistory.trendSummary();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CompactQuoteHeader(data: data, selectedEtf: selectedEtf),
        const SizedBox(height: 8),
        if (selectedEtf.is00631L)
          _OverviewDailySummaryStrip(data: data, detailsLoading: false)
        else
          _SelectedEtfOverviewDigest(selectedEtf: selectedEtf),
        const SizedBox(height: 8),
        _AlwaysExpandedPanel(
          title: selectedEtf.is00631L ? '價格與曝險' : '價格走勢',
          subtitle: selectedEtf.is00631L
              ? '近一年收盤與官方每日曝險。'
              : '${selectedEtf.code} 近一年收盤與歷史資料狀態。',
          child: selectedEtf.is00631L
              ? _OverviewSignalPanel(data: data)
              : _SelectedEtfSignalPanel(selectedEtf: selectedEtf),
        ),
        const SizedBox(height: 8),
        if (selectedEtf.is00631L) ...[
          _OverviewHoldingsDigestPanel(data: data),
          const SizedBox(height: 8),
        ],
        _CompactExpansionPanel(
          key: const ValueKey('00631l-overview-more-expansion'),
          title: '進階資料',
          subtitle: selectedEtf.is00631L
              ? '資料來源、完整性、比較與維護細節集中在這裡。'
              : '${selectedEtf.code} 的資料來源、資料範圍與目前限制。',
          child: selectedEtf.is00631L
              ? _OverviewMorePanel(
                  data: data,
                  history: history,
                  selectedEtf: selectedEtf,
                )
              : _SelectedEtfMorePanel(data: data, selectedEtf: selectedEtf),
        ),
      ],
    );
  }
}

// ignore: unused_element
class _OverviewDailySummaryStrip extends StatelessWidget {
  const _OverviewDailySummaryStrip({
    required this.data,
    required this.detailsLoading,
  });

  final Etf00631LLabData data;
  final bool detailsLoading;

  @override
  Widget build(BuildContext context) {
    final nav = data.intradayNav;
    final priceSummary = data.priceHistory.completenessSummary();
    final hasUsableSnapshot = _hasUsableHoldingsSnapshot(data.snapshot);
    final snapshotKnownUnavailable =
        _summaryStatusIsKnownUnavailable(data.snapshot.status.label);
    final hasNavTime = nav?.dataTime != null;
    final navKnownUnavailable =
        _summaryStatusIsKnownUnavailable(nav?.status.label);
    final liveBackendWarmup = shouldShow00631LLiveBackendWarmup(
      detailsLoading: detailsLoading,
      liveProxyEnabled: _use00631LLiveProxy,
    );
    final dayValue = hasUsableSnapshot
        ? _summaryMonthDay(data.snapshot.tradeDate)
        : snapshotKnownUnavailable
            ? liveBackendWarmup
                ? '喚醒中'
                : '不可用'
            : detailsLoading
                ? '同步中'
                : '不可用';
    final dayCaption = hasUsableSnapshot || snapshotKnownUnavailable
        ? liveBackendWarmup && !hasUsableSnapshot
            ? '後端'
            : _sourceStatusBadgeLabel(data.snapshot.status.label)
        : detailsLoading
            ? '每日'
            : _sourceStatusBadgeLabel(data.snapshot.status.label);
    final navTime = hasNavTime
        ? _summaryTimeMinute(nav!.dataTime!)
        : navKnownUnavailable
            ? liveBackendWarmup
                ? '連線中'
                : '不可用'
            : detailsLoading
                ? '連線中'
                : '不可用';
    final navCaption = hasNavTime || navKnownUnavailable
        ? _intradaySummarySourceLabel(nav)
        : detailsLoading
            ? '後端'
            : _intradaySummarySourceLabel(nav);
    final historyIsAvailable = priceSummary.rowCount >= 2;
    final items = [
      _OverviewDailySummaryItem(
        title: '內容物',
        value: dayValue,
        caption: dayCaption,
      ),
      _OverviewDailySummaryItem(
        title: '盤中 NAV',
        value: navTime,
        caption: navCaption,
      ),
      _OverviewDailySummaryItem(
        title: '歷史資料',
        value: detailsLoading && !historyIsAvailable
            ? '檢查中'
            : '${formatInteger(priceSummary.rowCount)}筆',
        caption: detailsLoading && !historyIsAvailable
            ? '靜態'
            : _summaryCoverageCompactYears(priceSummary),
      ),
    ];

    return KeyedSubtree(
      key: const ValueKey('00631l-overview-daily-summary-strip'),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _marketPanelColor(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _marketBorderColor(context)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
          child: Row(
            key: const ValueKey('00631l-overview-daily-summary-grid'),
            children: [
              for (var index = 0; index < items.length; index++) ...[
                Expanded(
                  child: _OverviewDailySummaryChip(item: items[index]),
                ),
                if (index != items.length - 1) const SizedBox(width: 4),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

bool _summaryStatusIsKnownUnavailable(String? label) {
  final normalized = label?.trim().toLowerCase();
  return normalized == 'error' || normalized == 'unavailable';
}

bool shouldShow00631LLiveBackendWarmup({
  required bool detailsLoading,
  required bool liveProxyEnabled,
}) {
  return detailsLoading && liveProxyEnabled;
}

String _summaryCoverageCompactYears(
  EtfPriceHistoryCompletenessSummary summary,
) {
  final start = summary.coverageStart;
  final end = summary.coverageEnd;
  if (start == null || end == null) {
    return '資料不足';
  }
  if (start.year == end.year) {
    return '${start.year}';
  }
  final endYear = (end.year % 100).toString().padLeft(2, '0');
  return '${start.year}-$endYear';
}

String _summaryMonthDay(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$month/$day';
}

String _summaryTimeMinute(DateTime dateTime) {
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _intradaySummarySourceLabel(EtfIntradayNav? nav) {
  final contract = nav?.sourceContract?.trim().toLowerCase();
  if (contract == null || contract.isEmpty) {
    return nav?.status.label ?? '資料狀態';
  }
  if (contract.contains('twse')) {
    return 'TWSE';
  }
  if (contract.contains('yuanta')) {
    return 'Yuanta';
  }
  return nav?.status.label ?? contract;
}

String _txOverviewStatusLabel(FuturesQuote quote) {
  if (quote.txPrice == null) {
    return '需 live backend';
  }
  if (quote.isStale || quote.status == EtfDataStatus.stale) {
    return 'stale';
  }
  return _sourceStatusBadgeLabel(quote.status.label);
}

class _OverviewDailySummaryItem {
  const _OverviewDailySummaryItem({
    required this.title,
    required this.value,
    required this.caption,
  });

  final String title;
  final String value;
  final String caption;
}

class _OverviewDailySummaryChip extends StatelessWidget {
  const _OverviewDailySummaryChip({required this.item});

  final _OverviewDailySummaryItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _marketPanelAltColor(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _marketBorderColor(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: _marketMutedTextColor(context),
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                item.value,
                maxLines: 1,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: _marketTextColor(context),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
            const SizedBox(height: 0),
            Text(
              item.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: _marketMutedTextColor(context),
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewUpdateClockStrip extends StatelessWidget {
  const _OverviewUpdateClockStrip({
    required this.data,
    required this.selectedEtf,
  });

  final Etf00631LLabData data;
  final _SelectedEtfViewData selectedEtf;

  @override
  Widget build(BuildContext context) {
    final priceSummary = selectedEtf.priceHistory.completenessSummary();
    final nav = data.intradayNav;
    final navSession = nav?.marketSession();
    final tx = data.futuresQuote;
    final items = selectedEtf.is00631L
        ? [
            _OverviewClockItem(
              badge: 'DAY',
              title: '內容物',
              value: formatTaiwanDate(data.snapshot.tradeDate),
              caption: '官方每日快照',
              status: _sourceStatusBadgeLabel(data.snapshot.status.label),
            ),
            _OverviewClockItem(
              badge: 'LIVE',
              title: 'NAV',
              value: nav?.dataTime == null
                  ? '暫無'
                  : _sourceTimeText(nav!.dataTime!),
              caption: navSession == null
                  ? '需要後端'
                  : '${navSession.phaseLabel} · ${navSession.dataFreshnessLabel}',
              status: _sourceStatusBadgeLabel(nav?.status.label),
            ),
            _OverviewClockItem(
              badge: 'TX',
              title: '期貨',
              value: tx.dataTime == null ? '暫無' : _sourceTimeText(tx.dataTime!),
              caption: tx.txPrice == null
                  ? 'TAIFEX 資料暫無'
                  : '${tx.txSymbol ?? tx.symbol} ${_price(tx.txPrice)}',
              status: _txOverviewStatusLabel(tx),
            ),
            _OverviewClockItem(
              badge: 'HIS',
              title: '歷史',
              value: _dateOrDash(priceSummary.coverageEnd),
              caption: '${formatInteger(priceSummary.rowCount)} 筆',
              status: _sourceStatusBadgeLabel(
                selectedEtf.priceHistory.sourceStatusLabel,
              ),
            ),
          ]
        : [
            _OverviewClockItem(
              badge: 'ETF',
              title: selectedEtf.code,
              value: selectedEtf.dataTime == null
                  ? _dateOrDash(priceSummary.coverageEnd)
                  : _sourceTimeText(selectedEtf.dataTime!),
              caption: selectedEtf.hasImportedHistory ? '歷史可用' : '僅清單資料',
              status: _sourceStatusBadgeLabel(selectedEtf.sourceStatusLabel),
            ),
            _OverviewClockItem(
              badge: 'HIS',
              title: '歷史',
              value: _dateOrDash(priceSummary.coverageEnd),
              caption: '${formatInteger(priceSummary.rowCount)} 筆',
              status: _sourceStatusBadgeLabel(
                selectedEtf.priceHistory.sourceStatusLabel,
              ),
            ),
            const _OverviewClockItem(
              badge: 'DAY',
              title: '內容物',
              value: '00631L only',
              caption: '不套用到其他 ETF',
              status: 'not mapped',
            ),
          ];

    return KeyedSubtree(
      key: const ValueKey('00631l-overview-update-clock-strip'),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _marketPanelColor(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _marketBorderColor(context)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            children: [
              Text(
                '更新時間',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: _marketTextColor(context),
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      for (var index = 0; index < items.length; index++) ...[
                        _OverviewClockChip(item: items[index]),
                        if (index != items.length - 1) const SizedBox(width: 6),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverviewClockItem {
  const _OverviewClockItem({
    required this.badge,
    required this.title,
    required this.value,
    required this.caption,
    required this.status,
  });

  final String badge;
  final String title;
  final String value;
  final String caption;
  final String status;
}

class _OverviewClockChip extends StatelessWidget {
  const _OverviewClockChip({required this.item});

  final _OverviewClockItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('00631l-overview-clock-chip-${item.badge}'),
      width: 118,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: _marketPanelAltColor(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _marketBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _MiniStatusBadge(label: item.badge),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: _marketMutedTextColor(context),
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            item.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: _marketTextColor(context),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            item.caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: _marketMutedTextColor(context),
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            item.status,
            key: ValueKey('00631l-overview-clock-status-${item.badge}'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: _marketMutedTextColor(context),
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
    );
  }
}

class _OverviewQualityRibbon extends StatelessWidget {
  const _OverviewQualityRibbon({
    required this.data,
    required this.selectedEtf,
  });

  final Etf00631LLabData data;
  final _SelectedEtfViewData selectedEtf;

  @override
  Widget build(BuildContext context) {
    final summary = selectedEtf.priceHistory.completenessSummary();
    final adjustmentLabel = summary.hasNonUnitAdjustment
        ? '已辨識'
        : summary.hasAdjustedClose
            ? '調整價可用'
            : '未套用';
    final priceField = summary.hasAdjustedClose ? 'adjustedClose' : 'close';
    final coverage =
        summary.rowCount >= 2 ? '${formatInteger(summary.rowCount)} 筆' : '資料不足';
    final coverageKind = summary.isCompleteFromListing ? '上市日起' : '部分區間';
    final catalogCount = data.etfCatalog.hasData
        ? data.etfCatalog.rowCount
        : data.operationsStatus.etfCatalogRowCount;
    final readyHistory = data.operationsStatus.etfPriceHistoryReadyCount;
    final etfHistoryLabel = catalogCount > 0
        ? '${formatInteger(readyHistory)} / ${formatInteger(catalogCount)}'
        : formatInteger(readyHistory);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: _marketPanelColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _marketBorderColor(context)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              const _MiniStatusBadge(label: '資料'),
              const SizedBox(width: 8),
              Text(
                '資料正確性',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: _marketTextColor(context),
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(width: 8),
              _InlineQualityPill(label: '目前檔案', value: selectedEtf.code),
              _InlineQualityPill(label: '價格欄位', value: priceField),
              _InlineQualityPill(label: '分割調整', value: adjustmentLabel),
              _InlineQualityPill(label: '覆蓋', value: coverage),
              _InlineQualityPill(label: '覆蓋型態', value: coverageKind),
              _InlineQualityPill(label: 'ETF歷史', value: etfHistoryLabel),
            ],
          ),
        ),
      ),
    );
  }
}

class _InlineQualityPill extends StatelessWidget {
  const _InlineQualityPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _marketPanelAltColor(context),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: _marketBorderColor(context)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: _marketMutedTextColor(context),
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(width: 4),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: _marketTextColor(context),
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedEtfReadinessBanner extends StatelessWidget {
  const _SelectedEtfReadinessBanner({required this.selectedEtf});

  final _SelectedEtfViewData selectedEtf;

  @override
  Widget build(BuildContext context) {
    final ready = selectedEtf.hasImportedHistory;
    final accent = ready
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.tertiary;
    return DecoratedBox(
      key: const ValueKey('00631l-selected-etf-readiness-banner'),
      decoration: BoxDecoration(
        color: _marketPanelColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.55)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _MiniStatusBadge(label: ready ? '可用' : '資料'),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${selectedEtf.code} ${selectedEtf.readinessLabel}',
                    key: const ValueKey('00631l-selected-etf-readiness-title'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: _marketTextColor(context),
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                _CompactTextBadge(
                  label: ready ? '歷史可用' : '僅清單資料',
                ),
              ],
            ),
            const SizedBox(height: 7),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final badge in selectedEtf.capabilityBadges)
                  KeyedSubtree(
                    key: ValueKey(
                      '00631l-selected-etf-capability-${badge.keySuffix}',
                    ),
                    child: _StatusPill(label: badge.label),
                  ),
              ],
            ),
            const SizedBox(height: 7),
            Text(
              selectedEtf.readinessDetail,
              key: const ValueKey('00631l-selected-etf-readiness-detail'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _marketMutedTextColor(context),
                    height: 1.35,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              selectedEtf.readinessAction,
              key: const ValueKey('00631l-selected-etf-readiness-action'),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedEtfDataContextCard extends StatelessWidget {
  const _SelectedEtfDataContextCard({required this.selectedEtf});

  final _SelectedEtfViewData selectedEtf;

  @override
  Widget build(BuildContext context) {
    final history = selectedEtf.historySummary;
    final latestDate = _dateOrDash(history.latest?.date);
    final historyReady = selectedEtf.hasImportedHistory;
    final liveNavCaption =
        selectedEtf.is00631L ? '公開後端可更新盤中 NAV' : '此檔尚未建立盤中 NAV 對應';
    final backtestCaption = historyReady ? '可用現有歷史資料做歷史與回測檢視' : '歷史不足，先不解讀回測';
    return KeyedSubtree(
      key: const ValueKey('00631l-selected-etf-data-context-card'),
      child: _SectionBlock(
        title: '資料脈絡',
        subtitle: '${selectedEtf.code} 的資料覆蓋、欄位與即時範圍；這裡只描述資料狀態，非買賣建議。',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatusWrap(
              labels: [
                'ETF ${selectedEtf.code}',
                '歷史 ${_sourceStatusBadgeLabel(selectedEtf.priceHistory.sourceStatusLabel)}',
                '筆數 ${formatInteger(history.rowCount)}',
                selectedEtf.backtestReadinessLabel,
                selectedEtf.liveNavScopeLabel,
                '非買賣建議',
              ],
            ),
            const SizedBox(height: 12),
            _ResponsiveMetricGrid(
              cards: [
                _MetricCard(
                  label: '歷史筆數',
                  value: formatInteger(history.rowCount),
                  caption: selectedEtf.historyCoverageText,
                  icon: Icons.timeline_outlined,
                ),
                _MetricCard(
                  label: '最新收盤',
                  value: _price(history.latest?.performanceClose),
                  caption: latestDate,
                  icon: Icons.show_chart_outlined,
                ),
                _MetricCard(
                  label: '價格欄位',
                  value: selectedEtf.priceFieldLabel,
                  caption: selectedEtf.adjustmentContextLabel,
                  icon: Icons.tune_outlined,
                ),
                _MetricCard(
                  label: 'live NAV',
                  value: selectedEtf.is00631L ? '可用' : '未接',
                  caption: liveNavCaption,
                  icon: Icons.sensors_outlined,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _BulletLine(
              text: historyReady
                  ? '${selectedEtf.code} 已有 ${formatInteger(history.rowCount)} 筆歷史價格，資料範圍 ${selectedEtf.historyCoverageText}。'
                  : '${selectedEtf.code} 目前沒有足夠歷史價格，畫面會保留清單、靜態或錯誤狀態。',
              icon: Icons.fact_check_outlined,
            ),
            const _BulletLine(
              text: '即時 NAV / 折溢價目前以 00631L 為主；其他 ETF 先以歷史價格與清單狀態觀察。',
              icon: Icons.sensors_outlined,
            ),
            _BulletLine(
              text:
                  '價格分析使用 ${selectedEtf.priceFieldLabel}；若資料含分割或調整，請以調整價與調整係數為準。',
              icon: Icons.rule_outlined,
            ),
            _BulletLine(
              text: backtestCaption,
              icon: Icons.query_stats_outlined,
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedEtfHistoryReadinessStrip extends StatelessWidget {
  const _SelectedEtfHistoryReadinessStrip({required this.selectedEtf});

  final _SelectedEtfViewData selectedEtf;

  @override
  Widget build(BuildContext context) {
    final history = selectedEtf.historySummary;
    final theme = Theme.of(context);
    return DecoratedBox(
      key: const ValueKey('00631l-selected-etf-history-readiness-strip'),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _CompactTextBadge(label: selectedEtf.code),
              const SizedBox(width: 8),
              Text(
                'history ${selectedEtf.priceHistory.sourceStatusLabel}',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 10),
              Text('${formatInteger(history.rowCount)} 筆'),
              const SizedBox(width: 10),
              Text(selectedEtf.historyCoverageText),
              const SizedBox(width: 10),
              Text(selectedEtf.backtestReadinessLabel),
              const SizedBox(width: 10),
              Text(selectedEtf.liveNavScopeLabel),
              const SizedBox(width: 10),
              for (final badge in selectedEtf.capabilityBadges) ...[
                KeyedSubtree(
                  key: ValueKey(
                    '00631l-selected-etf-history-strip-capability-${badge.keySuffix}',
                  ),
                  child: _StatusPill(label: badge.label),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedEtfSignalPanel extends StatelessWidget {
  const _SelectedEtfSignalPanel({required this.selectedEtf});

  final _SelectedEtfViewData selectedEtf;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _marketPanelColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _marketBorderColor(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: _OverviewSparklineBlock(points: selectedEtf.priceHistory.points),
      ),
    );
  }
}

class _SelectedEtfMorePanel extends StatelessWidget {
  const _SelectedEtfMorePanel({
    required this.data,
    required this.selectedEtf,
  });

  final Etf00631LLabData data;
  final _SelectedEtfViewData selectedEtf;

  @override
  Widget build(BuildContext context) {
    final summary = selectedEtf.priceHistory.completenessSummary();
    final theme = Theme.of(context);
    return Column(
      children: [
        _QuoteReadinessStrip(data: data, selectedEtf: selectedEtf),
        const SizedBox(height: 6),
        Text(
          '資料範圍 ${selectedEtf.historyCoverageText} · 價格欄位 ${selectedEtf.priceFieldLabel} · 分割調整 ${_priceAdjustmentConfidenceLabel(selectedEtf.code, selectedEtf.historySummary)}',
          key: const ValueKey('00631l-selected-etf-coverage-line'),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(
            color: _marketMutedTextColor(context),
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 8),
        _StatusList(
          items: [
            _StatusItem(
              label: '目前 ETF',
              status: selectedEtf.code,
              detail: selectedEtf.name,
              action: '左上角代號搜尋可切換其他 ETF 或內建股票研究資料。',
            ),
            _StatusItem(
              label: '價格歷史',
              status: selectedEtf.priceHistory.sourceStatusLabel,
              detail:
                  '筆數 ${formatInteger(summary.rowCount)}，範圍 ${_dateOrDash(summary.coverageStart)} - ${_dateOrDash(summary.coverageEnd)}。',
              action: summary.rowCount >= 2
                  ? '可切到歷史回測頁調整日期與查看回測。'
                  : '請先匯入該 ETF 歷史價格。',
            ),
            const _StatusItem(
              label: '官方內容物',
              status: '僅 00631L',
              detail: '目前官方 內容物 parser 仍只接 00631L，不會套用到其他 ETF。',
              action: '其他 ETF 先使用清單資料與價格歷史；內容物資料後續再逐檔接入。',
            ),
          ],
        ),
      ],
    );
  }
}

class _OverviewMorePanel extends StatelessWidget {
  const _OverviewMorePanel({
    required this.data,
    required this.history,
    required this.selectedEtf,
  });

  final Etf00631LLabData data;
  final EtfHoldingsHistoryTrendSummary history;
  final _SelectedEtfViewData selectedEtf;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _QuoteReadinessStrip(data: data, selectedEtf: selectedEtf),
        const SizedBox(height: 8),
        _OverviewUpdateClockStrip(data: data, selectedEtf: selectedEtf),
        const SizedBox(height: 8),
        _OverviewQualityRibbon(data: data, selectedEtf: selectedEtf),
        const SizedBox(height: 8),
        _OverviewActionRow(data: data),
        const SizedBox(height: 8),
        _CompactExpansionPanel(
          title: '資料正確性細節',
          subtitle: '價格欄位、分割調整、資料範圍與來源狀態。首屏只保留精簡版。',
          child: _OverviewDataQualityPanel(selectedEtf: selectedEtf),
        ),
        const SizedBox(height: 8),
        _CompactExpansionPanel(
          title: '完整數字比較',
          subtitle: 'NAV、規模、發行單位數與歷史績效；需要核對時再展開。',
          child: _OverviewComparisonPanel(data: data),
        ),
        const SizedBox(height: 8),
        _CompactExpansionPanel(
          title: '資料來源',
          subtitle: '目前模式、官方每日資料、盤中 NAV 與歷史資料來源。',
          child: _OverviewModeCards(data: data),
        ),
        const SizedBox(height: 8),
        _CompactExpansionPanel(
          title: '7 / 30 日內容物變化',
          subtitle: _historyChangeSubtitle(history),
          child: history.latest == null
              ? const _EmptyPanel(
                  title: '尚無內容物紀錄',
                  message: '請先執行每日流程累積官方每日快照。',
                )
              : _HistoryChangeCards(summary: history),
        ),
        const SizedBox(height: 8),
        _CompactExpansionPanel(
          title: '更多資料狀態',
          subtitle: '平常可略過；需要排除資料問題時再展開。',
          child: _OverviewHiddenDetails(data: data),
        ),
      ],
    );
  }
}

class _OverviewDataQualityPanel extends StatelessWidget {
  const _OverviewDataQualityPanel({required this.selectedEtf});

  final _SelectedEtfViewData selectedEtf;

  @override
  Widget build(BuildContext context) {
    final history = selectedEtf.priceHistory;
    final summary = history.completenessSummary();
    final adjustmentLabel = summary.hasNonUnitAdjustment
        ? '已辨識'
        : summary.hasAdjustedClose
            ? '調整價可用'
            : '未套用';
    final adjustmentCaption =
        selectedEtf.is00631L ? '00631L 2026 分割；績效使用調整價' : '依本檔歷史資料欄位判斷';
    final coverageCaption =
        '${_dateOrDash(summary.coverageStart)} - ${_dateOrDash(summary.coverageEnd)}';
    final metrics = [
      _AtAGlanceMetricData(
        label: '價格欄位',
        value: summary.hasAdjustedClose ? 'adjustedClose' : 'close',
        caption: '圖表 / 回測 / 績效',
      ),
      _AtAGlanceMetricData(
        label: '分割調整',
        value: adjustmentLabel,
        caption: adjustmentCaption,
      ),
      _AtAGlanceMetricData(
        label: '覆蓋區間',
        value: summary.rowCount >= 2
            ? '${formatInteger(summary.rowCount)} 筆'
            : '資料不足',
        caption: coverageCaption,
      ),
      _AtAGlanceMetricData(
        label: '資料來源',
        value: history.sourceStatusLabel,
        caption: summary.isCompleteFromListing ? '上市日起完整' : '依 cache 範圍',
      ),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: _marketPanelColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _marketBorderColor(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const _MiniStatusBadge(label: '資料'),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '資料正確性',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: _marketTextColor(context),
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                _CompactTextBadge(label: selectedEtf.code),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '目前檔案 ${selectedEtf.code}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _marketMutedTextColor(context),
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 6),
            _AtAGlanceMetricGrid(metrics: metrics),
          ],
        ),
      ),
    );
  }
}

class _OverviewHoldingsDigestPanel extends StatelessWidget {
  const _OverviewHoldingsDigestPanel({required this.data});

  final Etf00631LLabData data;

  @override
  Widget build(BuildContext context) {
    final snapshot = data.snapshot;
    final txLine = _primaryFuturesLine(snapshot);
    final tsmcLine = _stockHoldingByCode(snapshot, '2330');
    final hasUsableHoldings = _hasUsableHoldingsSnapshot(snapshot);
    final titleText = hasUsableHoldings ? '官方內容物重點' : '官方內容物暫不可用';
    final subtitleText =
        hasUsableHoldings ? '每日快照 · 盤中看 NAV' : '資料來源尚未回傳可用快照；已隱藏 0 值內容物。';
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _marketPanelColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _marketBorderColor(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(9, 8, 9, 9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    titleText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: _marketTextColor(context),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _CompactTextBadge(
                  label: hasUsableHoldings
                      ? formatTaiwanDate(snapshot.tradeDate)
                      : snapshot.status.label,
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              subtitleText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: _marketMutedTextColor(context),
                fontWeight: FontWeight.w700,
                height: 1.18,
              ),
            ),
            const SizedBox(height: 7),
            hasUsableHoldings
                ? _HoldingDigestStrip(
                    items: [
                      _HoldingDigestItem(
                        title: '期貨',
                        value: txLine == null
                            ? 'unavailable'
                            : formatNullablePercent(txLine.weightPct),
                        caption: txLine == null
                            ? '官方快照未列 TX'
                            : '${txLine.code} / ${txLine.contractMonth}',
                      ),
                      _HoldingDigestItem(
                        title: '台積電',
                        value: tsmcLine == null
                            ? 'unavailable'
                            : formatNullablePercent(tsmcLine.weightPct),
                        caption: tsmcLine == null
                            ? '官方快照未列 2330'
                            : '${formatInteger(tsmcLine.quantity)} 股',
                      ),
                      _HoldingDigestItem(
                        title: '曝險結構',
                        value: '三項比例',
                        caption: '股票 / 期貨 / 現金',
                        metrics: [
                          _HoldingDigestMetric(
                            label: '股',
                            value: formatNullablePercent(
                              snapshot.stockExposureWeightPct,
                            ),
                          ),
                          _HoldingDigestMetric(
                            label: '期',
                            value: formatNullablePercent(
                              snapshot.futuresExposureWeightPct,
                            ),
                          ),
                          _HoldingDigestMetric(
                            label: '現',
                            value: formatNullablePercent(
                              snapshot.cashAndMarginWeightPct,
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                : _HoldingDigestUnavailable(snapshot: snapshot),
          ],
        ),
      ),
    );
  }
}

class _HoldingDigestUnavailable extends StatelessWidget {
  const _HoldingDigestUnavailable({required this.snapshot});

  final EtfDailyHoldingSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      key: const ValueKey('00631l-overview-holdings-digest-unavailable'),
      decoration: BoxDecoration(
        color: _marketPanelAltColor(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _marketBorderColor(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            const _MiniStatusBadge(label: 'DAY'),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '資料來源尚未回傳可用快照；未顯示 0 值內容物。',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _marketMutedTextColor(context),
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
            ),
            _CompactTextBadge(label: snapshot.status.label),
          ],
        ),
      ),
    );
  }
}

class _HoldingDigestItem {
  const _HoldingDigestItem({
    required this.title,
    required this.value,
    required this.caption,
    this.metrics = const [],
  });

  final String title;
  final String value;
  final String caption;
  final List<_HoldingDigestMetric> metrics;
}

class _HoldingDigestMetric {
  const _HoldingDigestMetric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;
}

class _HoldingDigestStrip extends StatelessWidget {
  const _HoldingDigestStrip({required this.items});

  final List<_HoldingDigestItem> items;

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const ValueKey('00631l-overview-holdings-digest-strip'),
      children: [
        for (var index = 0; index < items.length; index++) ...[
          Expanded(child: _HoldingDigestTile(item: items[index])),
          if (index != items.length - 1) const SizedBox(width: 6),
        ],
      ],
    );
  }
}

bool _hasUsableHoldingsSnapshot(EtfDailyHoldingSnapshot snapshot) {
  if (snapshot.status == EtfDataStatus.error ||
      snapshot.fundNetAssetValue <= 0 ||
      snapshot.outstandingUnits <= 0) {
    return false;
  }
  return snapshot.stockHoldings.isNotEmpty ||
      snapshot.futuresHoldings.isNotEmpty ||
      snapshot.cashHoldings.isNotEmpty;
}

class _HoldingDigestTile extends StatelessWidget {
  const _HoldingDigestTile({required this.item});

  final _HoldingDigestItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _marketPanelAltColor(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _marketBorderColor(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(9, 8, 9, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: _marketTextColor(context),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            if (item.metrics.isEmpty) ...[
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  item.value,
                  maxLines: 1,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: _marketTextColor(context),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                item.caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: _marketMutedTextColor(context),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ] else ...[
              for (final metric in item.metrics)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    children: [
                      Text(
                        metric.label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: _marketMutedTextColor(context),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            metric.value,
                            maxLines: 1,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: _marketTextColor(context),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

// ignore: unused_element
class _OverviewDataReadinessStrip extends StatelessWidget {
  const _OverviewDataReadinessStrip({required this.data});

  final Etf00631LLabData data;

  @override
  Widget build(BuildContext context) {
    final price = data.priceHistory.completenessSummary();
    final nav = data.intradayNav;
    final holdingsReady = data.snapshot.status != EtfDataStatus.error;
    final historyReady = price.rowCount >= 2;
    final backtestReady = data.operationsStatus.backtestAvailable ||
        data.priceHistory.points.length >= 2;
    final intradayReady = nav != null &&
        nav.status != EtfDataStatus.error &&
        nav.status != EtfDataStatus.mock &&
        nav.dataTime != null;
    final items = [
      _ReadinessItem(
        label: '歷史',
        value: historyReady ? '${formatInteger(price.rowCount)} 筆' : '尚無',
        ready: historyReady,
      ),
      _ReadinessItem(
        label: '回測',
        value: backtestReady ? '可用' : '缺歷史',
        ready: backtestReady,
      ),
      _ReadinessItem(
        label: '內容物',
        value:
            holdingsReady ? formatTaiwanDate(data.snapshot.tradeDate) : '缺資料',
        ready: holdingsReady,
      ),
      _ReadinessItem(
        label: '盤中',
        value: intradayReady ? formatTimeSeconds(nav.dataTime!) : '暫無',
        ready: intradayReady,
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          Text(
            '資料完整度',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: _marketMutedTextColor(context),
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(width: 8),
          for (var index = 0; index < items.length; index++) ...[
            if (index > 0) const SizedBox(width: 6),
            _ReadinessPill(item: items[index]),
          ],
        ],
      ),
    );
  }
}

class _ReadinessItem {
  const _ReadinessItem({
    required this.label,
    required this.value,
    required this.ready,
  });

  final String label;
  final String value;
  final bool ready;
}

class _ReadinessPill extends StatelessWidget {
  const _ReadinessPill({required this.item});

  final _ReadinessItem item;

  @override
  Widget build(BuildContext context) {
    final color = item.ready ? _marketGreen : _marketRed;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.38)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              item.label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: _marketMutedTextColor(context),
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(width: 5),
            Text(
              item.value,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: _marketTextColor(context),
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewSignalPanel extends StatelessWidget {
  const _OverviewSignalPanel({required this.data});

  final Etf00631LLabData data;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _marketPanelColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _marketBorderColor(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 680;
            final hasUsableExposure = _hasUsableHoldingsSnapshot(data.snapshot);
            final priceBlock = _OverviewSparklineBlock(
              points: data.priceHistory.points,
            );
            final exposureBlock = _OverviewExposureBlock(
              snapshot: data.snapshot,
            );
            if (wide) {
              if (!hasUsableExposure) {
                return priceBlock;
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: priceBlock),
                  const SizedBox(width: 10),
                  Expanded(child: exposureBlock),
                ],
              );
            }
            return priceBlock;
          },
        ),
      ),
    );
  }
}

class _OverviewSparklineBlock extends StatelessWidget {
  const _OverviewSparklineBlock({required this.points});

  final List<EtfPriceHistoryPoint> points;

  @override
  Widget build(BuildContext context) {
    final ordered = [...points]..sort((a, b) => a.date.compareTo(b.date));
    final recent = _overviewSparklineWindow(ordered);
    final latest = recent.isEmpty ? null : recent.last;
    final first = recent.isEmpty ? null : recent.first;
    final changePct =
        latest == null || first == null || first.performanceClose <= 0
            ? null
            : (latest.performanceClose / first.performanceClose - 1) * 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '近一年走勢',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: _marketTextColor(context),
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
            Text(
              formatSignedNullablePercent(changePct),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: (changePct ?? 0) >= 0 ? _marketRed : _marketGreen,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Text(
              _price(latest?.close),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: _marketTextColor(context),
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                latest == null ? '歷史資料暫無' : formatTaiwanDate(latest.date),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: _marketMutedTextColor(context),
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        _SparklineChart(points: recent),
      ],
    );
  }
}

List<EtfPriceHistoryPoint> _overviewSparklineWindow(
  List<EtfPriceHistoryPoint> ordered,
) {
  if (ordered.length <= 2) {
    return ordered;
  }
  final latestDate = ordered.last.date;
  final startDate = DateTime(
    latestDate.year - 1,
    latestDate.month,
    latestDate.day,
  );
  final recent =
      ordered.where((point) => !point.date.isBefore(startDate)).toList();
  if (recent.length >= 2) {
    return recent;
  }
  return ordered.sublist(ordered.length - 2);
}

class _SparklineChart extends StatefulWidget {
  const _SparklineChart({required this.points});

  final List<EtfPriceHistoryPoint> points;

  @override
  State<_SparklineChart> createState() => _SparklineChartState();
}

class _SparklineChartState extends State<_SparklineChart> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[];
    final spotPoints = <EtfPriceHistoryPoint>[];
    for (var index = 0; index < widget.points.length; index += 1) {
      final close = widget.points[index].performanceClose;
      if (close.isFinite) {
        spots.add(FlSpot(spots.length.toDouble(), close));
        spotPoints.add(widget.points[index]);
      }
    }
    if (spots.length < 2) {
      return SizedBox(
        height: 72,
        child: Center(
          child: Text(
            '尚無圖表資料',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _marketMutedTextColor(context),
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      );
    }

    final chartMinY =
        spots.map((spot) => spot.y).reduce((a, b) => a < b ? a : b);
    final chartMaxY =
        spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
    final padding = ((chartMaxY - chartMinY).abs() * 0.08).clamp(0.2, 20.0);
    final fallbackIndex = spots.length - 1;
    final safeTouchedIndex = _touchedIndex == null
        ? fallbackIndex
        : _touchedIndex!.clamp(0, spots.length - 1);
    final hasManualSelection = _touchedIndex != null;
    final touchedPoint = spotPoints[safeTouchedIndex];
    final touchedValue = spots[safeTouchedIndex].y;
    final lastX = (spots.length - 1).toDouble();
    final edgePaddingX = (lastX * 0.08).clamp(2.0, 24.0).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          key: const ValueKey('00631l-overview-sparkline-chart'),
          height: 104,
          child: LineChart(
            LineChartData(
              minX: -edgePaddingX,
              maxX: lastX + edgePaddingX,
              minY: chartMinY - padding,
              maxY: chartMaxY + padding,
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: _marketBorderColor(context),
                  strokeWidth: 0.8,
                ),
              ),
              titlesData: const FlTitlesData(
                topTitles: AxisTitles(),
                rightTitles: AxisTitles(),
                leftTitles: AxisTitles(),
                bottomTitles: AxisTitles(),
              ),
              lineTouchData: LineTouchData(
                enabled: true,
                touchCallback: (event, response) {
                  final touched = response?.lineBarSpots?.isNotEmpty == true
                      ? response!.lineBarSpots!.first.spotIndex
                      : null;
                  if (touched != null && touched != _touchedIndex) {
                    setState(() => _touchedIndex = touched);
                  }
                },
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touchedSpots) => [
                    for (final spot in touchedSpots)
                      LineTooltipItem(
                        '${formatTaiwanDate(spotPoints[spot.spotIndex].date)}\n${_price(spot.y)}',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  barWidth: 2.2,
                  isCurved: true,
                  color: _marketBlue,
                  dotData: FlDotData(
                    show: hasManualSelection,
                    checkToShowDot: (spot, _) => spot.x == safeTouchedIndex,
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: _marketBlue.withValues(alpha: 0.10),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 5),
        _OverviewSparklineDateStrip(
          start: spotPoints.first.date,
          middle: spotPoints[(spotPoints.length - 1) ~/ 2].date,
          end: spotPoints.last.date,
        ),
        const SizedBox(height: 5),
        KeyedSubtree(
          key: const ValueKey('00631l-overview-sparkline-touch-detail'),
          child: _ChartTouchDetail(
            point: touchedPoint,
            value: touchedValue,
            rangeStart: spotPoints.first.date,
            rangeEnd: spotPoints.last.date,
            isManualSelection: hasManualSelection,
          ),
        ),
      ],
    );
  }
}

class _OverviewSparklineDateStrip extends StatelessWidget {
  const _OverviewSparklineDateStrip({
    required this.start,
    required this.middle,
    required this.end,
  });

  final DateTime start;
  final DateTime middle;
  final DateTime end;

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const ValueKey('00631l-overview-sparkline-date-strip'),
      children: [
        Expanded(
          child: _dateCell(
            context,
            key: const ValueKey('00631l-overview-sparkline-date-start'),
            label: '起點',
            date: start,
            align: CrossAxisAlignment.start,
            textAlign: TextAlign.left,
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: _dateCell(
            context,
            key: const ValueKey('00631l-overview-sparkline-date-mid'),
            label: '中段',
            date: middle,
            align: CrossAxisAlignment.center,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: _dateCell(
            context,
            key: const ValueKey('00631l-overview-sparkline-date-end'),
            label: '終點',
            date: end,
            align: CrossAxisAlignment.end,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _dateCell(
    BuildContext context, {
    required Key key,
    required String label,
    required DateTime date,
    required CrossAxisAlignment align,
    required TextAlign textAlign,
  }) {
    final theme = Theme.of(context);
    return DecoratedBox(
      key: key,
      decoration: BoxDecoration(
        color: _marketPanelAltColor(context),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: _marketBorderColor(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          crossAxisAlignment: align,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: textAlign,
              style: theme.textTheme.labelSmall?.copyWith(
                color: _marketMutedTextColor(context),
                fontWeight: FontWeight.w800,
                fontSize: 9,
                height: 1,
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: textAlign == TextAlign.left
                  ? Alignment.centerLeft
                  : textAlign == TextAlign.center
                      ? Alignment.center
                      : Alignment.centerRight,
              child: Text(
                formatTaiwanDate(date),
                maxLines: 1,
                textAlign: textAlign,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: _marketTextColor(context),
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                  height: 1.08,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewExposureBlock extends StatelessWidget {
  const _OverviewExposureBlock({required this.snapshot});

  final EtfDailyHoldingSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        final stockPct = snapshot.assetWeightPct(EtfAssetClass.stock);
        final futuresPct = snapshot.assetWeightPct(EtfAssetClass.futures);
        final cashPct = snapshot.cashAndMarginWeightPct;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const _MiniStatusBadge(label: 'DAY'),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '官方曝險',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: _marketTextColor(context),
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                Text(
                  formatTaiwanDate(snapshot.tradeDate),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: _marketMutedTextColor(context),
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (compact)
              Row(
                key: const ValueKey('00631l-overview-exposure-compact-row'),
                children: [
                  Expanded(
                    child: _OverviewExposureCompactTile(
                      label: '股票',
                      valuePct: stockPct,
                      color: _marketGreen,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _OverviewExposureCompactTile(
                      label: '期貨',
                      valuePct: futuresPct,
                      color: _marketRed,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _OverviewExposureCompactTile(
                      label: '現金',
                      valuePct: cashPct,
                      color: _marketBlue,
                    ),
                  ),
                ],
              )
            else ...[
              _OverviewExposureLine(
                label: '股票',
                valuePct: stockPct,
                color: _marketGreen,
              ),
              _OverviewExposureLine(
                label: '期貨',
                valuePct: futuresPct,
                color: _marketRed,
              ),
              _OverviewExposureLine(
                label: '現金 / 保證金',
                valuePct: cashPct,
                color: _marketBlue,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _OverviewExposureCompactTile extends StatelessWidget {
  const _OverviewExposureCompactTile({
    required this.label,
    required this.valuePct,
    required this.color,
  });

  final String label;
  final double valuePct;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _marketPanelAltColor(context),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: _marketBorderColor(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: _marketMutedTextColor(context),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                formatNullablePercent(valuePct),
                maxLines: 1,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: _marketTextColor(context),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                  height: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewExposureLine extends StatelessWidget {
  const _OverviewExposureLine({
    required this.label,
    required this.valuePct,
    required this.color,
  });

  final String label;
  final double valuePct;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: _marketMutedTextColor(context),
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: (valuePct.abs() / 220).clamp(0, 1).toDouble(),
                minHeight: 7,
                backgroundColor: _marketPanelAltColor(context),
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 66,
            child: Text(
              formatNullablePercent(valuePct),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: _marketTextColor(context),
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AtAGlanceMetric extends StatelessWidget {
  const _AtAGlanceMetric({
    required this.width,
    required this.label,
    required this.value,
    required this.caption,
  });

  final double width;
  final String label;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _marketPanelAltColor(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _marketBorderColor(context)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: _marketMutedTextColor(context),
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _marketTextColor(context),
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 1),
              Text(
                caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: _marketMutedTextColor(context),
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AtAGlanceMetricData {
  const _AtAGlanceMetricData({
    required this.label,
    required this.value,
    required this.caption,
  });

  final String label;
  final String value;
  final String caption;
}

class _AtAGlanceMetricGrid extends StatelessWidget {
  const _AtAGlanceMetricGrid({required this.metrics});

  final List<_AtAGlanceMetricData> metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth =
            constraints.hasBoundedWidth ? constraints.maxWidth : 360.0;
        final columns = maxWidth >= 760
            ? 5
            : maxWidth >= 520
                ? 3
                : 2;
        const gap = 6.0;
        final width = (maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final metric in metrics)
              _AtAGlanceMetric(
                width: width,
                label: metric.label,
                value: metric.value,
                caption: metric.caption,
              ),
          ],
        );
      },
    );
  }
}

class _OverviewComparisonPanel extends StatelessWidget {
  const _OverviewComparisonPanel({required this.data});

  final Etf00631LLabData data;

  @override
  Widget build(BuildContext context) {
    final nav = data.intradayNav;
    final snapshot = data.snapshot;
    final performance = data.priceHistory.performance;
    final price = data.priceHistory.completenessSummary();
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 680;
        final groupWidth =
            compact ? constraints.maxWidth : (constraints.maxWidth - 8) / 2;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            SizedBox(
              width: groupWidth,
              child: _ComparisonGroup(
                title: '行情 / NAV',
                rows: [
                  _ComparisonRowData(
                    label: '市價',
                    value: _price(nav?.marketPrice),
                    caption: nav == null ? '盤中資料不可用' : nav.status.label,
                  ),
                  _ComparisonRowData(
                    label: '預估淨值',
                    value: _price(nav?.estimatedNav),
                    caption: '需公開後端',
                  ),
                  _ComparisonRowData(
                    label: '官方 NAV',
                    value: _price(snapshot.navPerUnit),
                    caption: formatTaiwanDate(snapshot.tradeDate),
                  ),
                  _ComparisonRowData(
                    label: '折溢價',
                    value: formatSignedNullablePercent(
                      nav?.resolvedPremiumDiscountPct,
                    ),
                    caption: '價格偏離提示',
                  ),
                ],
              ),
            ),
            SizedBox(
              width: groupWidth,
              child: _ComparisonGroup(
                title: '規模 / 歷史',
                rows: [
                  _ComparisonRowData(
                    label: '基金淨資產',
                    value: formatNtdAmount(snapshot.fundNetAssetValue),
                    caption: '官方每日資料',
                  ),
                  _ComparisonRowData(
                    label: '發行單位數',
                    value: formatInteger(snapshot.outstandingUnits),
                    caption: '官方每日資料',
                  ),
                  _ComparisonRowData(
                    label: '價格總報酬',
                    value: formatSignedNullablePercent(
                      performance.totalReturnPct,
                    ),
                    caption: price.rowCount < 2
                        ? '尚無 價格歷史'
                        : '${formatInteger(price.rowCount)} 筆',
                  ),
                  _ComparisonRowData(
                    label: '歷史區間',
                    value:
                        '${_dateOrDash(price.coverageStart)} - ${_dateOrDash(price.coverageEnd)}',
                    caption:
                        price.isCompleteFromListing ? '已補齊到上市日起' : '目前為部分區間',
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _OverviewHiddenDetails extends StatelessWidget {
  const _OverviewHiddenDetails({required this.data});

  final Etf00631LLabData data;

  @override
  Widget build(BuildContext context) {
    final priceCompleteness = data.priceHistory.completenessSummary();
    return Column(
      children: [
        _CompactExpansionPanel(
          title: '資料覆蓋細節',
          subtitle: '價格歷史、內容物紀錄、盤中 NAV 與 TX 狀態。',
          child: _DataCoveragePanel(data: data),
        ),
        const SizedBox(height: 8),
        _CompactExpansionPanel(
          title: '歷史資料完整度',
          subtitle: '筆數、範圍、52 週區間與欄位覆蓋。',
          child: _PriceCompletenessPanel(
            priceHistory: data.priceHistory,
            summary: priceCompleteness,
          ),
        ),
      ],
    );
  }
}

class _OverviewModeCards extends StatelessWidget {
  const _OverviewModeCards({required this.data});

  final Etf00631LLabData data;

  @override
  Widget build(BuildContext context) {
    final price = data.priceHistory.completenessSummary();
    final nav = data.intradayNav;
    final tx = data.futuresQuote;
    final txSymbol = tx.txSymbol ?? tx.symbol;
    final txContract = tx.contractMonth == 'front_month'
        ? txSymbol
        : '${tx.contractMonth} · $txSymbol';
    return _InfoCardGrid(
      children: [
        _HoldingInfoCard(
          badge: 'DAY',
          title: '官方內容物',
          primary: formatTaiwanDate(data.snapshot.tradeDate),
          secondary: data.snapshot.status.label,
          caption: '每日官方快照，不是盤中即時內容物',
          progressValue: null,
        ),
        _HoldingInfoCard(
          badge: 'LIVE',
          title: '盤中 NAV',
          primary: _price(nav?.marketPrice),
          secondary:
              '折溢價 ${formatSignedNullablePercent(nav?.resolvedPremiumDiscountPct)}',
          caption: '公開後端可連線時更新；靜態模式不提供盤中資料',
          progressValue: nav?.resolvedPremiumDiscountPct == null
              ? null
              : (nav!.resolvedPremiumDiscountPct!.abs() / 1.5)
                  .clamp(0, 1)
                  .toDouble(),
        ),
        _HoldingInfoCard(
          badge: 'HIS',
          title: '歷史價格',
          primary: '${formatInteger(price.rowCount)} 筆',
          secondary:
              '${_dateOrDash(price.coverageStart)} - ${_dateOrDash(price.coverageEnd)}',
          caption: price.isCompleteFromListing ? '已補齊到上市日起' : '目前為部分區間',
          progressValue: price.rowCount < 2
              ? null
              : (price.rowCount / 3000).clamp(0, 1).toDouble(),
        ),
        _HoldingInfoCard(
          badge: 'TX',
          title: 'TX live',
          primary: _price(tx.txPrice),
          secondary:
              '$txContract · 基差 ${formatSignedNullablePercent(tx.futuresBasisPct)}',
          caption: tx.status == EtfDataStatus.mock
              ? 'mock fallback；不是 TAIFEX live'
              : '${tx.status.label} · ${tx.sourceContract ?? 'taifex'}',
          progressValue: tx.txPrice == null
              ? null
              : ((tx.futuresBasisPct?.abs() ?? 0) / 2).clamp(0, 1).toDouble(),
        ),
        _HoldingInfoCard(
          badge: 'AI',
          title: 'AI 摘要',
          primary: data.aiAnalysis.readinessLabel,
          secondary: data.aiAnalysis.source,
          caption: data.aiAnalysis.disclaimer,
          progressValue: null,
        ),
      ],
    );
  }
}

class _MiniStatusBadge extends StatelessWidget {
  const _MiniStatusBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final lower = label.toLowerCase();
    final color = lower.contains('official') ||
            lower.contains('ready') ||
            lower.contains('pass') ||
            lower.contains('可日常')
        ? _marketGreen
        : lower.contains('warn') ||
                lower.contains('觀察') ||
                lower.contains('cached')
            ? const Color(0xFFFBBF24)
            : lower.contains('error') ||
                    lower.contains('missing') ||
                    lower.contains('unavailable')
                ? _marketRed
                : _marketBlue;
    return Align(
      alignment: Alignment.centerLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.45)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ),
      ),
    );
  }
}

// ignore: unused_element
class _HoldingsSection extends StatelessWidget {
  const _HoldingsSection({required this.data});

  final Etf00631LLabData data;

  @override
  Widget build(BuildContext context) {
    final snapshot = data.snapshot;
    final txLine = _primaryFuturesLine(snapshot);
    final tsmcLine = _stockHoldingByCode(snapshot, '2330');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeaderCard(
          title: '內容物快覽',
          subtitle: '官方每日資料，不是盤中即時內容物；盤中請看 盤中 NAV 與折溢價。',
          icon: Icons.inventory_2_outlined,
          badges: [
            'DAY',
            'source ${snapshot.status.label}',
            'tradeDate ${formatTaiwanDate(snapshot.tradeDate)}',
          ],
          metrics: [
            _SectionHeaderMetric(
              label: 'TX 權重',
              value: txLine == null
                  ? 'unavailable'
                  : formatNullablePercent(txLine.weightPct),
            ),
            _SectionHeaderMetric(
              label: '台積電權重',
              value: tsmcLine == null
                  ? 'unavailable'
                  : formatNullablePercent(tsmcLine.weightPct),
            ),
            _SectionHeaderMetric(
              label: '股票 / 期貨',
              value:
                  '${formatNullablePercent(snapshot.stockExposureWeightPct)} / ${formatNullablePercent(snapshot.futuresExposureWeightPct)}',
            ),
            _SectionHeaderMetric(
              label: 'NAV',
              value: _price(snapshot.navPerUnit),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _HoldingsExposureCompare(snapshot: snapshot),
        const SizedBox(height: 12),
        _SectionBlock(
          title: '官方每日內容物',
          subtitle:
              'tradeDate ${formatTaiwanDate(snapshot.tradeDate)}，每日揭露資料，不代表盤中即時變動。',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HoldingsCompositionCards(snapshot: snapshot),
              const SizedBox(height: 12),
              _ExposureBars(snapshot: snapshot),
              const SizedBox(height: 12),
              _CompactExpansionPanel(
                title: '資產結構表格',
                subtitle: '金額與占基金淨資產比例；需要核對數字時再展開。',
                child: _HorizontalTable(
                  columns: const ['項目', '金額', '占基金淨資產'],
                  rows: [
                    [
                      '股票資產',
                      formatNtdAmount(snapshot.assetSummary.stock),
                      formatNullablePercent(
                        snapshot.assetWeightPct(EtfAssetClass.stock),
                      ),
                    ],
                    [
                      '期貨資產',
                      formatNtdAmount(snapshot.assetSummary.futures),
                      formatNullablePercent(
                        snapshot.assetWeightPct(EtfAssetClass.futures),
                      ),
                    ],
                    [
                      'ETF',
                      formatNtdAmount(snapshot.assetSummary.etf),
                      formatNullablePercent(
                        snapshot.assetWeightPct(EtfAssetClass.etf),
                      ),
                    ],
                    [
                      '債券',
                      formatNtdAmount(snapshot.assetSummary.bond),
                      formatNullablePercent(
                        snapshot.assetWeightPct(EtfAssetClass.bond),
                      ),
                    ],
                    [
                      '現金與保證金',
                      formatNtdAmount(snapshot.cashAndMarginValue),
                      formatNullablePercent(snapshot.cashAndMarginWeightPct),
                    ],
                    [
                      '其他應收應付',
                      formatNtdAmount(snapshot.otherReceivablesPayablesValue),
                      formatNullablePercent(
                        snapshot.otherReceivablesPayablesWeightPct,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SectionBlock(
          title: '主要內容物',
          subtitle: '先看主要股票、期貨與現金項目；下方保留完整明細。',
          child: _KeyHoldingsCards(snapshot: snapshot),
        ),
        const SizedBox(height: 12),
        _SectionBlock(
          title: '完整明細',
          subtitle: '平常先看主要內容物；需要核對官方表格時再展開。',
          child: Column(
            children: [
              _CompactExpansionPanel(
                title: '完整股票明細',
                subtitle: '官方每日資料，手機版可橫向閱讀。',
                child: _HorizontalTable(
                  columns: const ['代碼', '名稱', '數量', '權重'],
                  rows: [
                    for (final line in snapshot.stockHoldings)
                      [
                        line.code,
                        line.name,
                        formatInteger(line.quantity),
                        formatNullablePercent(line.weightPct),
                      ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _CompactExpansionPanel(
                title: '完整期貨明細',
                subtitle: '這裡是官方每日內容物快照；TX live quote 請看總覽與資料狀態。',
                child: _HorizontalTable(
                  columns: const ['代碼', '名稱', '數量', '權重', '年月'],
                  rows: [
                    for (final line in snapshot.futuresHoldings)
                      [
                        line.code,
                        line.name,
                        formatInteger(line.quantity),
                        formatNullablePercent(line.weightPct),
                        line.contractMonth,
                      ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _CompactExpansionPanel(
                title: '完整現金 / 保證金明細',
                subtitle: '官方每日資料，包含現金、保證金與其他應收應付。',
                child: _HorizontalTable(
                  columns: const ['項目', '金額', '占基金淨資產'],
                  rows: [
                    for (final line in snapshot.cashHoldings)
                      [
                        line.item,
                        formatNtdAmount(line.amount),
                        formatNullablePercent(
                          line.weightPct(snapshot.fundNetAssetValue),
                        ),
                      ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _CompactExpansionPanel(
                title: '內容物歷史覆蓋',
                subtitle: '本機歷史從每日流程開始保存，不補假過去資料。',
                child: _HoldingsCoveragePanel(data: data),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HistorySection extends StatelessWidget {
  const _HistorySection({
    super.key,
    required this.data,
    required this.selectedEtfCode,
    required this.priceHistory,
    required this.show00631LHoldingsHistory,
  });

  final Etf00631LLabData data;
  final String selectedEtfCode;
  final EtfPriceHistory priceHistory;
  final bool show00631LHoldingsHistory;

  @override
  Widget build(BuildContext context) {
    final holdingsTrend = data.holdingsHistory.trendSummary();
    final completeness = priceHistory.completenessSummary();
    final selectedName =
        priceHistory.name.trim().isEmpty ? selectedEtfCode : priceHistory.name;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HistoryBacktestTopStrip(
          code: selectedEtfCode,
          name: selectedName,
          priceHistory: priceHistory,
          completeness: completeness,
        ),
        const SizedBox(height: 8),
        _SectionBlock(
          title: '價格歷史',
          subtitle: priceHistory.hasData
              ? '完整資料範圍 ${_dateOrDash(priceHistory.coverageStart)} - ${_dateOrDash(priceHistory.coverageEnd)}；圖表預設最近 1 年。'
              : '尚無官方價格歷史，請執行 scripts\\00631l_update_price_history.cmd。',
          child: priceHistory.hasData
              ? _FilterablePriceHistoryBlock(priceHistory: priceHistory)
              : const _EmptyPanel(
                  title: '尚無官方價格歷史',
                  message: '價格歷史需要官方、快取或公開靜態資料；不會用模擬資料當成官方資料。',
                ),
        ),
        const SizedBox(height: 8),
        _CompactExpansionPanel(
          key: const ValueKey('00631l-history-quality-expansion'),
          title: '資料品質',
          subtitle: '資料範圍、分割調整與來源狀態。',
          child: _SelectedHistoryQualityCard(
            code: selectedEtfCode,
            name: selectedName,
            priceHistory: priceHistory,
          ),
        ),
        const SizedBox(height: 12),
        if (show00631LHoldingsHistory)
          _SectionBlock(
            title: '每日內容物紀錄',
            subtitle: '官方內容物紀錄從每日流程開始累積，不補假過去資料。',
            child: data.holdingsHistory.hasData
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HistoryChangeCards(summary: holdingsTrend),
                      const SizedBox(height: 12),
                      _HoldingsTrendCharts(summary: holdingsTrend),
                      const SizedBox(height: 12),
                      _CompactExpansionPanel(
                        title: '最近 30 筆 holdings',
                        subtitle: 'TX、台積電、股票、期貨、現金與 NAV。',
                        child: _HorizontalTable(
                          columns: const [
                            '日期',
                            'TX 權重',
                            '台積電',
                            '股票 %',
                            '期貨 %',
                            '現金/保證金 %',
                            'NAV',
                            '發行單位數',
                          ],
                          rows: [
                            for (final point in holdingsTrend.points)
                              [
                                formatTaiwanDate(point.tradeDate),
                                formatNullablePercent(point.txWeightPct),
                                formatNullablePercent(point.tsmcWeightPct),
                                formatNullablePercent(point.stockExposurePct),
                                formatNullablePercent(point.futuresExposurePct),
                                formatNullablePercent(point.cashAndMarginPct),
                                _price(point.navPerUnit),
                                formatInteger(point.outstandingUnits),
                              ],
                          ],
                        ),
                      ),
                    ],
                  )
                : const _EmptyPanel(
                    title: '尚無內容物紀錄',
                    message: '請執行每日流程累積官方每日快照。',
                  ),
          )
        else
          _SectionBlock(
            title: '$selectedEtfCode 內容物紀錄',
            subtitle: '目前此 ETF 尚未接官方每日內容物；此頁保留價格歷史、回測與 ETF 比較。',
            child: const _StatusWrap(
              labels: [
                '價格歷史可用',
                '內容物尚未接入',
                '不套用 00631L 內容物',
              ],
            ),
          ),
      ],
    );
  }
}

class _SelectedHistoryQualityCard extends StatelessWidget {
  const _SelectedHistoryQualityCard({
    required this.code,
    required this.name,
    required this.priceHistory,
  });

  final String code;
  final String name;
  final EtfPriceHistory priceHistory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = priceHistory.completenessSummary();
    final hasHistory = summary.rowCount >= 2;
    final coverage = hasHistory
        ? '${_dateOrDash(summary.coverageStart)} - ${_dateOrDash(summary.coverageEnd)}'
        : '尚無';
    final priceField = summary.hasAdjustedClose ? 'adjustedClose' : 'close';
    final splitAdjustmentLabel = summary.hasNonUnitAdjustment
        ? '已套用分割調整'
        : summary.hasAdjustedClose
            ? '調整價可用'
            : '未套用';
    final coverageLabel = summary.isCompleteFromListing ? '完整上市日起' : '部分區間';

    final adjustmentConfidenceKey =
        _priceAdjustmentConfidenceKey(code, summary);
    final adjustmentConfidenceLabel =
        _priceAdjustmentConfidenceLabel(code, summary);

    return Card(
      key: const ValueKey('00631l-selected-history-quality-card'),
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$code 歷史資料',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                _CompactTextBadge(
                  label: _sourceStatusBadgeLabel(
                    priceHistory.sourceStatusLabel,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _CompactTextBadge(
                  label: hasHistory
                      ? '${formatInteger(summary.rowCount)} 筆'
                      : '尚無歷史',
                ),
                _CompactTextBadge(label: coverageLabel),
                KeyedSubtree(
                  key: ValueKey(
                    '00631l-history-adjustment-$adjustmentConfidenceKey',
                  ),
                  child: _CompactTextBadge(label: adjustmentConfidenceLabel),
                ),
                _CompactTextBadge(label: '價格欄位 $priceField'),
                _CompactTextBadge(label: '分割調整 $splitAdjustmentLabel'),
              ],
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 520;
                final itemWidth = compact
                    ? (constraints.maxWidth - 8) / 2
                    : (constraints.maxWidth - 24) / 4;
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    SizedBox(
                      width: itemWidth,
                      child: _SectionHeaderMetricChip(
                        metric: _SectionHeaderMetric(
                          label: '資料區間',
                          value: coverage,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _SectionHeaderMetricChip(
                        metric: _SectionHeaderMetric(
                          label: '最新收盤',
                          value: _price(summary.latest?.performanceClose),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _SectionHeaderMetricChip(
                        metric: _SectionHeaderMetric(
                          label: '分割調整',
                          value: splitAdjustmentLabel,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _SectionHeaderMetricChip(
                        metric: _SectionHeaderMetric(
                          label: '資料來源',
                          value: _sourceStatusBadgeLabel(
                            priceHistory.sourceStatusLabel,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
            Text(
              '價格欄位 $priceField；分割調整 $splitAdjustmentLabel；回測只使用目前資料範圍內的已載入收盤資料，回測不代表未來表現。',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryBacktestTopStrip extends StatelessWidget {
  const _HistoryBacktestTopStrip({
    required this.code,
    required this.name,
    required this.priceHistory,
    required this.completeness,
  });

  final String code;
  final String name;
  final EtfPriceHistory priceHistory;
  final EtfPriceHistoryCompletenessSummary completeness;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final coverage =
        '${_dateOrDash(completeness.coverageStart)} - ${_dateOrDash(completeness.coverageEnd)}';

    return Card(
      key: const ValueKey('00631l-history-backtest-top-strip'),
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '歷史回測',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '預設顯示最近 1 年，可自行調整開始與結束日期。',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _CompactTextBadge(
                  label: _sourceStatusBadgeLabel(
                    priceHistory.sourceStatusLabel,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _StatusWrap(
              labels: _dedupeStatusLabels([
                'HIS',
                code,
                name,
                coverage,
                _historySourceContractDetail(priceHistory.sourceContractCounts),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterablePriceHistoryBlock extends StatefulWidget {
  const _FilterablePriceHistoryBlock({required this.priceHistory});

  final EtfPriceHistory priceHistory;

  @override
  State<_FilterablePriceHistoryBlock> createState() =>
      _FilterablePriceHistoryBlockState();
}

class _FilterablePriceHistoryBlockState
    extends State<_FilterablePriceHistoryBlock> {
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _syncedCoverageEnd;

  @override
  void initState() {
    super.initState();
    _syncDefaultRange();
  }

  @override
  void didUpdateWidget(covariant _FilterablePriceHistoryBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    final currentEnd = _historyLastDate(widget.priceHistory);
    if (currentEnd != _syncedCoverageEnd) {
      _syncDefaultRange();
    }
  }

  @override
  Widget build(BuildContext context) {
    final fullHistory = widget.priceHistory;
    final filteredHistory = _filteredPriceHistory(
      fullHistory,
      startDate: _startDate,
      endDate: _endDate,
    );
    final performance = filteredHistory.performance;
    final selectedSummary = filteredHistory.completenessSummary();
    final fullSummary = fullHistory.completenessSummary();
    final firstDate = _historyFirstDate(fullHistory);
    final lastDate = _historyLastDate(fullHistory);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DateRangeControlPanel(
          key: const ValueKey('00631l-history-range-context'),
          title: '日期區間',
          subtitle: '預設最近 1 年；圖表、指標與下方回測快覽都套用同一段日期。',
          items: [
            _RangeContextItem(
              label: '目前區間',
              value:
                  '${_dateOrDash(selectedSummary.coverageStart)} - ${_dateOrDash(selectedSummary.coverageEnd)}',
            ),
            _RangeContextItem(
              label: '區間筆數',
              value: formatInteger(selectedSummary.rowCount),
              separator: ' ',
            ),
            _RangeContextItem(
              label: '完整筆數',
              value: formatInteger(fullSummary.rowCount),
              separator: ' ',
            ),
            _RangeContextItem(
              label: '最新資料',
              value: _dateOrDash(selectedSummary.coverageEnd),
            ),
          ],
          startDate: _startDate,
          endDate: _endDate,
          firstDate: firstDate,
          lastDate: lastDate,
          onStartTap: _selectStartDate,
          onEndTap: _selectEndDate,
          onOneYearTap: () => _setTrailingYears(1),
          onThreeYearsTap: () => _setTrailingYears(3),
          onAllTap: _setAllRange,
          chipsKey: const ValueKey('00631l-history-range-chips'),
          oneYearKey: const ValueKey('00631l-history-range-1y'),
          threeYearsKey: const ValueKey('00631l-history-range-3y'),
          allKey: const ValueKey('00631l-history-range-all'),
          dateControlsKey:
              const ValueKey('00631l-history-date-controls-visible'),
        ),
        const SizedBox(height: 8),
        _PriceTrendCharts(priceHistory: filteredHistory),
        const SizedBox(height: 8),
        const _StatusWrap(
          labels: [
            '回測不代表未來表現',
            'split-adjusted close',
          ],
        ),
        const SizedBox(height: 8),
        const SizedBox(height: 8),
        _ResponsiveMetricGrid(
          cards: [
            _MetricCard(
              label: '區間報酬',
              value: formatSignedNullablePercent(
                performance.totalReturnPct,
              ),
              caption: '目前日期區間',
              icon: Icons.trending_up_outlined,
            ),
            _MetricCard(
              label: '年化報酬',
              value: formatSignedNullablePercent(
                performance.annualizedReturnPct,
              ),
              caption: '以區間資料計算',
              icon: Icons.functions_outlined,
            ),
            _MetricCard(
              label: '最大回撤',
              value: formatSignedNullablePercent(
                performance.maxDrawdownPct,
              ),
              caption: '目前日期區間',
              icon: Icons.trending_down_outlined,
            ),
            _MetricCard(
              label: '年化波動',
              value: formatNullablePercent(
                performance.annualizedVolatilityPct,
              ),
              caption: '收盤價日報酬',
              icon: Icons.multiline_chart_outlined,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _CompactExpansionPanel(
          title: '歷史資料完整度',
          subtitle: '完整筆數、資料範圍、欄位完整度。',
          child: _PriceCompletenessPanel(
            priceHistory: fullHistory,
            summary: fullSummary,
          ),
        ),
        const SizedBox(height: 8),
        _CompactExpansionPanel(
          title: '目前區間價格表',
          subtitle: '顯示目前日期區間最近 30 筆。',
          child: _HorizontalTable(
            columns: const [
              '日期',
              '開',
              '高',
              '低',
              '收',
              'NAV',
              '折溢價',
              '量',
              '日報酬',
              '回撤',
            ],
            rows: [
              for (final point in filteredHistory.points.reversed.take(30))
                [
                  formatTaiwanDate(point.date),
                  _price(point.open),
                  _price(point.high),
                  _price(point.low),
                  _price(point.close),
                  _price(point.nav),
                  formatSignedNullablePercent(
                    point.premiumDiscountPct,
                  ),
                  formatInteger(point.volume),
                  formatSignedNullablePercent(point.dailyReturnPct),
                  formatSignedNullablePercent(point.drawdownPct),
                ],
            ],
          ),
        ),
      ],
    );
  }

  void _syncDefaultRange() {
    final last = _historyLastDate(widget.priceHistory);
    if (last == null) {
      _startDate = null;
      _endDate = null;
      _syncedCoverageEnd = null;
      return;
    }
    final first = _historyFirstDate(widget.priceHistory);
    _endDate = last;
    _startDate = _defaultTrailingStart(first: first, end: last, years: 1);
    _syncedCoverageEnd = last;
  }

  Future<void> _selectStartDate() async {
    final history = widget.priceHistory;
    final picked = await _pickBacktestDate(
      context: context,
      initialDate: _startDate ?? _historyFirstDate(history) ?? DateTime.now(),
      firstDate: _historyFirstDate(history),
      lastDate: _historyLastDate(history),
      helpText: '選擇開始日期',
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _startDate = picked;
      if (_endDate != null && _endDate!.isBefore(picked)) {
        _endDate = picked;
      }
    });
  }

  Future<void> _selectEndDate() async {
    final history = widget.priceHistory;
    final picked = await _pickBacktestDate(
      context: context,
      initialDate: _endDate ?? _historyLastDate(history) ?? DateTime.now(),
      firstDate: _historyFirstDate(history),
      lastDate: _historyLastDate(history),
      helpText: '選擇結束日期',
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _endDate = picked;
      if (_startDate != null && _startDate!.isAfter(picked)) {
        _startDate = picked;
      }
    });
  }

  void _setTrailingYears(int years) {
    final last = _historyLastDate(widget.priceHistory);
    if (last == null) {
      return;
    }
    setState(() {
      _endDate = last;
      _startDate = _defaultTrailingStart(
        first: _historyFirstDate(widget.priceHistory),
        end: last,
        years: years,
      );
    });
  }

  void _setAllRange() {
    setState(() {
      _startDate = _historyFirstDate(widget.priceHistory);
      _endDate = _historyLastDate(widget.priceHistory);
    });
  }
}

class _RangeActionChip extends StatelessWidget {
  const _RangeActionChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      avatar: Icon(
        selected ? Icons.check_circle_outline : Icons.date_range_outlined,
        size: 16,
      ),
      visualDensity: VisualDensity.compact,
      onSelected: (_) => onTap(),
    );
  }
}

class _DateRangeControlPanel extends StatelessWidget {
  const _DateRangeControlPanel({
    super.key,
    required this.title,
    required this.subtitle,
    required this.items,
    required this.startDate,
    required this.endDate,
    required this.firstDate,
    required this.lastDate,
    required this.onStartTap,
    required this.onEndTap,
    required this.onOneYearTap,
    required this.onThreeYearsTap,
    required this.onAllTap,
    required this.chipsKey,
    required this.oneYearKey,
    required this.threeYearsKey,
    required this.allKey,
    this.dateControlsKey,
  });

  final String title;
  final String subtitle;
  final List<_RangeContextItem> items;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final VoidCallback onStartTap;
  final VoidCallback onEndTap;
  final VoidCallback onOneYearTap;
  final VoidCallback onThreeYearsTap;
  final VoidCallback onAllTap;
  final Key chipsKey;
  final Key oneYearKey;
  final Key threeYearsKey;
  final Key allKey;
  final Key? dateControlsKey;

  @override
  Widget build(BuildContext context) {
    final activePreset = _activeDateRangePreset(
      startDate: startDate,
      endDate: endDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    return _RangeContextStrip(
      title: title,
      subtitle: subtitle,
      items: items,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KeyedSubtree(
            key: chipsKey,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _RangeActionChip(
                  key: oneYearKey,
                  label: '最近 1 年',
                  selected: activePreset == _DateRangePreset.oneYear,
                  onTap: onOneYearTap,
                ),
                _RangeActionChip(
                  key: threeYearsKey,
                  label: '最近 3 年',
                  selected: activePreset == _DateRangePreset.threeYears,
                  onTap: onThreeYearsTap,
                ),
                _RangeActionChip(
                  key: allKey,
                  label: '全部資料',
                  selected: activePreset == _DateRangePreset.all,
                  onTap: onAllTap,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          KeyedSubtree(
            key: dateControlsKey,
            child: _BacktestDateRangeControls(
              startDate: startDate,
              endDate: endDate,
              firstDate: firstDate,
              lastDate: lastDate,
              onStartTap: onStartTap,
              onEndTap: onEndTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryBacktestSection extends StatelessWidget {
  const _HistoryBacktestSection({
    required this.data,
    required this.selectedEtfCode,
    required this.selectedPriceHistory,
    required this.selectedPriceHistoryLoading,
    required this.selectedPriceHistoryError,
    required this.comparisonHistories,
    required this.comparisonHistoriesLoading,
    required this.comparisonHistoriesError,
    required this.selectedEtf,
  });

  final Etf00631LLabData data;
  final String selectedEtfCode;
  final EtfPriceHistory? selectedPriceHistory;
  final bool selectedPriceHistoryLoading;
  final Object? selectedPriceHistoryError;
  final List<EtfPriceHistory> comparisonHistories;
  final bool comparisonHistoriesLoading;
  final Object? comparisonHistoriesError;
  final _SelectedEtfViewData selectedEtf;

  @override
  Widget build(BuildContext context) {
    final history = selectedEtf.priceHistory;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (selectedPriceHistoryLoading ||
            selectedPriceHistoryError != null) ...[
          _DetailsLoadStateStrip(
            isLoading: selectedPriceHistoryLoading,
            errorMessage: selectedPriceHistoryError?.toString(),
          ),
          const SizedBox(height: 10),
        ],
        if (history.points.length < 2) ...[
          _SelectedEtfReadinessBanner(selectedEtf: selectedEtf),
          const SizedBox(height: 10),
          const _SectionBlock(
            title: 'ETF 歷史資料尚未匯入',
            subtitle: '目前只找到 ETF 清單；歷史圖表與回測需要先匯入該 ETF 的可驗證歷史價格。',
            child: _StatusWrap(
              labels: [
                '僅清單資料',
                '歷史未匯入',
                '請先匯入歷史價格',
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (!selectedEtf.is00631L) ...[
          _SelectedEtfHistoryReadinessStrip(selectedEtf: selectedEtf),
          const SizedBox(height: 10),
        ],
        _HistorySection(
          key: const ValueKey('00631l-history-view'),
          data: data,
          selectedEtfCode: selectedEtfCode,
          priceHistory: history,
          show00631LHoldingsHistory: selectedEtf.is00631L,
        ),
        const SizedBox(height: 10),
        _BacktestSection(
          key: const ValueKey('00631l-backtest-view'),
          data: data,
          selectedEtfCode: selectedEtfCode,
          priceHistory: history,
        ),
        const SizedBox(height: 10),
        _EtfHistoryComparisonPanel(
          key: const ValueKey('00631l-etf-history-comparison'),
          selectedEtfCode: selectedEtfCode,
          selectedHistory: history,
          histories: comparisonHistories,
          isLoading: comparisonHistoriesLoading,
          error: comparisonHistoriesError,
        ),
      ],
    );
  }
}

enum _EtfComparisonFilter {
  focused('代表'),
  market('市值型'),
  dividend('高股息'),
  tech('科技'),
  all('全部');

  const _EtfComparisonFilter(this.label);
  final String label;
}

class _EtfHistoryComparisonPanel extends StatefulWidget {
  const _EtfHistoryComparisonPanel({
    super.key,
    required this.selectedEtfCode,
    required this.selectedHistory,
    required this.histories,
    required this.isLoading,
    required this.error,
  });

  final String selectedEtfCode;
  final EtfPriceHistory selectedHistory;
  final List<EtfPriceHistory> histories;
  final bool isLoading;
  final Object? error;

  @override
  State<_EtfHistoryComparisonPanel> createState() =>
      _EtfHistoryComparisonPanelState();
}

class _EtfHistoryComparisonPanelState
    extends State<_EtfHistoryComparisonPanel> {
  late _EtfComparisonFilter _filter;
  Set<String>? _selectedComparisonCodes;

  @override
  void initState() {
    super.initState();
    _filter = _defaultComparisonFilterForCode(widget.selectedHistory.code);
  }

  @override
  void didUpdateWidget(covariant _EtfHistoryComparisonPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedEtfCode != widget.selectedEtfCode ||
        oldWidget.selectedHistory.code != widget.selectedHistory.code ||
        oldWidget.histories.length != widget.histories.length) {
      _filter = _defaultComparisonFilterForCode(widget.selectedHistory.code);
      _selectedComparisonCodes = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final endDate = _historyLastDate(widget.selectedHistory) ??
        _latestHistoryEnd(widget.histories) ??
        DateTime.now();
    final startDate = _defaultTrailingStart(
      first: _historyFirstDate(widget.selectedHistory),
      end: endDate,
      years: 1,
    );
    final mergedHistories = _mergeSelectedComparisonHistories(
      selectedHistory: widget.selectedHistory,
      histories: widget.histories,
    );
    final metrics = [
      for (final history in mergedHistories)
        _comparisonMetricForHistory(
          history: history,
          startDate: startDate,
          endDate: endDate,
        ),
    ];
    final availableMetrics = [
      for (final metric in metrics)
        if (metric.rowCount >= 2) metric,
    ];
    final skippedMetrics = [
      for (final metric in metrics)
        if (metric.rowCount < 2) metric,
    ];
    final selectedCodes = _effectiveComparisonCodes(availableMetrics);
    final usableMetrics = [
      for (final metric in availableMetrics)
        if (selectedCodes.contains(metric.code)) metric,
    ];
    final allUsableCount = availableMetrics.length;
    final chartHistories = _comparisonChartHistories(
      histories: mergedHistories,
      metrics: usableMetrics,
    );
    final basketContext = _comparisonBasketContext(usableMetrics);
    final comparisonModeSummary = usableMetrics.isEmpty
        ? '自選比較：尚未選擇 ETF；不設基準。'
        : '自選比較：${usableMetrics.map((metric) => metric.code).join(' / ')}；以重疊區間重算百分比，不設基準。';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeaderCard(
          title: 'ETF 歷史比較',
          subtitle: '預設只看目前 ETF；可用同類型快速帶入，也可清空後自行勾選 1-5 檔。',
          icon: Icons.stacked_line_chart_outlined,
          badges: const [
            '自選組合',
            '最近 1 年',
            'static / proxy history',
          ],
          metrics: [
            _SectionHeaderMetric(
              label: '比較檔數',
              value: formatInteger(usableMetrics.length),
              caption: usableMetrics.isEmpty ? '尚未選擇' : '目前組合',
            ),
            _SectionHeaderMetric(
              label: '區間',
              value: '${_dateOrDash(startDate)} - ${_dateOrDash(endDate)}',
              caption: '已載入 $allUsableCount 檔可比較資料',
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (widget.isLoading || widget.error != null) ...[
          _DetailsLoadStateStrip(
            isLoading: widget.isLoading,
            errorMessage: widget.error?.toString(),
          ),
          const SizedBox(height: 10),
        ],
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final filter in _EtfComparisonFilter.values) ...[
                ChoiceChip(
                  key: ValueKey('00631l-etf-comparison-filter-${filter.name}'),
                  label: Text(filter.label),
                  selected: _filter == filter,
                  onSelected: (_) =>
                      _applyComparisonFilter(filter, availableMetrics),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        _ComparisonSelectionChips(
          metrics: availableMetrics,
          selectedCodes: selectedCodes,
          onChanged: (code, selected) {
            setState(() {
              final next = {...selectedCodes};
              if (selected) {
                if (next.length < 5) {
                  next.add(code);
                }
              } else {
                next.remove(code);
              }
              _selectedComparisonCodes = next;
            });
          },
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          key: const ValueKey('00631l-etf-comparison-action-strip'),
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              OutlinedButton.icon(
                key: const ValueKey('00631l-etf-comparison-clear'),
                onPressed: selectedCodes.isEmpty
                    ? null
                    : () {
                        setState(() {
                          _selectedComparisonCodes = <String>{};
                        });
                      },
                icon: const Icon(Icons.remove_circle_outline, size: 16),
                label: const Text('清空組合'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                key: const ValueKey('00631l-etf-comparison-apply-peer'),
                onPressed: () {
                  setState(() {
                    _filter = _defaultComparisonFilterForCode(
                        widget.selectedHistory.code);
                    final preset = _presetComparisonCodes(
                      _filter,
                      availableMetrics,
                    );
                    _selectedComparisonCodes = preset.take(5).toSet();
                  });
                },
                icon: const Icon(Icons.group_work_outlined, size: 16),
                label: const Text('套用同類型'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                key: const ValueKey('00631l-etf-comparison-selected-only'),
                onPressed: () {
                  setState(() {
                    final selectedCode =
                        widget.selectedHistory.code.trim().toUpperCase();
                    _selectedComparisonCodes = availableMetrics
                            .any((metric) => metric.code == selectedCode)
                        ? {selectedCode}
                        : <String>{};
                  });
                },
                icon: const Icon(Icons.adjust_outlined, size: 16),
                label: const Text('只看目前 ETF'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _ComparisonCompactSummaryStrip(
          selectedMetrics: usableMetrics,
          readyCount: availableMetrics.length,
          candidateCount: metrics.length,
        ),
        const SizedBox(height: 8),
        Text(
          '預設只看目前 ETF；可選 1-5 檔 ETF 比較，資料筆數足夠才會進入圖表。',
          key: const ValueKey('00631l-etf-comparison-guidance'),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: _marketMutedTextColor(context),
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          comparisonModeSummary,
          key: const ValueKey('00631l-etf-comparison-mode-summary'),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: _marketTextColor(context),
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          usableMetrics.isEmpty
              ? '尚未選擇比較 ETF'
              : '目前組合：${usableMetrics.map((metric) => metric.code).join(' / ')}',
          key: const ValueKey('00631l-etf-comparison-selected-codes'),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: _marketMutedTextColor(context),
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 10),
        _ComparisonDataReadinessStrip(
          candidateCount: metrics.length,
          readyCount: availableMetrics.length,
          skippedMetrics: skippedMetrics,
        ),
        const SizedBox(height: 10),
        _ComparisonBasketContextCard(basketContext: basketContext),
        const SizedBox(height: 10),
        _CompactExpansionPanel(
          key: const ValueKey('00631l-etf-comparison-chart-expansion'),
          title: '比較圖表與明細',
          subtitle: usableMetrics.isEmpty
              ? '尚未選擇比較 ETF；展開後顯示資料需求。'
              : '展開顯示報酬比較圖與明細表；目前 ${formatInteger(usableMetrics.length)} 檔。',
          child: usableMetrics.isEmpty
              ? const KeyedSubtree(
                  key: ValueKey('00631l-etf-comparison-return-chart'),
                  child: _EmptyPanel(
                    title: 'ETF 報酬比較圖暫無資料',
                    message: '請先匯入 ETF 歷史價格，或確認公開靜態資料內含 etf_price_history 檔案。',
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StatusWrap(
                      labels: [
                        '自選比較',
                        _filter.label,
                        '筆數 ${formatInteger(usableMetrics.fold<int>(0, (sum, item) => sum + item.rowCount))}',
                        'history comparison',
                      ],
                    ),
                    const SizedBox(height: 10),
                    _EtfComparisonReturnChart(
                      key: const ValueKey(
                        '00631l-etf-comparison-return-chart',
                      ),
                      histories: chartHistories,
                      startDate: startDate,
                      endDate: endDate,
                    ),
                    const SizedBox(height: 10),
                    _HorizontalTable(
                      columns: const [
                        '代號',
                        '名稱',
                        '區間報酬',
                        '年化',
                        '最大回撤',
                        '波動',
                        '最新收盤',
                        '筆數',
                        '狀態',
                      ],
                      rows: [
                        for (final metric in usableMetrics)
                          [
                            metric.code,
                            metric.name,
                            formatSignedNullablePercent(
                              metric.totalReturnPct,
                            ),
                            formatSignedNullablePercent(
                              metric.annualizedReturnPct,
                            ),
                            formatSignedNullablePercent(metric.maxDrawdownPct),
                            formatNullablePercent(
                              metric.annualizedVolatilityPct,
                            ),
                            _price(metric.latestClose),
                            formatInteger(metric.rowCount),
                            metric.sourceStatusLabel,
                          ],
                      ],
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Set<String> _effectiveComparisonCodes(
      List<_EtfComparisonMetric> availableMetrics) {
    final availableCodes = {
      for (final metric in availableMetrics) metric.code,
    };
    if (availableCodes.isEmpty) {
      _selectedComparisonCodes = <String>{};
      return const <String>{};
    }

    final current = _selectedComparisonCodes;
    if (current == null) {
      final selectedCode = widget.selectedHistory.code.trim().toUpperCase();
      _selectedComparisonCodes = availableCodes.contains(selectedCode)
          ? {selectedCode}
          : availableCodes.take(1).toSet();
    } else {
      final cleaned = current.where(availableCodes.contains).toSet();
      _selectedComparisonCodes =
          cleaned.isEmpty ? <String>{} : cleaned.take(5).toSet();
    }
    return _selectedComparisonCodes!;
  }

  void _applyComparisonFilter(
    _EtfComparisonFilter filter,
    List<_EtfComparisonMetric> availableMetrics,
  ) {
    setState(() {
      _filter = filter;
      final preset = _presetComparisonCodes(filter, availableMetrics);
      _selectedComparisonCodes = preset.isNotEmpty
          ? preset
          : {
              for (final metric in availableMetrics.take(5)) metric.code,
            };
    });
  }
}

class _ComparisonCompactSummaryStrip extends StatelessWidget {
  const _ComparisonCompactSummaryStrip({
    required this.selectedMetrics,
    required this.readyCount,
    required this.candidateCount,
  });

  final List<_EtfComparisonMetric> selectedMetrics;
  final int readyCount;
  final int candidateCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final codes = selectedMetrics.map((metric) => metric.code).join(' / ');
    final commonRange = _comparisonCommonRangeText(selectedMetrics);
    final totalRows =
        selectedMetrics.fold<int>(0, (sum, metric) => sum + metric.rowCount);
    final summary = selectedMetrics.isEmpty
        ? '尚未選擇比較 ETF · 不設基準 · 可比較 ${formatInteger(readyCount)} / ${formatInteger(candidateCount)} 檔'
        : '目前組合 $codes · 不設基準 · $commonRange · ${formatInteger(totalRows)} 筆';
    return Container(
      key: const ValueKey('00631l-etf-comparison-compact-summary'),
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _marketPanelColor(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _marketBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            summary,
            key: const ValueKey('00631l-etf-comparison-compact-summary-text'),
            style: theme.textTheme.labelMedium?.copyWith(
              color: _marketTextColor(context),
              fontWeight: FontWeight.w900,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),
          _StatusWrap(
            labels: [
              selectedMetrics.isEmpty
                  ? '組合 0 檔'
                  : '組合 ${formatInteger(selectedMetrics.length)} 檔',
              '不設基準',
              '可比較 ${formatInteger(readyCount)} / ${formatInteger(candidateCount)}',
            ],
          ),
        ],
      ),
    );
  }
}

class _ComparisonSelectionChips extends StatelessWidget {
  const _ComparisonSelectionChips({
    required this.metrics,
    required this.selectedCodes,
    required this.onChanged,
  });

  final List<_EtfComparisonMetric> metrics;
  final Set<String> selectedCodes;
  final void Function(String code, bool selected) onChanged;

  @override
  Widget build(BuildContext context) {
    if (metrics.isEmpty) {
      return const _EmptyPanel(
        title: '尚無可比較 ETF',
        message: '請先匯入 ETF 歷史價格，再選擇要比較的標的。',
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final metric in metrics)
          FilterChip(
            key: ValueKey('00631l-etf-compare-chip-${metric.code}'),
            label: Text(metric.code),
            selected: selectedCodes.contains(metric.code),
            onSelected: (selected) => onChanged(metric.code, selected),
            visualDensity: VisualDensity.compact,
          ),
      ],
    );
  }
}

class _ComparisonDataReadinessStrip extends StatelessWidget {
  const _ComparisonDataReadinessStrip({
    required this.candidateCount,
    required this.readyCount,
    required this.skippedMetrics,
  });

  final int candidateCount;
  final int readyCount;
  final List<_EtfComparisonMetric> skippedMetrics;

  @override
  Widget build(BuildContext context) {
    final skippedCodes = skippedMetrics
        .map((metric) => metric.code)
        .where((code) => code.trim().isNotEmpty)
        .take(6)
        .join(' / ');
    final labels = [
      '候選 ${formatInteger(candidateCount)}',
      '可比較 ${formatInteger(readyCount)}',
      '略過 ${formatInteger(skippedMetrics.length)}',
      if (skippedCodes.isNotEmpty) '略過 $skippedCodes',
    ];
    return Column(
      key: const ValueKey('00631l-etf-comparison-readiness-strip'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KeyedSubtree(
          key: ValueKey('00631l-etf-comparison-ready-count-$readyCount'),
          child: const SizedBox.shrink(),
        ),
        KeyedSubtree(
          key: ValueKey(
            '00631l-etf-comparison-skipped-count-${skippedMetrics.length}',
          ),
          child: const SizedBox.shrink(),
        ),
        for (final metric in skippedMetrics.take(6))
          KeyedSubtree(
            key: ValueKey('00631l-etf-comparison-skipped-${metric.code}'),
            child: const SizedBox.shrink(),
          ),
        _StatusWrap(labels: labels),
        if (skippedMetrics.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            '少於兩筆歷史價格的 ETF 不會放入比較圖。',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: _marketMutedTextColor(context),
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final metric in skippedMetrics.take(4))
                Container(
                  key: ValueKey(
                    '00631l-etf-comparison-skipped-detail-${metric.code}',
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _marketPanelColor(context),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _marketBorderColor(context)),
                  ),
                  child: Text(
                    '${metric.code}: ${formatInteger(metric.rowCount)} 筆 / ${_sourceStatusBadgeLabel(metric.sourceStatusLabel)}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: _marketMutedTextColor(context),
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ComparisonBasketContextCard extends StatelessWidget {
  const _ComparisonBasketContextCard({required this.basketContext});

  final _EtfComparisonBasketContext basketContext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      key: const ValueKey('00631l-etf-comparison-basket-context'),
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.rule_folder_outlined,
                  color: theme.colorScheme.primary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '自選比較組合檢查',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              basketContext.explanation,
              key: const ValueKey('00631l-etf-comparison-basket-explanation'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            _StatusWrap(labels: basketContext.labels),
          ],
        ),
      ),
    );
  }
}

class _EtfComparisonReturnChart extends StatefulWidget {
  const _EtfComparisonReturnChart({
    super.key,
    required this.histories,
    required this.startDate,
    required this.endDate,
  });

  final List<EtfPriceHistory> histories;
  final DateTime startDate;
  final DateTime endDate;

  @override
  State<_EtfComparisonReturnChart> createState() =>
      _EtfComparisonReturnChartState();
}

class _EtfComparisonReturnChartState extends State<_EtfComparisonReturnChart> {
  List<_TouchedComparisonValue> _touchedValues = const [];
  DateTime? _touchedDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final series = _buildComparisonChartSeries(
      context: context,
      histories: widget.histories,
      startDate: widget.startDate,
      endDate: widget.endDate,
    );
    if (series.isEmpty) {
      return const _EmptyPanel(
        title: 'ETF 報酬比較圖暫無資料',
        message: '目前篩選條件下沒有足夠歷史價格可畫比較圖。',
      );
    }

    final maxDays =
        widget.endDate.difference(widget.startDate).inDays.clamp(1, 10000);
    var minY = 0.0;
    var maxY = 0.0;
    for (final item in series) {
      for (final spot in item.spots) {
        if (spot.y < minY) {
          minY = spot.y;
        }
        if (spot.y > maxY) {
          maxY = spot.y;
        }
      }
    }
    if ((maxY - minY).abs() < 0.01) {
      maxY += 1;
      minY -= 1;
    }
    final padding = (maxY - minY).abs() * 0.12;
    final bottomInterval = maxDays <= 2 ? 1.0 : maxDays / 2;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ETF 報酬比較圖',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '以區間第一筆收盤價歸零，顯示歷史區間報酬；可點擊圖表查看日期與數值。',
              style: theme.textTheme.bodySmall?.copyWith(
                color: _marketMutedTextColor(context),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final item in series)
                  _ChartLegendPill(
                    color: item.color,
                    label: '${item.code} ${item.name}',
                  ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 230,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: maxDays.toDouble(),
                  minY: minY - padding,
                  maxY: maxY + padding,
                  gridData: FlGridData(
                    show: true,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: theme.colorScheme.outlineVariant
                          .withValues(alpha: 0.45),
                      strokeWidth: 0.8,
                    ),
                    getDrawingVerticalLine: (_) => FlLine(
                      color: theme.colorScheme.outlineVariant
                          .withValues(alpha: 0.3),
                      strokeWidth: 0.6,
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant,
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchCallback: (event, response) {
                      final spots = response?.lineBarSpots;
                      if (spots == null || spots.isEmpty) {
                        return;
                      }
                      final values = [
                        for (final spot in spots)
                          if (spot.barIndex >= 0 &&
                              spot.barIndex < series.length &&
                              spot.spotIndex >= 0 &&
                              spot.spotIndex <
                                  series[spot.barIndex].points.length)
                            _TouchedComparisonValue(
                              code: series[spot.barIndex].code,
                              value: spot.y,
                              date:
                                  series[spot.barIndex].points[spot.spotIndex],
                            ),
                      ];
                      final touchedDate =
                          values.isEmpty ? null : values.first.date;
                      setState(() {
                        _touchedDate = touchedDate;
                        _touchedValues = values;
                      });
                    },
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (spots) => [
                        for (final spot in spots)
                          if (spot.barIndex >= 0 &&
                              spot.barIndex < series.length)
                            LineTooltipItem(
                              '${series[spot.barIndex].code}\n${formatSignedNullablePercent(spot.y)}',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                              ),
                            ),
                      ],
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(),
                    rightTitles: const AxisTitles(),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 44,
                        getTitlesWidget: (value, meta) => Text(
                          '${value.toStringAsFixed(0)}%',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 34,
                        interval: bottomInterval,
                        getTitlesWidget: (value, meta) {
                          final day = value.round().clamp(0, maxDays);
                          final date =
                              widget.startDate.add(Duration(days: day));
                          return Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: Text(
                              _shortChartDate(date),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 10,
                                height: 1.05,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    for (final item in series)
                      LineChartBarData(
                        spots: item.spots,
                        isCurved: false,
                        barWidth: 2.4,
                        color: item.color,
                        dotData: FlDotData(show: item.spots.length <= 18),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            _ChartAxisDateStrip(
              start: widget.startDate,
              middle: widget.startDate.add(Duration(days: maxDays ~/ 2)),
              end: widget.endDate,
            ),
            const SizedBox(height: 8),
            _ComparisonTouchDetail(
              date: _touchedDate,
              values: _touchedValues,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartLegendPill extends StatelessWidget {
  const _ChartLegendPill({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ComparisonTouchDetail extends StatelessWidget {
  const _ComparisonTouchDetail({
    required this.date,
    required this.values,
  });

  final DateTime? date;
  final List<_TouchedComparisonValue> values;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = <Widget>[];
    if (date == null || values.isEmpty) {
      content.add(
        Text(
          '點擊圖表可查看指定資料日與各 ETF 區間報酬。',
          key: const ValueKey('00631l-comparison-touch-empty'),
          style: theme.textTheme.labelSmall?.copyWith(
            color: _marketMutedTextColor(context),
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    } else {
      content.addAll([
        Text(
          '選取資料日 ${formatTaiwanDate(date!)}',
          key: const ValueKey('00631l-comparison-touch-date'),
          style: theme.textTheme.labelMedium?.copyWith(
            color: _marketTextColor(context),
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final item in values)
              _StatusPill(
                label: '${item.code} ${formatSignedNullablePercent(item.value)}'
                    '${_isSameDay(item.date, date!) ? '' : ' · ${formatTaiwanDate(item.date)}'}',
              ),
          ],
        ),
      ]);
    }
    return DecoratedBox(
      key: const ValueKey('00631l-comparison-touch-detail'),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: content,
        ),
      ),
    );
  }
}

class _EtfComparisonChartSeries {
  const _EtfComparisonChartSeries({
    required this.code,
    required this.name,
    required this.color,
    required this.spots,
    required this.points,
  });

  final String code;
  final String name;
  final Color color;
  final List<FlSpot> spots;
  final List<DateTime> points;
}

class _TouchedComparisonValue {
  const _TouchedComparisonValue({
    required this.code,
    required this.value,
    required this.date,
  });

  final String code;
  final double value;
  final DateTime date;
}

class _BacktestQuickResultStrip extends StatelessWidget {
  const _BacktestQuickResultStrip({
    required this.result,
    required this.selectedEtfCode,
    required this.sourceStatusLabel,
    required this.strategyLabel,
  });

  final EtfBacktestResult result;
  final String selectedEtfCode;
  final String sourceStatusLabel;
  final String strategyLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = [
      _InlineQualityPill(
        label: '期末',
        value: formatNtdAmount(result.finalValue),
      ),
      _InlineQualityPill(
        label: '投入',
        value: formatNtdAmount(result.totalInvested),
      ),
      _InlineQualityPill(
        label: '報酬',
        value: formatSignedNullablePercent(result.totalReturnPct),
      ),
      _InlineQualityPill(
        label: '年化',
        value: formatSignedNullablePercent(result.annualizedReturnPct),
      ),
      _InlineQualityPill(
        label: '回撤',
        value: formatSignedNullablePercent(result.maxDrawdownPct),
      ),
      _InlineQualityPill(
        label: '波動',
        value: formatNullablePercent(result.volatilityPct),
      ),
    ];
    return DecoratedBox(
      key: const ValueKey('00631l-backtest-quick-result-strip'),
      decoration: BoxDecoration(
        color: _marketPanelColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _marketBorderColor(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const _MiniStatusBadge(label: 'BT'),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '回測快覽',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: _marketTextColor(context),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _CompactTextBadge(label: selectedEtfCode),
              ],
            ),
            const SizedBox(height: 7),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(children: items),
            ),
            const SizedBox(height: 6),
            _StatusWrap(
              labels: [
                strategyLabel,
                'source $sourceStatusLabel',
                '回測不代表未來表現',
                '非買賣建議',
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BacktestSection extends StatefulWidget {
  const _BacktestSection({
    super.key,
    required this.data,
    required this.selectedEtfCode,
    required this.priceHistory,
  });

  final Etf00631LLabData data;
  final String selectedEtfCode;
  final EtfPriceHistory priceHistory;

  @override
  State<_BacktestSection> createState() => _BacktestSectionState();
}

class _BacktestSectionState extends State<_BacktestSection> {
  EtfBacktestStrategy _strategy = EtfBacktestStrategy.monthlyContribution;
  final _initialController = TextEditingController(text: '100000');
  final _monthlyController = TextEditingController(text: '5000');
  final _dayController = TextEditingController(text: '5');
  final _feeController = TextEditingController(text: '0');
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _syncBacktestRange();
  }

  @override
  void didUpdateWidget(covariant _BacktestSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedEtfCode != widget.selectedEtfCode ||
        oldWidget.priceHistory.coverageEnd != widget.priceHistory.coverageEnd) {
      _syncBacktestRange();
    }
  }

  @override
  void dispose() {
    _initialController.dispose();
    _monthlyController.dispose();
    _dayController.dispose();
    _feeController.dispose();
    super.dispose();
  }

  void _syncBacktestRange() {
    final history = widget.priceHistory;
    final end = _historyLastDate(history);
    _endDate = end;
    _startDate = end == null
        ? _historyFirstDate(history)
        : _defaultTrailingStart(
            first: _historyFirstDate(history),
            end: end,
            years: 1,
          );
  }

  @override
  Widget build(BuildContext context) {
    final history = widget.priceHistory;
    final firstDate = _historyFirstDate(history);
    final lastDate = _historyLastDate(history);
    final result = const EtfBacktestEngine().run(
      request: EtfBacktestRequest(
        strategy: _strategy,
        startDate: _startDate ?? DateTime(1970),
        endDate: _endDate ?? DateTime.now(),
        initialAmount: _parseDouble(_initialController.text),
        monthlyAmount: _parseDouble(_monthlyController.text),
        monthlyDay: _parseInt(_dayController.text, fallback: 5),
        feeRatePct: _parseDouble(_feeController.text),
      ),
      history: history.points,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BacktestQuickResultStrip(
          result: result,
          selectedEtfCode: widget.selectedEtfCode,
          sourceStatusLabel: history.sourceStatusLabel,
          strategyLabel:
              _strategy == EtfBacktestStrategy.lumpSum ? '一次投入' : '定期定額',
        ),
        const SizedBox(height: 8),
        _SectionBlock(
          title: '歷史回測',
          subtitle: '只使用已保存的歷史收盤價。回測不代表未來表現，非買賣建議。',
          child: history.hasData
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          selected: _strategy == EtfBacktestStrategy.lumpSum,
                          label: const Text('一次投入'),
                          onSelected: (_) => setState(
                            () => _strategy = EtfBacktestStrategy.lumpSum,
                          ),
                        ),
                        ChoiceChip(
                          selected: _strategy ==
                              EtfBacktestStrategy.monthlyContribution,
                          label: const Text('定期定額'),
                          onSelected: (_) => setState(
                            () => _strategy =
                                EtfBacktestStrategy.monthlyContribution,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _DateRangeControlPanel(
                      key: const ValueKey('00631l-backtest-range-context'),
                      title: '日期與設定',
                      subtitle: '預設最近 1 年；結果只套用目前日期區間與下方參數。',
                      items: [
                        _RangeContextItem(
                          label: '回測區間',
                          value:
                              '${_dateOrDash(_startDate)} - ${_dateOrDash(_endDate)}',
                          separator: ' ',
                        ),
                        _RangeContextItem(
                          label: '策略',
                          value: _strategy == EtfBacktestStrategy.lumpSum
                              ? '一次投入'
                              : '定期定額',
                          separator: ' ',
                        ),
                        _RangeContextItem(
                          label: '樣本',
                          value: formatInteger(result.equityCurve.length),
                          separator: ' ',
                        ),
                        _RangeContextItem(
                          label: '成本',
                          value:
                              '${_parseDouble(_feeController.text).toStringAsFixed(2)}%',
                          separator: ' ',
                        ),
                      ],
                      startDate: _startDate,
                      endDate: _endDate,
                      firstDate: firstDate,
                      lastDate: lastDate,
                      onStartTap: _selectStartDate,
                      onEndTap: _selectEndDate,
                      onOneYearTap: () => _setTrailingYears(1),
                      onThreeYearsTap: () => _setTrailingYears(3),
                      onAllTap: _setAllRange,
                      chipsKey: const ValueKey('00631l-backtest-range-chips'),
                      oneYearKey: const ValueKey('00631l-backtest-range-1y'),
                      threeYearsKey: const ValueKey('00631l-backtest-range-3y'),
                      allKey: const ValueKey('00631l-backtest-range-all'),
                    ),
                    const SizedBox(height: 12),
                    _CompactExpansionPanel(
                      title: '金額與成本參數',
                      subtitle: '預設值可直接跑；需要調整金額、投入日或成本時再展開。',
                      child: _InputGrid(
                        children: [
                          _NumberField(
                            label: '初始金額',
                            controller: _initialController,
                            onChanged: (_) => setState(() {}),
                          ),
                          _NumberField(
                            label: '每月投入金額',
                            controller: _monthlyController,
                            onChanged: (_) => setState(() {}),
                          ),
                          _NumberField(
                            label: '每月日期',
                            controller: _dayController,
                            onChanged: (_) => setState(() {}),
                          ),
                          _NumberField(
                            label: '手續費率 %',
                            controller: _feeController,
                            onChanged: (_) => setState(() {}),
                          ),
                        ],
                      ),
                    ),
                    if (result.equityCurve.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _CurveChartPanel(points: result.equityCurve),
                    ],
                    const SizedBox(height: 10),
                    const Text('回測不代表未來表現，非買賣建議。'),
                  ],
                )
              : const _EmptyPanel(
                  title: '尚無回測資料',
                  message:
                      '請先執行 scripts\\00631l_update_price_history.cmd 建立官方價格歷史快取。',
                ),
        ),
      ],
    );
  }

  Future<void> _selectStartDate() async {
    final history = widget.priceHistory;
    final picked = await _pickBacktestDate(
      context: context,
      initialDate: _startDate ?? history.coverageStart ?? DateTime.now(),
      firstDate: history.coverageStart,
      lastDate: history.coverageEnd,
      helpText: '選擇開始日期',
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _startDate = picked;
      if (_endDate != null && _endDate!.isBefore(picked)) {
        _endDate = picked;
      }
    });
  }

  Future<void> _selectEndDate() async {
    final history = widget.priceHistory;
    final picked = await _pickBacktestDate(
      context: context,
      initialDate: _endDate ?? history.coverageEnd ?? DateTime.now(),
      firstDate: history.coverageStart,
      lastDate: history.coverageEnd,
      helpText: '選擇結束日期',
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _endDate = picked;
      if (_startDate != null && _startDate!.isAfter(picked)) {
        _startDate = picked;
      }
    });
  }

  void _setTrailingYears(int years) {
    final last = _historyLastDate(widget.priceHistory);
    if (last == null) {
      return;
    }
    setState(() {
      _endDate = last;
      _startDate = _defaultTrailingStart(
        first: _historyFirstDate(widget.priceHistory),
        end: last,
        years: years,
      );
    });
  }

  void _setAllRange() {
    setState(() {
      _startDate = _historyFirstDate(widget.priceHistory);
      _endDate = _historyLastDate(widget.priceHistory);
    });
  }
}

class _BacktestDateRangeControls extends StatelessWidget {
  const _BacktestDateRangeControls({
    required this.startDate,
    required this.endDate,
    required this.firstDate,
    required this.lastDate,
    required this.onStartTap,
    required this.onEndTap,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final VoidCallback onStartTap;
  final VoidCallback onEndTap;

  @override
  Widget build(BuildContext context) {
    final preset = _activeDateRangePreset(
      startDate: startDate,
      endDate: endDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BacktestDateRangeSummary(
          startDate: startDate,
          endDate: endDate,
          rangeLabel: preset.label,
        ),
        const SizedBox(height: 6),
        _DateRangeInlineLabels(
          startDate: startDate,
          endDate: endDate,
          rangeLabel: preset.label,
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final children = [
              _BacktestDateButton(
                key: const ValueKey('00631l-start-date-button'),
                label: '開始日期',
                value: _dateOrDash(startDate),
                caption: firstDate == null ? '起始日暫無' : '點擊調整',
                onTap: onStartTap,
              ),
              _BacktestDateButton(
                key: const ValueKey('00631l-end-date-button'),
                label: '結束日期',
                value: _dateOrDash(endDate),
                caption: lastDate == null ? '結束日暫無' : '點擊調整',
                onTap: onEndTap,
              ),
            ];
            return Row(
              children: [
                Expanded(child: children[0]),
                const SizedBox(width: 8),
                Expanded(child: children[1]),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _BacktestDateRangeSummary extends StatelessWidget {
  const _BacktestDateRangeSummary({
    required this.startDate,
    required this.endDate,
    required this.rangeLabel,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final String rangeLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      key: const ValueKey('00631l-date-range-summary'),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          children: [
            Icon(
              Icons.date_range_outlined,
              size: 15,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '$rangeLabel · ${_dateOrDash(startDate)} - ${_dateOrDash(endDate)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateRangeInlineLabels extends StatelessWidget {
  const _DateRangeInlineLabels({
    required this.startDate,
    required this.endDate,
    required this.rangeLabel,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final String rangeLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.labelSmall?.copyWith(
      color: _marketMutedTextColor(context),
      fontWeight: FontWeight.w800,
    );
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        _InlineDateRangeBadge(
          key: const ValueKey('00631l-date-range-summary-mode'),
          label: rangeLabel,
        ),
        Text(
          '起 ${_dateOrDash(startDate)}',
          key: const ValueKey('00631l-date-range-summary-start'),
          style: textStyle,
        ),
        Text(
          '迄 ${_dateOrDash(endDate)}',
          key: const ValueKey('00631l-date-range-summary-end'),
          style: textStyle,
        ),
      ],
    );
  }
}

class _InlineDateRangeBadge extends StatelessWidget {
  const _InlineDateRangeBadge({
    super.key,
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _BacktestDateButton extends StatelessWidget {
  const _BacktestDateButton({
    super.key,
    required this.label,
    required this.value,
    required this.caption,
    required this.onTap,
  });

  final String label;
  final String value;
  final String caption;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 9),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RangeContextItem {
  const _RangeContextItem({
    required this.label,
    required this.value,
    this.separator = '：',
  });

  final String label;
  final String value;
  final String separator;

  String get text => '$label$separator$value';
}

class _RangeContextStrip extends StatelessWidget {
  const _RangeContextStrip({
    required this.title,
    required this.subtitle,
    required this.items,
    this.child,
  });

  final String title;
  final String subtitle;
  final List<_RangeContextItem> items;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const _CompactTextBadge(label: '日期可調'),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 8),
            _RangeContextMetricStrip(
              items: items,
            ),
            if (child != null) ...[
              const SizedBox(height: 8),
              child!,
            ],
          ],
        ),
      ),
    );
  }
}

class _RangeContextMetricStrip extends StatelessWidget {
  const _RangeContextMetricStrip({required this.items});

  final List<_RangeContextItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      key: const ValueKey('00631l-range-context-metric-strip'),
      builder: (context, constraints) {
        if (constraints.maxWidth < 380) {
          final tileWidth = (constraints.maxWidth - 8) / 2;
          return Wrap(
            key: const ValueKey('00631l-range-context-wrap'),
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in items)
                SizedBox(
                  width: tileWidth,
                  child: _RangeContextTile(item: item),
                ),
            ],
          );
        }
        return SingleChildScrollView(
          key: const ValueKey('00631l-range-context-scroll'),
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              for (var index = 0; index < items.length; index += 1) ...[
                if (index > 0) const SizedBox(width: 8),
                SizedBox(
                  width: 132,
                  child: _RangeContextTile(item: items[index]),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _RangeContextTile extends StatelessWidget {
  const _RangeContextTile({required this.item});

  final _RangeContextItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
        child: Text(
          item.text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w900,
            height: 1.18,
          ),
        ),
      ),
    );
  }
}

class _PositionSection extends StatefulWidget {
  const _PositionSection({
    required this.data,
    required this.selectedEtf,
  });

  final Etf00631LLabData data;
  final _SelectedEtfViewData selectedEtf;

  @override
  State<_PositionSection> createState() => _PositionSectionState();
}

class _PositionSectionState extends State<_PositionSection> {
  final _sharesController = TextEditingController();
  final _costController = TextEditingController();
  final _assetsController = TextEditingController();
  final _feeController = TextEditingController(text: '0');
  final _noteController = TextEditingController();
  String? _exportJson;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadPosition();
  }

  @override
  void didUpdateWidget(covariant _PositionSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedEtf.code != widget.selectedEtf.code) {
      _loadPosition();
    }
  }

  void _loadPosition() {
    _loaded = false;
    _sharesController.clear();
    _costController.clear();
    _assetsController.clear();
    _feeController.text = '0';
    _noteController.clear();
    PositionStore.loadPosition(widget.selectedEtf.code).then((value) {
      if (!mounted) {
        return;
      }
      if (value != null) {
        final decoded = jsonDecode(value);
        if (decoded is Map) {
          _sharesController.text = decoded['shares']?.toString() ?? '';
          _costController.text = decoded['averageCost']?.toString() ?? '';
          _assetsController.text = decoded['totalAssets']?.toString() ?? '';
          _feeController.text = decoded['feeAndTax']?.toString() ?? '0';
          _noteController.text = decoded['note']?.toString() ?? '';
        }
      }
      setState(() => _loaded = true);
    });
  }

  bool get _showPositionHeader => false;

  @override
  void dispose() {
    _sharesController.dispose();
    _costController.dispose();
    _assetsController.dispose();
    _feeController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final input = _input;
    final summary = EtfPositionSummary.evaluate(
      input: input,
      marketPrice: widget.selectedEtf.marketPrice,
      dataTime: widget.selectedEtf.dataTime,
    );
    final inputForm = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!_loaded) const LinearProgressIndicator(),
        _StatusWrap(
          labels: [
            input.hasPosition ? '持倉資料已輸入' : '尚未輸入持倉',
            '本機保存',
            '目前標的 ${widget.selectedEtf.code}',
            '行情來源 ${_sourceStatusBadgeLabel(widget.selectedEtf.sourceStatusLabel)}',
          ],
        ),
        const SizedBox(height: 8),
        if (!input.hasPosition) ...[
          const _PositionEmptyHintStrip(),
          const SizedBox(height: 8),
        ],
        _InputGrid(
          children: [
            _NumberField(
              key: const ValueKey('00631l-position-field-shares'),
              label: '持有股數',
              controller: _sharesController,
              onChanged: (_) => setState(() {}),
            ),
            _NumberField(
              key: const ValueKey('00631l-position-field-average-cost'),
              label: '平均成本',
              controller: _costController,
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _CompactExpansionPanel(
          key: const ValueKey('00631l-position-advanced-inputs'),
          title: '進階持倉欄位',
          subtitle: '總資產、費用與備註，可選填。',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InputGrid(
                children: [
                  _NumberField(
                    key: const ValueKey('00631l-position-field-assets'),
                    label: '總資產，選填',
                    controller: _assetsController,
                    onChanged: (_) => setState(() {}),
                  ),
                  _NumberField(
                    key: const ValueKey('00631l-position-field-fee'),
                    label: '費用，選填',
                    controller: _feeController,
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _noteController,
                decoration: const InputDecoration(labelText: '備註，選填'),
                minLines: 1,
                maxLines: 2,
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _CompactExpansionPanel(
          title: '估算細節',
          subtitle: input.hasPosition ? '市值、成本、損益與部位比例。' : '輸入股數與成本後顯示完整估算。',
          child: _PositionResultGrid(summary: summary),
        ),
        if (_exportJson != null) ...[
          const SizedBox(height: 12),
          SelectableText(_exportJson!),
        ],
        const SizedBox(height: 10),
        const Text('本區只做持倉資料狀態與估算顯示，非買賣建議。'),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_showPositionHeader)
          _CompactPageTitle(
            title: '本機持倉',
            subtitle: input.hasPosition
                ? '依目前市價估算；資料只保存在本機瀏覽器。'
                : '先輸入股數與平均成本，就能在本機估算持倉狀態。',
            badges: ['本機保存', widget.selectedEtf.code],
          ),
        const SizedBox(height: 8),
        _PositionAccountStrip(
          input: input,
          summary: summary,
          selectedEtf: widget.selectedEtf,
        ),
        if (input.hasPosition) ...[
          const SizedBox(height: 8),
          _PositionActionBar(
            hasPosition: input.hasPosition,
            onSave: _save,
            onExport: _export,
            onClear: _clear,
          ),
        ],
        const SizedBox(height: 12),
        KeyedSubtree(
          key: const ValueKey('00631l-position-compact-input-card'),
          child: input.hasPosition
              ? _CompactExpansionPanel(
                  title: '輸入持倉資料',
                  subtitle: '已保存本機持倉；需要修改股數、成本或備註時再展開。',
                  child: inputForm,
                )
              : _SectionBlock(
                  title: '輸入持倉資料',
                  subtitle: '本機保存，資料留在本機瀏覽器；清除資料後不會保留副本。',
                  child: inputForm,
                ),
        ),
        if (!input.hasPosition) ...[
          const SizedBox(height: 8),
          _PositionActionBar(
            hasPosition: input.hasPosition,
            onSave: _save,
            onExport: _export,
            onClear: _clear,
          ),
        ],
      ],
    );
  }

  EtfPositionInput get _input {
    final totalAssetsText = _assetsController.text.trim();
    return EtfPositionInput(
      shares: _parseDouble(_sharesController.text),
      averageCost: _parseDouble(_costController.text),
      totalAssets:
          totalAssetsText.isEmpty ? null : _parseDouble(totalAssetsText),
      feeAndTax: _parseDouble(_feeController.text),
      note: _noteController.text,
    );
  }

  Future<void> _save() async {
    await PositionStore.savePosition(widget.selectedEtf.code, _encodedInput);
    setState(() => _exportJson = null);
  }

  Future<void> _clear() async {
    await PositionStore.clearPosition(widget.selectedEtf.code);
    _sharesController.clear();
    _costController.clear();
    _assetsController.clear();
    _feeController.text = '0';
    _noteController.clear();
    setState(() => _exportJson = null);
  }

  void _export() {
    setState(() => _exportJson = _encodedInput);
  }

  String get _encodedInput {
    final input = _input;
    return const JsonEncoder.withIndent('  ').convert({
      'symbol': widget.selectedEtf.code,
      'name': widget.selectedEtf.name,
      'storage': 'local_browser_only',
      'shares': input.shares,
      'averageCost': input.averageCost,
      'totalAssets': input.totalAssets,
      'feeAndTax': input.feeAndTax,
      'note': input.note,
    });
  }
}

class _PositionActionBar extends StatelessWidget {
  const _PositionActionBar({
    required this.hasPosition,
    required this.onSave,
    required this.onExport,
    required this.onClear,
  });

  final bool hasPosition;
  final VoidCallback onSave;
  final VoidCallback onExport;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const ValueKey('00631l-position-primary-actions'),
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _PositionQuickAction(
            key: const ValueKey('00631l-position-action-save'),
            icon: Icons.save_outlined,
            label: hasPosition ? '更新' : '保存',
            caption: '本機資料',
            isPrimary: true,
            onTap: onSave,
          ),
          const SizedBox(width: 8),
          _PositionQuickAction(
            key: const ValueKey('00631l-position-action-export'),
            icon: Icons.ios_share_outlined,
            label: 'JSON',
            caption: '匯出',
            onTap: onExport,
          ),
          const SizedBox(width: 8),
          _PositionQuickAction(
            key: const ValueKey('00631l-position-action-clear'),
            icon: Icons.delete_outline,
            label: '清除',
            caption: '本機資料',
            onTap: onClear,
          ),
        ],
      ),
    );
  }
}

class _PositionEmptyHintStrip extends StatelessWidget {
  const _PositionEmptyHintStrip();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      key: const ValueKey('00631l-position-empty-hint-strip'),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.edit_note_outlined,
              size: 18,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '輸入股數與平均成本後，即可顯示市值、損益與部位比例；資料只保存在本機。',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PositionQuickAction extends StatelessWidget {
  const _PositionQuickAction({
    super.key,
    required this.icon,
    required this.label,
    required this.caption,
    required this.onTap,
    this.isPrimary = false,
  });

  final IconData icon;
  final String label;
  final String caption;
  final VoidCallback onTap;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = isPrimary
        ? theme.colorScheme.primaryContainer.withValues(alpha: 0.68)
        : theme.colorScheme.surfaceContainerHighest;
    final foreground = isPrimary
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurface;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: SizedBox(
          width: 96,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
            child: Row(
              children: [
                Icon(icon, size: 16, color: foreground),
                const SizedBox(width: 7),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: foreground.withValues(alpha: 0.76),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PositionAccountStrip extends StatelessWidget {
  const _PositionAccountStrip({
    required this.input,
    required this.summary,
    required this.selectedEtf,
  });

  final EtfPositionInput input;
  final EtfPositionSummary summary;
  final _SelectedEtfViewData selectedEtf;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dataTime = summary.dataTime == null
        ? '暫無'
        : formatTaiwanDateTimeSeconds(summary.dataTime!);
    final unrealizedPctText = summary.unrealizedPnlPct == null
        ? '尚無比例'
        : formatSignedNullablePercent(summary.unrealizedPnlPct);
    final items = [
      _RangeContextItem(
        label: '目前標的',
        value: selectedEtf.code,
        separator: ' ',
      ),
      _RangeContextItem(
        label: '市值',
        value: formatNtdAmount(summary.marketValue),
        separator: ' ',
      ),
      _RangeContextItem(
        label: '未實現損益',
        value: '${formatNtdAmount(summary.unrealizedPnl)} / $unrealizedPctText',
        separator: ' ',
      ),
      _RangeContextItem(
        label: '資料',
        value: input.hasPosition ? '本機已輸入' : '尚未輸入',
        separator: ' ',
      ),
    ];
    return DecoratedBox(
      key: const ValueKey('00631l-position-account-strip'),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '持倉帳戶摘要',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const _CompactTextBadge(label: '本機保存'),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              '不需登入、不會上傳；估算依目前可用行情與資料時間。',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 8),
            _PositionAccountMetricStrip(
              items: items,
            ),
            const SizedBox(height: 8),
            _PositionSourceChipStrip(
              selectedEtf: selectedEtf,
              dataTime: dataTime,
            ),
          ],
        ),
      ),
    );
  }
}

class _PositionSourceChipStrip extends StatelessWidget {
  const _PositionSourceChipStrip({
    required this.selectedEtf,
    required this.dataTime,
  });

  final _SelectedEtfViewData selectedEtf;
  final String dataTime;

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: const ValueKey('00631l-position-source-chip-strip'),
      child: _StatusWrap(
        labels: [
          '行情來源 ${_sourceStatusBadgeLabel(selectedEtf.sourceStatusLabel)}',
          '歷史來源 ${_sourceStatusBadgeLabel(selectedEtf.priceHistory.sourceStatusLabel)}',
          '資料時間 $dataTime',
        ],
      ),
    );
  }
}

class _PositionAccountMetricStrip extends StatelessWidget {
  const _PositionAccountMetricStrip({required this.items});

  final List<_RangeContextItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      key: const ValueKey('00631l-position-account-metric-strip'),
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 460;
        if (isCompact) {
          final tileWidth = (constraints.maxWidth - 8) / 2;
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in items)
                SizedBox(
                  width: tileWidth,
                  child: _RangeContextTile(item: item),
                ),
            ],
          );
        }
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              for (var index = 0; index < items.length; index += 1) ...[
                if (index > 0) const SizedBox(width: 8),
                SizedBox(
                  width: 132,
                  child: _RangeContextTile(item: items[index]),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _PositionResultGrid extends StatelessWidget {
  const _PositionResultGrid({required this.summary});

  final EtfPositionSummary summary;

  @override
  Widget build(BuildContext context) {
    return _ResponsiveMetricGrid(
      cards: [
        _MetricCard(
          label: '目前市值',
          value: formatNtdAmount(summary.marketValue),
          caption: '依 intraday 市價估算',
          icon: Icons.account_balance_wallet_outlined,
        ),
        _MetricCard(
          label: '成本',
          value: formatNtdAmount(summary.cost),
          caption: '股數 x 平均成本 + 費用',
          icon: Icons.receipt_long_outlined,
        ),
        _MetricCard(
          label: '未實現損益',
          value: formatNtdAmount(summary.unrealizedPnl),
          caption: formatSignedNullablePercent(summary.unrealizedPnlPct),
          icon: Icons.insights_outlined,
        ),
        _MetricCard(
          label: '部位比例',
          value: formatNullablePercent(summary.assetWeightPct),
          caption: '需輸入總資產',
          icon: Icons.pie_chart_outline,
        ),
      ],
    );
  }
}

class _AiSectionV2 extends StatelessWidget {
  const _AiSectionV2({
    required this.data,
    required this.selectedEtf,
  });

  final Etf00631LLabData data;
  final _SelectedEtfViewData selectedEtf;

  @override
  Widget build(BuildContext context) {
    if (!selectedEtf.is00631L) {
      return _SelectedEtfAiSection(selectedEtf: selectedEtf);
    }
    final summary = data.aiAnalysis;
    final hiddenBullets =
        summary.bullets.skip(2).map(_aiDisplayText).toList(growable: false);
    final hiddenActions =
        summary.actionItems.skip(1).map(_aiDisplayText).toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AiDailyBriefingHero(data: data, summary: summary),
        const SizedBox(height: 10),
        _CompactExpansionPanel(
          title: '進階 AI 明細',
          subtitle: '來源、矩陣、資料完整性與更多程式操作；需要核對時再展開。',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AiBriefCards(data: data, summary: summary),
              const SizedBox(height: 12),
              _StatusWrap(
                labels: [
                  '分析來源 ${_statusDisplay(summary.source)}',
                  '整體狀態 ${summary.readinessLabel}',
                  summary.disclaimer,
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '產生時間 ${formatTaiwanDateTimeSeconds(summary.generatedAt)}'
                '${summary.dataTime == null ? '' : '；資料時間 ${formatTaiwanDateTimeSeconds(summary.dataTime!)}'}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 12),
              _AiTodaySnapshotPanel(data: data, summary: summary),
              const SizedBox(height: 12),
              _AiDailyInterpretationCard(data: data, summary: summary),
              const SizedBox(height: 12),
              _AiTodayInterpretationMatrix(
                data: data,
                summary: summary,
              ),
              const SizedBox(height: 12),
              _AiDailyStatusPanel(data: data, summary: summary),
              const SizedBox(height: 12),
              _AiSignalGrid(data: data, summary: summary),
              const SizedBox(height: 12),
              if (hiddenBullets.isNotEmpty) ...[
                Text(
                  '更多 AI 摘要',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                for (final bullet in hiddenBullets)
                  _BulletLine(
                    text: bullet,
                    icon: Icons.insights_outlined,
                  ),
                const SizedBox(height: 8),
              ],
              if (hiddenActions.isNotEmpty) ...[
                Text(
                  '更多程式操作',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                for (final action in hiddenActions)
                  _BulletLine(
                    text: action,
                    icon: Icons.task_alt_outlined,
                  ),
                const SizedBox(height: 8),
              ],
              Text(
                '資料完整性',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              for (final bullet in _completeDataBriefing(data))
                _BulletLine(
                  text: _aiDisplayText(bullet),
                  icon: Icons.analytics_outlined,
                ),
              const SizedBox(height: 8),
              const Text('非買賣建議'),
            ],
          ),
        ),
      ],
    );
  }
}

// ignore: unused_element
class _AiSection extends StatelessWidget {
  const _AiSection({
    required this.data,
    required this.selectedEtf,
  });

  final Etf00631LLabData data;
  final _SelectedEtfViewData selectedEtf;

  @override
  Widget build(BuildContext context) {
    if (!selectedEtf.is00631L) {
      return _SelectedEtfAiSection(selectedEtf: selectedEtf);
    }
    final summary = data.aiAnalysis;
    final visibleBullets =
        summary.bullets.take(3).map(_aiDisplayText).toList(growable: false);
    final visibleActions = summary.actionItems.isEmpty
        ? const ['目前沒有程式操作項目；請保留資料時間檢查。']
        : summary.actionItems
            .take(3)
            .map(_aiDisplayText)
            .toList(growable: false);
    final hiddenBullets =
        summary.bullets.skip(3).map(_aiDisplayText).toList(growable: false);
    final hiddenActions =
        summary.actionItems.skip(3).map(_aiDisplayText).toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AiDailyBriefingHero(data: data, summary: summary),
        const SizedBox(height: 12),
        _SectionBlock(
          title: '今日 AI 快覽',
          subtitle: '規則分析；聚焦今日資料時間、內容物、折溢價偏離與維護狀態。',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AiBriefCards(data: data, summary: summary),
              const SizedBox(height: 12),
              _StatusWrap(
                labels: [
                  '分析來源 ${_statusDisplay(summary.source)}',
                  '整體狀態 ${summary.readinessLabel}',
                  summary.disclaimer,
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '產生時間 ${formatTaiwanDateTimeSeconds(summary.generatedAt)}'
                '${summary.dataTime == null ? '' : '，資料時間 ${formatTaiwanDateTimeSeconds(summary.dataTime!)}'}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SectionBlock(
          title: '今日 AI 分析摘要',
          subtitle: '摘要只描述當日資料狀態、內容物變化與價格偏離；完整資料放在展開區。',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '今日重點',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 8),
              for (final bullet in visibleBullets)
                _BulletLine(text: bullet, icon: Icons.insights_outlined),
              const SizedBox(height: 8),
              Text(
                '程式操作項目',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              for (final action in visibleActions)
                _BulletLine(text: action, icon: Icons.task_alt_outlined),
              const SizedBox(height: 12),
              _CompactExpansionPanel(
                title: '進階 AI 明細',
                subtitle: '展開查看判讀矩陣、資料狀態、完整日報與資料完整度。',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _AiTodaySnapshotPanel(data: data, summary: summary),
                    const SizedBox(height: 12),
                    _AiDailyInterpretationCard(data: data, summary: summary),
                    const SizedBox(height: 12),
                    _AiTodayInterpretationMatrix(
                      data: data,
                      summary: summary,
                    ),
                    const SizedBox(height: 12),
                    _AiDailyStatusPanel(data: data, summary: summary),
                    const SizedBox(height: 12),
                    _AiSignalGrid(data: data, summary: summary),
                    const SizedBox(height: 12),
                    if (hiddenBullets.isNotEmpty) ...[
                      Text(
                        '其餘 AI 條目',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      for (final bullet in hiddenBullets)
                        _BulletLine(
                          text: bullet,
                          icon: Icons.insights_outlined,
                        ),
                      const SizedBox(height: 8),
                    ],
                    if (hiddenActions.isNotEmpty) ...[
                      Text(
                        '其餘程式操作',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      for (final action in hiddenActions)
                        _BulletLine(
                          text: action,
                          icon: Icons.task_alt_outlined,
                        ),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      '完整資料摘要',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    for (final bullet in _completeDataBriefing(data))
                      _BulletLine(
                        text: _aiDisplayText(bullet),
                        icon: Icons.analytics_outlined,
                      ),
                    const SizedBox(height: 8),
                    const Text('非買賣建議。'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AiDailyBriefingHero extends StatelessWidget {
  const _AiDailyBriefingHero({
    required this.data,
    required this.summary,
  });

  final Etf00631LLabData data;
  final EtfAiAnalysisSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nav = data.intradayNav;
    final snapshot = data.snapshot;
    final premium = nav?.premiumDiscountAssessment;
    final txWeight = snapshot.futuresHoldings
        .where((line) => line.code.toUpperCase().contains('TX'))
        .fold<double>(0, (sum, line) => sum + line.weightPct);
    final tsmcWeight = snapshot.stockHoldings
        .where((line) => line.code == '2330')
        .fold<double>(0, (sum, line) => sum + line.weightPct);
    final primaryAction = summary.actionItems.isEmpty
        ? '目前沒有必要的程式操作；請持續確認官方資料時間。'
        : _aiDisplayText(summary.actionItems.first);
    final premiumText = premium == null
        ? '盤中 NAV 暫時不可用，折溢價狀態無法判斷。'
        : _premiumDescription(premium);
    final statusColor = _aiStatusColor(context, summary, premium);
    final briefingBullets =
        summary.bullets.take(2).map(_aiDisplayText).toList(growable: false);
    final priceSummary = data.priceHistory.completenessSummary();
    final todayReadouts = [
      _AiTodayReadoutItem(
        label: '當日資料',
        detail:
            '官方內容物 ${_dateOrDash(snapshot.tradeDate)}；盤中 NAV ${_intradayDataTimeText(nav)}。每日快照與盤中估算分開判讀。',
      ),
      _AiTodayReadoutItem(
        label: '價格偏離',
        detail: premiumText,
      ),
      _AiTodayReadoutItem(
        label: '結構觀察',
        detail:
            'TX ${formatNullablePercent(txWeight)}；台積電 ${formatNullablePercent(tsmcWeight)}；歷史價格 ${formatInteger(priceSummary.rowCount)} 筆。',
      ),
    ];

    return DecoratedBox(
      key: const ValueKey('00631l-ai-daily-briefing-hero'),
      decoration: BoxDecoration(
        color: _marketPanelColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _marketBorderColor(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const _MiniStatusBadge(label: 'AI'),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '今日 AI 判讀',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: _marketTextColor(context),
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                const _CompactTextBadge(label: '規則分析'),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '依據官方每日內容物、盤中 NAV、歷史資料與維護狀態產生摘要。非買賣建議。',
              key: const ValueKey('00631l-ai-daily-briefing-disclaimer'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: _marketMutedTextColor(context),
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            _StatusWrap(
              labels: [
                '內容物 ${_dateOrDash(snapshot.tradeDate)}',
                'NAV ${_intradayDataTimeText(nav)}',
                '來源 ${_sourceStatusBadgeLabel(summary.sourceStatusLabel)}',
              ],
            ),
            const SizedBox(height: 10),
            _AiDailyConclusionCard(
              data: data,
              summary: summary,
              premiumText: premiumText,
            ),
            const SizedBox(height: 10),
            _AiDailyDecisionStrip(
              data: data,
              summary: summary,
              premiumText: premiumText,
              primaryAction: primaryAction,
            ),
            const SizedBox(height: 10),
            _CompactExpansionPanel(
              key: const ValueKey('00631l-ai-daily-detail-expansion'),
              title: 'AI 資料細節',
              subtitle: '資料狀態、當日讀數與歷史來源；需要核對時再展開。',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.45),
                      ),
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Text(
                      '資料狀態為 ${summary.readinessLabel}。$premiumText '
                      '官方 內容物 更新至 ${_dateOrDash(snapshot.tradeDate)}；'
                      'TX 權重 ${formatNullablePercent(txWeight)}，'
                      '台積電權重 ${formatNullablePercent(tsmcWeight)}。',
                      key: const ValueKey('00631l-ai-daily-briefing-summary'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: _marketTextColor(context),
                        height: 1.35,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  DecoratedBox(
                    key: const ValueKey('00631l-ai-today-readout'),
                    decoration: BoxDecoration(
                      color: _marketPanelAltColor(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _marketBorderColor(context)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        children: [
                          for (var index = 0;
                              index < todayReadouts.length;
                              index += 1) ...[
                            if (index > 0) const SizedBox(height: 8),
                            _AiTodayReadoutRow(item: todayReadouts[index]),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (briefingBullets.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    DecoratedBox(
                      key: const ValueKey('00631l-ai-daily-briefing-bullets'),
                      decoration: BoxDecoration(
                        color: _marketPanelAltColor(context),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _marketBorderColor(context)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '當日判讀',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: _marketTextColor(context),
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 6),
                            for (final bullet in briefingBullets)
                              _BulletLine(
                                text: bullet,
                                icon: Icons.analytics_outlined,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 640;
                      final factCards = [
                        _AiDailyBriefingFact(
                          label: '內容物',
                          value: 'TX ${formatNullablePercent(txWeight)}',
                          detail:
                              '台積電 ${formatNullablePercent(tsmcWeight)}；官方每日快照',
                        ),
                        _AiDailyBriefingFact(
                          label: '盤中 NAV',
                          value: formatSignedNullablePercent(
                            nav?.resolvedPremiumDiscountPct,
                          ),
                          detail: _intradayDataTimeText(nav),
                        ),
                        _AiDailyBriefingFact(
                          label: '歷史資料',
                          value:
                              '${formatInteger(data.priceHistory.completenessSummary().rowCount)} 筆',
                          detail: _sourceStatusBadgeLabel(
                            data.priceHistory.sourceStatusLabel,
                          ),
                        ),
                      ];
                      if (compact) {
                        return Row(
                          key: const ValueKey('00631l-ai-daily-fact-row'),
                          children: [
                            for (var index = 0;
                                index < factCards.length;
                                index += 1)
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    left: index == 0 ? 0 : 4,
                                    right:
                                        index == factCards.length - 1 ? 0 : 4,
                                  ),
                                  child: factCards[index],
                                ),
                              ),
                          ],
                        );
                      }
                      final itemWidth = compact
                          ? constraints.maxWidth
                          : (constraints.maxWidth - 16) / 3;
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final card in factCards)
                            SizedBox(width: itemWidth, child: card),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '程式操作',
              style: theme.textTheme.titleSmall?.copyWith(
                color: _marketTextColor(context),
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            _BulletLine(text: primaryAction, icon: Icons.task_alt_outlined),
          ],
        ),
      ),
    );
  }
}

class _AiDailyConclusionCard extends StatelessWidget {
  const _AiDailyConclusionCard({
    required this.data,
    required this.summary,
    required this.premiumText,
  });

  final Etf00631LLabData data;
  final EtfAiAnalysisSummary summary;
  final String premiumText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final price = data.priceHistory.completenessSummary();
    final coverage = price.coverageStart == null || price.coverageEnd == null
        ? '資料區間暫無'
        : '${_dateOrDash(price.coverageStart)} 至 ${_dateOrDash(price.coverageEnd)}';
    final latestMove = formatSignedNullablePercent(price.latestDailyReturnPct);
    final dataTime = [
      '內容物 ${_dateOrDash(data.snapshot.tradeDate)}',
      '盤中 NAV ${_intradayDataTimeText(data.intradayNav)}',
    ].join('，');

    return DecoratedBox(
      key: const ValueKey('00631l-ai-daily-conclusion'),
      decoration: BoxDecoration(
        color: _marketPanelAltColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _marketBorderColor(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '當日資料判讀',
              style: theme.textTheme.titleSmall?.copyWith(
                color: _marketTextColor(context),
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '資料時間：$dataTime。',
              style: theme.textTheme.bodySmall?.copyWith(
                color: _marketTextColor(context),
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '折溢價：$premiumText',
              style: theme.textTheme.bodySmall?.copyWith(
                color: _marketTextColor(context),
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '歷史資料：${formatInteger(price.rowCount)} 筆，區間 $coverage，最近一日 $latestMove。',
              style: theme.textTheme.bodySmall?.copyWith(
                color: _marketTextColor(context),
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '目前分析來源 ${_sourceStatusBadgeLabel(summary.sourceStatusLabel)}；只解讀資料狀態與歷史變化，非投資建議。',
              style: theme.textTheme.bodySmall?.copyWith(
                color: _marketMutedTextColor(context),
                height: 1.35,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiDailyDecisionStrip extends StatelessWidget {
  const _AiDailyDecisionStrip({
    required this.data,
    required this.summary,
    required this.premiumText,
    required this.primaryAction,
  });

  final Etf00631LLabData data;
  final EtfAiAnalysisSummary summary;
  final String premiumText;
  final String primaryAction;

  @override
  Widget build(BuildContext context) {
    final price = data.priceHistory.completenessSummary();
    final coverage = price.coverageStart == null || price.coverageEnd == null
        ? '資料範圍暫無'
        : '${_dateOrDash(price.coverageStart)} - ${_dateOrDash(price.coverageEnd)}';
    final items = [
      _AiDailyDecisionItem(
        label: '今日資料',
        value:
            '內容物 ${_dateOrDash(data.snapshot.tradeDate)}；NAV ${_intradayDataTimeText(data.intradayNav)}',
      ),
      _AiDailyDecisionItem(
        label: '偏離判讀',
        value: premiumText,
      ),
      _AiDailyDecisionItem(
        label: '歷史資料',
        value: '${formatInteger(price.rowCount)} 筆；$coverage',
      ),
      _AiDailyDecisionItem(
        label: '後續操作',
        value: primaryAction,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 620;
        return Wrap(
          key: const ValueKey('00631l-ai-daily-decision-strip'),
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in items)
              SizedBox(
                width: compact
                    ? constraints.maxWidth
                    : (constraints.maxWidth - 8) / 2,
                child: _AiDailyDecisionTile(item: item),
              ),
          ],
        );
      },
    );
  }
}

class _AiDailyDecisionItem {
  const _AiDailyDecisionItem({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;
}

class _AiDailyDecisionTile extends StatelessWidget {
  const _AiDailyDecisionTile({required this.item});

  final _AiDailyDecisionItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _marketPanelAltColor(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _marketBorderColor(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: _marketMutedTextColor(context),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item.value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: _marketTextColor(context),
                height: 1.3,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiDailyBriefingFact extends StatelessWidget {
  const _AiDailyBriefingFact({
    required this.label,
    required this.value,
    required this.detail,
  });

  final String label;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _marketPanelAltColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _marketBorderColor(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: _marketMutedTextColor(context),
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                color: _marketTextColor(context),
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              detail,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: _marketMutedTextColor(context),
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiTodayReadoutItem {
  const _AiTodayReadoutItem({
    required this.label,
    required this.detail,
  });

  final String label;
  final String detail;
}

class _AiTodayReadoutRow extends StatelessWidget {
  const _AiTodayReadoutRow({required this.item});

  final _AiTodayReadoutItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 68,
          child: Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            item.detail,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: _marketTextColor(context),
              height: 1.3,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

Color _aiStatusColor(
  BuildContext context,
  EtfAiAnalysisSummary summary,
  PremiumDiscountAssessment? premium,
) {
  final label =
      '${summary.readinessLabel} ${summary.sourceStatusLabel} ${premium?.level.name ?? ''}'
          .toLowerCase();
  if (label.contains('error') ||
      label.contains('unavailable') ||
      label.contains('extreme') ||
      label.contains('stale')) {
    return _marketRed;
  }
  if (label.contains('watch') ||
      label.contains('elevated') ||
      label.contains('warn') ||
      label.contains('觀察')) {
    return const Color(0xFFFBBF24);
  }
  return _marketGreen;
}

class _AiTodayInterpretationMatrix extends StatelessWidget {
  const _AiTodayInterpretationMatrix({
    required this.data,
    required this.summary,
  });

  final Etf00631LLabData data;
  final EtfAiAnalysisSummary summary;

  @override
  Widget build(BuildContext context) {
    final nav = data.intradayNav;
    final session = nav?.marketSession() ??
        IntradayMarketSession.evaluate(sourceAvailable: false);
    final premium = nav?.premiumDiscountAssessment;
    final holdings = data.holdingsHistory.trendSummary().latest;
    final price = data.priceHistory.completenessSummary();
    final items = [
      _AiInterpretationItem(
        label: '資料新鮮度',
        value: session.dataFreshnessLabel,
        detail:
            'NAV ${_intradayDataTimeText(nav)}；holdings ${formatTaiwanDate(data.snapshot.tradeDate)}。',
        status: session.dataFreshness,
      ),
      _AiInterpretationItem(
        label: '折溢價狀態',
        value: premium?.label ?? '資料不足',
        detail:
            premium == null ? '目前沒有可判斷的盤中折溢價資料。' : _premiumDescription(premium),
        status: premium?.level.name ?? 'unavailable',
      ),
      _AiInterpretationItem(
        label: '內容物變化',
        value: holdings == null ? '歷史不足' : '已累積',
        detail: holdings == null
            ? '尚未累積內容物紀錄，請先執行每日流程。'
            : 'TX ${formatNullablePercent(holdings.txWeightPct)}；台積電 ${formatNullablePercent(holdings.tsmcWeightPct)}；股票/期貨 ${formatNullablePercent(holdings.stockExposurePct)} / ${formatNullablePercent(holdings.futuresExposurePct)}。',
        status: holdings == null
            ? 'unavailable'
            : data.holdingsHistory.sourceStatusLabel,
      ),
      _AiInterpretationItem(
        label: '歷史範圍',
        value: '${formatInteger(price.rowCount)} 筆',
        detail:
            '${_dateOrDash(price.coverageStart)} - ${_dateOrDash(price.coverageEnd)}；${price.isCompleteFromListing ? '上市日起完整' : '目前為部分區間'}。',
        status: data.priceHistory.sourceStatusLabel,
      ),
    ];

    return KeyedSubtree(
      key: const ValueKey('00631l-ai-interpretation-matrix'),
      child: _SectionBlock(
        title: '今日判讀矩陣',
        subtitle: '規則分析將今日資料拆成可檢查的四個面向；只描述資料狀態。',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 720;
                final width = compact
                    ? constraints.maxWidth
                    : (constraints.maxWidth - 8) / 2;
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final item in items)
                      SizedBox(
                        width: width,
                        child: _AiInterpretationTile(item: item),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
            Text(
              '${summary.disclaimer}；請以官方資料時間為準。',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: _marketMutedTextColor(context),
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiInterpretationItem {
  const _AiInterpretationItem({
    required this.label,
    required this.value,
    required this.detail,
    required this.status,
  });

  final String label;
  final String value;
  final String detail;
  final String status;
}

class _AiInterpretationTile extends StatelessWidget {
  const _AiInterpretationTile({required this.item});

  final _AiInterpretationItem item;

  @override
  Widget build(BuildContext context) {
    final normalized = item.status.toLowerCase();
    final color = normalized.contains('official') ||
            normalized.contains('fresh') ||
            normalized.contains('normal') ||
            normalized.contains('cached') ||
            normalized.contains('已')
        ? _marketGreen
        : normalized.contains('warn') ||
                normalized.contains('stale') ||
                normalized.contains('watch') ||
                normalized.contains('elevated')
            ? const Color(0xFFFBBF24)
            : normalized.contains('error') ||
                    normalized.contains('unavailable') ||
                    normalized.contains('extreme')
                ? _marketRed
                : _marketBlue;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _marketPanelAltColor(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _marketBorderColor(context)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(10),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: _marketMutedTextColor(context),
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.value,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: _marketTextColor(context),
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.detail,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: _marketMutedTextColor(context),
                            height: 1.25,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiTodaySnapshotPanel extends StatelessWidget {
  const _AiTodaySnapshotPanel({
    required this.data,
    required this.summary,
  });

  final Etf00631LLabData data;
  final EtfAiAnalysisSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bullets = _aiTodaySnapshotBullets(data, summary)
        .map(_aiDisplayText)
        .toList(growable: false);
    final action = summary.actionItems.isEmpty
        ? '目前沒有程式操作項目；請保留資料時間檢查。'
        : _aiDisplayText(summary.actionItems.first);
    return DecoratedBox(
      key: const ValueKey('00631l-ai-today-snapshot'),
      decoration: BoxDecoration(
        color: _marketPanelColor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _marketBorderColor(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const _MiniStatusBadge(label: 'AI'),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '今日 AI 資料解讀',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: _marketTextColor(context),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const _CompactTextBadge(label: '規則分析'),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '只整理資料狀態、內容物、折溢價與資料風險；非買賣建議。',
              style: theme.textTheme.bodySmall?.copyWith(
                color: _marketMutedTextColor(context),
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            for (final bullet in bullets)
              _BulletLine(text: bullet, icon: Icons.insights_outlined),
            const SizedBox(height: 8),
            _BulletLine(text: '程式操作：$action', icon: Icons.task_alt_outlined),
          ],
        ),
      ),
    );
  }
}

class _AiDailyInterpretationCard extends StatelessWidget {
  const _AiDailyInterpretationCard({
    required this.data,
    required this.summary,
  });

  final Etf00631LLabData data;
  final EtfAiAnalysisSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final snapshot = data.snapshot;
    final nav = data.intradayNav;
    final txWeight = snapshot.futuresHoldings
        .where((line) => line.code.toUpperCase().contains('TX'))
        .fold<double>(0, (sum, line) => sum + line.weightPct);
    final tsmcWeight = snapshot.stockHoldings
        .where((line) => line.code == '2330')
        .fold<double>(0, (sum, line) => sum + line.weightPct);
    final premium = nav?.premiumDiscountAssessment;
    final firstAction = summary.actionItems.isEmpty
        ? '目前沒有程式操作項目；請保留資料時間檢查。'
        : summary.actionItems.first;
    return DecoratedBox(
      key: const ValueKey('00631l-ai-daily-interpretation-card'),
      decoration: BoxDecoration(
        color:
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome_outlined,
                  color: theme.colorScheme.primary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '當日資料解讀',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const _CompactTextBadge(label: '非買賣建議'),
              ],
            ),
            const SizedBox(height: 8),
            _StatusWrap(
              labels: [
                '內容物 ${_dateOrDash(snapshot.tradeDate)}',
                'NAV ${_intradayDataTimeText(nav)}',
                premium?.label ?? '折溢價資料不足',
                '分析來源 ${_statusDisplay(summary.source)}',
              ],
            ),
            const SizedBox(height: 10),
            _BulletLine(
              text:
                  '官方每日內容物顯示 TX 權重 ${formatNullablePercent(txWeight)}、台積電 ${formatNullablePercent(tsmcWeight)}、現金與保證金 ${formatNullablePercent(snapshot.cashAndMarginWeightPct)}。',
              icon: Icons.account_tree_outlined,
            ),
            const _BulletLine(
              text: '盤中觀察以市價、預估淨值與折溢價為主；內容物仍以官方每日快照時間為準。',
              icon: Icons.schedule_outlined,
            ),
            _BulletLine(
              text: '程式操作：$firstAction',
              icon: Icons.task_alt_outlined,
            ),
          ],
        ),
      ),
    );
  }
}

class _AiBriefCards extends StatelessWidget {
  const _AiBriefCards({required this.data, required this.summary});

  final Etf00631LLabData data;
  final EtfAiAnalysisSummary summary;

  @override
  Widget build(BuildContext context) {
    final dailyBrief = _findAnalysisBullet(summary, '當日重點') ??
        (summary.bullets.isEmpty ? '今日資料仍在載入或不足。' : summary.bullets.first);
    final premiumAssessment = data.intradayNav?.premiumDiscountAssessment;
    final intradayBrief = _findAnalysisBullet(summary, '盤中折溢價最新') ??
        '盤中 NAV ${_intradayDataTimeText(data.intradayNav)}；${premiumAssessment == null ? '目前沒有可判斷的盤中偏離資料。' : _premiumDescription(premiumAssessment)}';
    final riskBrief = _findAnalysisBullet(summary, '資料風險') ??
        '資料來源 ${_sourceStatusBadgeLabel(summary.sourceStatusLabel)}；若資料過期、錯誤或不可用，先檢查後端與來源時間。';

    final cards = [
      _AiBriefTile(
        key: const ValueKey('00631l-ai-daily-brief'),
        label: '當日重點',
        value: _aiDisplayText(dailyBrief),
        icon: Icons.today_outlined,
      ),
      _AiBriefTile(
        key: const ValueKey('00631l-ai-intraday-brief'),
        label: '盤中偏離',
        value: _aiDisplayText(intradayBrief),
        icon: Icons.price_change_outlined,
      ),
      _AiBriefTile(
        key: const ValueKey('00631l-ai-risk-brief'),
        label: '資料風險',
        value: _aiDisplayText(riskBrief),
        icon: Icons.health_and_safety_outlined,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 720) {
          return Column(
            children: [
              for (var index = 0; index < cards.length; index += 1) ...[
                if (index > 0) const SizedBox(height: 8),
                cards[index],
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var index = 0; index < cards.length; index += 1) ...[
              if (index > 0) const SizedBox(width: 8),
              Expanded(child: cards[index]),
            ],
          ],
        );
      },
    );
  }
}

class _AiBriefTile extends StatelessWidget {
  const _AiBriefTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color:
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  icon,
                  size: 18,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiDailyStatusPanel extends StatelessWidget {
  const _AiDailyStatusPanel({required this.data, required this.summary});

  final Etf00631LLabData data;
  final EtfAiAnalysisSummary summary;

  @override
  Widget build(BuildContext context) {
    final price = data.priceHistory.completenessSummary();
    final intradayTime = _intradayDataTimeText(data.intradayNav);
    final holdingsDate = _dateOrDash(_latestHoldingsDate(data));
    final generatedAt = formatTaiwanDateTimeSeconds(summary.generatedAt);
    final dataTime = summary.dataTime == null
        ? 'unavailable'
        : formatTaiwanDateTimeSeconds(summary.dataTime!);
    final actions = summary.actionItems.isEmpty
        ? const ['目前沒有程式操作項目；請保留資料時間檢查。']
        : summary.actionItems.take(3).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '今日資料狀態',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 8),
        _BulletLine(
          text:
              '整體狀態 ${summary.readinessLabel}；後端 ${data.operationsStatus.backendConnectionLabel}；歷史資料 ${_sourceStatusBadgeLabel(data.priceHistory.sourceStatusLabel)}。',
          icon: Icons.fact_check_outlined,
        ),
        _BulletLine(
          text: '官方每日內容物日期 $holdingsDate；盤中 NAV 資料時間 $intradayTime；兩者更新頻率不同。',
          icon: Icons.schedule_outlined,
        ),
        const SizedBox(height: 10),
        Text(
          '資料來源與時間',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 8),
        _BulletLine(
          text:
              'AI 來源 ${_statusDisplay(summary.source)}；分析產生時間 $generatedAt；分析資料時間 $dataTime。',
          icon: Icons.psychology_alt_outlined,
        ),
        _BulletLine(
          text:
              '歷史價格範圍 ${_dateOrDash(price.coverageStart)} - ${_dateOrDash(price.coverageEnd)}，共 ${formatInteger(price.rowCount)} 筆。',
          icon: Icons.timeline_outlined,
        ),
        const SizedBox(height: 10),
        Text(
          '缺口與下一步',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 8),
        for (final action in actions)
          _BulletLine(text: action, icon: Icons.task_alt_outlined),
      ],
    );
  }
}

class _SelectedEtfAiSection extends StatelessWidget {
  const _SelectedEtfAiSection({required this.selectedEtf});

  final _SelectedEtfViewData selectedEtf;

  @override
  Widget build(BuildContext context) {
    final history = selectedEtf.priceHistory.completenessSummary();
    final performance = selectedEtf.priceHistory.performance;
    final latestDate = _dateOrDash(history.latest?.date);
    final priceField = history.hasAdjustedClose ? 'adjustedClose' : 'close';
    final adjustmentLabel = history.hasNonUnitAdjustment
        ? '已辨識'
        : history.hasAdjustedClose
            ? '調整價可用'
            : '未套用';
    final bullets = _selectedEtfAnalysisBullets(selectedEtf)
        .map(_aiDisplayText)
        .toList(growable: false);
    final actions = _selectedEtfProgramActions(selectedEtf)
        .map(_aiDisplayText)
        .toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeaderCard(
          title: '${selectedEtf.code} AI 快覽',
          subtitle: '規則分析；只解釋目前已載入的 ETF 清單與歷史資料。',
          icon: Icons.psychology_alt_outlined,
          badges: [
            'AI',
            '規則分析',
            _sourceStatusBadgeLabel(selectedEtf.sourceStatusLabel),
          ],
          metrics: [
            _SectionHeaderMetric(
              label: '資料筆數',
              value: formatInteger(history.rowCount),
            ),
            _SectionHeaderMetric(
              label: '最新交易日',
              value: latestDate,
            ),
            _SectionHeaderMetric(
              label: '最新收盤',
              value: _price(history.latest?.close),
            ),
            _SectionHeaderMetric(
              label: '日變動',
              value: formatSignedNullablePercent(history.latestDailyReturnPct),
            ),
            _SectionHeaderMetric(
              label: '回撤',
              value: formatSignedNullablePercent(performance.maxDrawdownPct),
            ),
            const _SectionHeaderMetric(
              label: '性質',
              value: '非買賣建議',
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SelectedEtfDataContextCard(selectedEtf: selectedEtf),
        const SizedBox(height: 12),
        _SectionBlock(
          title: '${selectedEtf.code} 資料解讀摘要',
          subtitle: '目前不需要 API key；資料不足時只提示缺口。',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StatusWrap(
                labels: [
                  '來源 規則分析',
                  'ETF ${selectedEtf.code}',
                  _sourceStatusBadgeLabel(selectedEtf.sourceStatusLabel),
                  '價格欄位 $priceField',
                  '分割調整 $adjustmentLabel',
                  '非買賣建議',
                ],
              ),
              const SizedBox(height: 12),
              for (final bullet in bullets)
                _BulletLine(text: bullet, icon: Icons.insights_outlined),
              const SizedBox(height: 8),
              Text(
                '程式操作',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 8),
              for (final action in actions)
                _BulletLine(text: action, icon: Icons.task_alt_outlined),
            ],
          ),
        ),
      ],
    );
  }
}

class _AiSignalGrid extends StatelessWidget {
  const _AiSignalGrid({required this.data, required this.summary});

  final Etf00631LLabData data;
  final EtfAiAnalysisSummary summary;

  @override
  Widget build(BuildContext context) {
    final nav = data.intradayNav;
    final snapshot = data.snapshot;
    final txLine = snapshot.futuresHoldings
        .where((line) => line.code.toUpperCase().contains('TX'))
        .fold<double>(0, (sum, line) => sum + line.weightPct);
    final tsmcLine = snapshot.stockHoldings
        .where((line) => line.code == '2330')
        .fold<double>(0, (sum, line) => sum + line.weightPct);
    return _ResponsiveMetricGrid(
      cards: [
        _MetricCard(
          label: '資料狀態',
          value: summary.readinessLabel,
          caption: '來源 ${_sourceStatusBadgeLabel(summary.sourceStatusLabel)}',
          icon: Icons.verified_outlined,
        ),
        _MetricCard(
          label: '內容物重點',
          value: 'TX ${formatNullablePercent(txLine)}',
          caption: '台積電 ${formatNullablePercent(tsmcLine)}',
          icon: Icons.account_tree_outlined,
        ),
        _MetricCard(
          label: '折溢價',
          value: formatSignedNullablePercent(nav?.resolvedPremiumDiscountPct),
          caption: nav?.premiumDiscountAssessment.label ?? '資料不足',
          icon: Icons.price_change_outlined,
        ),
        _MetricCard(
          label: '程式操作',
          value: '${summary.actionItems.length} 項',
          caption: data.operationsStatus.dailyCycleStatus,
          icon: Icons.task_alt_outlined,
        ),
      ],
    );
  }
}

enum _EtfCatalogFilter {
  focus('常用', Icons.star_border_outlined),
  taiwanEquity('台股', Icons.stacked_line_chart_outlined),
  dividend('高股息', Icons.payments_outlined),
  leveraged('槓桿/反向', Icons.compare_arrows_outlined),
  all('全部', Icons.dataset_outlined);

  const _EtfCatalogFilter(this.label, this.icon);

  final String label;
  final IconData icon;
}

class _EtfCatalogSection extends StatefulWidget {
  const _EtfCatalogSection({required this.data, required this.onEtfSelected});

  final Etf00631LLabData data;
  final ValueChanged<String> onEtfSelected;

  @override
  State<_EtfCatalogSection> createState() => _EtfCatalogSectionState();
}

class _EtfCatalogSectionState extends State<_EtfCatalogSection> {
  final _queryController = TextEditingController();
  _EtfCatalogFilter _filter = _EtfCatalogFilter.focus;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = widget.data.etfCatalog;
    final status = widget.data.operationsStatus;
    final rowCount =
        catalog.hasData ? catalog.rowCount : status.etfCatalogRowCount;
    final dataTime = catalog.dataTime ?? status.etfCatalogDataTime;
    final readyHistoryCount = _searchReadyHistoryCount(widget.data);
    final filteredItems = _filteredItems(catalog);
    final visibleItems = filteredItems.take(60).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeaderCard(
          title: 'ETF 資料庫',
          subtitle: '整理 TWSE 全 ETF 清單；可搜尋並切換 ETF，歷史比較在歷史回測頁使用。',
          icon: Icons.dataset_outlined,
          badges: [
            'ETF',
            'catalog ${catalog.sourceStatusLabel}',
            _frontendDataMode,
          ],
          metrics: [
            _SectionHeaderMetric(
              label: 'ETF 筆數',
              value: formatInteger(rowCount),
            ),
            _SectionHeaderMetric(
              label: '資料時間',
              value: dataTime == null
                  ? 'unavailable'
                  : formatTaiwanDateTimeSeconds(dataTime),
            ),
            _SectionHeaderMetric(
              label: '目前篩選',
              value: _filter.label,
            ),
            _SectionHeaderMetric(
              label: '顯示筆數',
              value: formatInteger(visibleItems.length),
            ),
            _SectionHeaderMetric(
              label: '歷史可用',
              value: formatInteger(readyHistoryCount),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _EtfDataLibrarySummary(
          key: const ValueKey('00631l-etf-data-completion-strip'),
          data: widget.data,
          compact: true,
        ),
        const SizedBox(height: 12),
        _SectionBlock(
          title: 'ETF 查詢',
          subtitle: '可用代號、名稱或商品類型搜尋；有歷史資料的 ETF 可切換後查看歷史、回測與比較。',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                key: const ValueKey('00631l-etf-catalog-search'),
                controller: _queryController,
                onChanged: (_) => setState(() {}),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _queryController.text.trim().isEmpty
                      ? null
                      : IconButton(
                          tooltip: '清除搜尋',
                          onPressed: () {
                            _queryController.clear();
                            setState(() {});
                          },
                          icon: const Icon(Icons.close),
                        ),
                  labelText: '搜尋 ETF',
                  hintText: '例如 0050、00631L、高股息',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final filter in _EtfCatalogFilter.values)
                    ChoiceChip(
                      key: ValueKey('00631l-etf-filter-${filter.name}'),
                      selected: _filter == filter,
                      avatar: Icon(filter.icon, size: 16),
                      label: Text(filter.label),
                      onSelected: (_) => setState(() => _filter = filter),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              _StatusWrap(
                labels: [
                  'source ${catalog.sourceStatusLabel}',
                  catalog.sourceContract,
                  if (catalog.errorMessage != null)
                    'error ${catalog.errorMessage}',
                  '顯示 ${visibleItems.length} / ${filteredItems.length}',
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SectionBlock(
          title: 'ETF 清單',
          subtitle: '重點是代號、名稱、狀態、價格與折溢價；不使用無意義裝飾圖示。',
          child: catalog.hasData
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (visibleItems.isEmpty)
                      const _EmptyPanel(
                        title: '查無符合 ETF',
                        message: '請調整搜尋文字或切換分類。',
                      )
                    else ...[
                      for (final item in visibleItems) ...[
                        _EtfCatalogItemTile(
                          key: ValueKey('00631l-etf-list-item-${item.code}'),
                          item: item,
                          onSelected: widget.onEtfSelected,
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (filteredItems.length > visibleItems.length)
                        _StatusWrap(
                          labels: [
                            '已先顯示前 ${visibleItems.length} 筆',
                            '可輸入代號或名稱縮小範圍',
                          ],
                        ),
                    ],
                  ],
                )
              : const _EmptyPanel(
                  title: 'ETF 清單暫不可用',
                  message: '公開後端可提供 ETF 清單；公開靜態模式仍保留 00631L 歷史與回測。',
                ),
        ),
        const SizedBox(height: 12),
        _SectionBlock(
          title: 'ETF 清單快覽',
          subtitle: '只對照 catalog snapshot 的行情與 NAV；長期績效比較請到歷史回測頁自選 1-5 檔。',
          child: _EtfComparisonPreview(catalog: catalog),
        ),
      ],
    );
  }

  List<EtfCatalogItem> _filteredItems(EtfCatalog catalog) {
    final query = _queryController.text.trim().toLowerCase();
    final base = _baseItems(catalog);
    if (query.isEmpty) {
      return base;
    }
    return [
      for (final item in base)
        if (_catalogSearchText(item).contains(query)) item,
    ];
  }

  List<EtfCatalogItem> _baseItems(EtfCatalog catalog) {
    switch (_filter) {
      case _EtfCatalogFilter.focus:
        return catalog.focusItems;
      case _EtfCatalogFilter.taiwanEquity:
        return [
          for (final item in catalog.items)
            if (_isTaiwanEquityEtf(item)) item,
        ];
      case _EtfCatalogFilter.dividend:
        return [
          for (final item in catalog.items)
            if (_isDividendEtf(item)) item,
        ];
      case _EtfCatalogFilter.leveraged:
        return [
          for (final item in catalog.items)
            if (_isLeveragedOrInverseEtf(item)) item,
        ];
      case _EtfCatalogFilter.all:
        return catalog.items;
    }
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.data,
    required this.selectedEtf,
    required this.gapDetailsValue,
  });

  final Etf00631LLabData data;
  final _SelectedEtfViewData selectedEtf;
  final AsyncValue<EtfPriceHistoryGapDetails>? gapDetailsValue;

  @override
  Widget build(BuildContext context) {
    final status = data.operationsStatus;
    final readiness = status.dailyReadinessSummary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SettingsQuickSummaryGrid(
          data: data,
          selectedEtf: selectedEtf,
          readinessLabel: readiness.label,
        ),
        const SizedBox(height: 10),
        _SectionBlock(
          title: '帳戶與偏好',
          subtitle: '一般使用者只需要看這裡：登入、外觀、目前 ETF 與本機持倉狀態。',
          child: _SettingsPreferenceGrid(
            items: [
              const _SettingsPreferenceItem(
                keySuffix: 'account',
                icon: Icons.person_outline,
                label: '帳戶',
                status: '不需登入',
                detail: '00631L 正二研究室目前不需要帳號或券商登入。',
                action: '可直接使用公開 PWA；持倉資料留在本機。',
              ),
              const _SettingsPreferenceItem(
                keySuffix: 'appearance',
                icon: Icons.contrast_outlined,
                label: '外觀',
                status: '可切換',
                detail: '右上角可切換夜間模式，偏好會保存在本機。',
                action: '需要切換時點選月亮或太陽圖示。',
              ),
              _SettingsPreferenceItem(
                keySuffix: 'selected-etf',
                icon: Icons.manage_search_outlined,
                label: '目前 ETF',
                status: selectedEtf.code,
                detail:
                    '${selectedEtf.name}；價格資料 ${_sourceStatusBadgeLabel(selectedEtf.priceHistory.sourceStatusLabel)}。',
                action: '左上角代號按鈕可搜尋並切換 ETF。',
              ),
              _SettingsPreferenceItem(
                keySuffix: 'position',
                icon: Icons.account_balance_wallet_outlined,
                label: '持倉資料',
                status: _sourceStatusBadgeLabel(status.positionStatus),
                detail: '${selectedEtf.code} 持倉追蹤採本機保存，不會上傳個人持倉。',
                action: '可在持倉頁保存、匯出 JSON 或清除。',
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const _CompactExpansionPanel(
          title: 'App 上架準備',
          subtitle: 'PWA 已可用；原生 Android / iOS 的上架資料先收在這裡。',
          child: _StatusList(
            items: [
              _StatusItem(
                label: 'PWA',
                status: '可用',
                detail:
                    '公開 GitHub Pages root 可直接開啟 ETF 研究室，並保留 static history fallback。',
                action: '可先用 PWA 日常使用與收集 store 截圖素材。',
              ),
              _StatusItem(
                label: 'Android',
                status: '規劃中',
                detail:
                    '目前 repo 尚未加入 Android 原生 scaffold 與 release signing 設定。',
                action: '下一階段建立 Android shell、app id、icon、簽章與 store build 流程。',
              ),
              _StatusItem(
                label: 'iOS',
                status: '規劃中',
                detail:
                    'iOS 上架需要 macOS、Xcode、Apple Developer 與 App Store Connect。',
                action: '下一階段準備 bundle id、簽章、隱私資訊與 TestFlight 流程。',
              ),
              _StatusItem(
                label: '隱私與支援',
                status: '待準備',
                detail:
                    '正式商店頁需要 privacy policy、support URL、app icon、截圖與資料使用說明。',
                action: '先整理 policy 草稿與上架素材清單；不把任何 key 放進 repo。',
              ),
              _StatusItem(
                label: '公開後端',
                status: '範本就緒',
                detail: '公開後端已有 Docker / Render / CORS / 持久化資料設計。',
                action: '正式上架前確認後端可用性、persistent volume 與公開 API URL。',
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _CompactExpansionPanel(
          key: const ValueKey('00631l-etf-data-library-panel'),
          title: 'ETF 資料與比較能力',
          subtitle: 'ETF 清單、歷史資料覆蓋、比較能力與研究室資料來源。',
          child: Column(
            children: [
              _EtfResearchRoomReadinessPanel(
                data: data,
                selectedEtf: selectedEtf,
              ),
              const SizedBox(height: 10),
              _EtfDataLibrarySummary(data: data, compact: true),
              _EtfGapDetailPanel(
                value: gapDetailsValue,
                status: status,
              ),
              const SizedBox(height: 10),
              _StatusList(
                items: [
                  _StatusItem(
                    label: 'ETF 清單',
                    status: data.etfCatalog.hasData
                        ? _sourceStatusBadgeLabel(
                            data.etfCatalog.sourceStatusLabel)
                        : _sourceStatusBadgeLabel(status.etfCatalogStatus),
                    detail:
                        '筆數 ${data.etfCatalog.hasData ? data.etfCatalog.rowCount : status.etfCatalogRowCount}，資料時間 ${_dateTimeOrDash(data.etfCatalog.dataTime ?? status.etfCatalogDataTime)}。',
                    action: '左上角代號按鈕可搜尋代號、名稱與分類。',
                  ),
                  const _StatusItem(
                    label: 'ETF 比較',
                    status: '可使用',
                    detail: '歷史回測頁可自選 1-5 檔 ETF，比較同一區間的歷史報酬與回撤。',
                    action: '在歷史回測頁使用同類型篩選或手動勾選比較組合。',
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _CompactExpansionPanel(
          title: '資料模式與完整度',
          subtitle: '公開靜態歷史資料、即時後端與內容物狀態需要時再看。',
          child: _StatusList(items: _dataCoverageItems(data)),
        ),
        const SizedBox(height: 10),
        _CompactExpansionPanel(
          key: const ValueKey('00631l-settings-advanced-maintenance-panel'),
          title: '進階維護診斷',
          subtitle: '後端、歷史、日報、匯出、備份與部署設定。',
          child: _StatusList(
            items: [
              _StatusItem(
                label: '後端連線',
                status: status.sourceStatusLabel,
                detail: status.backendConnectionCaption,
                action:
                    status.backendDisconnected ? '請啟動後端或檢查公開後端 URL。' : '後端可連線。',
              ),
              _StatusItem(
                label: '後端版本',
                status: status.backendAppVersion.isEmpty
                    ? '未知'
                    : status.backendAppVersion,
                detail: status.backendReleaseLabel,
                action: status.backendGitSha.isEmpty
                    ? '部署時設定 00631L_BACKEND_GIT_SHA，方便追蹤後端版本。'
                    : 'git ${status.backendGitSha}',
              ),
              if (status.sourceStatusLabel == 'static_public_data' ||
                  status.staticReleaseGitSha.isNotEmpty)
                _StatusItem(
                  label: '公開靜態版本',
                  status: status.staticReleaseAppVersion.isEmpty
                      ? '未載入'
                      : status.staticReleaseAppVersion,
                  detail: status.staticReleaseLabel,
                  action: status.staticReleaseGitSha.isEmpty
                      ? 'Pages 建置前請執行 scripts\\00631l_export_static_data.cmd --update。'
                      : 'git ${_shortGitSha(status.staticReleaseGitSha)}; build ${_dateTimeOrDash(status.staticReleaseBuildTime)}',
                ),
              _StatusItem(
                label: '部署同步',
                status: status.publicDeploymentSyncLabel,
                detail: status.publicDeploymentSyncCaption,
                action: status.publicDeploymentSyncAction,
              ),
              _StatusItem(
                label: '官方每日內容物',
                status: status.holdingsHistoryStatus,
                detail:
                    '歷史筆數 ${status.holdingsHistoryItemCount}，最新 ${_dateOrDash(status.latestHoldingTradeDate)}。',
                action: status.holdingsHistoryItemCount == 0
                    ? '請執行 scripts\\00631l_daily_cycle.cmd。'
                    : '每日資料已累積。',
              ),
              _StatusItem(
                label: '盤中 NAV',
                status: status.intradayHistoryStatus,
                detail:
                    '樣本 ${status.intradaySampleCount}，最新 ${status.latestIntradayDataTime == null ? '暫無' : formatTaiwanDateTimeSeconds(status.latestIntradayDataTime!)}。',
                action: status.intradaySampleCount == 0
                    ? '請確認 TWSE URL、後端服務與交易時段。'
                    : '盤中估算資料已保存。',
              ),
              _StatusItem(
                label: '歷史價格',
                status: status.priceHistoryStatus,
                detail:
                    '筆數 ${status.priceHistoryRows}，範圍 ${_dateOrDash(status.priceHistoryCoverageStart)} - ${_dateOrDash(status.priceHistoryCoverageEnd)}，產生時間 ${_dateTimeOrDash(status.latestExportUpdatedAt)}。',
                action: status.priceHistoryRows < 2
                    ? '請執行 scripts\\00631l_update_price_history.cmd；GitHub Pages 請執行 scripts\\00631l_export_static_data.cmd --update。'
                    : '歷史價格可供回測。',
              ),
              _StatusItem(
                label: '回測',
                status: status.backtestStatus,
                detail: status.backtestAvailable ? '價格歷史可用' : '價格歷史不足',
                action: status.backtestAvailable ? '可在回測區使用。' : '請先更新歷史價格。',
              ),
              _StatusItem(
                label: '本機持倉資料',
                status: status.positionStatus,
                detail: '持倉資料保存在瀏覽器本機。',
                action: '可在持倉區保存、匯出或清除。',
              ),
              _StatusItem(
                label: '日常流程',
                status: status.dailyCycleStatus,
                detail:
                    '提醒 ${status.dailyCycleWarningCount}，失敗 ${status.dailyCycleFailureCount}。',
                action: status.dailyCycleStatus == 'PASS'
                    ? '最近日常流程可讀。'
                    : '請執行 scripts\\00631l_daily_cycle.cmd。',
              ),
              _StatusItem(
                label: '報告 / 匯出 / 備份',
                status:
                    '${_sourceStatusBadgeLabel(status.reportOverallStatus)} / '
                    '${status.exportAvailable ? '已就緒' : '缺少'} / '
                    '${status.backupAvailable ? '已就緒' : '缺少'}',
                detail:
                    '報告 ${status.latestReportPath ?? '缺少'}，匯出 ${status.latestExportPath ?? '缺少'}，備份 ${status.latestBackupPath ?? '缺少'}。',
                action: '必要時執行日報、匯出、備份腳本。',
              ),
              _StatusItem(
                label: '公開部署設定',
                status: status.dataPersistenceLabel,
                detail:
                    'API ${status.publicApiBaseUrl.isEmpty ? _proxyBaseUrl00631l : status.publicApiBaseUrl}，origins ${status.allowedOrigins.isEmpty ? 'local/LAN' : status.allowedOrigins.join(', ')}。',
                action: status.dataPathPersistent
                    ? '持久化資料目錄可用。'
                    : '公開部署需設定 persistent volume。',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EtfComparisonPreview extends StatelessWidget {
  const _EtfComparisonPreview({required this.catalog});

  final EtfCatalog catalog;

  @override
  Widget build(BuildContext context) {
    final items = catalog.focusItems.take(6).toList(growable: false);
    if (items.isEmpty) {
      return const _EmptyPanel(
        title: '尚無可比較 ETF',
        message: '需要公開後端 ETF 清單，才能顯示比較基礎資料。',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StatusWrap(
          labels: [
            'catalog snapshot',
            '非完整績效比較',
            '00631L 研究室仍為主軸',
          ],
        ),
        const SizedBox(height: 10),
        _HorizontalTable(
          columns: const [
            '代號',
            '名稱',
            '市價',
            '預估淨值',
            '折溢價',
            '前日淨值',
            '資料時間',
          ],
          rows: [
            for (final item in items)
              [
                item.code,
                item.displayName,
                _price(item.marketPrice),
                _price(item.estimatedNav),
                formatSignedNullablePercent(item.resolvedPremiumDiscountPct),
                _price(item.previousNav),
                _dateTimeOrDash(item.dataTime),
              ],
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          '這裡只做 catalog 欄位對照；若要比較長期績效，需要各 ETF 的可驗證歷史資料。',
        ),
      ],
    );
  }
}

class _EtfCatalogItemTile extends StatelessWidget {
  const _EtfCatalogItemTile({
    super.key,
    required this.item,
    required this.onSelected,
  });

  final EtfCatalogItem item;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasHistory = _catalogItemHasImportedEtfHistory(item);
    final historyMetadataLabel = _etfHistoryMetadataLabel(item);
    final missingReasonLabel = _etfHistoryMissingReasonLabel(item);
    final priceBasisLabel = _etfHistoryPriceBasisLabel(item);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => onSelected(item.code),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _marketPanelAltColor(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _marketBorderColor(context)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              _MiniStatusBadge(label: item.code),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: _marketTextColor(context),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Wrap(
                      spacing: 6,
                      runSpacing: 5,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          item.targetType.isEmpty ? 'ETF' : item.targetType,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: _marketMutedTextColor(context),
                          ),
                        ),
                        KeyedSubtree(
                          key: ValueKey(
                            hasHistory
                                ? '00631l-etf-list-history-ready-${item.code}'
                                : '00631l-etf-list-catalog-only-${item.code}',
                          ),
                          child: _CompactTextBadge(
                            label: hasHistory ? '歷史/回測可用' : '僅清單資料',
                          ),
                        ),
                        if (historyMetadataLabel.isNotEmpty)
                          _CompactTextBadge(label: historyMetadataLabel),
                        if (priceBasisLabel.isNotEmpty)
                          KeyedSubtree(
                            key: ValueKey(
                              '00631l-etf-list-price-basis-${item.code}',
                            ),
                            child: _CompactTextBadge(label: priceBasisLabel),
                          ),
                        if (missingReasonLabel.isNotEmpty)
                          KeyedSubtree(
                            key: ValueKey(
                              '00631l-etf-list-gap-reason-${item.code}',
                            ),
                            child: _CompactTextBadge(
                              label: missingReasonLabel,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _price(item.marketPrice),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: _marketTextColor(context),
                    ),
                  ),
                  Text(
                    formatSignedNullablePercent(
                        item.resolvedPremiumDiscountPct),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: _marketMutedTextColor(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsPreferenceItem {
  const _SettingsPreferenceItem({
    required this.keySuffix,
    required this.icon,
    required this.label,
    required this.status,
    required this.detail,
    required this.action,
  });

  final String keySuffix;
  final IconData icon;
  final String label;
  final String status;
  final String detail;
  final String action;
}

class _SettingsPreferenceGrid extends StatelessWidget {
  const _SettingsPreferenceGrid({required this.items});

  final List<_SettingsPreferenceItem> items;

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: const ValueKey('00631l-settings-preference-grid'),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final veryNarrow = constraints.maxWidth < 320;
          return GridView.count(
            crossAxisCount: veryNarrow ? 1 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: veryNarrow ? 2.6 : 1.34,
            children: [
              for (final item in items)
                _SettingsPreferenceCard(
                  key: ValueKey(
                    '00631l-settings-preference-${item.keySuffix}',
                  ),
                  item: item,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _SettingsPreferenceCard extends StatelessWidget {
  const _SettingsPreferenceCard({
    super.key,
    required this.item,
  });

  final _SettingsPreferenceItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _marketPanelAltColor(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _marketBorderColor(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(item.icon, size: 17, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: _marketMutedTextColor(context),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Text(
              item.status,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                color: _marketTextColor(context),
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item.detail,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: _marketMutedTextColor(context),
                height: 1.25,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              item.action,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsQuickSummaryGrid extends StatelessWidget {
  const _SettingsQuickSummaryGrid({
    required this.data,
    required this.selectedEtf,
    required this.readinessLabel,
  });

  final Etf00631LLabData data;
  final _SelectedEtfViewData selectedEtf;
  final String readinessLabel;

  @override
  Widget build(BuildContext context) {
    final status = data.operationsStatus;
    final readinessStatus = readinessLabel == '就緒' ? '就緒' : '進階檢查';
    final theme = Theme.of(context);
    return KeyedSubtree(
      key: const ValueKey('00631l-settings-quick-summary-compact'),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '我的',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  _StatusPill(label: _frontendDataModeLabel),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '帳戶、外觀、目前 ETF 與本機資料；維護細節需要時再展開。',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 10),
              _StatusWrap(
                labels: [
                  '免登入',
                  '本機保存',
                  '目前 ${selectedEtf.code}',
                  _sourceStatusBadgeLabel(
                    selectedEtf.priceHistory.sourceStatusLabel,
                  ),
                  readinessStatus,
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _settingsDataModeCaption(status),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _settingsDataModeCaption(EtfOperationsStatus status) {
  if (status.sourceStatusLabel == 'static_public_data') {
    return '公開靜態資料可用';
  }
  if (status.backendDisconnected ||
      status.sourceStatusLabel == 'error' ||
      status.sourceStatusLabel == 'unavailable') {
    return '靜態資料可用，詳情在下方';
  }
  if (status.sourceStatusLabel == 'mock') {
    return '預設示範資料';
  }
  if (_use00631LLiveProxy) {
    return '後端連線狀態詳情在下方';
  }
  return status.backendConnectionLabel;
}

class _EtfResearchRoomReadinessPanel extends StatelessWidget {
  const _EtfResearchRoomReadinessPanel({
    required this.data,
    required this.selectedEtf,
  });

  final Etf00631LLabData data;
  final _SelectedEtfViewData selectedEtf;

  @override
  Widget build(BuildContext context) {
    final status = data.operationsStatus;
    final price = data.priceHistory.completenessSummary();
    final etfReady = status.etfPriceHistoryReadyCount;
    final etfTotal = _etfDataCompletionTotal(
      status: status,
      catalogRows: data.etfCatalog.rowCount,
    );
    return KeyedSubtree(
      key: const ValueKey('00631l-etf-room-readiness-panel'),
      child: _SectionBlock(
        title: 'ETF 研究室完成度',
        subtitle: '檢查正式工具的主要能力是否已可日常使用；只描述資料與程式狀態。',
        child: _StatusList(
          items: [
            const _StatusItem(
              label: '公開 PWA',
              status: '可用',
              detail: 'GitHub Pages 公開靜態模式可開啟；盤中即時資料需要公開後端服務。',
              action: '手機可直接開公開網址；若要盤中即時資料，請保持後端 /ready 正常。',
            ),
            _StatusItem(
              label: '00631L 核心資料',
              status: data.status.label,
              detail:
                  '內容物 ${formatTaiwanDate(data.snapshot.tradeDate)}；價格筆數 ${formatInteger(price.rowCount)}；盤中 ${_sourceStatusBadgeLabel(data.intradayNav?.status.label)}。',
              action: '每日執行每日流程，確認官方 / 快取 / 過期狀態。',
            ),
            _StatusItem(
              label: '多 ETF 資料庫',
              status: '$etfReady / $etfTotal 可用',
              detail: '已匯入 ETF 價格歷史的檔數會影響搜尋切換、歷史、回測與比較。',
              action:
                  '資料不足時執行 scripts\\00631l_import_etf_price_history.cmd --update。',
            ),
            _StatusItem(
              label: '目前選取',
              status: selectedEtf.code,
              detail: selectedEtf.readinessDetail,
              action: selectedEtf.readinessAction,
            ),
            const _StatusItem(
              label: '持倉與 AI',
              status: '本機保存 / 規則分析',
              detail: '持倉保存在瀏覽器本機；AI 目前只做 rule-based 資料解讀。',
              action: '需要移機前先匯出持倉 JSON；外部 LLM 預設關閉。',
            ),
          ],
        ),
      ),
    );
  }
}

class _EtfDataLibrarySummary extends StatelessWidget {
  const _EtfDataLibrarySummary({
    super.key,
    required this.data,
    this.compact = false,
  });

  final Etf00631LLabData data;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final status = data.operationsStatus;
    final catalogRows = _effectiveEtfCatalogRows(
      status: status,
      loadedCatalogRows: data.etfCatalog.rowCount,
    );
    final historyTotal = _etfDataCompletionTotal(
      status: status,
      catalogRows: catalogRows,
    );
    final tiers = status.etfPriceHistoryCoverageTierCounts;
    final longTerm = tiers['long_term'] ?? 0;
    final recent = tiers['recent'] ?? 0;
    final notReady = status.etfPriceHistoryMissingCount > 0
        ? status.etfPriceHistoryMissingCount
        : (historyTotal - status.etfPriceHistoryReadyCount)
            .clamp(0, historyTotal)
            .toInt();
    final historyReadyValue = historyTotal > 0
        ? '${formatInteger(status.etfPriceHistoryReadyCount)} / ${formatInteger(historyTotal)}'
        : formatInteger(status.etfPriceHistoryReadyCount);
    final readyRatio = historyTotal <= 0
        ? 0.0
        : status.etfPriceHistoryReadyCount / historyTotal;

    final cards = [
      _MetricCard(
        label: '完成度',
        value: formatNullablePercent(readyRatio * 100),
        caption: '歷史可用比例',
        icon: Icons.fact_check_outlined,
      ),
      _MetricCard(
        label: '清單檔數',
        value: formatInteger(catalogRows),
        caption: data.etfCatalog.hasData
            ? _sourceStatusBadgeLabel(data.etfCatalog.sourceStatusLabel)
            : _sourceStatusBadgeLabel(status.etfCatalogStatus),
        icon: Icons.dataset_outlined,
      ),
      _MetricCard(
        label: '歷史可用',
        value: historyReadyValue,
        caption: status.etfPriceHistoryStatus,
        icon: Icons.query_stats_outlined,
      ),
      _MetricCard(
        label: '長期',
        value: formatInteger(longTerm),
        caption: '長期範圍',
        icon: Icons.timeline_outlined,
      ),
      _MetricCard(
        label: '近期',
        value: formatInteger(recent),
        caption: '近期範圍',
        icon: Icons.schedule_outlined,
      ),
      _MetricCard(
        label: '尚未可用',
        value: formatInteger(notReady),
        caption: '需補歷史或等待驗證',
        icon: Icons.hourglass_empty_outlined,
      ),
      _MetricCard(
        label: '資料時間',
        value: _dateTimeOrDash(
          status.etfPriceHistoryDataTime ?? data.etfCatalog.dataTime,
        ),
        caption: '歷史 / 清單',
        icon: Icons.update_outlined,
      ),
    ];

    return _SectionBlock(
      title: 'ETF 資料庫狀態',
      subtitle: compact
          ? '先看 catalog 與歷史價格覆蓋；缺口代表尚未有足夠資料可供比較或回測。'
          : '顯示可搜尋的 ETF 清單與已匯入歷史價格；可用代表能用於歷史、回測與比較，不代表官方內容物已完整匯入。',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ResponsiveMetricGrid(
            cards: cards,
          ),
          const SizedBox(height: 10),
          _EtfLibraryReadableSummary(
            status: status,
            historyTotal: historyTotal,
            missingCount: notReady,
          ),
          const SizedBox(height: 8),
          _EtfLibraryCompletionStrip(
            status: status,
            historyTotal: historyTotal,
            missingCount: notReady,
          ),
          const SizedBox(height: 10),
          _StatusRow(
            item: _etfHistoryNextActionItem(
              status: status,
              historyTotal: historyTotal,
              missingCount: notReady,
            ),
          ),
          const SizedBox(height: 8),
          _StatusRow(
            item: _etfHistoryGapReasonItem(status),
          ),
        ],
      ),
    );
  }
}

class _EtfLibraryReadableSummary extends StatelessWidget {
  const _EtfLibraryReadableSummary({
    required this.status,
    required this.historyTotal,
    required this.missingCount,
  });

  final EtfOperationsStatus status;
  final int historyTotal;
  final int missingCount;

  @override
  Widget build(BuildContext context) {
    final counts = status.etfPriceHistoryGapReasonCounts;
    final unclassified = counts['not_saved'] ?? 0;
    final officialEmpty = counts['official_empty'] ?? 0;
    final sourceError = counts['source_error'] ?? 0;
    final ready = status.etfPriceHistoryReadyCount;
    final total = historyTotal > 0 ? historyTotal : ready + missingCount;
    final allClassified = missingCount == 0 || unclassified == 0;
    final statusText =
        allClassified ? '缺口已分類' : '待分類 ${formatInteger(unclassified)}';
    final detail = missingCount <= 0
        ? '目前 ${formatInteger(ready)} 檔 ETF 歷史資料可用。'
        : '目前 ${formatInteger(ready)} / ${formatInteger(total)} 檔 ETF 歷史資料可用；${formatInteger(missingCount)} 檔尚未可用。原因：官方空資料 ${formatInteger(officialEmpty)}、來源錯誤 ${formatInteger(sourceError)}、未分類 ${formatInteger(unclassified)}。';
    final action = allClassified
        ? '資料缺口已有原因分類；維持靜態匯出與驗收檢查。'
        : '請執行 scripts\\00631l_probe_missing_etf_reasons.cmd 後重新匯出 static data。';

    return KeyedSubtree(
      key: const ValueKey('00631l-etf-library-readable-summary'),
      child: _StatusRow(
        item: _StatusItem(
          label: 'ETF 資料庫摘要',
          status: statusText,
          detail: detail,
          action: action,
        ),
      ),
    );
  }
}

class _EtfLibraryCompletionStrip extends StatelessWidget {
  const _EtfLibraryCompletionStrip({
    required this.status,
    required this.historyTotal,
    required this.missingCount,
  });

  final EtfOperationsStatus status;
  final int historyTotal;
  final int missingCount;

  @override
  Widget build(BuildContext context) {
    final counts = status.etfPriceHistoryGapReasonCounts;
    final ready = status.etfPriceHistoryReadyCount;
    final total = historyTotal > 0 ? historyTotal : ready + missingCount;
    final officialEmpty = counts['official_empty'] ?? 0;
    final sourceError = counts['source_error'] ?? 0;
    final unclassified = counts['not_saved'] ?? 0;
    final statusLine = sourceError <= 0 && unclassified <= 0
        ? '所有缺口已有官方回覆或分類'
        : '仍有來源待處理或未分類缺口';
    final actionLine = sourceError <= 0
        ? '資料維護已確認：可用資料與官方空資料分開標示。'
        : '可執行 scripts\\00631l_import_missing_etf_batch.cmd 重新檢查來源錯誤。';

    return DecoratedBox(
      key: const ValueKey('00631l-etf-library-completion-strip'),
      decoration: BoxDecoration(
        color: _marketPanelColor(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _marketBorderColor(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _InlineQualityPill(
                    label: '可用',
                    value: '${formatInteger(ready)}/${formatInteger(total)}',
                  ),
                  _InlineQualityPill(
                    label: '官方空資料',
                    value: formatInteger(officialEmpty),
                  ),
                  _InlineQualityPill(
                    label: '來源待處理',
                    value: formatInteger(sourceError),
                  ),
                  _InlineQualityPill(
                    label: '未分類',
                    value: formatInteger(unclassified),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              statusLine,
              key: const ValueKey('00631l-etf-library-completion-status-text'),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: _marketTextColor(context),
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              actionLine,
              key: const ValueKey('00631l-etf-library-completion-action-text'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _marketMutedTextColor(context),
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EtfGapDetailPanel extends StatefulWidget {
  const _EtfGapDetailPanel({
    required this.value,
    required this.status,
  });

  final AsyncValue<EtfPriceHistoryGapDetails>? value;
  final EtfOperationsStatus status;

  @override
  State<_EtfGapDetailPanel> createState() => _EtfGapDetailPanelState();
}

class _EtfGapDetailPanelState extends State<_EtfGapDetailPanel> {
  String? _selectedReason;

  @override
  Widget build(BuildContext context) {
    final current = widget.value?.valueOrNull;
    final shouldShow = widget.status.etfPriceHistoryGapDetailCount > 0 ||
        current?.items.isNotEmpty == true ||
        widget.value?.isLoading == true ||
        widget.value?.hasError == true;
    if (!shouldShow) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final allRows = current?.items ?? const <EtfPriceHistoryGapDetail>[];
    final reasons = _gapReasonCounts(current, allRows);
    final selectedReason =
        reasons.containsKey(_selectedReason) ? _selectedReason : null;
    final filteredRows = selectedReason == null
        ? allRows
        : allRows
            .where((row) => row.gapReason == selectedReason)
            .toList(growable: false);
    final rows = filteredRows.take(8).toList(growable: false);
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: DecoratedBox(
        key: const ValueKey('00631l-etf-gap-detail-panel'),
        decoration: BoxDecoration(
          color: _marketPanelAltColor(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _marketBorderColor(context)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'ETF 缺口明細',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  _StatusPill(label: current?.sourceStatusLabel ?? 'loading'),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '缺口明細只用來檢查資料狀態；不可用資料不會拿來做歷史、回測或比較。',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _marketMutedTextColor(context),
                ),
              ),
              if (reasons.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    FilterChip(
                      key: const ValueKey('00631l-etf-gap-filter-all'),
                      label: Text('全部 ${formatInteger(allRows.length)}'),
                      selected: selectedReason == null,
                      onSelected: (_) {
                        setState(() {
                          _selectedReason = null;
                        });
                      },
                    ),
                    for (final entry in reasons.entries)
                      FilterChip(
                        key: ValueKey(
                          '00631l-etf-gap-filter-${entry.key}',
                        ),
                        label: Text(
                          '${_etfGapReasonLabel(entry.key)} ${formatInteger(entry.value)}',
                        ),
                        selected: selectedReason == entry.key,
                        onSelected: (_) {
                          setState(() {
                            _selectedReason =
                                selectedReason == entry.key ? null : entry.key;
                          });
                        },
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              _StatusWrap(
                labels: [
                  '明細 ${formatInteger(current?.gapDetailCount ?? widget.status.etfPriceHistoryGapDetailCount)}',
                  '回傳 ${formatInteger(current?.returnedCount ?? rows.length)}',
                  if (selectedReason != null)
                    '篩選 ${formatInteger(filteredRows.length)} / ${formatInteger(allRows.length)}',
                  if (current?.reason != null)
                    '原因 ${_etfGapReasonLabel(current!.reason!)}',
                  if (current?.dataTime != null)
                    'dataTime ${_dateTimeOrDash(current!.dataTime)}',
                ],
              ),
              if (widget.value?.isLoading == true) ...[
                const SizedBox(height: 8),
                const LinearProgressIndicator(),
              ] else if (widget.value?.hasError == true) ...[
                const SizedBox(height: 8),
                _EmptyPanel(
                  title: '缺口明細暫不可用',
                  message: widget.value?.error.toString() ?? 'Unknown error',
                ),
              ] else if (allRows.isEmpty) ...[
                const SizedBox(height: 8),
                const _EmptyPanel(
                  title: '目前沒有缺口明細',
                  message: '目前 ETF 歷史資料狀態沒有個別代號的維護明細。',
                ),
              ] else if (rows.isEmpty) ...[
                const SizedBox(height: 8),
                const _EmptyPanel(
                  title: '此分類沒有資料',
                  message: '請切換其他缺口分類檢查 ETF 歷史資料維護明細。',
                ),
              ] else ...[
                const SizedBox(height: 10),
                for (final row in rows) ...[
                  _EtfGapDetailRow(row: row),
                  const SizedBox(height: 8),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Map<String, int> _gapReasonCounts(
    EtfPriceHistoryGapDetails? details,
    List<EtfPriceHistoryGapDetail> rows,
  ) {
    final counts = <String, int>{};
    for (final entry in details?.gapReasonCounts.entries ??
        const Iterable<MapEntry<String, int>>.empty()) {
      if (entry.value > 0) {
        counts[entry.key] = entry.value;
      }
    }
    for (final row in rows) {
      counts.putIfAbsent(row.gapReason, () => 0);
      if (counts[row.gapReason] == 0) {
        counts[row.gapReason] = rows
            .where((candidate) => candidate.gapReason == row.gapReason)
            .length;
      }
    }
    final entries = counts.entries.toList()
      ..sort((a, b) {
        final countCompare = b.value.compareTo(a.value);
        return countCompare != 0 ? countCompare : a.key.compareTo(b.key);
      });
    return Map<String, int>.fromEntries(entries);
  }
}

class _EtfGapDetailRow extends StatelessWidget {
  const _EtfGapDetailRow({required this.row});

  final EtfPriceHistoryGapDetail row;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final error = row.errorMessage?.trim();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _marketPanelColor(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _marketBorderColor(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  row.code,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                _StatusPill(label: _etfGapReasonLabel(row.gapReason)),
                _StatusPill(label: row.sourceStatus),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              row.displayName,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            _StatusWrap(
              labels: [
                '類型 ${_etfCoverageTierLabel(row.coverageTier)}',
                '筆數 ${formatInteger(row.rowCount)}',
                if (row.validationFailureCount > 0)
                  '驗證 ${formatInteger(row.validationFailureCount)}',
                if (row.requestedMonths > 0)
                  '月份 ${formatInteger(row.requestedMonths)}',
                if (row.lastAttemptAt != null)
                  '嘗試 ${_dateTimeOrDash(row.lastAttemptAt)}',
              ],
            ),
            if (error != null && error.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                error,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _marketMutedTextColor(context),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ExposureBars extends StatelessWidget {
  const _ExposureBars({required this.snapshot});

  final EtfDailyHoldingSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('股票資產', snapshot.assetWeightPct(EtfAssetClass.stock)),
      ('期貨資產', snapshot.assetWeightPct(EtfAssetClass.futures)),
      ('ETF', snapshot.assetWeightPct(EtfAssetClass.etf)),
      ('債券', snapshot.assetWeightPct(EtfAssetClass.bond)),
      ('現金與保證金', snapshot.cashAndMarginWeightPct),
      ('其他應收應付', snapshot.otherReceivablesPayablesWeightPct),
    ];
    return Column(
      children: [
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                SizedBox(width: 110, child: Text(row.$1)),
                Expanded(
                  child: LinearProgressIndicator(
                    value: (row.$2.abs() / 220).clamp(0, 1).toDouble(),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 76,
                  child: Text(
                    formatNullablePercent(row.$2),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _HoldingsExposureCompare extends StatelessWidget {
  const _HoldingsExposureCompare({required this.snapshot});

  final EtfDailyHoldingSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final txLine = _primaryFuturesLine(snapshot);
    final tsmcLine = _stockHoldingByCode(snapshot, '2330');
    final rows = [
      _HoldingsCompareItem(
        label: 'TX 期貨',
        valuePct: txLine?.weightPct,
        detail: txLine == null
            ? '官方快照未列 TX 期貨'
            : '${txLine.code} / ${txLine.contractMonth}',
      ),
      _HoldingsCompareItem(
        label: '台積電現股',
        valuePct: tsmcLine?.weightPct,
        detail: tsmcLine == null
            ? '官方快照未列 2330'
            : '${tsmcLine.code} / ${formatInteger(tsmcLine.quantity)}',
      ),
      _HoldingsCompareItem(
        label: '股票資產',
        valuePct: snapshot.stockExposureWeightPct,
        detail: '官方資產結構',
      ),
      _HoldingsCompareItem(
        label: '期貨資產',
        valuePct: snapshot.futuresExposureWeightPct,
        detail: '官方資產結構',
      ),
      _HoldingsCompareItem(
        label: '現金/保證金',
        valuePct: snapshot.cashAndMarginWeightPct,
        detail: '現金、保證金與附買回債券',
      ),
    ];
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const _MiniStatusBadge(label: 'DAY'),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '曝險比較',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _CompactTextBadge(
                  label: formatTaiwanDate(snapshot.tradeDate),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '同一張官方每日內容物快照；盤中變化請看 盤中 NAV。',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),
            for (final row in rows)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _HoldingsCompareRow(item: row),
              ),
          ],
        ),
      ),
    );
  }
}

class _HoldingsCompareItem {
  const _HoldingsCompareItem({
    required this.label,
    required this.valuePct,
    required this.detail,
  });

  final String label;
  final double? valuePct;
  final String detail;
}

class _HoldingsCompareRow extends StatelessWidget {
  const _HoldingsCompareRow({required this.item});

  final _HoldingsCompareItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final normalized =
        ((item.valuePct ?? 0).abs() / 220).clamp(0, 1).toDouble();
    return Row(
      children: [
        SizedBox(
          width: 92,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                item.detail,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: LinearProgressIndicator(
            value: normalized,
            minHeight: 7,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 62,
          child: Text(
            formatNullablePercent(item.valuePct),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _HoldingsCompositionCards extends StatelessWidget {
  const _HoldingsCompositionCards({required this.snapshot});

  final EtfDailyHoldingSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final items = [
      _CompositionItem(
        badge: 'STK',
        label: '股票資產',
        amount: snapshot.assetSummary.stock,
        weightPct: snapshot.assetWeightPct(EtfAssetClass.stock),
        caption: '現股部位',
      ),
      _CompositionItem(
        badge: 'FUT',
        label: '期貨資產',
        amount: snapshot.assetSummary.futures,
        weightPct: snapshot.assetWeightPct(EtfAssetClass.futures),
        caption: '官方內容物期貨曝險',
      ),
      _CompositionItem(
        badge: 'CASH',
        label: '現金與保證金',
        amount: snapshot.cashAndMarginValue,
        weightPct: snapshot.cashAndMarginWeightPct,
        caption: '現金、保證金、附買回債券',
      ),
      _CompositionItem(
        badge: 'OTHER',
        label: '其他應收應付',
        amount: snapshot.otherReceivablesPayablesValue,
        weightPct: snapshot.otherReceivablesPayablesWeightPct,
        caption: '應收、應付與利息項目',
      ),
    ];
    return _InfoCardGrid(
      children: [
        for (final item in items)
          _HoldingInfoCard(
            badge: item.badge,
            title: item.label,
            primary: formatNullablePercent(item.weightPct),
            secondary: formatNtdAmount(item.amount),
            caption: item.caption,
            progressValue: (item.weightPct.abs() / 220).clamp(0, 1).toDouble(),
          ),
      ],
    );
  }
}

class _KeyHoldingsCards extends StatelessWidget {
  const _KeyHoldingsCards({required this.snapshot});

  final EtfDailyHoldingSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final txLine = _primaryFuturesLine(snapshot);
    final tsmcLine = _stockHoldingByCode(snapshot, '2330');
    final topStock = tsmcLine ??
        (snapshot.stockHoldings.isEmpty ? null : snapshot.stockHoldings.first);
    final sortedCash = [...snapshot.cashHoldings]
      ..sort((a, b) => b.amount.abs().compareTo(a.amount.abs()));
    final topCashLine = sortedCash.isEmpty ? null : sortedCash.first;

    return _InfoCardGrid(
      children: [
        _HoldingInfoCard(
          badge: 'FUT',
          title: txLine?.name ?? 'TX 期貨',
          primary: txLine == null
              ? 'unavailable'
              : formatNullablePercent(txLine.weightPct),
          secondary: txLine == null
              ? '官方快照沒有期貨行'
              : '${txLine.code} / ${txLine.contractMonth}',
          caption: '官方每日內容物；不是 TX live quote',
          progressValue: txLine == null
              ? null
              : (txLine.weightPct.abs() / 220).clamp(0, 1).toDouble(),
        ),
        _HoldingInfoCard(
          badge: 'STK',
          title: topStock?.name ?? '主要股票',
          primary: topStock == null
              ? 'unavailable'
              : formatNullablePercent(topStock.weightPct),
          secondary: topStock == null
              ? '官方快照沒有股票行'
              : '${topStock.code} / ${formatInteger(topStock.quantity)}',
          caption: tsmcLine == null ? '官方每日股票明細' : '台積電現股權重',
          progressValue: topStock == null
              ? null
              : (topStock.weightPct.abs() / 100).clamp(0, 1).toDouble(),
        ),
        _HoldingInfoCard(
          badge: 'CASH',
          title: topCashLine?.item ?? '現金項目',
          primary: topCashLine == null
              ? 'unavailable'
              : formatNullablePercent(
                  topCashLine.weightPct(snapshot.fundNetAssetValue),
                ),
          secondary: topCashLine == null
              ? '官方快照沒有現金行'
              : formatNtdAmount(topCashLine.amount),
          caption: '官方每日現金 / 保證金明細',
          progressValue: topCashLine == null
              ? null
              : (topCashLine.weightPct(snapshot.fundNetAssetValue).abs() / 100)
                  .clamp(0, 1)
                  .toDouble(),
        ),
      ],
    );
  }
}

class _InfoCardGrid extends StatelessWidget {
  const _InfoCardGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columnCount = constraints.maxWidth >= 720 ? 3 : 1;
        final width = columnCount == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - (columnCount - 1) * 8) / columnCount;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final child in children)
              SizedBox(
                width: width,
                child: child,
              ),
          ],
        );
      },
    );
  }
}

class _HoldingInfoCard extends StatelessWidget {
  const _HoldingInfoCard({
    required this.badge,
    required this.title,
    required this.primary,
    required this.secondary,
    required this.caption,
    this.progressValue,
  });

  final String badge;
  final String title;
  final String primary;
  final String secondary;
  final String caption;
  final double? progressValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color:
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _MiniStatusBadge(label: badge),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              primary,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              secondary,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (progressValue != null) ...[
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: progressValue,
                minHeight: 6,
              ),
            ],
            const SizedBox(height: 8),
            Text(
              caption,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompositionItem {
  const _CompositionItem({
    required this.badge,
    required this.label,
    required this.amount,
    required this.weightPct,
    required this.caption,
  });

  final String badge;
  final String label;
  final double amount;
  final double weightPct;
  final String caption;
}

class _DataCoveragePanel extends StatelessWidget {
  const _DataCoveragePanel({required this.data});

  final Etf00631LLabData data;

  @override
  Widget build(BuildContext context) {
    final price = data.priceHistory.completenessSummary();
    final holdingsCount = _holdingsHistoryCount(data);
    final intradayTime = _intradayDataTimeText(data.intradayNav);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StatusWrap(
          labels: [
            price.isCompleteFromListing
                ? '價格歷史已補齊到上市日起'
                : '價格歷史 ${price.rowCount >= 2 ? '部分區間' : '尚無資料'}',
            '價格筆數 ${formatInteger(price.rowCount)}',
            '內容物紀錄 $holdingsCount',
            '盤中 $intradayTime',
          ],
        ),
        const SizedBox(height: 12),
        _StatusList(items: _dataCoverageItems(data)),
      ],
    );
  }
}

class _HoldingsCoveragePanel extends StatelessWidget {
  const _HoldingsCoveragePanel({required this.data});

  final Etf00631LLabData data;

  @override
  Widget build(BuildContext context) {
    final status = data.operationsStatus;
    final count = _holdingsHistoryCount(data);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StatusWrap(
          labels: [
            '歷史筆數 $count',
            '最新 ${_dateOrDash(_latestHoldingsDate(data))}',
            '完整性 ${_sourceStatusBadgeLabel(status.integrityStatus)}',
            _holdingsGapText(data),
          ],
        ),
        const SizedBox(height: 12),
        _StatusList(items: _holdingsCoverageItems(data)),
      ],
    );
  }
}

class _HistoryChangeCards extends StatelessWidget {
  const _HistoryChangeCards({required this.summary});

  final EtfHoldingsHistoryTrendSummary summary;

  @override
  Widget build(BuildContext context) {
    return _ResponsiveMetricGrid(
      cards: [
        for (final line in summary.changeLines)
          _MetricCard(
            label: _historyMetricLabel(line.key),
            value: _historyMetricValue(line),
            caption:
                '日變化 ${_historyMetricDelta(line)}，區間 ${_historyMetricRangeDelta(line)}',
            icon: Icons.compare_arrows_outlined,
          ),
      ],
    );
  }
}

class _PriceCompletenessPanel extends StatelessWidget {
  const _PriceCompletenessPanel({
    required this.priceHistory,
    required this.summary,
  });

  final EtfPriceHistory priceHistory;
  final EtfPriceHistoryCompletenessSummary summary;

  @override
  Widget build(BuildContext context) {
    final latest = summary.latest;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StatusWrap(
          labels: [
            '來源 ${_sourceStatusBadgeLabel(priceHistory.sourceStatusLabel)}',
            '筆數 ${summary.rowCount}',
            '範圍 ${_dateOrDash(summary.coverageStart)} - ${_dateOrDash(summary.coverageEnd)}',
            summary.isCompleteFromListing ? '上市日起完整' : '部分區間',
          ],
        ),
        const SizedBox(height: 12),
        _ResponsiveMetricGrid(
          cards: [
            _MetricCard(
              label: '最新收盤',
              value: _price(latest?.close),
              caption: summary.latestDailyReturnPct == null
                  ? '日報酬暫無'
                  : '日報酬 ${formatSignedNullablePercent(summary.latestDailyReturnPct)}',
              icon: Icons.candlestick_chart_outlined,
            ),
            _MetricCard(
              label: '最新 OHLC',
              value: latest == null
                  ? '暫無'
                  : '${_price(latest.open)} / ${_price(latest.high)} / ${_price(latest.low)}',
              caption: summary.hasOhlc ? '開 / 高 / 低' : 'OHLC 暫無',
              icon: Icons.stacked_line_chart_outlined,
            ),
            _MetricCard(
              label: '成交量',
              value: formatInteger(latest?.volume),
              caption: summary.hasVolume ? '最新交易日' : '成交量暫無',
              icon: Icons.bar_chart_outlined,
            ),
            _MetricCard(
              label: '52 週區間',
              value:
                  '${_price(summary.trailingLowClose)} - ${_price(summary.trailingHighClose)}',
              caption:
                  '${_dateOrDash(summary.trailingLowDate)} / ${_dateOrDash(summary.trailingHighDate)}',
              icon: Icons.swap_vert_outlined,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'NAV 欄位 ${summary.hasNav ? '可用' : '尚未覆蓋'}，折溢價欄位 ${summary.hasPremiumDiscount ? '可用' : '尚未覆蓋'}；盤中折溢價仍以後端盤中 NAV 為準。',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

class _PriceTrendCharts extends StatelessWidget {
  const _PriceTrendCharts({required this.priceHistory});

  final EtfPriceHistory priceHistory;

  @override
  Widget build(BuildContext context) {
    final derived = _DerivedPriceSeries(priceHistory.points);
    return _MiniChartGrid(
      children: [
        _MiniChartCard(
          title: '收盤價',
          caption: '完整價格歷史',
          points: priceHistory.points,
          valueOf: (point) => point.performanceClose,
        ),
        _MiniChartCard(
          title: '累積報酬',
          caption: '從資料起點計算',
          points: priceHistory.points,
          valueOf: (point) =>
              point.cumulativeReturnPct ??
              derived.cumulativeReturnPct(point.date),
        ),
        _MiniChartCard(
          title: '回撤',
          caption: '相對歷史高點',
          points: priceHistory.points,
          valueOf: (point) =>
              point.drawdownPct ?? derived.drawdownPct(point.date),
        ),
        _MiniChartCard(
          title: '成交量',
          caption: '最新資料表同步',
          points: priceHistory.points
              .where((point) => point.volume != null)
              .toList(),
          valueOf: (point) => point.volume?.toDouble() ?? 0,
        ),
      ],
    );
  }
}

class _HoldingsTrendCharts extends StatelessWidget {
  const _HoldingsTrendCharts({required this.summary});

  final EtfHoldingsHistoryTrendSummary summary;

  @override
  Widget build(BuildContext context) {
    final ordered = [...summary.points]
      ..sort((a, b) => a.tradeDate.compareTo(b.tradeDate));
    return _MiniChartGrid(
      children: [
        _MiniChartCard(
          title: 'TX 權重',
          caption: '官方內容物紀錄',
          points: _holdingChartPoints(ordered, (point) => point.txWeightPct),
        ),
        _MiniChartCard(
          title: '台積電權重',
          caption: '官方內容物紀錄',
          points: _holdingChartPoints(ordered, (point) => point.tsmcWeightPct),
        ),
        _MiniChartCard(
          title: '股票資產 %',
          caption: '官方每日資產結構',
          points:
              _holdingChartPoints(ordered, (point) => point.stockExposurePct),
        ),
        _MiniChartCard(
          title: '期貨資產 %',
          caption: '官方每日資產結構',
          points:
              _holdingChartPoints(ordered, (point) => point.futuresExposurePct),
        ),
        _MiniChartCard(
          title: '現金/保證金 %',
          caption: '官方每日資產結構',
          points:
              _holdingChartPoints(ordered, (point) => point.cashAndMarginPct),
        ),
        _MiniChartCard(
          title: 'NAV',
          caption: '官方每日淨值',
          points: _holdingChartPoints(ordered, (point) => point.navPerUnit),
        ),
      ],
    );
  }
}

class _MiniChartGrid extends StatelessWidget {
  const _MiniChartGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 620;
        return GridView.count(
          crossAxisCount: isCompact ? 1 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: isCompact ? 1.35 : 1.5,
          children: children,
        );
      },
    );
  }
}

class _MiniChartCard extends StatelessWidget {
  const _MiniChartCard({
    required this.title,
    required this.caption,
    required this.points,
    this.valueOf,
  });

  final String title;
  final String caption;
  final List<EtfPriceHistoryPoint> points;
  final double Function(EtfPriceHistoryPoint point)? valueOf;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Expanded(
              child: _LineChartPanel(
                points: points,
                valueOf: valueOf ?? (point) => point.close,
                labelOf: (point) => _monthDay(point.date),
                height: 76,
                color: theme.colorScheme.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusList extends StatelessWidget {
  const _StatusList({required this.items});

  final List<_StatusItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _StatusRow(item: item),
          ),
      ],
    );
  }
}

class _StatusItem {
  const _StatusItem({
    required this.label,
    required this.status,
    required this.detail,
    required this.action,
  });

  final String label;
  final String status;
  final String detail;
  final String action;
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.item});

  final _StatusItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  item.label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                _StatusPill(label: item.status),
              ],
            ),
            const SizedBox(height: 6),
            Text(item.detail),
            const SizedBox(height: 4),
            Text(
              item.action,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

List<String> _dedupeStatusLabels(Iterable<String> labels) {
  final seen = <String>{};
  final result = <String>[];
  for (final label in labels) {
    final trimmed = label.trim();
    if (trimmed.isEmpty || seen.contains(trimmed)) {
      continue;
    }
    seen.add(trimmed);
    result.add(trimmed);
  }
  return result;
}

class _StatusWrap extends StatelessWidget {
  const _StatusWrap({
    required this.labels,
    this.onDark = false,
  });

  final List<String> labels;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final label in labels)
          _StatusPill(
            label: label,
            onDark: onDark,
          ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    this.onDark = false,
  });

  final String label;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground =
        onDark ? Colors.white : theme.colorScheme.onSecondaryContainer;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: onDark
            ? Colors.white.withValues(alpha: 0.12)
            : theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
        border: onDark
            ? Border.all(color: Colors.white.withValues(alpha: 0.18))
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: foreground,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ComparisonRowData {
  const _ComparisonRowData({
    required this.label,
    required this.value,
    required this.caption,
  });

  final String label;
  final String value;
  final String caption;
}

class _EtfComparisonMetric {
  const _EtfComparisonMetric({
    required this.code,
    required this.name,
    required this.rowCount,
    required this.coverageStart,
    required this.coverageEnd,
    required this.latestClose,
    required this.totalReturnPct,
    required this.annualizedReturnPct,
    required this.maxDrawdownPct,
    required this.annualizedVolatilityPct,
    required this.sourceStatusLabel,
  });

  final String code;
  final String name;
  final int rowCount;
  final DateTime? coverageStart;
  final DateTime? coverageEnd;
  final double? latestClose;
  final double? totalReturnPct;
  final double? annualizedReturnPct;
  final double? maxDrawdownPct;
  final double? annualizedVolatilityPct;
  final String sourceStatusLabel;
}

class _EtfComparisonBasketContext {
  const _EtfComparisonBasketContext({
    required this.labels,
    required this.explanation,
  });

  final List<String> labels;
  final String explanation;
}

class _ComparisonGroup extends StatelessWidget {
  const _ComparisonGroup({
    required this.title,
    required this.rows,
  });

  final String title;
  final List<_ComparisonRowData> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color:
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            for (var index = 0; index < rows.length; index += 1) ...[
              if (index > 0)
                Divider(
                  height: 13,
                  color: theme.colorScheme.outlineVariant,
                ),
              _ComparisonRow(row: rows[index]),
            ],
          ],
        ),
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({required this.row});

  final _ComparisonRowData row;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                row.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                row.caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            row.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _AlwaysExpandedPanel extends StatelessWidget {
  const _AlwaysExpandedPanel({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$title $subtitle',
      child: child,
    );
  }
}

class _CompactExpansionPanel extends StatelessWidget {
  const _CompactExpansionPanel({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          title: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          children: [child],
        ),
      ),
    );
  }
}

class _SectionHeaderMetric {
  const _SectionHeaderMetric({
    required this.label,
    required this.value,
    this.caption,
  });

  final String label;
  final String value;
  final String? caption;
}

class _CompactPageTitle extends StatelessWidget {
  const _CompactPageTitle({
    required this.title,
    required this.subtitle,
    required this.badges,
  });

  final String title;
  final String subtitle;
  final List<String> badges;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _marketPanelColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _marketBorderColor(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                color: _marketTextColor(context),
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: _marketMutedTextColor(context),
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 7),
            _StatusWrap(labels: badges),
          ],
        ),
      ),
    );
  }
}

class _SectionHeaderCard extends StatelessWidget {
  const _SectionHeaderCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.badges,
    required this.metrics,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<String> badges;
  final List<_SectionHeaderMetric> metrics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(7),
                    child: Icon(icon, color: color, size: 18),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            _StatusWrap(labels: badges),
            if (metrics.isNotEmpty) ...[
              const SizedBox(height: 9),
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 520;
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final metric in metrics)
                        SizedBox(
                          width: compact
                              ? (constraints.maxWidth - 8) / 2
                              : (constraints.maxWidth - 24) / 4,
                          child: _SectionHeaderMetricChip(metric: metric),
                        ),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionHeaderMetricChip extends StatelessWidget {
  const _SectionHeaderMetricChip({required this.metric});

  final _SectionHeaderMetric metric;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              metric.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              metric.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            if (metric.caption != null) ...[
              const SizedBox(height: 2),
              Text(
                metric.caption!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionBlock extends StatelessWidget {
  const _SectionBlock({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _ResponsiveMetricGrid extends StatelessWidget {
  const _ResponsiveMetricGrid({required this.cards});

  final List<Widget> cards;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isVeryNarrow = constraints.maxWidth < 300;
        final isCompact = constraints.maxWidth < 560;
        final isWide = constraints.maxWidth > 960;
        return GridView.count(
          crossAxisCount: isVeryNarrow ? 1 : (isWide ? 4 : 2),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: isVeryNarrow ? 2.7 : (isCompact ? 1.35 : 1.35),
          children: cards,
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.caption,
    required this.icon,
  });

  final String label;
  final String value;
  final String caption;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    return LayoutBuilder(
      builder: (context, constraints) {
        final tight = constraints.maxWidth < 180;
        final textContent = Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                caption,
                maxLines: tight ? 1 : 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: EdgeInsets.all(tight ? 10 : 12),
            child: tight
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(icon, color: color, size: 18),
                      const SizedBox(height: 6),
                      textContent,
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(icon, color: color, size: 22),
                      const SizedBox(width: 10),
                      textContent,
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class _InputGrid extends StatelessWidget {
  const _InputGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final veryNarrow = constraints.maxWidth < 300;
        return GridView.count(
          crossAxisCount: veryNarrow ? 1 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: veryNarrow ? 3.9 : 2.55,
          children: children,
        );
      },
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    super.key,
    required this.label,
    required this.controller,
    required this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ).copyWith(labelText: label),
      onChanged: onChanged,
    );
  }
}

class _LineChartPanel extends StatefulWidget {
  const _LineChartPanel({
    required this.points,
    required this.valueOf,
    required this.labelOf,
    this.height = 220,
    this.color,
  });

  final List<EtfPriceHistoryPoint> points;
  final double Function(EtfPriceHistoryPoint point) valueOf;
  final String Function(EtfPriceHistoryPoint point) labelOf;
  final double height;
  final Color? color;

  @override
  State<_LineChartPanel> createState() => _LineChartPanelState();
}

class _LineChartPanelState extends State<_LineChartPanel> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final selected = widget.points.length > 120
        ? [
            for (var i = 0;
                i < widget.points.length;
                i += (widget.points.length / 120).ceil())
              widget.points[i],
          ]
        : widget.points;
    final spots = <FlSpot>[];
    final spotPoints = <EtfPriceHistoryPoint>[];
    for (var index = 0; index < selected.length; index += 1) {
      final value = widget.valueOf(selected[index]);
      if (value.isFinite) {
        spots.add(FlSpot(index.toDouble(), value));
        spotPoints.add(selected[index]);
      }
    }
    final fallbackIndex = spots.isEmpty ? null : spots.length - 1;
    final safeTouchedIndex = _touchedIndex == null || spots.isEmpty
        ? fallbackIndex
        : _touchedIndex!.clamp(0, spots.length - 1);
    final hasManualSelection = _touchedIndex != null && spots.isNotEmpty;
    final touchedPoint =
        safeTouchedIndex == null ? null : spotPoints[safeTouchedIndex];
    final touchedValue =
        safeTouchedIndex == null ? null : spots[safeTouchedIndex].y;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: widget.height,
          child: spots.isEmpty
              ? const Center(child: Text('尚無圖表資料'))
              : LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: true),
                    lineTouchData: LineTouchData(
                      enabled: true,
                      touchCallback: (event, response) {
                        final touched =
                            response?.lineBarSpots?.isNotEmpty == true
                                ? response!.lineBarSpots!.first.spotIndex
                                : null;
                        if (touched != null && touched != _touchedIndex) {
                          setState(() => _touchedIndex = touched);
                        }
                      },
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipItems: (touchedSpots) => [
                          for (final spot in touchedSpots)
                            LineTooltipItem(
                              '${formatTaiwanDate(spotPoints[spot.spotIndex].date)}\n${_compactChartValue(spot.y)}',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                    ),
                    titlesData: const FlTitlesData(
                      rightTitles: AxisTitles(),
                      topTitles: AxisTitles(),
                      bottomTitles: AxisTitles(),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        barWidth: 2.5,
                        isCurved: false,
                        dotData: FlDotData(show: spots.length <= 12),
                        color: widget.color ??
                            Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ),
        ),
        const SizedBox(height: 6),
        if (spotPoints.isNotEmpty) ...[
          _ChartAxisDateStrip(
            start: spotPoints.first.date,
            middle: spotPoints[(spotPoints.length - 1) ~/ 2].date,
            end: spotPoints.last.date,
          ),
          const SizedBox(height: 6),
        ],
        _ChartTouchDetail(
          point: touchedPoint,
          value: touchedValue,
          rangeStart: spotPoints.isEmpty ? null : spotPoints.first.date,
          rangeEnd: spotPoints.isEmpty ? null : spotPoints.last.date,
          isManualSelection: hasManualSelection,
        ),
      ],
    );
  }
}

class _ChartAxisDateStrip extends StatelessWidget {
  const _ChartAxisDateStrip({
    required this.start,
    required this.middle,
    required this.end,
  });

  final DateTime start;
  final DateTime middle;
  final DateTime end;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _axisLabel(context, '起點', start, TextAlign.left)),
        Expanded(child: _axisLabel(context, '中段', middle, TextAlign.center)),
        Expanded(child: _axisLabel(context, '終點', end, TextAlign.right)),
      ],
    );
  }

  Widget _axisLabel(
    BuildContext context,
    String label,
    DateTime date,
    TextAlign align,
  ) {
    final theme = Theme.of(context);
    final key = align == TextAlign.left
        ? const ValueKey('00631l-chart-axis-start-label')
        : align == TextAlign.center
            ? const ValueKey('00631l-chart-axis-middle-label')
            : const ValueKey('00631l-chart-axis-end-label');
    return DecoratedBox(
      key: key,
      decoration: BoxDecoration(
        color:
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: align == TextAlign.left
              ? Alignment.centerLeft
              : align == TextAlign.center
                  ? Alignment.center
                  : Alignment.centerRight,
          child: Text(
            '$label ${formatTaiwanDate(date)}',
            maxLines: 1,
            overflow: TextOverflow.visible,
            textAlign: align,
            style: theme.textTheme.labelSmall?.copyWith(
              color: _marketMutedTextColor(context),
              fontWeight: FontWeight.w800,
              fontSize: 10,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChartTouchDetail extends StatelessWidget {
  const _ChartTouchDetail({
    required this.point,
    required this.value,
    required this.rangeStart,
    required this.rangeEnd,
    required this.isManualSelection,
  });

  final EtfPriceHistoryPoint? point;
  final double? value;
  final DateTime? rangeStart;
  final DateTime? rangeEnd;
  final bool isManualSelection;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = isManualSelection ? '選取日期' : '最新資料';
    final primary = point == null || value == null
        ? rangeStart == null || rangeEnd == null
            ? '點擊圖表可查看完整日期與數值'
            : '圖表區間 ${formatTaiwanDate(rangeStart!)} - ${formatTaiwanDate(rangeEnd!)}'
        : '$label ${formatTaiwanDate(point!.date)} · ${_compactChartValue(value!)}';
    final secondary = isManualSelection ? '再次點擊圖表可切換日期' : '點擊圖表可查看指定日期數值';
    final secondaryDetail =
        point == null || value == null ? secondary : '$primary · $secondary';
    return DecoratedBox(
      key: const ValueKey('00631l-line-chart-touch-detail'),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (point != null && value != null)
              Wrap(
                key: const ValueKey('00631l-line-chart-touch-primary'),
                spacing: 6,
                runSpacing: 4,
                children: [
                  _ChartTouchInfoPill(
                    key: const ValueKey('00631l-line-chart-touch-date'),
                    label: '日期',
                    value: formatTaiwanDate(point!.date),
                  ),
                  _ChartTouchInfoPill(
                    key: const ValueKey('00631l-line-chart-touch-value'),
                    label: '數值',
                    value: _compactChartValue(value!),
                  ),
                ],
              )
            else
              Text(
                primary,
                key: const ValueKey('00631l-line-chart-touch-primary'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w900,
                ),
              ),
            const SizedBox(height: 3),
            Text(
              secondaryDetail,
              key: const ValueKey('00631l-line-chart-touch-secondary'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: _marketMutedTextColor(context),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartTouchInfoPill extends StatelessWidget {
  const _ChartTouchInfoPill({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: _marketMutedTextColor(context),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              value,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _shortChartDate(DateTime date) {
  final mm = date.month.toString().padLeft(2, '0');
  final dd = date.day.toString().padLeft(2, '0');
  return '${date.year}/$mm/$dd';
}

String _compactChartValue(double value) {
  if (value.abs() >= 1000000) {
    return formatInteger(value.round());
  }
  if (value.abs() >= 1000) {
    return value.toStringAsFixed(0);
  }
  if (value.abs() >= 100) {
    return value.toStringAsFixed(1);
  }
  return value.toStringAsFixed(2);
}

class _CurveChartPanel extends StatelessWidget {
  const _CurveChartPanel({required this.points});

  final List<EtfBacktestCurvePoint> points;

  @override
  Widget build(BuildContext context) {
    return _LineChartPanel(
      points: [
        for (final point in points)
          EtfPriceHistoryPoint(date: point.date, close: point.value),
      ],
      valueOf: (point) => point.close,
      labelOf: (point) => _monthDay(point.date),
    );
  }
}

class _DerivedPriceSeries {
  _DerivedPriceSeries(List<EtfPriceHistoryPoint> points) {
    final ordered = [...points]..sort((a, b) => a.date.compareTo(b.date));
    if (ordered.isEmpty) {
      return;
    }
    final firstClose = ordered.first.performanceClose;
    var peak = firstClose;
    for (final point in ordered) {
      final close = point.performanceClose;
      if (close > peak) {
        peak = close;
      }
      _cumulativeByDate[_dateKey(point.date)] =
          firstClose <= 0 ? 0 : (close / firstClose - 1) * 100;
      _drawdownByDate[_dateKey(point.date)] =
          peak <= 0 ? 0 : (close / peak - 1) * 100;
    }
  }

  final Map<String, double> _cumulativeByDate = {};
  final Map<String, double> _drawdownByDate = {};

  double cumulativeReturnPct(DateTime date) {
    return _cumulativeByDate[_dateKey(date)] ?? 0;
  }

  double drawdownPct(DateTime date) {
    return _drawdownByDate[_dateKey(date)] ?? 0;
  }
}

List<EtfPriceHistoryPoint> _holdingChartPoints(
  List<EtfHoldingsHistoryPoint> points,
  double Function(EtfHoldingsHistoryPoint point) valueOf,
) {
  return [
    for (final point in points)
      EtfPriceHistoryPoint(date: point.tradeDate, close: valueOf(point)),
  ];
}

class _HorizontalTable extends StatelessWidget {
  const _HorizontalTable({
    required this.columns,
    required this.rows,
  });

  final List<String> columns;
  final List<List<String>> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const Text('尚無資料');
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 560) {
          return _MobileTableCards(columns: columns, rows: rows);
        }
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: columns.length * 132),
            child: DataTable(
              headingRowHeight: 40,
              dataRowMinHeight: 42,
              dataRowMaxHeight: 58,
              columns: [
                for (final column in columns)
                  DataColumn(
                    label: Text(
                      column,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
              ],
              rows: [
                for (final row in rows)
                  DataRow(
                    cells: [
                      for (final cell in row)
                        DataCell(
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 220),
                            child: Text(
                              cell,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MobileTableCards extends StatelessWidget {
  const _MobileTableCards({
    required this.columns,
    required this.rows,
  });

  final List<String> columns;
  final List<List<String>> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.42),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.isEmpty ? '-' : row.first,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (var index = 1; index < row.length; index++)
                          _MobileTableField(
                            label: index < columns.length
                                ? columns[index]
                                : '欄位 $index',
                            value: row[index],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MobileTableField extends StatelessWidget {
  const _MobileTableField({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 118, maxWidth: 180),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _BulletLine extends StatelessWidget {
  const _BulletLine({
    required this.text,
    required this.icon,
  });

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({
    super.key,
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: theme.colorScheme.surfaceContainerHighest,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(message),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.error,
    required this.onRefresh,
  });

  final Object error;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionBlock(
          title: '00631L 資料載入失敗',
          subtitle: '頁面沒有取得可用資料。請檢查後端或 mock fallback 設定。',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(error.toString()),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh),
                label: const Text('重新整理'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

const _marketBackgroundColor = Color(0xFF101010);
const _marketPanel = Color(0xFF181818);
const _marketPanelAlt = Color(0xFF202020);
const _marketNav = Color(0xFF1B1B1B);
const _marketBorder = Color(0xFF303030);
const _marketText = Color(0xFFF5F5F5);
const _marketMutedText = Color(0xFFAAAAAA);
const _marketRed = Color(0xFFFF5A5F);
const _marketGreen = Color(0xFF67C58B);
const _marketBlue = Color(0xFF7DD3FC);

const _marketLightBackgroundColor = Color(0xFFF4F7FA);
const _marketLightPanel = Color(0xFFFFFFFF);
const _marketLightPanelAlt = Color(0xFFF0F5F8);
const _marketLightNav = Color(0xFFFFFFFF);
const _marketLightBorder = Color(0xFFD7E0E7);
const _marketLightText = Color(0xFF14202B);
const _marketLightMutedText = Color(0xFF5C6B78);

ThemeData _marketTheme(BuildContext context, [ThemeMode? mode]) {
  final base = Theme.of(context);
  final dark = mode == null
      ? base.brightness == Brightness.dark
      : mode == ThemeMode.dark ||
          (mode == ThemeMode.system &&
              MediaQuery.platformBrightnessOf(context) == Brightness.dark);
  final background =
      dark ? _marketBackgroundColor : _marketLightBackgroundColor;
  final panel = dark ? _marketPanel : _marketLightPanel;
  final panelAlt = dark ? _marketPanelAlt : _marketLightPanelAlt;
  final border = dark ? _marketBorder : _marketLightBorder;
  final text = dark ? _marketText : _marketLightText;
  final mutedText = dark ? _marketMutedText : _marketLightMutedText;
  final headingRow = dark ? const Color(0xFF282828) : const Color(0xFFE8F0F5);
  final scheme = ColorScheme.fromSeed(
    seedColor: _marketBlue,
    brightness: dark ? Brightness.dark : Brightness.light,
  ).copyWith(
    primary: _marketBlue,
    onPrimary: Colors.black,
    secondary: _marketGreen,
    tertiary: _marketRed,
    surface: panel,
    surfaceContainerHighest: panelAlt,
    onSurface: text,
    onSurfaceVariant: mutedText,
    outlineVariant: border,
    error: dark ? const Color(0xFFFF7777) : const Color(0xFFB42318),
  );
  return base.copyWith(
    brightness: dark ? Brightness.dark : Brightness.light,
    colorScheme: scheme,
    scaffoldBackgroundColor: background,
    cardTheme: CardThemeData(
      elevation: 0,
      color: panel,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: border),
      ),
    ),
    dividerColor: border,
    textTheme: base.textTheme.apply(
      bodyColor: text,
      displayColor: text,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: panelAlt,
      labelStyle: TextStyle(color: mutedText),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _marketBlue),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: border),
      ),
    ),
    dataTableTheme: DataTableThemeData(
      headingRowColor: WidgetStatePropertyAll(headingRow),
      dataRowColor: WidgetStatePropertyAll(panel),
      dividerThickness: 0.8,
      headingTextStyle: TextStyle(
        color: mutedText,
        fontWeight: FontWeight.w900,
      ),
      dataTextStyle: TextStyle(color: text),
    ),
  );
}

bool _marketIsDark(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

Color _marketBackground(BuildContext context) => _marketIsDark(context)
    ? _marketBackgroundColor
    : _marketLightBackgroundColor;

Color _marketPanelColor(BuildContext context) =>
    _marketIsDark(context) ? _marketPanel : _marketLightPanel;

Color _marketPanelAltColor(BuildContext context) =>
    _marketIsDark(context) ? _marketPanelAlt : _marketLightPanelAlt;

Color _marketNavColor(BuildContext context) =>
    _marketIsDark(context) ? _marketNav : _marketLightNav;

Color _marketBorderColor(BuildContext context) =>
    _marketIsDark(context) ? _marketBorder : _marketLightBorder;

Color _marketTextColor(BuildContext context) =>
    _marketIsDark(context) ? _marketText : _marketLightText;

Color _marketMutedTextColor(BuildContext context) =>
    _marketIsDark(context) ? _marketMutedText : _marketLightMutedText;

DateTime? _historyFirstDate(EtfPriceHistory history) {
  if (history.coverageStart != null) {
    return history.coverageStart;
  }
  if (history.points.isEmpty) {
    return null;
  }
  final sorted = [...history.points]..sort((a, b) => a.date.compareTo(b.date));
  return sorted.first.date;
}

String _catalogSearchText(EtfCatalogItem item) {
  return '${item.code} ${item.name} ${item.targetType}'.toLowerCase();
}

List<EtfCatalogItem> _rankedSymbolSearchItems(
  List<EtfCatalogItem> items,
  String query,
) {
  final normalizedQuery = query.trim().toLowerCase();
  final indexed = items.indexed.toList(growable: false);
  indexed.sort((left, right) {
    final rankCompare = _symbolSearchRank(left.$2, normalizedQuery)
        .compareTo(_symbolSearchRank(right.$2, normalizedQuery));
    if (rankCompare != 0) {
      return rankCompare;
    }
    final leftReady = _catalogItemHasImportedEtfHistory(left.$2);
    final rightReady = _catalogItemHasImportedEtfHistory(right.$2);
    if (leftReady != rightReady) {
      return leftReady ? -1 : 1;
    }
    final codeCompare = left.$2.code.compareTo(right.$2.code);
    if (codeCompare != 0) {
      return codeCompare;
    }
    return left.$1.compareTo(right.$1);
  });
  return [for (final entry in indexed) entry.$2];
}

int _symbolSearchRank(EtfCatalogItem item, String query) {
  if (query.isEmpty) {
    return 0;
  }
  final code = item.code.trim().toLowerCase();
  final name = item.name.trim().toLowerCase();
  final targetType = item.targetType.trim().toLowerCase();
  if (code == query) {
    return 0;
  }
  if (code.startsWith(query)) {
    return 1;
  }
  if (code.contains(query)) {
    return 2;
  }
  if (name.contains(query)) {
    return 3;
  }
  if (targetType.contains(query)) {
    return 4;
  }
  return 5;
}

String _stockSearchText(Stock stock) {
  return '${stock.symbol} ${stock.name} ${stock.industry} ${stock.tags.join(' ')}'
      .toLowerCase();
}

EtfCatalogItem? _catalogItemByCode(EtfCatalog catalog, String code) {
  final normalized = code.trim().toUpperCase();
  for (final item in catalog.items) {
    if (item.code.trim().toUpperCase() == normalized) {
      return item;
    }
  }
  return null;
}

String _priceAdjustmentConfidenceKey(
  String code,
  EtfPriceHistoryCompletenessSummary summary,
) {
  final normalized = code.trim().toUpperCase();
  if (summary.hasNonUnitAdjustment ||
      _knownSplitAdjustedEtfCodes.contains(normalized)) {
    return 'known-split';
  }
  if (summary.hasAdjustedClose) {
    return 'close-mirrored';
  }
  return 'raw-close';
}

String _priceAdjustmentConfidenceLabel(
  String code,
  EtfPriceHistoryCompletenessSummary summary,
) {
  switch (_priceAdjustmentConfidenceKey(code, summary)) {
    case 'known-split':
      return summary.hasNonUnitAdjustment ? '分割已調整' : '分割規則已套用';
    case 'close-mirrored':
      return '調整價同收盤';
    default:
      return '原始收盤';
  }
}

bool _hasImportedEtfHistory(String code) {
  return _etfHistoryReadyCodes.contains(code.trim().toUpperCase());
}

_EtfHistoryReadiness _etfHistoryReadiness(EtfCatalogItem item) {
  final hasHistory = _catalogItemHasImportedEtfHistory(item);
  final is00631L = item.code.trim().toUpperCase() == '00631L';
  return _EtfHistoryReadiness(
    hasHistory: hasHistory,
    badgeLabel: hasHistory ? '歷史/回測可用' : '僅清單資料',
    trailingLabel: hasHistory ? '可切換' : '清單資料',
    capabilities: [
      _SymbolSearchCapability(
        key: hasHistory ? 'history' : 'catalog',
        label: hasHistory ? '歷史可用' : '僅清單',
      ),
      if (hasHistory) ...const [
        _SymbolSearchCapability(key: 'backtest', label: '回測可用'),
        _SymbolSearchCapability(key: 'compare', label: '可比較'),
        _SymbolSearchCapability(key: 'ai-context', label: 'AI 可解讀'),
      ] else ...const [
        _SymbolSearchCapability(
          key: 'history-missing',
          label: '缺歷史',
        ),
        _SymbolSearchCapability(
          key: 'backtest-unavailable',
          label: '回測未開',
        ),
        _SymbolSearchCapability(
          key: 'ai-context-limited',
          label: 'AI 有限',
        ),
      ],
      if (is00631L) ...const [
        _SymbolSearchCapability(
          key: 'holdings-source',
          label: '內容物來源',
        ),
        _SymbolSearchCapability(
          key: 'live-nav',
          label: '盤中 NAV',
        ),
      ] else
        const _SymbolSearchCapability(
          key: 'live-nav-scope',
          label: '盤中 NAV 限 00631L',
        ),
    ],
  );
}

String _symbolSearchCapabilitySummary(
  EtfCatalogItem item,
  _EtfHistoryReadiness readiness,
) {
  final code = item.code.trim().toUpperCase();
  final liveNavLabel = code == '00631L' ? '盤中 NAV 可用' : '盤中 NAV 限 00631L';
  if (readiness.hasHistory) {
    return '歷史、回測、比較與 AI context 可用；$liveNavLabel。';
  }
  return '目前僅清單資料；歷史、回測與比較需先匯入，$liveNavLabel。';
}

bool _symbolSearchFilterIncludes(
  _SymbolSearchHistoryFilter filter,
  EtfCatalogItem item,
) {
  switch (filter) {
    case _SymbolSearchHistoryFilter.all:
      return true;
    case _SymbolSearchHistoryFilter.ready:
      return _catalogItemHasImportedEtfHistory(item);
    case _SymbolSearchHistoryFilter.catalogOnly:
      return !_catalogItemHasImportedEtfHistory(item);
  }
}

class _EtfHistoryReadiness {
  const _EtfHistoryReadiness({
    required this.hasHistory,
    required this.badgeLabel,
    required this.trailingLabel,
    required this.capabilities,
  });

  final bool hasHistory;
  final String badgeLabel;
  final String trailingLabel;
  final List<_SymbolSearchCapability> capabilities;

  String snackMessage(String code) {
    if (hasHistory) {
      return '$code 已匯入歷史價格，可查看歷史與回測。';
    }
    return '$code 目前只有 ETF 清單；尚未匯入可驗證歷史價格。';
  }
}

class _SymbolSearchCapability {
  const _SymbolSearchCapability({
    required this.key,
    required this.label,
  });

  final String key;
  final String label;
}

int _catalogHistoryReadyCount(EtfCatalog catalog) {
  return catalog.items
      .where(_catalogItemHasImportedEtfHistory)
      .map((item) => item.code.trim().toUpperCase())
      .toSet()
      .length;
}

bool _catalogItemHasImportedEtfHistory(EtfCatalogItem item) {
  return item.hasPriceHistory || _hasImportedEtfHistory(item.code);
}

String _etfHistoryMetadataLabel(EtfCatalogItem item) {
  if (item.priceHistoryRowCount < 2) {
    return '';
  }
  final tier = item.priceHistoryCoverageTier.trim().isEmpty
      ? 'history'
      : item.priceHistoryCoverageTier.trim();
  return '$tier · ${formatInteger(item.priceHistoryRowCount)} 筆';
}

String _etfHistoryMissingReasonLabel(EtfCatalogItem item) {
  if (_catalogItemHasImportedEtfHistory(item)) {
    return '';
  }
  final reason = item.priceHistoryGapReason.trim();
  if (reason.isNotEmpty) {
    return _etfGapReasonLabel(reason);
  }
  final tier = item.priceHistoryCoverageTier.trim();
  if (tier == 'error') {
    return _etfGapReasonLabel('source_error');
  }
  final sourceStatus = item.priceHistorySourceStatus.trim();
  if (sourceStatus == 'error') {
    return _etfGapReasonLabel('source_error');
  }
  return '';
}

String _etfHistoryPriceBasisLabel(EtfCatalogItem item) {
  if (!_catalogItemHasImportedEtfHistory(item)) {
    return '';
  }
  final priceField = item.priceHistoryPriceField.trim();
  if (priceField == 'adjustedClose') {
    return item.priceHistoryAdjustmentEventCount > 0 ? '調整價/分割' : '調整價';
  }
  if (priceField == 'close') {
    return '收盤價';
  }
  return '';
}

String _symbolSearchDataSummary(EtfCatalogItem item) {
  if (!_catalogItemHasImportedEtfHistory(item)) {
    final reason = _etfHistoryMissingReasonLabel(item);
    return reason.isEmpty ? '歷史：尚未匯入；資料基礎：待補齊' : '歷史：尚未匯入；資料基礎：$reason';
  }
  final rows = formatInteger(item.priceHistoryRowCount);
  final start = item.priceHistoryCoverageStart;
  final end = item.priceHistoryCoverageEnd;
  final coverage = start == null || end == null
      ? '區間待確認'
      : '${formatTaiwanDate(start)}-${formatTaiwanDate(end)}';
  final basis = _etfHistoryPriceBasisLabel(item);
  final basisText = basis.isEmpty ? '可驗證價格歷史' : basis;
  return '歷史：$rows 筆，$coverage；資料基礎：$basisText';
}

int _searchReadyHistoryCount(Etf00631LLabData data) {
  final catalogCount = _catalogHistoryReadyCount(data.etfCatalog);
  final operationsCount = data.operationsStatus.etfPriceHistoryReadyCount;
  return operationsCount > catalogCount ? operationsCount : catalogCount;
}

int _effectiveEtfCatalogRows({
  required EtfOperationsStatus status,
  required int loadedCatalogRows,
}) {
  return [
    loadedCatalogRows,
    status.etfCatalogRowCount,
  ].fold<int>(0, (maxRows, rows) => rows > maxRows ? rows : maxRows);
}

int _etfDataCompletionTotal({
  required EtfOperationsStatus status,
  required int catalogRows,
}) {
  return [
    catalogRows,
    status.etfCatalogRowCount,
    status.etfPriceHistoryRowCount,
    status.etfPriceHistoryReadyCount,
    status.etfPriceHistoryReadyCount + status.etfPriceHistoryMissingCount,
  ].fold<int>(0, (maxRows, rows) => rows > maxRows ? rows : maxRows);
}

List<EtfPriceHistory> _mergeSelectedComparisonHistories({
  required EtfPriceHistory selectedHistory,
  required List<EtfPriceHistory> histories,
}) {
  final byCode = <String, EtfPriceHistory>{};
  void put(EtfPriceHistory history) {
    final code = history.code.trim().toUpperCase();
    if (code.isEmpty) {
      return;
    }
    final existing = byCode[code];
    if (existing == null || history.points.length >= existing.points.length) {
      byCode[code] = history;
    }
  }

  put(selectedHistory);
  for (final history in histories) {
    put(history);
  }

  const preferredOrder = ['00631L', '0050', '006208', '00878', '00919'];
  final values = byCode.values.toList(growable: false);
  values.sort((a, b) {
    final selectedCode = selectedHistory.code.trim().toUpperCase();
    if (a.code == selectedCode && b.code != selectedCode) {
      return -1;
    }
    if (b.code == selectedCode && a.code != selectedCode) {
      return 1;
    }
    final aIndex = preferredOrder.indexOf(a.code);
    final bIndex = preferredOrder.indexOf(b.code);
    if (aIndex != -1 || bIndex != -1) {
      return (aIndex == -1 ? 999 : aIndex)
          .compareTo(bIndex == -1 ? 999 : bIndex);
    }
    return a.code.compareTo(b.code);
  });
  return values;
}

DateTime? _latestHistoryEnd(List<EtfPriceHistory> histories) {
  DateTime? latest;
  for (final history in histories) {
    final end = _historyLastDate(history);
    if (end != null && (latest == null || end.isAfter(latest))) {
      latest = end;
    }
  }
  return latest;
}

_EtfComparisonMetric _comparisonMetricForHistory({
  required EtfPriceHistory history,
  required DateTime startDate,
  required DateTime endDate,
}) {
  final filtered = _filteredPriceHistory(
    history,
    startDate: startDate,
    endDate: endDate,
  );
  final summary = filtered.completenessSummary();
  final performance = filtered.performance;
  final code = history.code.trim().toUpperCase();
  return _EtfComparisonMetric(
    code: code.isEmpty ? 'ETF' : code,
    name: _historyDisplayName(history),
    rowCount: summary.rowCount,
    coverageStart: summary.coverageStart,
    coverageEnd: summary.coverageEnd,
    latestClose: summary.latest?.performanceClose,
    totalReturnPct: performance.totalReturnPct,
    annualizedReturnPct: performance.annualizedReturnPct,
    maxDrawdownPct: performance.maxDrawdownPct,
    annualizedVolatilityPct: performance.annualizedVolatilityPct,
    sourceStatusLabel: history.sourceStatusLabel,
  );
}

String _historyDisplayName(EtfPriceHistory history) {
  final name = history.name.trim();
  if (name.isNotEmpty && name != history.code) {
    return name;
  }
  return _knownEtfName(history.code) ?? history.code;
}

bool _comparisonFilterIncludes(
  _EtfComparisonFilter filter,
  String code,
) {
  final normalized = code.trim().toUpperCase();
  switch (filter) {
    case _EtfComparisonFilter.focused:
      return const {'00631L', '0050', '006208', '00878', '00919'}
          .contains(normalized);
    case _EtfComparisonFilter.market:
      return const {'0050', '006208', '00692', '00850', '00922', '00923'}
          .contains(normalized);
    case _EtfComparisonFilter.dividend:
      return const {'0056', '00713', '00878', '00919', '00929', '00940'}
          .contains(normalized);
    case _EtfComparisonFilter.tech:
      return const {'00757', '00881', '00929'}.contains(normalized);
    case _EtfComparisonFilter.all:
      return true;
  }
}

_EtfComparisonFilter _defaultComparisonFilterForCode(String code) {
  final normalized = code.trim().toUpperCase();
  if (const {'0050', '006208', '00692', '00850', '00922', '00923'}
      .contains(normalized)) {
    return _EtfComparisonFilter.market;
  }
  if (const {'0056', '00713', '00878', '00919', '00929', '00940'}
      .contains(normalized)) {
    return _EtfComparisonFilter.dividend;
  }
  if (const {'00757', '00881'}.contains(normalized)) {
    return _EtfComparisonFilter.tech;
  }
  return _EtfComparisonFilter.focused;
}

Set<String> _presetComparisonCodes(
  _EtfComparisonFilter filter,
  List<_EtfComparisonMetric> availableMetrics,
) {
  return {
    for (final metric in availableMetrics)
      if (_comparisonFilterIncludes(filter, metric.code)) metric.code,
  }.take(5).toSet();
}

_EtfComparisonBasketContext _comparisonBasketContext(
  List<_EtfComparisonMetric> metrics,
) {
  if (metrics.isEmpty) {
    return const _EtfComparisonBasketContext(
      labels: [
        '尚未選擇',
        '共同區間不足',
        '最少筆數 -',
      ],
      explanation: '尚未選擇比較 ETF；勾選 1-5 檔後，圖表會用同一期間起點重算百分比，沒有固定比較基準。',
    );
  }

  DateTime? commonStart;
  DateTime? commonEnd;
  var minRows = metrics.first.rowCount;
  final statuses = <String>{};
  for (final metric in metrics) {
    final start = metric.coverageStart;
    final end = metric.coverageEnd;
    if (start != null && (commonStart == null || start.isAfter(commonStart))) {
      commonStart = start;
    }
    if (end != null && (commonEnd == null || end.isBefore(commonEnd))) {
      commonEnd = end;
    }
    if (metric.rowCount < minRows) {
      minRows = metric.rowCount;
    }
    if (metric.sourceStatusLabel.trim().isNotEmpty) {
      statuses.add(metric.sourceStatusLabel.trim());
    }
  }
  final hasCommonRange = commonStart != null &&
      commonEnd != null &&
      !commonStart.isAfter(commonEnd);
  final statusLabel = statuses.isEmpty ? 'unknown' : statuses.take(3).join('/');
  final codes = metrics.map((metric) => metric.code).join(' / ');
  return _EtfComparisonBasketContext(
    labels: [
      '組合 $codes',
      hasCommonRange
          ? '共同區間 ${_dateOrDash(commonStart)} - ${_dateOrDash(commonEnd)}'
          : '共同區間不足',
      '最少筆數 ${formatInteger(minRows)}',
      '來源 $statusLabel',
    ],
    explanation: hasCommonRange
        ? '目前比較組合會用共同資料區間重算百分比；這是自選比較，不把任何 ETF 設成固定基準。'
        : '目前比較組合的歷史區間沒有完整重疊；請調整 ETF 組合或確認價格歷史匯入狀態。',
  );
}

String _comparisonCommonRangeText(List<_EtfComparisonMetric> metrics) {
  if (metrics.isEmpty) {
    return '共同區間 --';
  }
  DateTime? commonStart;
  DateTime? commonEnd;
  for (final metric in metrics) {
    final start = metric.coverageStart;
    final end = metric.coverageEnd;
    if (start != null && (commonStart == null || start.isAfter(commonStart))) {
      commonStart = start;
    }
    if (end != null && (commonEnd == null || end.isBefore(commonEnd))) {
      commonEnd = end;
    }
  }
  if (commonStart == null ||
      commonEnd == null ||
      commonStart.isAfter(commonEnd)) {
    return '共同區間不足';
  }
  return '共同區間 ${_dateOrDash(commonStart)} - ${_dateOrDash(commonEnd)}';
}

List<EtfPriceHistory> _comparisonChartHistories({
  required List<EtfPriceHistory> histories,
  required List<_EtfComparisonMetric> metrics,
}) {
  final byCode = <String, EtfPriceHistory>{
    for (final history in histories) history.code.trim().toUpperCase(): history,
  };
  return [
    for (final metric in metrics.take(5))
      if (byCode[metric.code] != null) byCode[metric.code]!,
  ];
}

List<_EtfComparisonChartSeries> _buildComparisonChartSeries({
  required BuildContext context,
  required List<EtfPriceHistory> histories,
  required DateTime startDate,
  required DateTime endDate,
}) {
  final theme = Theme.of(context);
  final palette = [
    theme.colorScheme.primary,
    theme.colorScheme.tertiary,
    theme.colorScheme.secondary,
    Colors.amber.shade700,
    Colors.pinkAccent.shade200,
  ];
  final series = <_EtfComparisonChartSeries>[];
  for (var index = 0;
      index < histories.length && index < palette.length;
      index += 1) {
    final history = histories[index];
    final points = [
      for (final point in history.points)
        if (!point.date.isBefore(startDate) && !point.date.isAfter(endDate))
          point,
    ]..sort((a, b) => a.date.compareTo(b.date));
    if (points.length < 2) {
      continue;
    }
    final base = points.first.performanceClose;
    if (base <= 0) {
      continue;
    }
    final spots = <FlSpot>[];
    for (final point in points) {
      final x = point.date.difference(startDate).inDays.toDouble();
      final y = (point.performanceClose / base - 1) * 100;
      if (x.isFinite && y.isFinite) {
        spots.add(FlSpot(x, y));
      }
    }
    if (spots.length < 2) {
      continue;
    }
    series.add(
      _EtfComparisonChartSeries(
        code: history.code,
        name: _historyDisplayName(history),
        color: palette[index],
        spots: spots,
        points: [
          for (final point in points) point.date,
        ],
      ),
    );
  }
  return series;
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String? _knownEtfName(String code) {
  switch (code.trim().toUpperCase()) {
    case '00631L':
      return '元大台灣50正2';
    case '0050':
      return '元大台灣50';
    case '0056':
      return '元大高股息';
    case '006208':
      return '富邦台50';
    case '00692':
      return '富邦公司治理';
    case '00713':
      return '元大台灣高息低波';
    case '00757':
      return '統一FANG+';
    case '00850':
      return '元大臺灣ESG永續';
    case '00878':
      return '國泰永續高股息';
    case '00881':
      return '國泰台灣5G+';
    case '00919':
      return '群益台灣精選高息';
    case '00922':
      return '國泰台灣領袖50';
    case '00923':
      return '群益台ESG低碳50';
    case '00929':
      return '復華台灣科技優息';
    case '00940':
      return '元大台灣價值高息';
    default:
      return null;
  }
}

bool _isTaiwanEquityEtf(EtfCatalogItem item) {
  final text = _catalogSearchText(item);
  return text.contains('台灣') ||
      text.contains('臺灣') ||
      text.contains('twse') ||
      text.contains('上市') ||
      text.contains('加權') ||
      text.contains('0050') ||
      text.contains('006208');
}

bool _isDividendEtf(EtfCatalogItem item) {
  final text = _catalogSearchText(item);
  return text.contains('高股息') ||
      text.contains('股利') ||
      text.contains('收益') ||
      text.contains('00878') ||
      text.contains('00919');
}

bool _isLeveragedOrInverseEtf(EtfCatalogItem item) {
  final text = _catalogSearchText(item);
  return text.contains('槓桿') ||
      text.contains('正2') ||
      text.contains('正 2') ||
      text.contains('反向') ||
      text.contains('00631l');
}

DateTime? _historyLastDate(EtfPriceHistory history) {
  if (history.coverageEnd != null) {
    return history.coverageEnd;
  }
  if (history.points.isEmpty) {
    return null;
  }
  final sorted = [...history.points]..sort((a, b) => a.date.compareTo(b.date));
  return sorted.last.date;
}

DateTime _defaultTrailingStart({
  required DateTime? first,
  required DateTime end,
  required int years,
}) {
  final candidate = DateTime(end.year - years, end.month, end.day);
  if (first != null && candidate.isBefore(first)) {
    return first;
  }
  return candidate;
}

enum _DateRangePreset {
  oneYear('近 1 年'),
  threeYears('近 3 年'),
  all('全部資料'),
  custom('自訂區間');

  const _DateRangePreset(this.label);

  final String label;
}

_DateRangePreset _activeDateRangePreset({
  required DateTime? startDate,
  required DateTime? endDate,
  required DateTime? firstDate,
  required DateTime? lastDate,
}) {
  if (startDate == null || endDate == null || lastDate == null) {
    return _DateRangePreset.custom;
  }
  if (_isSameDate(endDate, lastDate)) {
    final oneYearStart = _defaultTrailingStart(
      first: firstDate,
      end: lastDate,
      years: 1,
    );
    if (_isSameDate(startDate, oneYearStart)) {
      return _DateRangePreset.oneYear;
    }
    if (firstDate != null && _isSameDate(startDate, firstDate)) {
      return _DateRangePreset.all;
    }
    final threeYearStart = _defaultTrailingStart(
      first: firstDate,
      end: lastDate,
      years: 3,
    );
    if (_isSameDate(startDate, threeYearStart)) {
      return _DateRangePreset.threeYears;
    }
  }
  return _DateRangePreset.custom;
}

bool _isSameDate(DateTime left, DateTime right) {
  return left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}

EtfPriceHistory _filteredPriceHistory(
  EtfPriceHistory history, {
  required DateTime? startDate,
  required DateTime? endDate,
}) {
  final filteredPoints = [
    for (final point in history.points)
      if ((startDate == null || !point.date.isBefore(startDate)) &&
          (endDate == null || !point.date.isAfter(endDate)))
        point,
  ]..sort((a, b) => a.date.compareTo(b.date));

  return EtfPriceHistory(
    code: history.code,
    name: history.name,
    points: filteredPoints,
    status: history.status,
    sourceStatusLabel: history.sourceStatusLabel,
    sourceUrl: history.sourceUrl,
    lastFetchedAt: history.lastFetchedAt,
    coverageStart: filteredPoints.isEmpty ? null : filteredPoints.first.date,
    coverageEnd: filteredPoints.isEmpty ? null : filteredPoints.last.date,
    isCompleteFromListing: false,
    sourceContractCounts: history.sourceContractCounts,
    errorMessage: history.errorMessage,
  );
}

String _price(num? value) {
  if (value == null) {
    return 'unavailable';
  }
  return value.toStringAsFixed(2);
}

String _compactNumber(num? value) {
  if (value == null) {
    return 'unavailable';
  }
  final absValue = value.abs();
  if (absValue >= 1000000000) {
    return '${(value / 1000000000).toStringAsFixed(2)}B';
  }
  if (absValue >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(2)}M';
  }
  if (absValue >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)}K';
  }
  return value.toStringAsFixed(0);
}

String _dateOrDash(DateTime? date) {
  return date == null ? 'unavailable' : formatTaiwanDate(date);
}

String _dateTimeOrDash(DateTime? dateTime) {
  return dateTime == null
      ? 'unavailable'
      : formatTaiwanDateTimeSeconds(dateTime);
}

String _shortGitSha(String value) {
  final normalized = value.trim();
  if (normalized.length <= 12) {
    return normalized.isEmpty ? 'unavailable' : normalized;
  }
  return normalized.substring(0, 12);
}

String _sourceTimeText(DateTime dateTime, {DateTime? now}) {
  final source = _asTaipeiClock(dateTime);
  final current = _asTaipeiClock(now ?? DateTime.now());
  if (_sameCalendarDate(source, current)) {
    return formatTimeSeconds(source);
  }
  return formatTaiwanDateTimeSeconds(source);
}

DateTime _asTaipeiClock(DateTime value) {
  final shifted = value.toUtc().add(const Duration(hours: 8));
  return DateTime(
    shifted.year,
    shifted.month,
    shifted.day,
    shifted.hour,
    shifted.minute,
    shifted.second,
  );
}

bool _sameCalendarDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

Future<DateTime?> _pickBacktestDate({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime? firstDate,
  required DateTime? lastDate,
  required String helpText,
}) {
  final earliest = firstDate ?? DateTime(2014, 10, 31);
  final latest = lastDate ?? DateTime.now();
  final boundedInitial = initialDate.isBefore(earliest)
      ? earliest
      : initialDate.isAfter(latest)
          ? latest
          : initialDate;
  return showDatePicker(
    context: context,
    firstDate: earliest,
    lastDate: latest,
    initialDate: boundedInitial,
    helpText: helpText,
  );
}

String _monthDay(DateTime date) {
  return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
}

String _dateKey(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

EtfFuturesHoldingLine? _primaryFuturesLine(EtfDailyHoldingSnapshot snapshot) {
  for (final line in snapshot.futuresHoldings) {
    final code = line.code.toUpperCase();
    final name = line.name.toUpperCase();
    if (code.contains('TX') || name.contains('TX')) {
      return line;
    }
  }
  return snapshot.futuresHoldings.isEmpty
      ? null
      : snapshot.futuresHoldings.first;
}

EtfStockHoldingLine? _stockHoldingByCode(
  EtfDailyHoldingSnapshot snapshot,
  String code,
) {
  for (final line in snapshot.stockHoldings) {
    if (line.code == code) {
      return line;
    }
  }
  return null;
}

List<_StatusItem> _dataCoverageItems(Etf00631LLabData data) {
  final price = data.priceHistory.completenessSummary();
  final holdingsCount = _holdingsHistoryCount(data);
  final latestHoldingDate = _latestHoldingsDate(data);
  final intradayTime = _intradayDataTimeText(data.intradayNav);
  final intradaySession = data.intradayNav?.marketSession() ??
      IntradayMarketSession.evaluate(sourceAvailable: false);
  final txLine = _primaryFuturesLine(data.snapshot);
  final txQuote = data.futuresQuote;
  final txSymbol = txQuote.txSymbol ?? txQuote.symbol;
  final txTime =
      txQuote.dataTime == null ? '-' : _sourceTimeText(txQuote.dataTime!);

  return [
    _StatusItem(
      label: '價格歷史',
      status: _priceCoverageStatus(data),
      detail:
          '筆數 ${formatInteger(price.rowCount)}，範圍 ${_dateOrDash(price.coverageStart)} - ${_dateOrDash(price.coverageEnd)}，來源 ${_sourceStatusBadgeLabel(data.priceHistory.sourceStatusLabel)}。',
      action: price.rowCount >= 2
          ? price.isCompleteFromListing
              ? '已可支援歷史與回測；資料範圍仍以公開靜態清單與官方更新時間為準。'
              : '可支援歷史與回測，但資料範圍不是完整上市以來區間。'
          : '請執行 scripts\\00631l_update_price_history.cmd 或 scripts\\00631l_export_static_data.cmd --update。',
    ),
    _StatusItem(
      label: '內容物歷史',
      status: _holdingsCoverageStatus(data),
      detail:
          '最新 ${_dateOrDash(latestHoldingDate)}，歷史筆數 $holdingsCount；${_holdingsGapText(data)}；官方 ratio 是每日快照。',
      action: holdingsCount > 0
          ? _holdingsIntegrityAction(data)
          : '請執行 scripts\\00631l_daily_cycle.cmd 累積官方每日快照。',
    ),
    _StatusItem(
      label: '盤中 NAV / 折溢價',
      status: data.intradayNav?.status.label ?? 'unavailable',
      detail: '資料時間 $intradayTime；盤中 NAV 需要後端服務連到 TWSE all_etf.txt。',
      action: data.intradayNav == null
          ? '公開靜態模式只提供歷史與回測；若要盤中資料，請啟用公開後端服務。'
          : '請以資料時間與來源格式為準。',
    ),
    _StatusItem(
      label: '盤中時段',
      status: intradaySession.dataFreshness,
      detail:
          '${intradaySession.phaseLabel}；${intradaySession.dataFreshnessLabel}；資料年齡 ${intradaySession.ageText}；下一次自動刷新 ${intradaySession.refreshText}。',
      action: intradaySession.isRegularSession
          ? '盤中只高頻更新 NAV、折溢價與狀態；官方 內容物 仍是每日快照。'
          : '非盤中時段會保留最後資料時間，請以官方資料時間為準。',
    ),
    _StatusItem(
      label: '台指期即時',
      status: txQuote.status.label,
      detail:
          'TAIFEX 來源 ${txQuote.sourceContract ?? 'quote'}；${txQuote.contractMonth} $txSymbol ${_price(txQuote.txPrice)}，加權指數 ${_price(txQuote.weightedIndex)}，基差 ${formatSignedNullablePercent(txQuote.futuresBasisPct)}，資料時間 $txTime。官方內容物台指期權重 ${txLine == null ? '暫無' : formatNullablePercent(txLine.weightPct)}。',
      action: txQuote.txPrice == null
          ? '請確認 TAIFEX 交易時段、後端連線與 TAIFEX_TX_SOCKJS_URL 設定。'
          : '請以 TAIFEX 資料時間與官方內容物日期分別判讀。',
    ),
    _StatusItem(
      label: 'ETF 清單資料',
      status: data.operationsStatus.etfCatalogStatus,
      detail:
          'TWSE all_etf 筆數 ${formatInteger(data.operationsStatus.etfCatalogRowCount)}；資料時間 ${_dateTimeOrDash(data.operationsStatus.etfCatalogDataTime)}。',
      action: data.operationsStatus.etfCatalogRowCount > 0
          ? 'ETF 清單已匯入；目前研究室仍以選取 ETF 為核心。'
          : '請執行 scripts\\00631l_import_etf_catalog.cmd 匯入 TWSE all_etf 清單。',
    ),
    _StatusItem(
      label: 'ETF 價格歷史',
      status: data.operationsStatus.etfPriceHistoryStatus,
      detail:
          '可用 ${formatInteger(data.operationsStatus.etfPriceHistoryReadyCount)} / 清單 ${formatInteger(data.operationsStatus.etfPriceHistoryRowCount)}；缺口明細 ${formatInteger(data.operationsStatus.etfPriceHistoryGapDetailCount)}；已嘗試 ${formatInteger(data.operationsStatus.etfPriceHistoryAttemptedCount)}；保留歷史 ${formatInteger(data.operationsStatus.etfPriceHistoryOutOfCatalogCount)}；${_etfCoverageTierDetail(data.operationsStatus)}；${_etfHistorySourceContractDetail(data.operationsStatus)}；${_etfGapReasonDetail(data.operationsStatus)}；資料時間 ${_dateTimeOrDash(data.operationsStatus.etfPriceHistoryDataTime)}。',
      action: data.operationsStatus.etfPriceHistoryReadyCount > 0
          ? 'ETF 價格歷史已可作為比較資料基礎。'
          : '請執行 scripts\\00631l_import_etf_price_history.cmd 匯入選取 ETF 的價格歷史。',
    ),
  ];
}

String _etfCoverageTierDetail(EtfOperationsStatus status) {
  final counts = status.etfPriceHistoryCoverageTierCounts;
  if (counts.isEmpty) {
    return '資料期間分類暫無資料';
  }
  return '${_etfCoverageTierLabel('long_term')} ${formatInteger(counts['long_term'] ?? 0)}, ${_etfCoverageTierLabel('recent')} ${formatInteger(counts['recent'] ?? 0)}, ${_etfCoverageTierLabel('unavailable')} ${formatInteger(counts['unavailable'] ?? 0)}, ${_etfCoverageTierLabel('error')} ${formatInteger(counts['error'] ?? 0)}';
}

String _etfHistorySourceContractDetail(EtfOperationsStatus status) {
  return _historySourceContractDetail(
    status.etfPriceHistorySourceContractCounts,
  );
}

String _historySourceContractDetail(Map<String, int> counts) {
  if (counts.isEmpty) {
    return '來源待確認';
  }
  final twse = counts['twse_stock_day_json'] ?? 0;
  final tpex = counts['tpex_etf_historical_daily_json'] ?? 0;
  final other = counts.entries
      .where(
        (entry) =>
            entry.key != 'twse_stock_day_json' &&
            entry.key != 'tpex_etf_historical_daily_json',
      )
      .fold<int>(0, (sum, entry) => sum + entry.value);
  final parts = <String>[
    if (twse > 0) 'TWSE ${formatInteger(twse)}',
    if (tpex > 0) 'TPEx ${formatInteger(tpex)}',
    if (other > 0) '其他 ${formatInteger(other)}',
  ];
  if (parts.isEmpty) {
    return '來源待確認';
  }
  return '來源 ${parts.join(' / ')}';
}

String _etfGapReasonDetail(EtfOperationsStatus status) {
  final counts = status.etfPriceHistoryGapReasonCounts;
  if (counts.isEmpty) {
    return '缺口原因暫無資料';
  }
  final parts = <String>[
    if ((counts['official_empty'] ?? 0) > 0)
      '${_etfGapReasonLabel('official_empty')} ${formatInteger(counts['official_empty'] ?? 0)}',
    if ((counts['not_saved'] ?? 0) > 0)
      '${_etfGapReasonLabel('not_saved')} ${formatInteger(counts['not_saved'] ?? 0)}',
    if ((counts['insufficient_rows'] ?? 0) > 0)
      '${_etfGapReasonLabel('insufficient_rows')} ${formatInteger(counts['insufficient_rows'] ?? 0)}',
    if ((counts['validation_error'] ?? 0) > 0)
      '${_etfGapReasonLabel('validation_error')} ${formatInteger(counts['validation_error'] ?? 0)}',
    if ((counts['source_error'] ?? 0) > 0)
      '${_etfGapReasonLabel('source_error')} ${formatInteger(counts['source_error'] ?? 0)}',
    if ((counts['not_ready'] ?? 0) > 0)
      '${_etfGapReasonLabel('not_ready')} ${formatInteger(counts['not_ready'] ?? 0)}',
  ];
  if (parts.isEmpty) {
    return '缺口原因已清空';
  }
  return '缺口: ${parts.join(', ')}';
}

String _etfGapReasonCompactLabel(EtfOperationsStatus status) {
  final counts = status.etfPriceHistoryGapReasonCounts;
  final officialEmpty = counts['official_empty'] ?? 0;
  final sourceError = counts['source_error'] ?? 0;
  final notSaved = counts['not_saved'] ?? 0;
  if (officialEmpty > 0 || sourceError > 0) {
    return '原因 ${_etfGapReasonLabel('official_empty')} ${formatInteger(officialEmpty)} / ${_etfGapReasonLabel('source_error')} ${formatInteger(sourceError)}';
  }
  if (notSaved > 0) {
    return '原因 ${_etfGapReasonLabel('not_saved')} ${formatInteger(notSaved)}';
  }
  return '原因已分類';
}

String _etfGapReasonSampleDetail(EtfOperationsStatus status) {
  final samples = status.etfPriceHistoryGapReasonSamples;
  if (samples.isEmpty) {
    return '樣本代號暫無資料';
  }
  final parts = <String>[];
  for (final entry in samples.entries) {
    final codes = entry.value.where((code) => code.trim().isNotEmpty).take(5);
    if (codes.isEmpty) {
      continue;
    }
    parts.add('${_etfGapReasonLabel(entry.key)}: ${codes.join(', ')}');
  }
  if (parts.isEmpty) {
    return '樣本代號暫無資料';
  }
  return '樣本代號 ${parts.join(' / ')}';
}

String _etfGapReasonLabel(String reason) {
  switch (reason) {
    case 'official_empty':
      return '官方無資料';
    case 'not_saved':
      return '尚未匯入';
    case 'insufficient_rows':
      return '資料不足';
    case 'validation_error':
      return '驗證異常';
    case 'source_error':
      return '來源錯誤';
    case 'not_ready':
      return '尚未就緒';
    default:
      return reason;
  }
}

String _etfCoverageTierLabel(String tier) {
  switch (tier) {
    case 'long_term':
      return '長期資料';
    case 'recent':
      return '近期資料';
    case 'unavailable':
      return '未匯入';
    case 'error':
      return '異常';
    default:
      return tier;
  }
}

_StatusItem _etfHistoryGapReasonItem(EtfOperationsStatus status) {
  final detail = _etfGapReasonDetail(status);
  final sampleDetail = _etfGapReasonSampleDetail(status);
  final missing = status.etfPriceHistoryMissingCount;
  final unclassified = status.etfPriceHistoryGapReasonCounts['not_saved'] ?? 0;
  final outOfCatalog = status.etfPriceHistoryOutOfCatalogCount;
  return _StatusItem(
    label: '資料缺口原因',
    status: missing > 0 ? '${formatInteger(missing)} 檔待補' : '已清空',
    detail:
        '$detail；$sampleDetail；缺口明細 ${formatInteger(status.etfPriceHistoryGapDetailCount)}；已嘗試 ${formatInteger(status.etfPriceHistoryAttemptedCount)}；保留歷史 ${formatInteger(outOfCatalog)}',
    action: unclassified > 0
        ? '可執行 scripts\\00631l_probe_missing_etf_reasons.cmd，將缺口分類成官方空資料、來源錯誤、驗證錯誤或可用資料。'
        : '目前 ETF 歷史索引沒有待補缺口；維持驗收檢查即可。',
  );
}

_StatusItem _etfHistoryNextActionItem({
  required EtfOperationsStatus status,
  required int historyTotal,
  required int missingCount,
}) {
  if (historyTotal <= 0) {
    return const _StatusItem(
      label: '資料補齊動作',
      status: 'catalog 未載入',
      detail: 'ETF 清單或價格歷史索引尚未載入，無法計算缺口。',
      action:
          '請先執行 scripts\\00631l_import_etf_catalog.cmd，再執行 scripts\\00631l_import_missing_etf_batch.cmd。',
    );
  }
  final unclassified = status.etfPriceHistoryGapReasonCounts['not_saved'] ?? 0;
  if (unclassified > 0) {
    return _StatusItem(
      label: '資料整理',
      status: '未分類 ${formatInteger(unclassified)}',
      detail:
          '目前已匯入 ${formatInteger(status.etfPriceHistoryReadyCount)} / ${formatInteger(historyTotal)} 檔 ETF 歷史，仍有未分類缺口。',
      action:
          '請執行 scripts\\00631l_probe_missing_etf_reasons.cmd，完成後再執行 scripts\\00631l_export_static_data.cmd --status-only。',
    );
  }
  if (missingCount > 0) {
    return _StatusItem(
      label: '資料整理',
      status: '缺口已分類',
      detail:
          '目前已匯入 ${formatInteger(status.etfPriceHistoryReadyCount)} / ${formatInteger(historyTotal)} 檔 ETF 歷史；其餘缺口已有官方空資料或來源錯誤等原因。',
      action: '請維持排程靜態匯出與驗收檢查。',
    );
  }
  if (missingCount > 0) {
    return _StatusItem(
      label: '資料補齊動作',
      status: '仍有 ${formatInteger(missingCount)} 檔缺口',
      detail:
          '目前已匯入 ${formatInteger(status.etfPriceHistoryReadyCount)} / ${formatInteger(historyTotal)} 檔 ETF 歷史；只會使用可驗證的官方資料。',
      action:
          '下一步可執行 scripts\\00631l_import_missing_etf_batch.cmd，完成後再跑 scripts\\00631l_export_static_data.cmd --status-only。',
    );
  }
  return _StatusItem(
    label: '資料補齊動作',
    status: '缺口已清空',
    detail:
        '目前 ${formatInteger(status.etfPriceHistoryReadyCount)} / ${formatInteger(historyTotal)} 檔 ETF 歷史已可用。',
    action:
        '日常可執行 scripts\\00631l_import_etf_price_history.cmd --status-only --summary-only 追蹤資料狀態。',
  );
}

List<_StatusItem> _holdingsCoverageItems(Etf00631LLabData data) {
  final status = data.operationsStatus;
  final snapshot = data.snapshot;
  final count = _holdingsHistoryCount(data);
  return [
    _StatusItem(
      label: '當日官方快照',
      status: snapshot.status.label,
      detail:
          'tradeDate ${formatTaiwanDate(snapshot.tradeDate)}；這是 Yuanta official ratio 每日資料。',
      action: snapshot.isStale(data.lastFetchedAt)
          ? '請執行每日流程並確認官方 ratio 來源。'
          : '請以官方內容物日期為準。',
    ),
    _StatusItem(
      label: 'history 累積',
      status: _holdingsCoverageStatus(data),
      detail:
          '歷史筆數 $count，最新 ${_dateOrDash(_latestHoldingsDate(data))}；不是發行以來完整內容物。',
      action: count == 0
          ? '請執行 scripts\\00631l_daily_cycle.cmd。'
          : '後續每日執行每日流程會繼續補新的官方快照。',
    ),
    _StatusItem(
      label: '完整性檢查',
      status: status.integrityStatus,
      detail:
          'warnings ${status.integrityWarningCount}，failures ${status.integrityFailureCount}，${_holdingsGapText(data)}。',
      action: _holdingsIntegrityAction(data),
    ),
  ];
}

String _priceCoverageStatus(Etf00631LLabData data) {
  final price = data.priceHistory.completenessSummary();
  if (price.rowCount < 2) {
    return 'unavailable';
  }
  if (price.isCompleteFromListing) {
    return '${data.priceHistory.sourceStatusLabel} complete';
  }
  return '${data.priceHistory.sourceStatusLabel} partial';
}

String _holdingsCoverageStatus(Etf00631LLabData data) {
  final count = _holdingsHistoryCount(data);
  final status = data.operationsStatus;
  if (count == 0) {
    return 'not accumulated';
  }
  if (status.integrityFailureCount > 0) {
    return '完整性異常';
  }
  if (status.holdingsMissingWeekdayCount > 0) {
    return '${data.holdingsHistory.sourceStatusLabel} gap';
  }
  if (status.integrityStatus == 'missing') {
    return '${data.holdingsHistory.sourceStatusLabel} unchecked';
  }
  return '${data.holdingsHistory.sourceStatusLabel} accumulated';
}

String _holdingsGapText(Etf00631LLabData data) {
  final status = data.operationsStatus;
  final count = status.holdingsMissingWeekdayCount;
  if (count <= 0) {
    return status.integrityStatus == 'missing' ? '缺日尚未檢查' : '未回報缺日';
  }
  return '缺日 $count 天：${_dateListPreview(status.holdingsMissingWeekdays)}';
}

String _holdingsIntegrityAction(Etf00631LLabData data) {
  final status = data.operationsStatus;
  if (status.integrityFailureCount > 0) {
    return '請執行 scripts\\00631l_check_integrity.cmd 並修正資料檔。';
  }
  if (status.holdingsMissingWeekdayCount > 0) {
    return '請檢查缺日是否為尚未執行每日流程；可重新執行每日流程後再檢查。';
  }
  if (status.integrityStatus == 'missing') {
    return '請執行 scripts\\00631l_check_integrity.cmd 產生完整性狀態。';
  }
  return '已從本機每日流程開始累積；不補假過去內容物。';
}

String _dateListPreview(List<DateTime> dates, {int limit = 3}) {
  if (dates.isEmpty) {
    return 'none';
  }
  final preview = dates.take(limit).map(formatTaiwanDate).join(', ');
  if (dates.length <= limit) {
    return preview;
  }
  return '$preview ...';
}

int _holdingsHistoryCount(Etf00631LLabData data) {
  final localCount = data.holdingsHistory.points.length;
  final statusCount = data.operationsStatus.holdingsHistoryItemCount;
  return localCount > statusCount ? localCount : statusCount;
}

DateTime? _latestHoldingsDate(Etf00631LLabData data) {
  final fromStatus = data.operationsStatus.latestHoldingTradeDate;
  if (fromStatus != null) {
    return fromStatus;
  }
  final latestHistory = data.holdingsHistory.trendSummary().latest?.tradeDate;
  return latestHistory ?? data.snapshot.tradeDate;
}

String _intradayDataTimeText(EtfIntradayNav? intradayNav) {
  return intradayNav?.dataTime == null
      ? 'unavailable'
      : formatTaiwanDateTimeSeconds(intradayNav!.dataTime!);
}

String? _findAnalysisBullet(EtfAiAnalysisSummary summary, String marker) {
  for (final bullet in summary.bullets) {
    if (bullet.contains(marker)) {
      return bullet;
    }
  }
  return null;
}

List<String> _aiTodaySnapshotBullets(
  Etf00631LLabData data,
  EtfAiAnalysisSummary summary,
) {
  final price = data.priceHistory.completenessSummary();
  final premiumAssessment = data.intradayNav?.premiumDiscountAssessment;
  final holdingsDate = _dateOrDash(_latestHoldingsDate(data));
  final intradayTime = _intradayDataTimeText(data.intradayNav);
  final latestClose = price.latest == null ? '暫無' : _price(price.latest!.close);
  final premiumText = premiumAssessment == null
      ? '目前沒有可判斷的盤中折溢價資料。'
      : _premiumDescription(premiumAssessment);
  return [
    '官方每日內容物：$holdingsDate；盤中 NAV：$intradayTime。',
    '折溢價狀態：$premiumText',
    '歷史資料：${formatInteger(price.rowCount)} 筆，範圍 ${_dateOrDash(price.coverageStart)} - ${_dateOrDash(price.coverageEnd)}，最新收盤 $latestClose。',
    '資料狀態：整體狀態 ${summary.readinessLabel}；後端 ${data.operationsStatus.backendConnectionLabel}；價格歷史 ${_sourceStatusBadgeLabel(data.priceHistory.sourceStatusLabel)}。',
  ];
}

List<String> _completeDataBriefing(Etf00631LLabData data) {
  final price = data.priceHistory.completenessSummary();
  final performance = data.priceHistory.performance;
  final holdings = data.holdingsHistory.trendSummary();
  final intraday = data.intradayNavHistory;
  final lines = <String>[
    '價格歷史共 ${price.rowCount} 筆，範圍 ${_dateOrDash(price.coverageStart)} - ${_dateOrDash(price.coverageEnd)}，來源 ${_sourceStatusBadgeLabel(data.priceHistory.sourceStatusLabel)}。',
  ];
  if (price.latest != null) {
    lines.add(
      '最新收盤 ${_price(price.latest!.close)}，日報酬 ${formatSignedNullablePercent(price.latestDailyReturnPct)}，52 週區間 ${_price(price.trailingLowClose)} - ${_price(price.trailingHighClose)}。',
    );
  }
  lines.add(
    '歷史累積報酬 ${formatSignedNullablePercent(performance.totalReturnPct)}，最大回撤 ${formatSignedNullablePercent(performance.maxDrawdownPct)}，年化波動 ${formatNullablePercent(performance.annualizedVolatilityPct)}。',
  );
  if (holdings.latest != null) {
    lines.add(
      '最新 官方每日內容物：TX 權重 ${formatNullablePercent(holdings.latest!.txWeightPct)}，台積電權重 ${formatNullablePercent(holdings.latest!.tsmcWeightPct)}，股票/期貨/現金保證金 ${formatNullablePercent(holdings.latest!.stockExposurePct)} / ${formatNullablePercent(holdings.latest!.futuresExposurePct)} / ${formatNullablePercent(holdings.latest!.cashAndMarginPct)}。',
    );
  } else {
    lines.add('尚無內容物紀錄，請執行每日流程累積官方每日快照。');
  }
  if (intraday.hasData) {
    lines.add(
      '今日 盤中 NAV samples ${intraday.sampleCount}，折溢價區間 ${formatSignedNullablePercent(intraday.lowestPremiumDiscountPct)} 至 ${formatSignedNullablePercent(intraday.highestPremiumDiscountPct)}，最後時間 ${_dateTimeOrDash(intraday.lastDataTime)}。',
    );
  } else {
    lines.add('盤中 NAV 歷史尚未累積；盤中折溢價需公開後端與 TWSE 資料可用。');
  }
  lines.add(
    '維護狀態：後端 ${data.operationsStatus.backendConnectionCaption}，日報 ${_sourceStatusBadgeLabel(data.operationsStatus.reportOverallStatus)}，匯出 ${data.operationsStatus.exportAvailable ? '已就緒' : '缺少'}，備份 ${data.operationsStatus.backupAvailable ? '已就緒' : '缺少'}。',
  );
  return lines;
}

List<String> _selectedEtfAnalysisBullets(_SelectedEtfViewData selectedEtf) {
  final history = selectedEtf.historySummary;
  final performance = selectedEtf.priceHistory.performance;
  final latest = history.latest;
  if (!selectedEtf.hasImportedHistory || latest == null) {
    return [
      '${selectedEtf.code} 目前資料不足，AI 只顯示清單、靜態或錯誤狀態，不產生歷史結論。',
      '若要檢視歷史、回測或比較，需先匯入可驗證的價格歷史。',
      '盤中 NAV 目前只完整接 00631L；不會把 00631L 的即時資料套用到 ${selectedEtf.code}。',
      '此摘要只描述資料狀態，非買賣建議。',
    ];
  }
  final latestChange = history.latestCloseChange == null
      ? '暫無'
      : '${history.latestCloseChange! >= 0 ? '+' : ''}${history.latestCloseChange!.toStringAsFixed(2)}';
  final rangePosition = _selectedEtfRangePositionText(history);
  final dailyMove = _selectedEtfDailyMoveText(history);
  final completeness = history.isCompleteFromListing ? '上市日起完整' : '部分區間';
  return [
    '${selectedEtf.code} 歷史資料範圍 ${selectedEtf.historyCoverageText}，共 ${formatInteger(history.rowCount)} 筆，資料範圍為 $completeness。',
    '最新交易日 ${_dateOrDash(latest.date)}，收盤 ${_price(latest.performanceClose)}，日變動 $latestChange / ${formatSignedNullablePercent(history.latestDailyReturnPct)}。',
    '$dailyMove；這是歷史收盤資料，不是盤中即時價格。',
    '區間累積報酬 ${formatSignedNullablePercent(performance.totalReturnPct)}，最大回撤 ${formatSignedNullablePercent(performance.maxDrawdownPct)}，年化波動 ${formatNullablePercent(performance.annualizedVolatilityPct)}。',
    '近一年區間 ${_price(history.trailingLowClose)} - ${_price(history.trailingHighClose)}；目前位置 $rangePosition。',
    '價格欄位使用 ${selectedEtf.priceFieldLabel}；${selectedEtf.adjustmentContextLabel}。若資料含分割或調整，請以調整係數與調整價為準。',
    selectedEtf.is00631L
        ? '00631L 已接 盤中 NAV；官方 內容物 仍是每日快照。'
        : '${selectedEtf.code} 尚未接 盤中 NAV；目前分析以歷史價格與清單狀態為主。',
    '回測不代表未來表現，非買賣建議。',
  ];
}

List<String> _selectedEtfProgramActions(_SelectedEtfViewData selectedEtf) {
  final actions = <String>[];
  if (selectedEtf.hasImportedHistory) {
    actions.add(
      '若要刷新 ${selectedEtf.code} 歷史資料，執行 scripts\\00631l_import_etf_price_history.cmd。',
    );
  } else {
    actions.add(
      '若要啟用 ${selectedEtf.code} 歷史與回測，先匯入 ETF 價格歷史。',
    );
  }
  if (!selectedEtf.is00631L) {
    actions.add(
      '若未來需要 ${selectedEtf.code} live NAV，需先建立官方來源 mapping 與 parser。',
    );
  }
  actions.add('若資料時間不符合預期，先查看設定頁的靜態/live 模式與資料覆蓋狀態。');
  return actions;
}

String _selectedEtfRangePositionText(
  EtfPriceHistoryCompletenessSummary history,
) {
  final latest = history.latest?.performanceClose;
  final low = history.trailingLowClose;
  final high = history.trailingHighClose;
  if (latest == null || low == null || high == null || high <= low) {
    return 'unavailable';
  }
  final position = ((latest - low) / (high - low) * 100).clamp(0, 100);
  return '近一年區間 ${position.toStringAsFixed(1)}%';
}

String _selectedEtfDailyMoveText(EtfPriceHistoryCompletenessSummary history) {
  final pct = history.latestDailyReturnPct;
  if (pct == null) {
    return '最新收盤缺少前一筆可比較資料';
  }
  final direction = pct > 0.05
      ? '上升'
      : pct < -0.05
          ? '下降'
          : '接近持平';
  return '最新收盤較前一筆$direction ${formatSignedNullablePercent(pct)}';
}

String _historyMetricLabel(String key) {
  switch (key) {
    case 'txWeightPct':
      return 'TX 權重';
    case 'tsmcWeightPct':
      return '台積電權重';
    case 'stockExposurePct':
      return '股票資產 %';
    case 'futuresExposurePct':
      return '期貨資產 %';
    case 'cashAndMarginPct':
      return '現金/保證金 %';
    case 'navPerUnit':
      return 'NAV';
    case 'outstandingUnits':
      return '發行單位數';
    default:
      return key;
  }
}

String _historyMetricValue(EtfHoldingsHistoryChangeLine line) {
  if (line.key == 'outstandingUnits') {
    return formatInteger(line.latestValue.round());
  }
  if (line.isPercent) {
    return formatNullablePercent(line.latestValue);
  }
  return line.latestValue.toStringAsFixed(2);
}

String _historyMetricDelta(EtfHoldingsHistoryChangeLine line) {
  return _historyMetricDeltaValue(line, line.dayOverDayChange);
}

String _historyMetricRangeDelta(EtfHoldingsHistoryChangeLine line) {
  return _historyMetricDeltaValue(line, line.firstToLatestChange);
}

String _historyMetricDeltaValue(
  EtfHoldingsHistoryChangeLine line,
  double? value,
) {
  if (value == null) {
    return 'n/a';
  }
  if (line.key == 'outstandingUnits') {
    return _signedInteger(value.round());
  }
  if (line.isPercent) {
    return _signedPercentPoints(value);
  }
  return _signedNumber(value);
}

String _signedPercentPoints(double value) {
  final prefix = value > 0 ? '+' : '';
  return '$prefix${value.toStringAsFixed(2)} pp';
}

String _signedNumber(double value) {
  final prefix = value > 0 ? '+' : '';
  return '$prefix${value.toStringAsFixed(2)}';
}

String _signedInteger(int value) {
  final prefix = value > 0 ? '+' : '';
  return '$prefix${formatInteger(value)}';
}

double _parseDouble(String value) {
  return double.tryParse(value.replaceAll(',', '').trim()) ?? 0;
}

int _parseInt(String value, {required int fallback}) {
  return int.tryParse(value.replaceAll(',', '').trim()) ?? fallback;
}

Color _levelColor(ColorScheme scheme, PremiumDiscountLevel level) {
  switch (level) {
    case PremiumDiscountLevel.normal:
      return scheme.primary;
    case PremiumDiscountLevel.watch:
      return scheme.secondary;
    case PremiumDiscountLevel.elevated:
      return scheme.tertiary;
    case PremiumDiscountLevel.extreme:
      return scheme.error;
    case PremiumDiscountLevel.unavailable:
    case PremiumDiscountLevel.stale:
      return scheme.onSurfaceVariant;
  }
}

IconData _levelIcon(PremiumDiscountLevel level) {
  switch (level) {
    case PremiumDiscountLevel.normal:
      return Icons.check_circle_outline;
    case PremiumDiscountLevel.watch:
      return Icons.visibility_outlined;
    case PremiumDiscountLevel.elevated:
      return Icons.priority_high_outlined;
    case PremiumDiscountLevel.extreme:
      return Icons.report_outlined;
    case PremiumDiscountLevel.stale:
      return Icons.schedule_outlined;
    case PremiumDiscountLevel.unavailable:
      return Icons.cloud_off_outlined;
  }
}

String _premiumLabel(PremiumDiscountAssessment assessment) {
  switch (assessment.level) {
    case PremiumDiscountLevel.unavailable:
      return '即時資料不可用';
    case PremiumDiscountLevel.stale:
      return '資料可能過期';
    case PremiumDiscountLevel.normal:
      return '正常';
    case PremiumDiscountLevel.watch:
      return assessment.isDiscount ? '折價觀察' : '溢價觀察';
    case PremiumDiscountLevel.elevated:
      return assessment.isDiscount ? '折價偏深' : '溢價偏高';
    case PremiumDiscountLevel.extreme:
      return assessment.isDiscount ? '折價極端' : '溢價極端';
  }
}

String _premiumDescription(PremiumDiscountAssessment assessment) {
  final value = assessment.premiumDiscountPct;
  if (assessment.level == PremiumDiscountLevel.unavailable || value == null) {
    return '即時淨值資料不可用，暫時無法判斷折溢價狀態。';
  }
  if (assessment.level == PremiumDiscountLevel.stale) {
    return '即時淨值資料可能過期，請以資料時間與官方來源為準。';
  }
  final relation = value >= 0 ? '市價高於預估淨值' : '市價低於預估淨值';
  final formatted = formatSignedNullablePercent(value);
  if (assessment.level == PremiumDiscountLevel.normal) {
    return '目前$relation $formatted，屬於正常區間。這是價格偏離提示。';
  }
  return '目前$relation $formatted，屬於${_premiumLabel(assessment)}。這是價格偏離提示。';
}
