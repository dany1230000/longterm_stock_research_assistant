import 'dart:async';
import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/leveraged_etf_lab.dart';
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

class LeveragedEtf00631LScreen extends ConsumerStatefulWidget {
  const LeveragedEtf00631LScreen({super.key});

  @override
  ConsumerState<LeveragedEtf00631LScreen> createState() =>
      _LeveragedEtf00631LScreenState();
}

class _LeveragedEtf00631LScreenState
    extends ConsumerState<LeveragedEtf00631LScreen> {
  Timer? _refreshTimer;
  _LabSection _section = _LabSection.overview;
  String _selectedEtfCode = '00631L';

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        _refreshLabData();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fastValue = ref.watch(etf00631LFastLabProvider);
    final fullValue = fastValue.hasValue || fastValue.hasError
        ? ref.watch(etf00631LLabProvider)
        : const AsyncValue<Etf00631LLabData>.loading();
    final displayData = fullValue.valueOrNull ?? fastValue.valueOrNull;
    final useEmbeddedPriceHistory = _selectedEtfCode == '00631L';
    final selectedHistoryValue = useEmbeddedPriceHistory
        ? null
        : ref.watch(selectedEtfPriceHistoryProvider(_selectedEtfCode));
    final comparisonHistoriesValue =
        ref.watch(etfHistoryComparisonProvider(_selectedEtfCode));
    final detailsLoading = !fullValue.hasValue && fullValue.isLoading;
    final detailsError = fullValue.hasError && !fullValue.hasValue
        ? fullValue.error.toString()
        : null;
    return SafeArea(
      child: displayData == null
          ? _buildInitialState(fastValue, fullValue)
          : _LabContent(
              data: displayData,
              selectedEtfCode: _selectedEtfCode,
              selectedPriceHistory: useEmbeddedPriceHistory
                  ? displayData.priceHistory
                  : selectedHistoryValue?.valueOrNull,
              selectedPriceHistoryLoading:
                  selectedHistoryValue?.isLoading ?? false,
              selectedPriceHistoryError: selectedHistoryValue?.hasError == true
                  ? selectedHistoryValue?.error
                  : null,
              comparisonHistories:
                  comparisonHistoriesValue.valueOrNull ?? const [],
              comparisonHistoriesLoading: comparisonHistoriesValue.isLoading,
              comparisonHistoriesError: comparisonHistoriesValue.hasError
                  ? comparisonHistoriesValue.error
                  : null,
              selectedSection: _section,
              detailsLoading: detailsLoading,
              detailsError: detailsError,
              onSectionChanged: (section) => setState(() => _section = section),
              onEtfSelected: _selectEtf,
              onRefresh: _refreshLabData,
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
  }

  void _selectEtf(String code) {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) {
      return;
    }
    setState(() {
      _selectedEtfCode = normalized;
      _section = _LabSection.historyBacktest;
    });
  }
}

enum _LabSection {
  overview('總覽', Icons.dashboard_outlined),
  historyBacktest('歷史回測', Icons.query_stats_outlined),
  etf('ETF', Icons.dataset_outlined),
  position('持倉', Icons.account_balance_wallet_outlined),
  ai('AI', Icons.psychology_alt_outlined),
  settings('設定', Icons.manage_accounts_outlined);

  const _LabSection(this.label, this.icon);
  final String label;
  final IconData icon;
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
  final _LabSection selectedSection;
  final bool detailsLoading;
  final String? detailsError;
  final ValueChanged<_LabSection> onSectionChanged;
  final ValueChanged<String> onEtfSelected;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
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
                                    onEtfSelected: onEtfSelected,
                                    onRefresh: onRefresh,
                                  ),
                                  const SizedBox(height: 8),
                                  if (detailsLoading ||
                                      detailsError != null) ...[
                                    _DetailsLoadStateStrip(
                                      isLoading: detailsLoading,
                                      errorMessage: detailsError,
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                  _sectionWidget(data),
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

  Widget _sectionWidget(Etf00631LLabData data) {
    switch (selectedSection) {
      case _LabSection.overview:
        return _OverviewSection(data: data);
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
        );
      case _LabSection.etf:
        return _EtfCatalogSection(
          data: data,
          onEtfSelected: onEtfSelected,
        );
      case _LabSection.position:
        return _PositionSection(data: data);
      case _LabSection.ai:
        return _AiSection(data: data);
      case _LabSection.settings:
        return _SettingsSection(data: data);
    }
  }
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
                hasError
                    ? '完整資料暫時不可用，已保留首屏資料與 fallback。'
                    : '先顯示首屏資料，正在載入歷史、AI 與維護狀態。',
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
        decoration: BoxDecoration(color: _marketBackground(context)),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 88),
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
                          const _LoadingQuoteCard(),
                          const SizedBox(height: 8),
                          const _LoadingSectionCard(title: '今日狀態'),
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

class _LoadingQuoteCard extends StatelessWidget {
  const _LoadingQuoteCard();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
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
    this.onEtfSelected,
    required this.onRefresh,
  });

  final Etf00631LLabData? data;
  final String selectedEtfCode;
  final ValueChanged<String>? onEtfSelected;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 50,
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
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '00631L 正二研究室',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: _marketMutedTextColor(context),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                        height: 1.05,
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
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 5),
                const Icon(Icons.search, color: Colors.white, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _showSymbolSearchSheet(BuildContext context, Etf00631LLabData data,
    {ValueChanged<String>? onEtfSelected}) {
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
        onEtfSelected: onEtfSelected,
      );
    },
  );
}

class _SymbolSearchSheet extends StatefulWidget {
  const _SymbolSearchSheet({required this.data, this.onEtfSelected});

  final Etf00631LLabData data;
  final ValueChanged<String>? onEtfSelected;

  @override
  State<_SymbolSearchSheet> createState() => _SymbolSearchSheetState();
}

class _SymbolSearchSheetState extends State<_SymbolSearchSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _controller.text.trim().toLowerCase();
    final catalog = widget.data.etfCatalog;
    final items = query.isEmpty
        ? catalog.focusItems
        : [
            for (final item in catalog.items)
              if (_catalogSearchText(item).contains(query)) item,
          ];
    final visibleItems = items.take(30).toList(growable: false);
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
                        '搜尋 ETF / 股票代號',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: _marketTextColor(context),
                                  fontWeight: FontWeight.w900,
                                ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ETF catalog 已集中到左上角代號搜尋；股票資料源尚未接入。',
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
                'catalog ${catalog.sourceStatusLabel}',
                'rows ${formatInteger(catalog.rowCount)}',
                if (query.isEmpty) '常用代號' else '搜尋結果 ${visibleItems.length}',
              ],
            ),
            const SizedBox(height: 10),
            Flexible(
              child: visibleItems.isEmpty
                  ? _EmptyPanel(
                      title: '查無代號',
                      message: query.isEmpty
                          ? 'ETF catalog 暫無明細。'
                          : '目前只載入 ETF catalog；股票資料源尚未接入。',
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: visibleItems.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = visibleItems[index];
                        return _SymbolSearchResultTile(
                          item: item,
                          selected: item.code == widget.data.profile.symbol,
                          onSelected: widget.onEtfSelected,
                        );
                      },
                    ),
            ),
          ],
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
    return InkWell(
      key: ValueKey('00631l-symbol-search-result-${item.code}'),
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.of(context).pop();
        onSelected?.call(item.code);
        final message = selected
            ? '目前已開啟 00631L 正二研究室。'
            : '${item.code} 已在 ETF catalog；完整研究室與比較頁後續接入。';
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
                    Text(
                      item.targetType.isEmpty ? 'ETF catalog' : item.targetType,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _marketMutedTextColor(context),
                      ),
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
                    selected ? '目前頁面' : 'catalog',
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
      premiumDiscountPct: nav?.estimatedPremiumDiscountPct,
      sourceStatus: nav?.status ?? EtfDataStatus.error,
      isStale: nav?.isStale ?? true,
    );
    final statusSummary = data.statusSummary;
    return DecoratedBox(
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
  const _CompactQuoteHeader({required this.data});

  final Etf00631LLabData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nav = data.intradayNav;
    final premiumAssessment = PremiumDiscountAssessment.evaluate(
      premiumDiscountPct: nav?.estimatedPremiumDiscountPct,
      sourceStatus: nav?.status ?? EtfDataStatus.error,
      isStale: nav?.isStale ?? true,
    );
    final premiumColor = _levelColor(
      theme.colorScheme,
      premiumAssessment.level,
    );
    final history = data.priceHistory.completenessSummary();
    final latestHistoryPoint = history.latest;
    final quoteValue = nav?.marketPrice ?? latestHistoryPoint?.close;
    final quoteStatus = nav?.status.label ??
        (latestHistoryPoint == null
            ? 'unavailable'
            : data.priceHistory.sourceStatusLabel);
    final quoteStatusDisplay = nav == null && latestHistoryPoint != null
        ? '歷史收盤'
        : _statusDisplay(quoteStatus);
    final quoteCaption = nav?.dataTime == null
        ? latestHistoryPoint == null
            ? '市價 · 盤中資料暫無'
            : '市價參考 · 歷史收盤 ${formatTaiwanDate(latestHistoryPoint.date)}'
        : '市價 · 盤中時間 ${formatTimeSeconds(nav!.dataTime!)}';
    final backendLabel = data.operationsStatus.backendDisconnected
        ? '後端未連線'
        : data.operationsStatus.backendConnectionLabel;

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
                              '00631L 元大台灣50正2',
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
                      const SizedBox(height: 3),
                      Text(
                        _price(quoteValue),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: _marketTextColor(context),
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                          height: 0.96,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        quoteCaption,
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
                  value: formatSignedNullablePercent(
                    nav?.estimatedPremiumDiscountPct,
                  ),
                  label: _premiumLabel(premiumAssessment),
                  color: premiumColor,
                ),
              ],
            ),
            const SizedBox(height: 5),
            _QuoteMetaStrip(
              items: [
                _QuoteMetaItem(
                  label: '預估淨值',
                  value: _price(nav?.estimatedNav),
                ),
                _QuoteMetaItem(
                  label: '前日淨值',
                  value: _price(nav?.previousBusinessDayNav),
                ),
                _QuoteMetaItem(
                  label: '歷史資料',
                  value: history.rowCount >= 2
                      ? '${formatInteger(history.rowCount)} 筆'
                      : '尚無',
                ),
                _QuoteMetaItem(
                  label: '模式',
                  value: _frontendDataModeDisplay,
                  caption: backendLabel,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuoteMetaItem {
  const _QuoteMetaItem({
    required this.label,
    required this.value,
    this.caption,
  });

  final String label;
  final String value;
  final String? caption;
}

class _QuoteMetaStrip extends StatelessWidget {
  const _QuoteMetaStrip({required this.items});

  final List<_QuoteMetaItem> items;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (var index = 0; index < items.length; index += 1) ...[
            if (index > 0) const SizedBox(width: 6),
            _QuoteMetaPill(item: items[index]),
          ],
        ],
      ),
    );
  }
}

class _QuoteMetaPill extends StatelessWidget {
  const _QuoteMetaPill({required this.item});

  final _QuoteMetaItem item;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _marketPanelAltColor(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _marketBorderColor(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 5,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${item.label} ',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: _marketMutedTextColor(context),
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 1),
            Text(
              item.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _marketTextColor(context),
                    fontWeight: FontWeight.w900,
                  ),
            ),
            if (item.caption != null) ...[
              const SizedBox(width: 5),
              Text(
                item.caption!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: _marketMutedTextColor(context),
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ],
        ),
      ),
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
      constraints: const BoxConstraints(minWidth: 96, maxWidth: 116),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.46)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
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
              const SizedBox(height: 4),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: _marketTextColor(context),
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 2),
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
        ? 'holdings history 尚未累積'
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
    return '尚無 daily cycle 累積資料；不補假資料。';
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
      premiumDiscountPct: nav?.estimatedPremiumDiscountPct,
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
                              nav?.estimatedPremiumDiscountPct,
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
                  'core ${_coreDataStatusLabel(data)}',
                  'holdings ${data.snapshot.status.label}',
                  'intraday ${nav?.status.label ?? 'unavailable'}',
                  'history ${data.priceHistory.sourceStatusLabel}',
                  'frontend $_frontendDataMode',
                  if (_use00631LLiveProxy)
                    'api ${data.operationsStatus.publicApiBaseUrl.isEmpty ? _proxyBaseUrl00631l : data.operationsStatus.publicApiBaseUrl}',
                  if (_use00631LLiveProxy)
                    'apiCheck ${_dateTimeOrDash(data.operationsStatus.lastFetchedAt)}',
                  if (_use00631LStaticData) 'static $_staticDataBaseUrl00631l',
                  if (_use00631LStaticData)
                    'rows ${data.operationsStatus.priceHistoryRows}',
                  if (_use00631LStaticData)
                    'generated ${_dateTimeOrDash(data.operationsStatus.latestExportUpdatedAt ?? data.priceHistory.lastFetchedAt)}',
                  'backend ${data.operationsStatus.backendConnectionLabel}',
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
    return 'live proxy';
  }
  if (_use00631LStaticData) {
    return 'static public';
  }
  return 'mock default';
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

String _coreDataStatusDisplay(Etf00631LLabData data) {
  return _statusDisplay(_coreDataStatusLabel(data));
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
      return 'Mock';
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
      return 'Live 後端';
    case 'mock_default':
      return 'Mock 預設';
    case 'backend disconnected':
      return '後端未連線';
    case 'backend connected':
      return '後端已連線';
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
        final label = isDark ? '夜間模式' : '日間模式';
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
                      isDark ? Icons.dark_mode : Icons.light_mode_outlined,
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
  const _OverviewSection({required this.data});

  final Etf00631LLabData data;

  @override
  Widget build(BuildContext context) {
    final history = data.holdingsHistory.trendSummary();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CompactQuoteHeader(data: data),
        const SizedBox(height: 8),
        _OverviewAtAGlancePanel(data: data),
        const SizedBox(height: 8),
        _OverviewHoldingsDigestPanel(data: data),
        const SizedBox(height: 8),
        _AlwaysExpandedPanel(
          title: '圖表與曝險',
          subtitle: '近 60 日收盤與官方每日曝險；需要比較時再展開。',
          child: _OverviewSignalPanel(data: data),
        ),
        const SizedBox(height: 8),
        _CompactExpansionPanel(
          title: '更多資料',
          subtitle: '完整數字、資料來源與內容物變化需要時再展開。',
          child: _OverviewMorePanel(data: data, history: history),
        ),
      ],
    );
  }
}

class _OverviewMorePanel extends StatelessWidget {
  const _OverviewMorePanel({
    required this.data,
    required this.history,
  });

  final Etf00631LLabData data;
  final EtfHoldingsHistoryTrendSummary history;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _OverviewActionRow(data: data),
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
                  title: '尚無 holdings history',
                  message: '請先執行 daily cycle 累積官方每日快照。',
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

class _OverviewAtAGlancePanel extends StatelessWidget {
  const _OverviewAtAGlancePanel({required this.data});

  final Etf00631LLabData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nav = data.intradayNav;
    final performance = data.priceHistory.performance;
    final latestHoldings = data.holdingsHistory.trendSummary().latest;
    final exposureText = latestHoldings == null
        ? 'history 尚未累積'
        : 'TX ${formatNullablePercent(latestHoldings.txWeightPct)} / 台積電 ${formatNullablePercent(latestHoldings.tsmcWeightPct)}';
    final metrics = [
      _AtAGlanceMetricData(
        label: '官方內容物',
        value: formatTaiwanDate(data.snapshot.tradeDate),
        caption: data.snapshot.status.label,
      ),
      _AtAGlanceMetricData(
        label: '盤中 NAV',
        value: _price(nav?.estimatedNav),
        caption: nav?.dataTime == null
            ? '盤中資料暫無'
            : formatTimeSeconds(nav!.dataTime!),
      ),
      _AtAGlanceMetricData(
        label: '內容物重點',
        value: exposureText,
        caption: '官方 history',
      ),
      _AtAGlanceMetricData(
        label: '累積報酬',
        value: formatSignedNullablePercent(
          performance.totalReturnPct,
        ),
        caption:
            '最大回撤 ${formatSignedNullablePercent(performance.maxDrawdownPct)}',
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
                Expanded(
                  child: Text(
                    '核心資料',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: _marketTextColor(context),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _CompactTextBadge(label: _coreDataStatusDisplay(data)),
              ],
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
    final theme = Theme.of(context);
    return DecoratedBox(
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
                const _MiniStatusBadge(label: 'DAY'),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '官方內容物重點',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: _marketTextColor(context),
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
              '每日官方快照，不是盤中即時內容物；盤中狀態看 NAV 與折溢價。',
              style: theme.textTheme.bodySmall?.copyWith(
                color: _marketMutedTextColor(context),
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),
            _InfoCardGrid(
              children: [
                _HoldingInfoCard(
                  badge: 'TX',
                  title: 'TX 期貨',
                  primary: txLine == null
                      ? 'unavailable'
                      : formatNullablePercent(txLine.weightPct),
                  secondary: txLine == null
                      ? '官方快照未列 TX'
                      : '${txLine.code} / ${txLine.contractMonth}',
                  caption: '官方每日期貨權重',
                  progressValue: txLine == null
                      ? null
                      : (txLine.weightPct.abs() / 220).clamp(0, 1).toDouble(),
                ),
                _HoldingInfoCard(
                  badge: '2330',
                  title: '台積電現股',
                  primary: tsmcLine == null
                      ? 'unavailable'
                      : formatNullablePercent(tsmcLine.weightPct),
                  secondary: tsmcLine == null
                      ? '官方快照未列 2330'
                      : formatInteger(tsmcLine.quantity),
                  caption: '官方每日股票權重',
                  progressValue: tsmcLine == null
                      ? null
                      : (tsmcLine.weightPct.abs() / 100).clamp(0, 1).toDouble(),
                ),
                _HoldingInfoCard(
                  badge: 'MIX',
                  title: '股票 / 期貨 / 現金',
                  primary:
                      '${formatNullablePercent(snapshot.stockExposureWeightPct)} / ${formatNullablePercent(snapshot.futuresExposureWeightPct)}',
                  secondary:
                      '現金 ${formatNullablePercent(snapshot.cashAndMarginWeightPct)}',
                  caption: '官方資產結構',
                  progressValue: (snapshot.futuresExposureWeightPct.abs() / 220)
                      .clamp(0, 1)
                      .toDouble(),
                ),
              ],
            ),
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
            final priceBlock = _OverviewSparklineBlock(
              points: data.priceHistory.points,
            );
            final exposureBlock = _OverviewExposureBlock(
              snapshot: data.snapshot,
            );
            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: priceBlock),
                  const SizedBox(width: 10),
                  Expanded(child: exposureBlock),
                ],
              );
            }
            return Column(
              children: [
                priceBlock,
                const SizedBox(height: 10),
                exposureBlock,
              ],
            );
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
    final recent =
        ordered.length > 60 ? ordered.sublist(ordered.length - 60) : ordered;
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
            const _MiniStatusBadge(label: 'HIS'),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '近 60 日收盤',
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
        const SizedBox(height: 6),
        _SparklineChart(points: recent),
      ],
    );
  }
}

class _SparklineChart extends StatelessWidget {
  const _SparklineChart({required this.points});

  final List<EtfPriceHistoryPoint> points;

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[];
    for (var index = 0; index < points.length; index += 1) {
      final close = points[index].performanceClose;
      if (close.isFinite) {
        spots.add(FlSpot(index.toDouble(), close));
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

    return SizedBox(
      height: 72,
      child: LineChart(
        LineChartData(
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              barWidth: 2.2,
              isCurved: true,
              color: _marketBlue,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: _marketBlue.withValues(alpha: 0.10),
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
        const SizedBox(height: 10),
        _OverviewExposureLine(
          label: '股票',
          valuePct: snapshot.assetWeightPct(EtfAssetClass.stock),
          color: _marketGreen,
        ),
        _OverviewExposureLine(
          label: '期貨',
          valuePct: snapshot.assetWeightPct(EtfAssetClass.futures),
          color: _marketRed,
        ),
        _OverviewExposureLine(
          label: '現金 / 保證金',
          valuePct: snapshot.cashAndMarginWeightPct,
          color: _marketBlue,
        ),
      ],
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

// ignore: unused_element
class _OverviewBriefPanel extends StatelessWidget {
  const _OverviewBriefPanel({required this.data});

  final Etf00631LLabData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nav = data.intradayNav;
    return DecoratedBox(
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
            Row(
              children: [
                const _MiniStatusBadge(label: 'OVERVIEW'),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '今日快覽',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              _overviewAiBrief(data),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.45,
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            _StatusWrap(
              labels: [
                _frontendDataModeLabel,
                '資料 ${data.status.label}',
                'NAV ${_dateTimeOrDash(nav?.dataTime)}',
                data.aiAnalysis.disclaimer,
              ],
            ),
          ],
        ),
      ),
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
                    caption: '需 live backend',
                  ),
                  _ComparisonRowData(
                    label: '官方 NAV',
                    value: _price(snapshot.navPerUnit),
                    caption: formatTaiwanDate(snapshot.tradeDate),
                  ),
                  _ComparisonRowData(
                    label: '折溢價',
                    value: formatSignedNullablePercent(
                      nav?.estimatedPremiumDiscountPct,
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
                        ? '尚無 price history'
                        : '${formatInteger(price.rowCount)} rows',
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
          subtitle: '價格歷史、內容物 history、盤中 NAV 與 TX live 狀態。',
          child: _DataCoveragePanel(data: data),
        ),
        const SizedBox(height: 8),
        _CompactExpansionPanel(
          title: '歷史資料完整度',
          subtitle: 'rows、coverage、52 週區間與欄位覆蓋。',
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
              '折溢價 ${formatSignedNullablePercent(nav?.estimatedPremiumDiscountPct)}',
          caption: 'live backend 可連線時更新；static mode 不提供盤中資料',
          progressValue: nav?.estimatedPremiumDiscountPct == null
              ? null
              : (nav!.estimatedPremiumDiscountPct!.abs() / 1.5)
                  .clamp(0, 1)
                  .toDouble(),
        ),
        _HoldingInfoCard(
          badge: 'HIS',
          title: '歷史價格',
          primary: '${formatInteger(price.rowCount)} rows',
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
          secondary: '基差 ${formatSignedNullablePercent(tx.futuresBasisPct)}',
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
          subtitle: '官方每日資料，不是盤中即時內容物；盤中請看 intraday NAV 與折溢價。',
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
                subtitle: '本機 history 從 daily cycle 開始保存，不補假過去資料。',
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
  });

  final Etf00631LLabData data;
  final String selectedEtfCode;
  final EtfPriceHistory priceHistory;

  @override
  Widget build(BuildContext context) {
    final holdingsTrend = data.holdingsHistory.trendSummary();
    final completeness = priceHistory.completenessSummary();
    final selectedName =
        priceHistory.name.trim().isEmpty ? selectedEtfCode : priceHistory.name;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeaderCard(
          title: '歷史回測',
          subtitle: '預設顯示最近 1 年，可自行調整開始與結束日期。',
          icon: Icons.show_chart_outlined,
          badges: [
            'HIS',
            selectedEtfCode,
            selectedName,
            'source ${priceHistory.sourceStatusLabel}',
            '${completeness.rowCount} rows',
          ],
          metrics: [
            _SectionHeaderMetric(
              label: '完整 coverage',
              value:
                  '${_dateOrDash(completeness.coverageStart)} - ${_dateOrDash(completeness.coverageEnd)}',
            ),
            _SectionHeaderMetric(
              label: '最新收盤',
              value: _price(completeness.latest?.close),
            ),
            const _SectionHeaderMetric(
              label: '預設區間',
              value: '最近 1 年',
            ),
            _SectionHeaderMetric(
              label: '日期調整',
              value: priceHistory.hasData ? '可用' : '缺資料',
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SectionBlock(
          title: '價格歷史',
          subtitle: priceHistory.hasData
              ? '完整 coverage ${_dateOrDash(priceHistory.coverageStart)} - ${_dateOrDash(priceHistory.coverageEnd)}；圖表預設最近 1 年。'
              : '尚無 official price history，請執行 scripts\\00631l_update_price_history.cmd。',
          child: priceHistory.hasData
              ? _FilterablePriceHistoryBlock(priceHistory: priceHistory)
              : const _EmptyPanel(
                  title: '尚無 official price history',
                  message:
                      '價格歷史需要 official/cache/static data；不會用 mock 當成 official。',
                ),
        ),
        const SizedBox(height: 12),
        _SectionBlock(
          title: '每日 holdings history',
          subtitle: '官方 holdings history 從 daily cycle 開始累積，不補假過去資料。',
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
                  title: '尚無 holdings history',
                  message: '請執行 daily cycle 累積官方每日快照。',
                ),
        ),
      ],
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BacktestDateRangeControls(
          startDate: _startDate,
          endDate: _endDate,
          firstDate: _historyFirstDate(fullHistory),
          lastDate: _historyLastDate(fullHistory),
          onStartTap: _selectStartDate,
          onEndTap: _selectEndDate,
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _RangeActionChip(
              label: '最近 1 年',
              onTap: () => _setTrailingYears(1),
            ),
            _RangeActionChip(
              label: '最近 3 年',
              onTap: () => _setTrailingYears(3),
            ),
            _RangeActionChip(
              label: '全部資料',
              onTap: _setAllRange,
            ),
          ],
        ),
        const SizedBox(height: 10),
        _StatusWrap(
          labels: [
            '目前區間：${_dateOrDash(selectedSummary.coverageStart)} - ${_dateOrDash(selectedSummary.coverageEnd)}',
            '區間筆數 ${formatInteger(selectedSummary.rowCount)}',
            '完整筆數 ${formatInteger(fullSummary.rowCount)}',
          ],
        ),
        const SizedBox(height: 12),
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
        _PriceTrendCharts(priceHistory: filteredHistory),
        const SizedBox(height: 8),
        const _StatusWrap(
          labels: [
            '回測不代表未來表現',
            '價格歷史使用 split-adjusted close',
          ],
        ),
        const SizedBox(height: 12),
        _CompactExpansionPanel(
          title: '歷史資料完整度',
          subtitle: '完整 rows、coverage、欄位完整度。',
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
  const _RangeActionChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      avatar: const Icon(Icons.date_range_outlined, size: 16),
      visualDensity: VisualDensity.compact,
      onPressed: onTap,
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
  });

  final Etf00631LLabData data;
  final String selectedEtfCode;
  final EtfPriceHistory? selectedPriceHistory;
  final bool selectedPriceHistoryLoading;
  final Object? selectedPriceHistoryError;
  final List<EtfPriceHistory> comparisonHistories;
  final bool comparisonHistoriesLoading;
  final Object? comparisonHistoriesError;

  @override
  Widget build(BuildContext context) {
    final history = selectedPriceHistory ?? data.priceHistory;
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
        _HistorySection(
          key: const ValueKey('00631l-history-view'),
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
        const SizedBox(height: 10),
        _BacktestSection(
          key: const ValueKey('00631l-backtest-view'),
          data: data,
          selectedEtfCode: selectedEtfCode,
          priceHistory: history,
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
  _EtfComparisonFilter _filter = _EtfComparisonFilter.focused;

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
    final usableMetrics = [
      for (final metric in metrics)
        if (metric.rowCount >= 2 &&
            _comparisonFilterIncludes(_filter, metric.code,
                selectedCode: widget.selectedEtfCode))
          metric,
    ];
    final allUsableCount =
        metrics.where((metric) => metric.rowCount >= 2).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeaderCard(
          title: 'ETF 歷史比較',
          subtitle: '使用已匯入的歷史收盤價；比較結果只描述過去資料，非買賣建議。',
          icon: Icons.stacked_line_chart_outlined,
          badges: [
            widget.selectedEtfCode,
            '最近 1 年',
            'static / proxy history',
          ],
          metrics: [
            _SectionHeaderMetric(
              label: '比較檔數',
              value: formatInteger(usableMetrics.length),
              caption: '已匯入且有足夠資料',
            ),
            _SectionHeaderMetric(
              label: '區間',
              value: '${_dateOrDash(startDate)} - ${_dateOrDash(endDate)}',
              caption: '依目前選取 ETF 對齊；已載入 $allUsableCount 檔',
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
                  label: Text(filter.label),
                  selected: _filter == filter,
                  onSelected: (_) => setState(() => _filter = filter),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (usableMetrics.isEmpty)
          const _EmptyPanel(
            title: '尚無 ETF 比較資料',
            message:
                '請先匯入 ETF 歷史價格，或確認 static public data 內含 etf_price_history 檔案。',
          )
        else ...[
          _StatusWrap(
            labels: [
              'selected ${widget.selectedEtfCode}',
              _filter.label,
              'rows ${formatInteger(usableMetrics.fold<int>(0, (sum, item) => sum + item.rowCount))}',
              'history comparison',
            ],
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
                  formatSignedNullablePercent(metric.totalReturnPct),
                  formatSignedNullablePercent(metric.annualizedReturnPct),
                  formatSignedNullablePercent(metric.maxDrawdownPct),
                  formatNullablePercent(metric.annualizedVolatilityPct),
                  _price(metric.latestClose),
                  formatInteger(metric.rowCount),
                  metric.sourceStatusLabel,
                ],
            ],
          ),
        ],
      ],
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
        _SectionHeaderCard(
          title: '回測快覽',
          subtitle: '使用歷史收盤價計算；回測不代表未來表現，非買賣建議。',
          icon: Icons.query_stats_outlined,
          badges: [
            'backtest',
            widget.selectedEtfCode,
            'source ${history.sourceStatusLabel}',
            _strategy == EtfBacktestStrategy.lumpSum ? '一次投入' : '定期定額',
          ],
          metrics: [
            _SectionHeaderMetric(
              label: '期末市值',
              value: formatNtdAmount(result.finalValue),
            ),
            _SectionHeaderMetric(
              label: '總投入',
              value: formatNtdAmount(result.totalInvested),
            ),
            _SectionHeaderMetric(
              label: '累積報酬',
              value: formatSignedNullablePercent(result.totalReturnPct),
            ),
            _SectionHeaderMetric(
              label: '最大回撤',
              value: formatSignedNullablePercent(result.maxDrawdownPct),
            ),
          ],
        ),
        const SizedBox(height: 12),
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
                    _BacktestDateRangeControls(
                      startDate: _startDate,
                      endDate: _endDate,
                      firstDate: history.coverageStart,
                      lastDate: history.coverageEnd,
                      onStartTap: _selectStartDate,
                      onEndTap: _selectEndDate,
                    ),
                    const SizedBox(height: 12),
                    _InputGrid(
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
                    const SizedBox(height: 12),
                    _ResponsiveMetricGrid(
                      cards: [
                        _MetricCard(
                          label: '期末市值',
                          value: formatNtdAmount(result.finalValue),
                          caption: result.sourceStatusLabel,
                          icon: Icons.account_balance_wallet_outlined,
                        ),
                        _MetricCard(
                          label: '總投入',
                          value: formatNtdAmount(result.totalInvested),
                          caption: '歷史投入加總',
                          icon: Icons.savings_outlined,
                        ),
                        _MetricCard(
                          label: '累積報酬',
                          value: formatSignedNullablePercent(
                            result.totalReturnPct,
                          ),
                          caption: '歷史回測',
                          icon: Icons.percent_outlined,
                        ),
                        _MetricCard(
                          label: '最大回撤',
                          value: formatSignedNullablePercent(
                            result.maxDrawdownPct,
                          ),
                          caption: '歷史區間',
                          icon: Icons.trending_down_outlined,
                        ),
                      ],
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
                      '請先執行 scripts\\00631l_update_price_history.cmd 建立 official price history cache。',
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final children = [
          _BacktestDateButton(
            key: const ValueKey('00631l-start-date-button'),
            label: '開始日期',
            value: _dateOrDash(startDate),
            caption: firstDate == null ? 'history start unavailable' : '點擊調整',
            onTap: onStartTap,
          ),
          _BacktestDateButton(
            key: const ValueKey('00631l-end-date-button'),
            label: '結束日期',
            value: _dateOrDash(endDate),
            caption: lastDate == null ? 'history end unavailable' : '點擊調整',
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

class _PositionSection extends StatefulWidget {
  const _PositionSection({required this.data});

  final Etf00631LLabData data;

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
    PositionStore.load00631L().then((value) {
      if (!mounted || value == null) {
        setState(() => _loaded = true);
        return;
      }
      final decoded = jsonDecode(value);
      if (decoded is Map) {
        _sharesController.text = decoded['shares']?.toString() ?? '';
        _costController.text = decoded['averageCost']?.toString() ?? '';
        _assetsController.text = decoded['totalAssets']?.toString() ?? '';
        _feeController.text = decoded['feeAndTax']?.toString() ?? '0';
        _noteController.text = decoded['note']?.toString() ?? '';
      }
      setState(() => _loaded = true);
    });
  }

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
      marketPrice: widget.data.intradayNav?.marketPrice,
      dataTime: widget.data.intradayNav?.dataTime,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeaderCard(
          title: '本機持倉',
          subtitle: input.hasPosition
              ? '依目前市價估算；資料只保存在本機瀏覽器。'
              : '先輸入股數與平均成本，就能在本機估算持倉狀態。',
          icon: Icons.account_balance_wallet_outlined,
          badges: const ['local-only', 'browser storage', '00631L'],
          metrics: [
            _SectionHeaderMetric(
              label: '目前市值',
              value: formatNtdAmount(summary.marketValue),
            ),
            _SectionHeaderMetric(
              label: '成本',
              value: formatNtdAmount(summary.cost),
            ),
            _SectionHeaderMetric(
              label: '損益',
              value: formatNtdAmount(summary.unrealizedPnl),
            ),
            _SectionHeaderMetric(
              label: '資料時間',
              value: summary.dataTime == null
                  ? 'unavailable'
                  : formatTimeSeconds(summary.dataTime!),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _PositionStatePanel(
          input: input,
          summary: summary,
          marketPrice: widget.data.intradayNav?.marketPrice,
          sourceLabel: widget.data.intradayNav?.status.label ?? 'unavailable',
        ),
        const SizedBox(height: 12),
        _SectionBlock(
          title: '輸入持倉資料',
          subtitle: 'local-only，本機瀏覽器保存。清除資料後不會保留副本。',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!_loaded) const LinearProgressIndicator(),
              if (!input.hasPosition) ...[
                const _EmptyPanel(
                  title: '尚未輸入持倉',
                  message: '填入持有股數與平均成本後，這裡會顯示目前市值、未實現損益與部位比例。',
                ),
                const SizedBox(height: 12),
              ],
              _InputGrid(
                children: [
                  _NumberField(
                    label: '持有股數',
                    controller: _sharesController,
                    onChanged: (_) => setState(() {}),
                  ),
                  _NumberField(
                    label: '平均成本',
                    controller: _costController,
                    onChanged: (_) => setState(() {}),
                  ),
                  _NumberField(
                    label: '總資產，選填',
                    controller: _assetsController,
                    onChanged: (_) => setState(() {}),
                  ),
                  _NumberField(
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
              const SizedBox(height: 12),
              _PositionResultGrid(summary: summary),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('保存本機資料'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _export,
                    icon: const Icon(Icons.ios_share_outlined),
                    label: const Text('匯出 JSON'),
                  ),
                  TextButton.icon(
                    onPressed: _clear,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('清除本機資料'),
                  ),
                ],
              ),
              if (_exportJson != null) ...[
                const SizedBox(height: 12),
                SelectableText(_exportJson!),
              ],
              const SizedBox(height: 10),
              const Text('本區只做持倉資料狀態與估算顯示，非買賣建議。'),
            ],
          ),
        ),
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
    await PositionStore.save00631L(_encodedInput);
    setState(() => _exportJson = null);
  }

  Future<void> _clear() async {
    await PositionStore.clear00631L();
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
      'symbol': '00631L',
      'storage': 'local_browser_only',
      'shares': input.shares,
      'averageCost': input.averageCost,
      'totalAssets': input.totalAssets,
      'feeAndTax': input.feeAndTax,
      'note': input.note,
    });
  }
}

class _PositionStatePanel extends StatelessWidget {
  const _PositionStatePanel({
    required this.input,
    required this.summary,
    required this.marketPrice,
    required this.sourceLabel,
  });

  final EtfPositionInput input;
  final EtfPositionSummary summary;
  final double? marketPrice;
  final String sourceLabel;

  @override
  Widget build(BuildContext context) {
    final title = input.hasPosition ? '持倉資料已輸入' : '尚未輸入持倉';
    final description = input.hasPosition
        ? '目前使用 ${_price(marketPrice)} 估算市值，資料來源 $sourceLabel。'
        : '本頁不需要登入。輸入資料只會存在目前瀏覽器。';
    return _SectionBlock(
      title: '持倉狀態',
      subtitle: description,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatusWrap(
            labels: [
              title,
              'local-only',
              '市價 ${_price(marketPrice)}',
              summary.dataTime == null
                  ? '資料時間 unavailable'
                  : '資料時間 ${formatTaiwanDateTimeSeconds(summary.dataTime!)}',
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '此區只做本機持倉試算與資料狀態顯示，非買賣建議。',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _marketMutedTextColor(context),
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
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

class _AiSection extends StatelessWidget {
  const _AiSection({required this.data});

  final Etf00631LLabData data;

  @override
  Widget build(BuildContext context) {
    final summary = data.aiAnalysis;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeaderCard(
          title: '今日 AI 快覽',
          subtitle: 'rule_based 分析；聚焦今日資料時間、內容物、折溢價偏離與維護狀態。',
          icon: Icons.psychology_alt_outlined,
          badges: [
            'AI',
            'source ${summary.source}',
            'readiness ${summary.readinessLabel}',
          ],
          metrics: [
            _SectionHeaderMetric(
              label: '資料時間',
              value: summary.dataTime == null
                  ? 'unavailable'
                  : formatTaiwanDateTimeSeconds(summary.dataTime!),
              caption: 'analysis data',
            ),
            _SectionHeaderMetric(
              label: '摘要',
              value: '${summary.bullets.length} 條',
            ),
            _SectionHeaderMetric(
              label: '程式操作',
              value: '${summary.actionItems.length} 項',
            ),
            const _SectionHeaderMetric(
              label: '性質',
              value: '非買賣建議',
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SectionBlock(
          title: '今日 AI 分析摘要',
          subtitle: '預設 rule_based，不需要 API key。只解釋今日資料狀態、內容物變化與價格偏離。',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StatusWrap(
                labels: [
                  'source ${summary.source}',
                  'sourceStatus ${summary.sourceStatusLabel}',
                  'readiness ${summary.readinessLabel}',
                  summary.disclaimer,
                ],
              ),
              const SizedBox(height: 12),
              _AiSignalGrid(data: data, summary: summary),
              const SizedBox(height: 12),
              Text(
                '產生時間 ${formatTaiwanDateTimeSeconds(summary.generatedAt)}'
                '${summary.dataTime == null ? '' : '，資料時間 ${formatTaiwanDateTimeSeconds(summary.dataTime!)}'}',
              ),
              const SizedBox(height: 12),
              Text(
                '今日重點',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 8),
              for (final bullet in summary.bullets)
                _BulletLine(text: bullet, icon: Icons.insights_outlined),
              const SizedBox(height: 8),
              Text(
                '程式操作項目',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              for (final action in summary.actionItems)
                _BulletLine(text: action, icon: Icons.task_alt_outlined),
              const Divider(height: 24),
              Text(
                '完整資料日報',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 8),
              for (final bullet in _completeDataBriefing(data))
                _BulletLine(text: bullet, icon: Icons.analytics_outlined),
              const SizedBox(height: 8),
              const Text('非買賣建議。'),
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
          caption: 'source ${summary.sourceStatusLabel}',
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
          value: formatSignedNullablePercent(nav?.estimatedPremiumDiscountPct),
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
    final filteredItems = _filteredItems(catalog);
    final visibleItems = filteredItems.take(60).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeaderCard(
          title: 'ETF 資料庫',
          subtitle:
              '先整理 TWSE all-ETF catalog；ETF 比較會沿用這份資料，不會把 fallback 說成 official。',
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
          ],
        ),
        const SizedBox(height: 12),
        _SectionBlock(
          title: 'ETF 查詢',
          subtitle: '可用代號、名稱或商品類型搜尋；目前先做資料整理，下一步再做比較視圖。',
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
                  title: 'ETF catalog 暫不可用',
                  message:
                      'live backend 可提供 ETF catalog；static public mode 仍保留 00631L 歷史與回測。',
                ),
        ),
        const SizedBox(height: 12),
        _SectionBlock(
          title: 'ETF 比較基礎',
          subtitle: '先比較 catalog snapshot 的行情與 NAV 欄位；完整 ETF 回測比較會在後續版本加入。',
          child: _EtfComparisonPreview(catalog: catalog),
        ),
        const SizedBox(height: 12),
        const _SectionBlock(
          title: '比較功能準備',
          subtitle: '這裡先建立 ETF catalog 與資料狀態基礎；完整 ETF 比較會在後續版本加入。',
          child: _StatusList(
            items: [
              _StatusItem(
                label: '資料來源',
                status: 'ready',
                detail: '前端已可讀取 ETF catalog，並保留 source status。',
                action: '下一步可加入 ETF 比較資料模型與比較頁。',
              ),
              _StatusItem(
                label: '00631L',
                status: 'focus',
                detail: '00631L 正二研究室仍是目前核心頁面。',
                action: '其他 ETF 先作為 catalog 與比較候選資料。',
              ),
            ],
          ),
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
  const _SettingsSection({required this.data});

  final Etf00631LLabData data;

  @override
  Widget build(BuildContext context) {
    final status = data.operationsStatus;
    final readiness = status.dailyReadinessSummary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SettingsHeaderStrip(
          readinessLabel: readiness.label,
          backendLabel: status.backendConnectionLabel,
          persistenceLabel: status.dataPersistenceLabel,
        ),
        const SizedBox(height: 10),
        _SectionBlock(
          title: '帳戶與偏好',
          subtitle: '目前不需要登入。持倉資料預設只保存在本機瀏覽器。',
          child: _StatusList(
            items: [
              const _StatusItem(
                label: '帳戶',
                status: 'not required',
                detail: '00631L 正二研究室目前不需要帳號或券商登入。',
                action: '可直接使用公開 PWA；持倉資料留在本機。',
              ),
              const _StatusItem(
                label: '外觀',
                status: 'available',
                detail: '右上角可切換夜間模式，偏好會保存在本機。',
                action: '需要切換時點選月亮或太陽圖示。',
              ),
              _StatusItem(
                label: '持倉資料',
                status: status.positionStatus,
                detail: '持倉追蹤採 local-only，不會上傳個人持倉。',
                action: '可在持倉頁保存、匯出 JSON 或清除。',
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _SectionBlock(
          title: 'ETF 資料狀態',
          subtitle: '完整 ETF 清單已移到 ETF 分頁；設定頁只保留狀態摘要。',
          child: _StatusList(
            items: [
              _StatusItem(
                label: 'catalog',
                status: data.etfCatalog.hasData
                    ? data.etfCatalog.sourceStatusLabel
                    : status.etfCatalogStatus,
                detail:
                    'rows ${data.etfCatalog.hasData ? data.etfCatalog.rowCount : status.etfCatalogRowCount}，dataTime ${_dateTimeOrDash(data.etfCatalog.dataTime ?? status.etfCatalogDataTime)}。',
                action: '切到 ETF 分頁可搜尋代號、名稱與分類。',
              ),
              const _StatusItem(
                label: 'ETF comparison',
                status: 'planned',
                detail: '目前先整理 ETF catalog；比較視圖會在後續版本加入。',
                action: '下一步建立 ETF 比較資料模型與 UI。',
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const _CompactExpansionPanel(
          title: 'App 上架準備',
          subtitle: '目前是 PWA 完成版；原生 Android / iOS 還需要平台打包、簽章與商店資料。',
          child: _StatusList(
            items: [
              _StatusItem(
                label: 'PWA',
                status: 'ready',
                detail:
                    '公開 GitHub Pages root 可直接開啟 ETF 研究室，並保留 static history fallback。',
                action: '可先用 PWA 日常使用與收集 store 截圖素材。',
              ),
              _StatusItem(
                label: 'Android',
                status: 'planned',
                detail:
                    '目前 repo 尚未加入 Android 原生 scaffold 與 release signing 設定。',
                action: '下一階段建立 Android shell、app id、icon、簽章與 store build 流程。',
              ),
              _StatusItem(
                label: 'iOS',
                status: 'planned',
                detail:
                    'iOS 上架需要 macOS、Xcode、Apple Developer 與 App Store Connect。',
                action: '下一階段準備 bundle id、簽章、隱私資訊與 TestFlight 流程。',
              ),
              _StatusItem(
                label: '隱私與支援',
                status: 'needed',
                detail:
                    '正式商店頁需要 privacy policy、support URL、app icon、截圖與資料使用說明。',
                action: '先整理 policy 草稿與上架素材清單；不把任何 key 放進 repo。',
              ),
              _StatusItem(
                label: 'Live backend',
                status: 'ready template',
                detail:
                    'public backend 已有 Docker / Render / CORS / persistent data 設計。',
                action: '正式上架前確認 backend uptime、persistent volume 與公開 API URL。',
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _CompactExpansionPanel(
          title: '資料模式與完整度',
          subtitle: 'static 歷史資料、live backend 與內容物狀態需要時再看。',
          child: _StatusList(items: _dataCoverageItems(data)),
        ),
        const SizedBox(height: 10),
        _CompactExpansionPanel(
          title: '進階維護診斷',
          subtitle: 'backend、history、report、export、backup 與部署設定。',
          child: _StatusList(
            items: [
              _StatusItem(
                label: 'backend',
                status: status.sourceStatusLabel,
                detail: status.backendConnectionCaption,
                action: status.backendDisconnected
                    ? '請啟動 backend 或檢查公開 backend URL。'
                    : 'backend reachable。',
              ),
              _StatusItem(
                label: 'official holdings',
                status: status.holdingsHistoryStatus,
                detail:
                    'history count ${status.holdingsHistoryItemCount}，latest ${_dateOrDash(status.latestHoldingTradeDate)}。',
                action: status.holdingsHistoryItemCount == 0
                    ? '請執行 scripts\\00631l_daily_cycle.cmd。'
                    : '每日資料已累積。',
              ),
              _StatusItem(
                label: 'intraday NAV',
                status: status.intradayHistoryStatus,
                detail:
                    'samples ${status.intradaySampleCount}，latest ${status.latestIntradayDataTime == null ? 'unavailable' : formatTaiwanDateTimeSeconds(status.latestIntradayDataTime!)}。',
                action: status.intradaySampleCount == 0
                    ? '請確認 TWSE URL、backend 與交易時段。'
                    : '盤中估算資料已保存。',
              ),
              _StatusItem(
                label: 'historical price',
                status: status.priceHistoryStatus,
                detail:
                    'rows ${status.priceHistoryRows}，coverage ${_dateOrDash(status.priceHistoryCoverageStart)} - ${_dateOrDash(status.priceHistoryCoverageEnd)}，generated ${_dateTimeOrDash(status.latestExportUpdatedAt)}。',
                action: status.priceHistoryRows < 2
                    ? '請執行 scripts\\00631l_update_price_history.cmd；GitHub Pages 請執行 scripts\\00631l_export_static_data.cmd --update。'
                    : '歷史價格可供回測。',
              ),
              _StatusItem(
                label: 'backtest',
                status: status.backtestStatus,
                detail: status.backtestAvailable
                    ? 'price history available'
                    : 'price history insufficient',
                action: status.backtestAvailable ? '可在回測區使用。' : '請先更新歷史價格。',
              ),
              _StatusItem(
                label: 'position local data',
                status: status.positionStatus,
                detail: '持倉資料保存在瀏覽器本機。',
                action: '可在持倉區保存、匯出或清除。',
              ),
              _StatusItem(
                label: 'daily cycle',
                status: status.dailyCycleStatus,
                detail:
                    'warnings ${status.dailyCycleWarningCount}，failures ${status.dailyCycleFailureCount}。',
                action: status.dailyCycleStatus == 'PASS'
                    ? '最近 daily cycle 可讀。'
                    : '請執行 scripts\\00631l_daily_cycle.cmd。',
              ),
              _StatusItem(
                label: 'report / export / backup',
                status: '${status.reportOverallStatus} / '
                    '${status.exportAvailable ? 'ready' : 'missing'} / '
                    '${status.backupAvailable ? 'ready' : 'missing'}',
                detail:
                    'report ${status.latestReportPath ?? 'missing'}，export ${status.latestExportPath ?? 'missing'}，backup ${status.latestBackupPath ?? 'missing'}。',
                action: '必要時執行 report、export、backup scripts。',
              ),
              _StatusItem(
                label: 'public deployment config',
                status: status.dataPersistenceLabel,
                detail:
                    'API ${status.publicApiBaseUrl.isEmpty ? _proxyBaseUrl00631l : status.publicApiBaseUrl}，origins ${status.allowedOrigins.isEmpty ? 'local/LAN' : status.allowedOrigins.join(', ')}。',
                action: status.dataPathPersistent
                    ? 'persistent storage ready。'
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
        message: '需要 live backend ETF catalog 才能顯示比較基礎資料。',
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
                formatSignedNullablePercent(item.premiumDiscountPct),
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
                    Text(
                      item.targetType.isEmpty ? 'ETF' : item.targetType,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: _marketMutedTextColor(context),
                      ),
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
                    formatSignedNullablePercent(item.premiumDiscountPct),
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

class _SettingsHeaderStrip extends StatelessWidget {
  const _SettingsHeaderStrip({
    required this.readinessLabel,
    required this.backendLabel,
    required this.persistenceLabel,
  });

  final String readinessLabel;
  final String backendLabel;
  final String persistenceLabel;

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
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const _MiniStatusBadge(label: 'APP'),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '設定',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: _marketTextColor(context),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _CompactTextBadge(label: readinessLabel),
              ],
            ),
            const SizedBox(height: 7),
            Text(
              '帳戶、外觀、上架準備與本機資料放在前面；資料診斷需要時再展開。',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: _marketMutedTextColor(context),
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            _StatusWrap(
              labels: [
                _frontendDataModeLabel,
                backendLabel,
                persistenceLabel,
              ],
            ),
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
              '同一張官方每日內容物快照；盤中變化請看 intraday NAV。',
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
            'price rows ${formatInteger(price.rowCount)}',
            'holdings history $holdingsCount',
            'intraday $intradayTime',
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
            'history count $count',
            'latest ${_dateOrDash(_latestHoldingsDate(data))}',
            'integrity ${status.integrityStatus}',
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
            'source ${priceHistory.sourceStatusLabel}',
            'rows ${summary.rowCount}',
            'coverage ${_dateOrDash(summary.coverageStart)} - ${_dateOrDash(summary.coverageEnd)}',
            summary.isCompleteFromListing ? 'from listing' : 'partial range',
          ],
        ),
        const SizedBox(height: 12),
        _ResponsiveMetricGrid(
          cards: [
            _MetricCard(
              label: '最新收盤',
              value: _price(latest?.close),
              caption: summary.latestDailyReturnPct == null
                  ? '日報酬 unavailable'
                  : '日報酬 ${formatSignedNullablePercent(summary.latestDailyReturnPct)}',
              icon: Icons.candlestick_chart_outlined,
            ),
            _MetricCard(
              label: '最新 OHLC',
              value: latest == null
                  ? 'unavailable'
                  : '${_price(latest.open)} / ${_price(latest.high)} / ${_price(latest.low)}',
              caption: summary.hasOhlc ? '開 / 高 / 低' : 'OHLC unavailable',
              icon: Icons.stacked_line_chart_outlined,
            ),
            _MetricCard(
              label: '成交量',
              value: formatInteger(latest?.volume),
              caption: summary.hasVolume ? '最新交易日' : 'volume unavailable',
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
          'NAV 欄位 ${summary.hasNav ? '可用' : '尚未覆蓋'}，折溢價欄位 ${summary.hasPremiumDiscount ? '可用' : '尚未覆蓋'}；盤中 live 折溢價仍以 backend intraday NAV 為準。',
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
          caption: '完整 price history',
          points: priceHistory.points,
          valueOf: (point) => point.performanceClose,
        ),
        _MiniChartCard(
          title: '累積報酬',
          caption: '從 coverage start 計算',
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
          caption: '官方 holdings history',
          points: _holdingChartPoints(ordered, (point) => point.txWeightPct),
        ),
        _MiniChartCard(
          title: '台積電權重',
          caption: '官方 holdings history',
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
          childAspectRatio: isCompact ? 1.78 : 1.5,
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
                height: 92,
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
  final double? latestClose;
  final double? totalReturnPct;
  final double? annualizedReturnPct;
  final double? maxDrawdownPct;
  final double? annualizedVolatilityPct;
  final String sourceStatusLabel;
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
    final safeTouchedIndex = _touchedIndex == null || spots.isEmpty
        ? null
        : _touchedIndex!.clamp(0, spots.length - 1);
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
                    titlesData: FlTitlesData(
                      rightTitles: const AxisTitles(),
                      topTitles: const AxisTitles(),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 34,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            final index = value.round();
                            if (!_isBottomDateTick(index, spotPoints.length)) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 5),
                              child: Text(
                                _shortChartDate(spotPoints[index].date),
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
        _ChartTouchDetail(
          point: touchedPoint,
          value: touchedValue,
        ),
      ],
    );
  }
}

class _ChartTouchDetail extends StatelessWidget {
  const _ChartTouchDetail({
    required this.point,
    required this.value,
  });

  final EtfPriceHistoryPoint? point;
  final double? value;

  @override
  Widget build(BuildContext context) {
    final text = point == null || value == null
        ? '點擊圖表可查看完整日期與數值'
        : '${formatTaiwanDate(point!.date)}  ${_compactChartValue(value!)}';
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: _marketMutedTextColor(context),
            fontWeight: FontWeight.w800,
          ),
    );
  }
}

bool _isBottomDateTick(int index, int length) {
  if (index < 0 || index >= length) {
    return false;
  }
  if (length <= 3) {
    return true;
  }
  final mid = (length - 1) ~/ 2;
  return index == 0 || index == mid || index == length - 1;
}

String _shortChartDate(DateTime date) {
  final yy = (date.year % 100).toString().padLeft(2, '0');
  final mm = date.month.toString().padLeft(2, '0');
  final dd = date.day.toString().padLeft(2, '0');
  return '$yy/$mm\n$dd';
}

String _compactChartValue(double value) {
  if (value.abs() >= 1000000) {
    return formatInteger(value.round());
  }
  if (value.abs() >= 1000) {
    return value.toStringAsFixed(0);
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
          subtitle: '頁面沒有取得可用資料。請檢查 backend 或 mock fallback 設定。',
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
  String code, {
  required String selectedCode,
}) {
  final normalized = code.trim().toUpperCase();
  final selected = selectedCode.trim().toUpperCase();
  if (normalized == selected) {
    return true;
  }
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
  final txLine = _primaryFuturesLine(data.snapshot);
  final txQuote = data.futuresQuote;
  final txTime = txQuote.dataTime == null
      ? '-'
      : '${formatTaiwanDate(txQuote.dataTime!)} ${formatTimeSeconds(txQuote.dataTime!)}';

  return [
    _StatusItem(
      label: '價格歷史',
      status: _priceCoverageStatus(data),
      detail:
          'rows ${formatInteger(price.rowCount)}，coverage ${_dateOrDash(price.coverageStart)} - ${_dateOrDash(price.coverageEnd)}，source ${data.priceHistory.sourceStatusLabel}。',
      action: price.rowCount >= 2
          ? price.isCompleteFromListing
              ? '已可支援歷史與回測；coverage 仍以 static manifest 與官方更新時間為準。'
              : '可支援歷史與回測，但 coverage 不是完整上市以來區間。'
          : '請執行 scripts\\00631l_update_price_history.cmd 或 scripts\\00631l_export_static_data.cmd --update。',
    ),
    _StatusItem(
      label: '內容物歷史',
      status: _holdingsCoverageStatus(data),
      detail:
          'latest ${_dateOrDash(latestHoldingDate)}，history count $holdingsCount；${_holdingsGapText(data)}；官方 ratio 是每日快照。',
      action: holdingsCount > 0
          ? _holdingsIntegrityAction(data)
          : '請執行 scripts\\00631l_daily_cycle.cmd 累積官方每日快照。',
    ),
    _StatusItem(
      label: '盤中 NAV / 折溢價',
      status: data.intradayNav?.status.label ?? 'unavailable',
      detail:
          'dataTime $intradayTime；live intraday NAV 需要 backend 連到 TWSE all_etf.txt。',
      action: data.intradayNav == null
          ? 'static public mode 只提供歷史與回測；若要盤中資料，請啟用 public backend。'
          : '請以資料時間與 sourceContract 為準。',
    ),
    _StatusItem(
      label: 'TX live',
      status: txQuote.status.label,
      detail:
          'TAIFEX ${txQuote.sourceContract ?? 'quote'}；TX ${_price(txQuote.txPrice)}，加權指數 ${_price(txQuote.weightedIndex)}，基差 ${formatSignedNullablePercent(txQuote.futuresBasisPct)}，dataTime $txTime。官方 holdings TX 權重 ${txLine == null ? 'unavailable' : formatNullablePercent(txLine.weightPct)}。',
      action: txQuote.txPrice == null
          ? '請確認 TAIFEX 交易時段、backend 連線與 TAIFEX_TX_SOCKJS_URL 設定。'
          : '請以 TAIFEX dataTime 與官方 holdings tradeDate 分別判讀。',
    ),
    _StatusItem(
      label: 'ETF catalog',
      status: data.operationsStatus.etfCatalogStatus,
      detail:
          'TWSE all_etf rows ${formatInteger(data.operationsStatus.etfCatalogRowCount)}; dataTime ${_dateTimeOrDash(data.operationsStatus.etfCatalogDataTime)}.',
      action: data.operationsStatus.etfCatalogRowCount > 0
          ? 'ETF catalog already imported; 00631L stays as the focused research room.'
          : 'Run scripts\\00631l_import_etf_catalog.cmd to import TWSE all_etf catalog.',
    ),
    _StatusItem(
      label: 'ETF history',
      status: data.operationsStatus.etfPriceHistoryStatus,
      detail:
          'ready ${formatInteger(data.operationsStatus.etfPriceHistoryReadyCount)} / symbols ${formatInteger(data.operationsStatus.etfPriceHistoryRowCount)}; dataTime ${_dateTimeOrDash(data.operationsStatus.etfPriceHistoryDataTime)}.',
      action: data.operationsStatus.etfPriceHistoryReadyCount > 0
          ? 'ETF price history imported for comparison data foundation.'
          : 'Run scripts\\00631l_import_etf_price_history.cmd to import selected ETF price history.',
    ),
  ];
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
          ? '請執行 daily cycle 並確認官方 ratio 來源。'
          : '請以官方內容物日期為準。',
    ),
    _StatusItem(
      label: 'history 累積',
      status: _holdingsCoverageStatus(data),
      detail:
          'history count $count，latest ${_dateOrDash(_latestHoldingsDate(data))}；不是發行以來完整 holdings。',
      action: count == 0
          ? '請執行 scripts\\00631l_daily_cycle.cmd。'
          : '後續每日執行 daily cycle 會繼續補新的官方快照。',
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
    return 'integrity fail';
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
    return '請檢查缺日是否為尚未執行 daily cycle；可重新執行 daily cycle 後再檢查。';
  }
  if (status.integrityStatus == 'missing') {
    return '請執行 scripts\\00631l_check_integrity.cmd 產生完整性狀態。';
  }
  return '已從本機 daily cycle 開始累積；不補假過去內容物。';
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

String _overviewAiBrief(Etf00631LLabData data) {
  if (data.aiAnalysis.bullets.isEmpty) {
    return 'AI 摘要暫無內容；請確認資料來源狀態後重新整理。';
  }
  return data.aiAnalysis.bullets.first;
}

List<String> _completeDataBriefing(Etf00631LLabData data) {
  final price = data.priceHistory.completenessSummary();
  final performance = data.priceHistory.performance;
  final holdings = data.holdingsHistory.trendSummary();
  final intraday = data.intradayNavHistory;
  final lines = <String>[
    '價格歷史共 ${price.rowCount} 筆，coverage ${_dateOrDash(price.coverageStart)} - ${_dateOrDash(price.coverageEnd)}，source ${data.priceHistory.sourceStatusLabel}。',
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
      '最新 official holdings：TX 權重 ${formatNullablePercent(holdings.latest!.txWeightPct)}，台積電權重 ${formatNullablePercent(holdings.latest!.tsmcWeightPct)}，股票/期貨/現金保證金 ${formatNullablePercent(holdings.latest!.stockExposurePct)} / ${formatNullablePercent(holdings.latest!.futuresExposurePct)} / ${formatNullablePercent(holdings.latest!.cashAndMarginPct)}。',
    );
  } else {
    lines.add('尚無 holdings history，請執行 daily cycle 累積官方每日快照。');
  }
  if (intraday.hasData) {
    lines.add(
      '今日 intraday NAV samples ${intraday.sampleCount}，折溢價區間 ${formatSignedNullablePercent(intraday.lowestPremiumDiscountPct)} 至 ${formatSignedNullablePercent(intraday.highestPremiumDiscountPct)}，最後時間 ${_dateTimeOrDash(intraday.lastDataTime)}。',
    );
  } else {
    lines
        .add('intraday NAV history 尚未累積；live 折溢價需 public backend 與 TWSE 資料可用。');
  }
  lines.add(
    '維護狀態：backend ${data.operationsStatus.backendConnectionCaption}，report ${data.operationsStatus.reportOverallStatus}，export ${data.operationsStatus.exportAvailable ? 'ready' : 'missing'}，backup ${data.operationsStatus.backupAvailable ? 'ready' : 'missing'}。',
  );
  return lines;
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
