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

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        ref.invalidate(etf00631LLabProvider);
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
    final labValue = ref.watch(etf00631LLabProvider);
    return SafeArea(
      child: labValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          error: error,
          onRefresh: () => ref.invalidate(etf00631LLabProvider),
        ),
        data: (data) => _LabContent(
          data: data,
          selectedSection: _section,
          onSectionChanged: (section) => setState(() => _section = section),
          onRefresh: () => ref.invalidate(etf00631LLabProvider),
        ),
      ),
    );
  }
}

enum _LabSection {
  overview('總覽', Icons.dashboard_outlined),
  holdings('內容物', Icons.inventory_2_outlined),
  history('歷史', Icons.show_chart_outlined),
  backtest('回測', Icons.query_stats_outlined),
  position('持倉', Icons.account_balance_wallet_outlined),
  ai('AI 分析', Icons.psychology_alt_outlined),
  system('系統狀態', Icons.health_and_safety_outlined);

  const _LabSection(this.label, this.icon);
  final String label;
  final IconData icon;
}

class _LabContent extends StatelessWidget {
  const _LabContent({
    required this.data,
    required this.selectedSection,
    required this.onSectionChanged,
    required this.onRefresh,
  });

  final Etf00631LLabData data;
  final _LabSection selectedSection;
  final ValueChanged<_LabSection> onSectionChanged;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = constraints.maxWidth < 520 ? 10.0 : 18.0;
        return ListView(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            8,
            horizontalPadding,
            24,
          ),
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _QuoteHeader(data: data, onRefresh: onRefresh),
                    const SizedBox(height: 10),
                    _SectionPicker(
                      selected: selectedSection,
                      onChanged: onSectionChanged,
                    ),
                    const SizedBox(height: 12),
                    _sectionWidget(data),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _sectionWidget(Etf00631LLabData data) {
    switch (selectedSection) {
      case _LabSection.overview:
        return _OverviewSection(data: data);
      case _LabSection.holdings:
        return _HoldingsSection(data: data);
      case _LabSection.history:
        return _HistorySection(data: data);
      case _LabSection.backtest:
        return _BacktestSection(data: data);
      case _LabSection.position:
        return _PositionSection(data: data);
      case _LabSection.ai:
        return _AiSection(data: data);
      case _LabSection.system:
        return _SystemStatusSection(status: data.operationsStatus);
    }
  }
}

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
                          Text(
                            '00631L 正二研究室',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: headerForeground,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                            ),
                          ),
                          _HeaderPill(
                            label: _frontendDataMode,
                            foreground: headerForeground,
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '官方內容物、盤中預估淨值、歷史資料、回測與系統狀態。',
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
                      const SizedBox(width: 4),
                      const _ThemeToggleButton(compact: true),
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
                  'page ${data.status.label}',
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

String _frontendModeDetail(Etf00631LLabData data) {
  if (_use00631LLiveProxy) {
    final status = data.operationsStatus;
    final api = status.publicApiBaseUrl.isEmpty
        ? _proxyBaseUrl00631l
        : status.publicApiBaseUrl;
    const fallback = _use00631LStaticData
        ? '; static public history remains available when live API is disconnected'
        : '';
    return 'live_proxy API $api$fallback.';
  }
  if (_use00631LStaticData) {
    final status = data.operationsStatus;
    return '公開靜態資料模式，rowCount ${status.priceHistoryRows}，coverage '
        '${_dateOrDash(status.priceHistoryCoverageStart)} - '
        '${_dateOrDash(status.priceHistoryCoverageEnd)}，generated '
        '${_dateTimeOrDash(status.latestExportUpdatedAt ?? data.priceHistory.lastFetchedAt)}。';
  }
  if (_use00631LLiveProxy) {
    final status = data.operationsStatus;
    return 'live proxy 模式，API ${status.publicApiBaseUrl.isEmpty ? _proxyBaseUrl00631l : status.publicApiBaseUrl}。';
  }
  return 'mock_default 模式，畫面可測試但不會把 fallback 標示為 official。';
}

String _frontendModeAction(Etf00631LLabData data) {
  if (_use00631LLiveProxy) {
    if (_use00631LStaticData && data.operationsStatus.backendDisconnected) {
      return 'Check public backend /ready; static public history remains visible while live API is unavailable.';
    }
    return 'Check public backend /health, /ready, and operations/status.';
  }
  if (_use00631LStaticData) {
    return data.operationsStatus.priceHistoryRows < 2
        ? '請執行 scripts\\00631l_export_static_data.cmd --update 產生 static JSON。'
        : '歷史與回測可讀；live intraday NAV 仍需要 backend。';
  }
  if (_use00631LLiveProxy) {
    return '請確認 backend /health 與 operations/status。';
  }
  return '需要公開手機使用時，請使用 GitHub Pages static-public build。';
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
        final theme = Theme.of(context);
        return IconButton(
          tooltip: isDark ? '切換淺色模式' : '切換夜間模式',
          onPressed: () {
            setAppThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
          },
          style: compact
              ? IconButton.styleFrom(
                  backgroundColor:
                      theme.colorScheme.onSurface.withValues(alpha: 0.10),
                  foregroundColor:
                      theme.colorScheme.brightness == Brightness.light
                          ? Colors.white
                          : theme.colorScheme.onSurface,
                )
              : null,
          icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode),
        );
      },
    );
  }
}

class _SectionPicker extends StatelessWidget {
  const _SectionPicker({
    required this.selected,
    required this.onChanged,
  });

  final _LabSection selected;
  final ValueChanged<_LabSection> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: SizedBox(
        height: 76,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          scrollDirection: Axis.horizontal,
          itemCount: _LabSection.values.length,
          separatorBuilder: (context, index) => const SizedBox(width: 6),
          itemBuilder: (context, index) {
            final section = _LabSection.values[index];
            final isSelected = section == selected;
            return InkWell(
              key: ValueKey('00631l-section-${section.name}'),
              borderRadius: BorderRadius.circular(12),
              onTap: () => onChanged(section),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                constraints: const BoxConstraints(minWidth: 74),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primaryContainer
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary.withValues(alpha: 0.35)
                        : Colors.transparent,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      section.icon,
                      size: 18,
                      color: isSelected
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      section.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: isSelected
                            ? theme.colorScheme.onPrimaryContainer
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight:
                            isSelected ? FontWeight.w900 : FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
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
    final snapshot = data.snapshot;
    final history = data.holdingsHistory.trendSummary();
    final performance = data.priceHistory.performance;
    final priceCompleteness = data.priceHistory.completenessSummary();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionBlock(
          title: '今日資料狀態',
          subtitle: '清楚區分每日官方資料、盤中估算資料與尚未接入的 TX live。',
          child: _StatusList(
            items: [
              _StatusItem(
                label: '官方 holdings / ratio',
                status: snapshot.status.label,
                detail:
                    '每日快照，內容物日期 ${formatTaiwanDate(snapshot.tradeDate)}，不是盤中即時內容物。',
                action: snapshot.isStale(data.lastFetchedAt)
                    ? '請執行 daily cycle 並確認 Yuanta official ratio。'
                    : '資料已可讀，請以官方日期為準。',
              ),
              _StatusItem(
                label: 'intraday NAV / 折溢價',
                status: data.intradayNav?.status.label ?? 'unavailable',
                detail: 'TWSE all_etf.txt 可約 15 秒級更新，需 backend 與 env 設定正常。',
                action: data.intradayNav == null
                    ? '請檢查 backend、TWSE URL 與交易時段。'
                    : '請以資料時間 ${data.intradayNav!.dataTime == null ? 'unavailable' : formatTaiwanDateTimeSeconds(data.intradayNav!.dataTime!)} 為準。',
              ),
              const _StatusItem(
                label: 'TX live',
                status: 'mock/fallback',
                detail: '尚未接 TX live，現階段只保留模型與 fallback 顯示。',
                action: '本版不需要任何 TX live 設定。',
              ),
              _StatusItem(
                label: 'frontend mode',
                status: _frontendDataMode,
                detail: _frontendModeDetail(data),
                action: _frontendModeAction(data),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _ResponsiveMetricGrid(
          cards: [
            _MetricCard(
              label: '基金淨資產',
              value: formatNtdAmount(snapshot.fundNetAssetValue),
              caption: '官方每日資料',
              icon: Icons.account_balance_outlined,
            ),
            _MetricCard(
              label: '每單位淨值',
              value: _price(snapshot.navPerUnit),
              caption: '官方每日資料',
              icon: Icons.paid_outlined,
            ),
            _MetricCard(
              label: '發行單位數',
              value: formatInteger(snapshot.outstandingUnits),
              caption: '官方每日資料',
              icon: Icons.confirmation_number_outlined,
            ),
            _MetricCard(
              label: '價格總報酬',
              value: formatSignedNullablePercent(
                performance.totalReturnPct,
              ),
              caption: data.priceHistory.hasData
                  ? '${_dateOrDash(data.priceHistory.coverageStart)} - ${_dateOrDash(data.priceHistory.coverageEnd)}'
                  : '尚無 official price history',
              icon: Icons.timeline_outlined,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SectionBlock(
          title: '歷史資料完整度',
          subtitle: '公開靜態資料與 live backend 共用這份 price history；沒有資料時不補假資料。',
          child: _PriceCompletenessPanel(
            priceHistory: data.priceHistory,
            summary: priceCompleteness,
          ),
        ),
        const SizedBox(height: 12),
        _SectionBlock(
          title: '7 / 30 日內容物變化',
          subtitle: '根據本機保存的 official holdings history；缺資料時不補假資料。',
          child: history.latest == null
              ? const _EmptyPanel(
                  title: '尚無 holdings history',
                  message: '請先執行 daily cycle 累積官方每日快照。',
                )
              : _HistoryChangeCards(summary: history),
        ),
      ],
    );
  }
}

class _HoldingsSection extends StatelessWidget {
  const _HoldingsSection({required this.data});

  final Etf00631LLabData data;

  @override
  Widget build(BuildContext context) {
    final snapshot = data.snapshot;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionBlock(
          title: '官方每日內容物',
          subtitle:
              'tradeDate ${formatTaiwanDate(snapshot.tradeDate)}，每日揭露資料，不代表盤中即時變動。',
          child: Column(
            children: [
              _ExposureBars(snapshot: snapshot),
              const SizedBox(height: 12),
              _HorizontalTable(
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
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SectionBlock(
          title: '股票明細',
          subtitle: '官方每日資料。',
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
        const SizedBox(height: 12),
        _SectionBlock(
          title: '期貨明細',
          subtitle: 'TX live 尚未接入，這裡是官方每日內容物快照。',
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
        const SizedBox(height: 12),
        _SectionBlock(
          title: '現金 / 保證金明細',
          subtitle: '官方每日資料。',
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
      ],
    );
  }
}

class _HistorySection extends StatelessWidget {
  const _HistorySection({required this.data});

  final Etf00631LLabData data;

  @override
  Widget build(BuildContext context) {
    final holdingsTrend = data.holdingsHistory.trendSummary();
    final priceHistory = data.priceHistory;
    final performance = priceHistory.performance;
    final completeness = priceHistory.completenessSummary();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionBlock(
          title: '價格 / 淨值歷史',
          subtitle: priceHistory.hasData
              ? 'coverage ${_dateOrDash(priceHistory.coverageStart)} - ${_dateOrDash(priceHistory.coverageEnd)}，sourceStatus ${priceHistory.sourceStatusLabel}'
              : '尚無 official price history。請執行 scripts\\00631l_update_price_history.cmd。',
          child: priceHistory.hasData
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ResponsiveMetricGrid(
                      cards: [
                        _MetricCard(
                          label: '累積報酬',
                          value: formatSignedNullablePercent(
                            performance.totalReturnPct,
                          ),
                          caption: '歷史價格計算',
                          icon: Icons.trending_up_outlined,
                        ),
                        _MetricCard(
                          label: '年化報酬',
                          value: formatSignedNullablePercent(
                            performance.annualizedReturnPct,
                          ),
                          caption: '歷史估算',
                          icon: Icons.functions_outlined,
                        ),
                        _MetricCard(
                          label: '最大回撤',
                          value: formatSignedNullablePercent(
                            performance.maxDrawdownPct,
                          ),
                          caption: '歷史區間',
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
                    Text(
                      '歷史資料完整度',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 8),
                    _PriceCompletenessPanel(
                      priceHistory: priceHistory,
                      summary: completeness,
                    ),
                    const SizedBox(height: 12),
                    _PriceTrendCharts(priceHistory: priceHistory),
                    const SizedBox(height: 12),
                    _HorizontalTable(
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
                        for (final point
                            in priceHistory.points.reversed.take(30))
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
                  ],
                )
              : const _EmptyPanel(
                  title: '尚無 official price history',
                  message: '歷史價格需要手動更新後才會顯示。本頁不會用 mock 偽裝 official。',
                ),
        ),
        const SizedBox(height: 12),
        _SectionBlock(
          title: '每日 holdings history',
          subtitle: '最近 7 日摘要與最近 30 筆表格，資料從本 app 開始累積。',
          child: data.holdingsHistory.hasData
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HistoryChangeCards(summary: holdingsTrend),
                    const SizedBox(height: 12),
                    _HoldingsTrendCharts(summary: holdingsTrend),
                    const SizedBox(height: 12),
                    _HorizontalTable(
                      columns: const [
                        '日期',
                        'TX 權重',
                        '台積電權重',
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
                  ],
                )
              : const _EmptyPanel(
                  title: '尚無歷史紀錄',
                  message: '請執行 daily cycle 保存官方每日內容物快照。',
                ),
        ),
      ],
    );
  }
}

class _BacktestSection extends StatefulWidget {
  const _BacktestSection({required this.data});

  final Etf00631LLabData data;

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
    _startDate = widget.data.priceHistory.coverageStart;
    _endDate = widget.data.priceHistory.coverageEnd;
  }

  @override
  void dispose() {
    _initialController.dispose();
    _monthlyController.dispose();
    _dayController.dispose();
    _feeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final history = widget.data.priceHistory;
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

    return _SectionBlock(
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
                      selected:
                          _strategy == EtfBacktestStrategy.monthlyContribution,
                      label: const Text('定期定額'),
                      onSelected: (_) => setState(
                        () =>
                            _strategy = EtfBacktestStrategy.monthlyContribution,
                      ),
                    ),
                  ],
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
    return _SectionBlock(
      title: '持倉追蹤',
      subtitle: 'local-only，本機瀏覽器資料，不需要登入，也不會上傳到外部服務。',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_loaded) const LinearProgressIndicator(),
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
          _ResponsiveMetricGrid(
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
          ),
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

class _AiSection extends StatelessWidget {
  const _AiSection({required this.data});

  final Etf00631LLabData data;

  @override
  Widget build(BuildContext context) {
    final summary = data.aiAnalysis;
    return _SectionBlock(
      title: 'AI 分析摘要',
      subtitle: '預設 rule_based，不需要 API key。只解釋資料狀態、歷史變化與風險暴露。',
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
          Text(
            '產生時間 ${formatTaiwanDateTimeSeconds(summary.generatedAt)}'
            '${summary.dataTime == null ? '' : '，資料時間 ${formatTaiwanDateTimeSeconds(summary.dataTime!)}'}',
          ),
          const SizedBox(height: 12),
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
    );
  }
}

class _SystemStatusSection extends StatelessWidget {
  const _SystemStatusSection({required this.status});

  final EtfOperationsStatus status;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SectionBlock(
          title: '系統狀態',
          subtitle: '正式工具狀態摘要，不顯示 debug dump。',
          child: _StatusList(
            items: [
              _StatusItem(
                label: 'backend',
                status: status.sourceStatusLabel,
                detail: status.backendConnectionCaption,
                action: status.backendDisconnected
                    ? '請啟動 backend 或檢查公開 backend URL。'
                    : 'backend connected。',
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
          valueOf: (point) => point.close,
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
          childAspectRatio: isCompact ? 2.15 : 1.65,
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
                height: 132,
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
        final isCompact = constraints.maxWidth < 560;
        final isWide = constraints.maxWidth > 960;
        return GridView.count(
          crossAxisCount: isCompact ? 1 : (isWide ? 4 : 2),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: isCompact ? 2.45 : 1.35,
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
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 10),
            Expanded(
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
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
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

class _InputGrid extends StatelessWidget {
  const _InputGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 560;
        return GridView.count(
          crossAxisCount: isCompact ? 1 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: isCompact ? 3.9 : 3.2,
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
      decoration: InputDecoration(labelText: label),
      onChanged: onChanged,
    );
  }
}

class _LineChartPanel extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final selected = points.length > 120
        ? [
            for (var i = 0;
                i < points.length;
                i += (points.length / 120).ceil())
              points[i],
          ]
        : points;
    final spots = <FlSpot>[];
    for (var index = 0; index < selected.length; index += 1) {
      final value = valueOf(selected[index]);
      if (value.isFinite) {
        spots.add(FlSpot(index.toDouble(), value));
      }
    }
    return SizedBox(
      height: height,
      child: spots.isEmpty
          ? const Center(child: Text('尚無圖表資料'))
          : LineChart(
              LineChartData(
                gridData: const FlGridData(show: true),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(),
                  topTitles: const AxisTitles(),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      interval: (spots.length / 4).clamp(1, 999).toDouble(),
                      getTitlesWidget: (value, meta) {
                        final index = value.round();
                        if (index < 0 || index >= selected.length) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          labelOf(selected[index]),
                          style: const TextStyle(fontSize: 10),
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
                    color: color ?? Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),
    );
  }
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
    final firstClose = ordered.first.close;
    var peak = firstClose;
    for (final point in ordered) {
      if (point.close > peak) {
        peak = point.close;
      }
      _cumulativeByDate[_dateKey(point.date)] =
          firstClose <= 0 ? 0 : (point.close / firstClose - 1) * 100;
      _drawdownByDate[_dateKey(point.date)] =
          peak <= 0 ? 0 : (point.close / peak - 1) * 100;
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

String _monthDay(DateTime date) {
  return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
}

String _dateKey(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
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
    '系統狀態：backend ${data.operationsStatus.backendConnectionCaption}，report ${data.operationsStatus.reportOverallStatus}，export ${data.operationsStatus.exportAvailable ? 'ready' : 'missing'}，backup ${data.operationsStatus.backupAvailable ? 'ready' : 'missing'}。',
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
