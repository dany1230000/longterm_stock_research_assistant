import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/leveraged_etf_lab.dart';
import '../../repositories/repository_providers.dart';
import '../../shared/utils/formatters.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/metric_tile.dart';
import '../../shared/widgets/risk_chip.dart';
import '../../shared/widgets/section_card.dart';

class LeveragedEtf00631LScreen extends ConsumerWidget {
  const LeveragedEtf00631LScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labValue = ref.watch(etf00631LLabProvider);

    return SafeArea(
      child: labValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _ErrorLabState(
          error: error,
          onRefresh: () => ref.invalidate(etf00631LLabProvider),
        ),
        data: (data) => _LabContent(
          data: data,
          onRefresh: () => ref.invalidate(etf00631LLabProvider),
        ),
      ),
    );
  }
}

class _LabContent extends StatelessWidget {
  const _LabContent({
    required this.data,
    required this.onRefresh,
  });

  final Etf00631LLabData data;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _Header(data: data, onRefresh: onRefresh),
        const SizedBox(height: 16),
        _SummaryGrid(data: data),
        const SizedBox(height: 16),
        _StatusSummarySection(summary: data.statusSummary),
        const SizedBox(height: 16),
        _TodayDataStatusSection(status: data.operationsStatus),
        const SizedBox(height: 16),
        _OperationsStatusSection(status: data.operationsStatus),
        const SizedBox(height: 16),
        _PremiumDiscountStatusSection(nav: data.intradayNav),
        const SizedBox(height: 16),
        _IntradayNavHistorySection(history: data.intradayNavHistory),
        const SizedBox(height: 16),
        _ProfileSection(profile: data.profile),
        const SizedBox(height: 16),
        _AssetAllocationSection(snapshot: data.snapshot),
        const SizedBox(height: 16),
        _HoldingsHistorySection(history: data.holdingsHistory),
        const SizedBox(height: 16),
        _HoldingsChangeNoticeSection(data: data),
        const SizedBox(height: 16),
        _IntradaySection(nav: data.intradayNav),
        const SizedBox(height: 16),
        _FuturesQuoteSection(quote: data.futuresQuote),
        const SizedBox(height: 16),
        _DetailsTables(snapshot: data.snapshot),
        const SizedBox(height: 16),
        _AnalysisSection(analysis: data.analysis),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.data,
    required this.onRefresh,
  });

  final Etf00631LLabData data;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE1E7EF)),
      ),
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
                      '00631L 正二研究室',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '整理元大 00631L 官方每日內容物、盤中預估淨值與折溢價觀察，不提供買賣建議。',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh),
                label: const Text('刷新'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              RiskChip(label: 'page ${data.status.label}'),
              RiskChip(label: 'profile ${data.profile.status.label}'),
              RiskChip(label: 'holdings ${data.snapshot.status.label}'),
              RiskChip(
                label:
                    'intraday ${data.intradayNav?.status.label ?? 'unavailable'}',
              ),
              RiskChip(label: 'futures ${data.futuresQuote.status.label}'),
              if (data.intradayNav?.sourceContract != null)
                RiskChip(label: data.intradayNav!.sourceContract!),
              RiskChip(
                  label: '官方每日資料 ${formatTaiwanDate(data.snapshot.tradeDate)}'),
              if (data.intradayNav?.dataTime != null)
                RiskChip(
                  label:
                      '盤中估算 ${formatTimeSeconds(data.intradayNav!.dataTime!)}',
                )
              else
                const RiskChip(label: '即時資料暫不可用'),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.data});

  final Etf00631LLabData data;

  @override
  Widget build(BuildContext context) {
    final nav = data.intradayNav;
    final snapshot = data.snapshot;
    final cards = [
      MetricTile(
        label: '00631L 市價',
        value: _price(nav?.marketPrice),
        caption: '盤中估算資料',
        icon: Icons.sell_outlined,
      ),
      MetricTile(
        label: '預估淨值',
        value: _price(nav?.estimatedNav),
        caption: '盤中估算資料',
        icon: Icons.troubleshoot_outlined,
      ),
      MetricTile(
        label: '折溢價 %',
        value: formatSignedNullablePercent(nav?.estimatedPremiumDiscountPct),
        caption: data.analysis.premiumDiscountLabel,
        icon: Icons.percent_outlined,
      ),
      MetricTile(
        label: '前一日淨值',
        value: _price(nav?.previousBusinessDayNav),
        caption: nav?.previousBusinessDayNavText ?? '即時資料暫不可用',
        icon: Icons.history_outlined,
      ),
      MetricTile(
        label: '官方內容物日期',
        value: formatTaiwanDate(snapshot.tradeDate),
        caption: '官方每日資料',
        icon: Icons.calendar_today_outlined,
      ),
      MetricTile(
        label: '基金資產總淨值',
        value: formatNtdAmount(snapshot.fundNetAssetValue),
        caption: '官方每日資料',
        icon: Icons.account_balance_outlined,
      ),
      MetricTile(
        label: '每單位淨值',
        value: _price(snapshot.navPerUnit),
        caption: '官方每日資料',
        icon: Icons.paid_outlined,
      ),
      MetricTile(
        label: '發行單位數',
        value: formatInteger(snapshot.outstandingUnits),
        caption: 'official snapshot',
        icon: Icons.confirmation_number_outlined,
      ),
      MetricTile(
        label: '最後更新時間',
        value: formatTaiwanDateTimeSeconds(data.lastFetchedAt),
        caption: 'lastFetchedAt',
        icon: Icons.update_outlined,
      ),
      MetricTile(
        label: '資料狀態',
        value: data.status.label,
        caption: snapshot.errorMessage ?? 'mock/fallback 會明確標示',
        icon: Icons.cloud_sync_outlined,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;
        final isCompact = constraints.maxWidth < 520;
        return GridView.count(
          crossAxisCount: isCompact ? 1 : (isWide ? 5 : 2),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: isCompact ? 2.65 : (isWide ? 1.35 : 1.05),
          children: cards,
        );
      },
    );
  }
}

class _StatusSummarySection extends StatelessWidget {
  const _StatusSummarySection({required this.summary});

  final EtfStatusSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _statusSummaryColor(theme.colorScheme, summary.level);

    return SectionCard(
      title: '00631L 狀態總結',
      subtitle: '整合官方內容物、即時淨值、折溢價與歷史資料狀態。此區只描述資料狀態，非買賣建議。',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Color.alphaBlend(
            color.withValues(alpha: 0.08),
            theme.colorScheme.surface,
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.30)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Icon(_statusSummaryIcon(summary.level), color: color),
                  RiskChip(label: summary.label),
                ],
              ),
              const SizedBox(height: 10),
              for (final line in summary.lines)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    line,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OperationsStatusSection extends StatelessWidget {
  const _OperationsStatusSection({required this.status});

  final EtfOperationsStatus status;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: '資料收集狀態',
      subtitle: '顯示 local history、collector 與 intraday NAV 設定狀態；這不是交易訊號。',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              RiskChip(label: 'sourceStatus ${status.sourceStatusLabel}'),
              RiskChip(label: 'sourceContract ${status.sourceContract}'),
              RiskChip(label: 'intradaySource ${status.intradaySourceMode}'),
              RiskChip(
                  label: 'history ${status.hasAnyHistory ? 'ready' : 'empty'}'),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 720;
              final isCompact = constraints.maxWidth < 520;
              return GridView.count(
                crossAxisCount: isCompact ? 1 : (isWide ? 4 : 2),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: isCompact ? 2.45 : (isWide ? 1.15 : 1.0),
                children: [
                  MetricTile(
                    label: 'holdings history',
                    value: status.holdingsHistoryItemCount.toString(),
                    caption: status.latestHoldingTradeDate == null
                        ? '尚無 official holdings history'
                        : formatTaiwanDate(status.latestHoldingTradeDate!),
                    icon: Icons.inventory_2_outlined,
                  ),
                  MetricTile(
                    label: 'intraday samples',
                    value: status.intradaySampleCount.toString(),
                    caption: status.latestIntradayDataTime == null
                        ? '尚無 intraday NAV history'
                        : formatTimeSeconds(status.latestIntradayDataTime!),
                    icon: Icons.timeline_outlined,
                  ),
                  MetricTile(
                    label: 'TWSE URL',
                    value: status.twseIntradayNavConfigured
                        ? 'configured'
                        : 'unset',
                    caption: 'twse_a_k_json',
                    icon: Icons.settings_ethernet_outlined,
                  ),
                  MetricTile(
                    label: 'Yuanta URL',
                    value: status.yuantaIntradayNavConfigured
                        ? 'configured'
                        : 'unset',
                    caption: 'yuanta_inav fallback',
                    icon: Icons.settings_backup_restore_outlined,
                  ),
                  MetricTile(
                    label: 'backup dir',
                    value: status.backupDirReady ? 'ready' : 'check',
                    caption: status.backupAvailable
                        ? 'latest backup saved'
                        : 'no local backup yet',
                    icon: Icons.backup_table_outlined,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          _CommandLine(
            label: 'daily collector',
            command: status.collectorOneShotCommand,
          ),
          const SizedBox(height: 8),
          _CommandLine(
            label: 'intraday collector',
            command: status.collectorIntradayCommand,
          ),
          if (status.errorMessage != null) ...[
            const SizedBox(height: 10),
            Text(status.errorMessage!),
          ],
        ],
      ),
    );
  }
}

class _TodayDataStatusSection extends StatelessWidget {
  const _TodayDataStatusSection({required this.status});

  final EtfOperationsStatus status;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: '今日資料狀態',
      subtitle:
          '彙整 local history、intraday NAV、CSV export 與 daily cycle 狀態；僅描述資料狀態，非買賣建議。',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              RiskChip(label: status.backendConnectionLabel),
              RiskChip(label: 'operations ${status.sourceStatusLabel}'),
              RiskChip(label: 'holdings ${status.holdingsHistoryStatus}'),
              RiskChip(label: 'intraday ${status.intradayHistoryStatus}'),
              RiskChip(
                  label:
                      'export ${status.exportAvailable ? 'ready' : 'empty'}'),
              RiskChip(
                  label:
                      'backup ${status.backupAvailable ? 'ready' : 'empty'}'),
              RiskChip(
                  label:
                      'report ${status.reportAvailable ? 'ready' : 'empty'}'),
              RiskChip(label: 'dailyCycle ${status.dailyCycleStatus}'),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 860;
              final isCompact = constraints.maxWidth < 520;
              return GridView.count(
                crossAxisCount: isCompact ? 1 : (isWide ? 4 : 2),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: isCompact ? 2.45 : (isWide ? 1.18 : 1.0),
                children: [
                  MetricTile(
                    label: 'backend',
                    value: status.backendConnectionLabel,
                    caption: status.backendConnectionCaption,
                    icon: Icons.cloud_sync_outlined,
                  ),
                  MetricTile(
                    label: 'holdings 更新',
                    value: status.latestHoldingTradeDate == null
                        ? '尚無'
                        : formatTaiwanDate(status.latestHoldingTradeDate!),
                    caption: 'sourceStatus ${status.holdingsHistoryStatus}',
                    icon: Icons.inventory_outlined,
                  ),
                  MetricTile(
                    label: 'intraday NAV',
                    value: status.latestIntradayDataTime == null
                        ? '尚無'
                        : formatTimeSeconds(status.latestIntradayDataTime!),
                    caption: 'samples ${status.intradaySampleCount}',
                    icon: Icons.schedule_outlined,
                  ),
                  MetricTile(
                    label: 'history 筆數',
                    value:
                        '${status.holdingsHistoryItemCount} / ${status.intradaySampleCount}',
                    caption: 'holdings / intraday',
                    icon: Icons.storage_outlined,
                  ),
                  MetricTile(
                    label: 'CSV export',
                    value: status.exportAvailable ? 'ready' : '尚無',
                    caption: status.latestExportUpdatedAt == null
                        ? '尚未匯出'
                        : formatTaiwanDateTimeSeconds(
                            status.latestExportUpdatedAt!,
                          ),
                    icon: Icons.file_download_done_outlined,
                  ),
                  MetricTile(
                    label: 'backup',
                    value: status.backupAvailable ? 'ready' : 'empty',
                    caption: status.latestBackupUpdatedAt == null
                        ? 'no local backup'
                        : formatTaiwanDateTimeSeconds(
                            status.latestBackupUpdatedAt!,
                          ),
                    icon: Icons.backup_outlined,
                  ),
                  MetricTile(
                    label: 'daily report',
                    value: status.reportAvailable
                        ? status.reportOverallStatus
                        : 'missing',
                    caption: status.latestReportGeneratedAt == null
                        ? '尚無日報'
                        : formatTaiwanDateTimeSeconds(
                            status.latestReportGeneratedAt!,
                          ),
                    icon: Icons.description_outlined,
                  ),
                  MetricTile(
                    label: 'daily cycle',
                    value: status.dailyCycleStatus,
                    caption: status.dailyCycleFinishedAt == null
                        ? '尚未執行 daily cycle'
                        : formatTaiwanDateTimeSeconds(
                            status.dailyCycleFinishedAt!,
                          ),
                    icon: Icons.task_alt_outlined,
                  ),
                  MetricTile(
                    label: 'env',
                    value: status.envReady ? 'ready' : 'missing',
                    caption: status.missingEnvKeys.isEmpty
                        ? 'required keys ready'
                        : status.missingEnvKeys.join(', '),
                    icon: Icons.settings_outlined,
                  ),
                  MetricTile(
                    label: 'fallback',
                    value: status.yuantaIntradayNavConfigured
                        ? 'yuanta ready'
                        : 'yuanta empty',
                    caption: status.optionalMissingEnvKeys.isEmpty
                        ? 'optional fallback configured'
                        : status.optionalMissingEnvKeys.join(', '),
                    icon: Icons.settings_backup_restore_outlined,
                  ),
                  MetricTile(
                    label: '資料目錄',
                    value: status.dataDirectoriesReady ? 'ready' : 'check',
                    caption: 'data + exports + backups',
                    icon: Icons.folder_outlined,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          _OperationGuidanceList(lines: status.operationGuidanceLines),
          if (status.dailyCycleWarningCount > 0 ||
              status.dailyCycleFailureCount > 0 ||
              status.reportWarningCount > 0 ||
              status.reportFailureCount > 0) ...[
            const SizedBox(height: 10),
            Text(
              'daily cycle warnings ${status.dailyCycleWarningCount}, failures ${status.dailyCycleFailureCount}; report warnings ${status.reportWarningCount}, failures ${status.reportFailureCount}',
            ),
          ],
        ],
      ),
    );
  }
}

class _OperationGuidanceList extends StatelessWidget {
  const _OperationGuidanceList({required this.lines});

  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color:
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '下一步操作提示',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            for (final line in lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(Icons.chevron_right, size: 18),
                    ),
                    const SizedBox(width: 6),
                    Expanded(child: Text(line)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CommandLine extends StatelessWidget {
  const _CommandLine({
    required this.label,
    required this.command,
  });

  final String label;
  final String command;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final labelText = Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w800,
              ),
            );
            final commandText = SelectableText(
              command,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
              ),
            );

            if (constraints.maxWidth < 420) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  labelText,
                  const SizedBox(height: 6),
                  commandText,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 116, child: labelText),
                Expanded(child: commandText),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PremiumDiscountStatusSection extends StatelessWidget {
  const _PremiumDiscountStatusSection({required this.nav});

  final EtfIntradayNav? nav;

  @override
  Widget build(BuildContext context) {
    final assessment = nav?.premiumDiscountAssessment ??
        PremiumDiscountAssessment.evaluate(
          premiumDiscountPct: null,
          sourceStatus: EtfDataStatus.error,
          isStale: false,
        );
    final theme = Theme.of(context);
    final color = _premiumDiscountColor(theme.colorScheme, assessment.level);
    final background = Color.alphaBlend(
      color.withValues(alpha: 0.10),
      theme.colorScheme.surface,
    );

    return SectionCard(
      title: '折溢價狀態',
      subtitle: '依盤中預估淨值資料判讀價格偏離；這是狀態提示，非買賣建議。',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.38)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                _premiumDiscountIcon(assessment.level),
                color: color,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          formatSignedNullablePercent(
                            assessment.premiumDiscountPct,
                          ),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: color,
                          ),
                        ),
                        RiskChip(label: assessment.label),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      assessment.description,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        RiskChip(
                          label:
                              'sourceStatus ${nav?.status.label ?? 'unavailable'}',
                        ),
                        RiskChip(
                          label:
                              'sourceContract ${nav?.sourceContract ?? 'unavailable'}',
                        ),
                      ],
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

class _IntradayNavHistorySection extends StatelessWidget {
  const _IntradayNavHistorySection({required this.history});

  final EtfIntradayNavHistorySummary history;

  @override
  Widget build(BuildContext context) {
    if (!history.hasData) {
      return SectionCard(
        title: '盤中折溢價歷史',
        subtitle:
            'backend 只保存 official intraday NAV；mock 或 unavailable 不會被標示為 official。',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                RiskChip(label: 'sourceStatus ${history.sourceStatusLabel}'),
                RiskChip(label: 'intradayHistory ${history.status.label}'),
              ],
            ),
            const SizedBox(height: 10),
            const Text('尚無盤中折溢價歷史'),
            if (history.errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(history.errorMessage!),
            ],
          ],
        ),
      );
    }

    return SectionCard(
      title: '盤中折溢價歷史',
      subtitle: '顯示今日 intraday NAV 保存紀錄的最高、最低與平均折溢價。這是資料觀察，不是交易訊號。',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              RiskChip(label: 'sourceStatus ${history.sourceStatusLabel}'),
              RiskChip(label: 'intradayHistory ${history.status.label}'),
              RiskChip(label: 'samples ${history.sampleCount}'),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 720;
              return GridView.count(
                crossAxisCount: isWide ? 4 : 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: isWide ? 1.05 : 1.0,
                children: [
                  MetricTile(
                    label: '最高溢價',
                    value: formatSignedNullablePercent(
                      history.highestPremiumDiscountPct,
                    ),
                    caption: 'intraday max',
                    icon: Icons.north_east_outlined,
                  ),
                  MetricTile(
                    label: '最低折價',
                    value: formatSignedNullablePercent(
                      history.lowestPremiumDiscountPct,
                    ),
                    caption: 'intraday min',
                    icon: Icons.south_east_outlined,
                  ),
                  MetricTile(
                    label: '平均折溢價',
                    value: formatSignedNullablePercent(
                      history.averagePremiumDiscountPct,
                    ),
                    caption: 'intraday average',
                    icon: Icons.timeline_outlined,
                  ),
                  MetricTile(
                    label: '最後紀錄',
                    value: history.lastDataTime == null
                        ? 'unavailable'
                        : formatTimeSeconds(history.lastDataTime!),
                    caption: history.date == null
                        ? 'dataDate unavailable'
                        : formatTaiwanDate(history.date!),
                    icon: Icons.schedule_outlined,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          _IntradayPremiumTrend(points: history.points),
          const SizedBox(height: 12),
          _HorizontalTable(
            columns: const ['時間', '市價', '預估淨值', '折溢價', 'sourceContract'],
            rows: [
              for (final point in history.points.take(12))
                [
                  formatTimeSeconds(point.dataTime),
                  _price(point.marketPrice),
                  _price(point.estimatedNav),
                  formatSignedNullablePercent(point.premiumDiscountPct),
                  point.sourceContract ?? 'unavailable',
                ],
            ],
          ),
        ],
      ),
    );
  }
}

class _IntradayPremiumTrend extends StatelessWidget {
  const _IntradayPremiumTrend({required this.points});

  final List<EtfIntradayNavHistoryPoint> points;

  @override
  Widget build(BuildContext context) {
    final ordered = points
        .where((point) => point.premiumDiscountPct != null)
        .take(120)
        .toList()
        .reversed
        .toList();
    if (ordered.length < 2) {
      return _TrendFrame(
        child: Text(
          '需要至少 2 筆 official intraday NAV history，才會顯示折溢價走勢。',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    final spots = [
      for (var index = 0; index < ordered.length; index += 1)
        FlSpot(index.toDouble(), ordered[index].premiumDiscountPct!),
    ];
    final minY = _premiumTrendMinY(spots);
    final maxY = _premiumTrendMaxY(spots);
    final interval = _premiumTrendInterval(minY, maxY);
    final labelInterval = (ordered.length / 4).ceilToDouble().clamp(1, 60);

    return _TrendFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('折溢價走勢', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(
            '依 official intraday NAV history 顯示 premiumDiscountPct 盤中變化。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (ordered.length - 1).toDouble(),
                minY: minY,
                maxY: maxY,
                clipData: const FlClipData.all(),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: interval,
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: 0,
                      color: colorScheme.outline,
                      strokeWidth: 1,
                      dashArray: [4, 4],
                    ),
                  ],
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 48,
                      interval: interval,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toStringAsFixed(1)}%',
                          style: Theme.of(context).textTheme.labelSmall,
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 34,
                      interval: labelInterval.toDouble(),
                      getTitlesWidget: (value, meta) {
                        final index = value.round();
                        if (index < 0 || index >= ordered.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            _hourMinuteLabel(ordered[index].dataTime),
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    color: colorScheme.primary,
                    barWidth: 2.5,
                    isCurved: false,
                    dotData: FlDotData(show: spots.length <= 12),
                    belowBarData: BarAreaData(
                      show: true,
                      color: colorScheme.primary.withValues(alpha: 0.08),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          _LegendDot(
            color: colorScheme.primary,
            label: '折溢價 %',
          ),
        ],
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({required this.profile});

  final LeveragedEtfProfile profile;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: '官方基本資訊',
      subtitle: '來源：元大投信 YuantaETFs 00631L Basic_information 頁。',
      child: Column(
        children: [
          _InfoRow(label: '基金名稱', value: profile.fundName),
          _InfoRow(label: '基金簡稱', value: profile.shortName),
          _InfoRow(label: '追蹤指數', value: profile.trackingIndex),
          _InfoRow(
              label: '成立日', value: formatTaiwanDate(profile.inceptionDate)),
          _InfoRow(label: '上市日', value: formatTaiwanDate(profile.listingDate)),
          _InfoRow(
              label: '是否配息', value: profile.distributesIncome ? 'YES' : 'NO'),
          _InfoRow(label: '風險等級', value: profile.riskLevel),
          _InfoRow(
            label: '管理費',
            value: formatPercent(profile.managementFeePercent, decimals: 2),
          ),
          _InfoRow(
            label: '保管費',
            value: formatPercent(profile.custodianFeePercent, decimals: 2),
          ),
          _InfoRow(label: '操作目標', value: profile.leverageObjective),
          _InfoRow(label: '曝險政策', value: profile.exposurePolicy),
          _InfoRow(label: '主要交易方式', value: profile.primaryTradingMethod),
        ],
      ),
    );
  }
}

class _AssetAllocationSection extends StatelessWidget {
  const _AssetAllocationSection({required this.snapshot});

  final EtfDailyHoldingSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final rows = [
      _AssetRowData(
        label: '股票資產',
        amount: snapshot.assetSummary.stock,
        weightPct: snapshot.assetWeightPct(EtfAssetClass.stock),
        maxPct: 100,
      ),
      _AssetRowData(
        label: '期貨資產',
        amount: snapshot.assetSummary.futures,
        weightPct: snapshot.assetWeightPct(EtfAssetClass.futures),
        maxPct: 220,
      ),
      _AssetRowData(
        label: 'ETF',
        amount: snapshot.assetSummary.etf,
        weightPct: snapshot.assetWeightPct(EtfAssetClass.etf),
        maxPct: 100,
      ),
      _AssetRowData(
        label: '債券',
        amount: snapshot.assetSummary.bond,
        weightPct: snapshot.assetWeightPct(EtfAssetClass.bond),
        maxPct: 100,
      ),
      _AssetRowData(
        label: '現金與保證金',
        amount: snapshot.cashAndMarginValue,
        weightPct: snapshot.cashAndMarginWeightPct,
        maxPct: 100,
      ),
      _AssetRowData(
        label: '其他應收應付',
        amount: snapshot.otherReceivablesPayablesValue,
        weightPct: snapshot.otherReceivablesPayablesWeightPct,
        maxPct: 100,
      ),
    ];

    return SectionCard(
      title: '內容物比例與資產結構',
      subtitle: '官方每日資料；期貨曝險可高於 100%，進度條僅作視覺比例參考。',
      child: Column(
        children: [
          ...rows.map((row) => _AssetAllocationRow(row: row)),
          const SizedBox(height: 12),
          _HorizontalTable(
            columns: const ['項目', '金額', '佔基金淨資產比例 %'],
            rows: [
              for (final row in rows)
                [
                  row.label,
                  formatNtdAmount(row.amount),
                  formatNullablePercent(row.weightPct),
                ],
            ],
          ),
        ],
      ),
    );
  }
}

class _HoldingsHistorySection extends StatelessWidget {
  const _HoldingsHistorySection({required this.history});

  final EtfHoldingsHistory history;

  @override
  Widget build(BuildContext context) {
    if (!history.hasData) {
      return SectionCard(
        title: '每日內容物歷史',
        subtitle:
            '由 backend 保存 Yuanta 00631L ratio official snapshot，依 tradeDate 去重。',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                RiskChip(label: 'sourceStatus ${history.sourceStatusLabel}'),
                RiskChip(label: 'history ${history.status.label}'),
              ],
            ),
            const SizedBox(height: 10),
            const Text('尚無歷史紀錄'),
            if (history.errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(history.errorMessage!),
            ],
          ],
        ),
      );
    }

    return SectionCard(
      title: '每日內容物歷史',
      subtitle: '最近每日 official holdings summary。官方內容物是每日快照，不是盤中即時內容物。',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              RiskChip(label: 'sourceStatus ${history.sourceStatusLabel}'),
              RiskChip(label: 'history ${history.status.label}'),
              RiskChip(label: 'rows ${history.points.length}'),
            ],
          ),
          const SizedBox(height: 12),
          _HoldingsHistorySummaryCards(summary: history.trendSummary()),
          const SizedBox(height: 12),
          _HoldingsHistoryChangeTable(summary: history.trendSummary()),
          const SizedBox(height: 12),
          _HoldingsHistoryTrend(points: history.points),
          const SizedBox(height: 12),
          _HorizontalTable(
            columns: const [
              '日期',
              'TX權重',
              '台積電權重',
              '股票資產%',
              '期貨資產%',
              '現金與保證金%',
              'NAV',
              '發行單位數',
            ],
            rows: [
              for (final point in history.points.take(30))
                [
                  formatTaiwanDate(point.tradeDate),
                  formatNullablePercent(point.txWeightPct),
                  formatNullablePercent(point.tsmcWeightPct),
                  formatNullablePercent(point.stockExposurePct),
                  formatNullablePercent(point.futuresExposurePct),
                  formatNullablePercent(point.cashAndMarginPct),
                  point.navPerUnit.toStringAsFixed(2),
                  formatInteger(point.outstandingUnits),
                ],
            ],
          ),
        ],
      ),
    );
  }
}

class _HoldingsHistorySummaryCards extends StatelessWidget {
  const _HoldingsHistorySummaryCards({required this.summary});

  final EtfHoldingsHistoryTrendSummary summary;

  @override
  Widget build(BuildContext context) {
    final latest = summary.latest;
    final previous = summary.previous;
    final recentCount = summary.recentSeven.length;
    final subtitle = previous == null
        ? 'day-over-day n/a'
        : 'day-over-day ${formatTaiwanDate(previous.tradeDate)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('最近 7 日摘要', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 860;
            final isCompact = constraints.maxWidth < 520;
            return GridView.count(
              crossAxisCount: isCompact ? 1 : (isWide ? 4 : 2),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: isCompact ? 2.45 : (isWide ? 1.16 : 1.0),
              children: [
                MetricTile(
                  label: '最近筆數',
                  value: recentCount.toString(),
                  caption: latest == null
                      ? '尚無 history'
                      : formatTaiwanDate(latest.tradeDate),
                  icon: Icons.calendar_view_week_outlined,
                ),
                MetricTile(
                  label: 'TX 權重',
                  value: latest == null
                      ? 'n/a'
                      : formatNullablePercent(latest.txWeightPct),
                  caption: subtitle,
                  icon: Icons.show_chart_outlined,
                ),
                MetricTile(
                  label: '台積電權重',
                  value: latest == null
                      ? 'n/a'
                      : formatNullablePercent(latest.tsmcWeightPct),
                  caption: subtitle,
                  icon: Icons.memory_outlined,
                ),
                MetricTile(
                  label: '現金/保證金',
                  value: latest == null
                      ? 'n/a'
                      : formatNullablePercent(latest.cashAndMarginPct),
                  caption: subtitle,
                  icon: Icons.account_balance_wallet_outlined,
                ),
                MetricTile(
                  label: '股票資產 %',
                  value: latest == null
                      ? 'n/a'
                      : formatNullablePercent(latest.stockExposurePct),
                  caption: subtitle,
                  icon: Icons.pie_chart_outline,
                ),
                MetricTile(
                  label: '期貨資產 %',
                  value: latest == null
                      ? 'n/a'
                      : formatNullablePercent(latest.futuresExposurePct),
                  caption: subtitle,
                  icon: Icons.stacked_line_chart_outlined,
                ),
                MetricTile(
                  label: 'NAV',
                  value: latest == null
                      ? 'n/a'
                      : latest.navPerUnit.toStringAsFixed(2),
                  caption: subtitle,
                  icon: Icons.paid_outlined,
                ),
                MetricTile(
                  label: '發行單位數',
                  value: latest == null
                      ? 'n/a'
                      : formatInteger(latest.outstandingUnits),
                  caption: subtitle,
                  icon: Icons.confirmation_number_outlined,
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _HoldingsHistoryChangeTable extends StatelessWidget {
  const _HoldingsHistoryChangeTable({required this.summary});

  final EtfHoldingsHistoryTrendSummary summary;

  @override
  Widget build(BuildContext context) {
    if (summary.changeLines.isEmpty) {
      return const Text('尚無變化資料');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('變化摘要', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        _HorizontalTable(
          columns: const ['項目', '最新', '日變化', '首末變化'],
          rows: [
            for (final line in summary.changeLines)
              [
                _historyMetricLabel(line.key),
                _historyMetricValue(line),
                _historyMetricDelta(line),
                _historyMetricRangeDelta(line),
              ],
          ],
        ),
      ],
    );
  }
}

class _HoldingsHistoryTrend extends StatelessWidget {
  const _HoldingsHistoryTrend({required this.points});

  final List<EtfHoldingsHistoryPoint> points;

  @override
  Widget build(BuildContext context) {
    final ordered = points.take(30).toList().reversed.toList();
    final colorScheme = Theme.of(context).colorScheme;

    if (ordered.length < 2) {
      return _TrendFrame(
        child: Text(
          '需要至少 2 筆 official holdings history，才會顯示權重趨勢。',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    final txColor = colorScheme.primary;
    final tsmcColor = colorScheme.tertiary;
    final cashColor = Colors.teal.shade600;
    final maxY = _trendMaxY(ordered);
    final labelInterval = (ordered.length / 4).ceilToDouble().clamp(1, 30);

    return _TrendFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('權重趨勢', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(
            '依 official holdings history 顯示 TX、台積電、現金與保證金比例變化。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (ordered.length - 1).toDouble(),
                minY: 0,
                maxY: maxY,
                clipData: const FlClipData.all(),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: _trendInterval(maxY),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      interval: _trendInterval(maxY),
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toStringAsFixed(0)}%',
                          style: Theme.of(context).textTheme.labelSmall,
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 34,
                      interval: labelInterval.toDouble(),
                      getTitlesWidget: (value, meta) {
                        final index = value.round();
                        if (index < 0 || index >= ordered.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            _monthDayLabel(ordered[index].tradeDate),
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  _trendLine(
                    color: txColor,
                    spots: _spots(ordered, (point) => point.txWeightPct),
                  ),
                  _trendLine(
                    color: tsmcColor,
                    spots: _spots(ordered, (point) => point.tsmcWeightPct),
                  ),
                  _trendLine(
                    color: cashColor,
                    spots: _spots(ordered, (point) => point.cashAndMarginPct),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _LegendDot(color: txColor, label: 'TX 權重'),
              _LegendDot(color: tsmcColor, label: '台積電權重'),
              _LegendDot(color: cashColor, label: '現金與保證金'),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrendFrame extends StatelessWidget {
  const _TrendFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: child,
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}

class _HoldingsChangeNoticeSection extends StatelessWidget {
  const _HoldingsChangeNoticeSection({required this.data});

  final Etf00631LLabData data;

  @override
  Widget build(BuildContext context) {
    final assessment = data.holdingsChangeAssessment;

    return SectionCard(
      title: '內容物變化提醒',
      subtitle:
          '依最近 official holdings history 比較 TX、台積電、現金保證金與曝險比例。這是資料狀態提醒，非買賣建議。',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              RiskChip(label: 'changeStatus ${assessment.statusLabel}'),
              RiskChip(label: 'history ${data.holdingsHistory.status.label}'),
            ],
          ),
          const SizedBox(height: 12),
          for (final notice in assessment.notices)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _HoldingChangeNoticeTile(notice: notice),
            ),
        ],
      ),
    );
  }
}

class _HoldingChangeNoticeTile extends StatelessWidget {
  const _HoldingChangeNoticeTile({required this.notice});

  final HoldingChangeNotice notice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _holdingNoticeColor(theme.colorScheme, notice.level);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          color.withValues(alpha: 0.08),
          theme.colorScheme.surface,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(_holdingNoticeIcon(notice.level), color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notice.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    notice.message,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
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

class _IntradaySection extends StatelessWidget {
  const _IntradaySection({required this.nav});

  final EtfIntradayNav? nav;

  @override
  Widget build(BuildContext context) {
    final current = nav;
    if (current == null) {
      return const SectionCard(
        title: '盤中估算資料',
        subtitle: 'TWSE ETF 申贖資訊及即時淨值揭露格式。',
        child: Column(
          children: [
            _InfoRow(label: 'sourceStatus', value: 'unavailable'),
            _InfoRow(label: 'sourceContract', value: 'unavailable'),
            Text('即時資料暫不可用；頁面保留官方每日內容物與 mock/fallback 狀態。'),
          ],
        ),
      );
    }

    return SectionCard(
      title: '盤中估算資料',
      subtitle: 'TWSE ETF 申贖資訊及即時淨值揭露格式；依 userDelay 更新。',
      child: Column(
        children: [
          _InfoRow(label: 'ETF 代號', value: current.symbol),
          _InfoRow(label: 'ETF 名稱', value: current.name),
          _InfoRow(label: '成交價', value: _price(current.marketPrice)),
          _InfoRow(label: '投信預估淨值', value: _price(current.estimatedNav)),
          _InfoRow(
            label: '預估折溢價幅度',
            value: formatSignedNullablePercent(
              current.estimatedPremiumDiscountPct,
            ),
          ),
          _InfoRow(
            label: '前一營業日淨值',
            value: _price(current.previousBusinessDayNav),
          ),
          _InfoRow(
            label: '資料日期',
            value: current.dataDate == null
                ? 'unavailable'
                : formatTaiwanDate(current.dataDate!),
          ),
          _InfoRow(
            label: '資料時間',
            value: current.dataTime == null
                ? 'unavailable'
                : formatTimeSeconds(current.dataTime!),
          ),
          _InfoRow(
            label: 'sourceContract',
            value: current.sourceContract ?? 'unavailable',
          ),
          _InfoRow(label: '更新間隔', value: '${current.userDelayMs} ms'),
          _InfoRow(label: '資料狀態', value: current.status.label),
        ],
      ),
    );
  }
}

class _FuturesQuoteSection extends StatelessWidget {
  const _FuturesQuoteSection({required this.quote});

  final FuturesQuote quote;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'TX 台指期觀察',
      subtitle: '目前以 repository interface + mock/fallback 呈現；缺值時不計算。',
      child: Column(
        children: [
          _InfoRow(label: '商品代碼', value: quote.symbol),
          _InfoRow(label: '契約月份', value: quote.contractMonth),
          _InfoRow(label: 'TX 近月價格', value: _plainNumber(quote.txPrice)),
          _InfoRow(label: '加權指數', value: _plainNumber(quote.weightedIndex)),
          _InfoRow(
            label: 'TX 契約價值',
            value: formatNtdAmount(quote.txContractValue),
          ),
          _InfoRow(
            label: '期現價差',
            value: _plainNumber(quote.futuresBasisPoints),
          ),
          _InfoRow(
            label: '期現價差 %',
            value: formatSignedNullablePercent(quote.futuresBasisPct),
          ),
          _InfoRow(
            label: '夜盤變動',
            value: formatSignedNullablePercent(quote.nightSessionChange),
          ),
          _InfoRow(label: '資料狀態', value: quote.status.label),
        ],
      ),
    );
  }
}

class _DetailsTables extends StatelessWidget {
  const _DetailsTables({required this.snapshot});

  final EtfDailyHoldingSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SectionCard(
          title: '股票明細表',
          subtitle: '官方每日資料，不代表盤中即時持股變動。',
          child: _HorizontalTable(
            columns: const ['商品代碼', '商品名稱', '數量', '權重 %'],
            rows: [
              for (final holding in snapshot.stockHoldings)
                [
                  holding.code,
                  holding.name,
                  formatInteger(holding.quantity),
                  formatNullablePercent(holding.weightPct),
                ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: '期貨明細表',
          subtitle: '官方每日資料，不代表盤中即時期貨部位變動。',
          child: _HorizontalTable(
            columns: const ['商品代碼', '商品名稱', '數量', '權重 %', '商品年月'],
            rows: [
              for (final holding in snapshot.futuresHoldings)
                [
                  holding.code,
                  holding.name,
                  formatInteger(holding.quantity),
                  formatNullablePercent(holding.weightPct),
                  holding.contractMonth,
                ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: '現金 / 保證金明細表',
          subtitle: '以基金淨資產價值計算佔比；應付項目可為負值。',
          child: _HorizontalTable(
            columns: const ['項目', '金額', '佔基金淨資產比例 %'],
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

class _AnalysisSection extends StatelessWidget {
  const _AnalysisSection({required this.analysis});

  final EtfAnalysisSummary analysis;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: '基礎分析摘要',
      subtitle: '自動整理曝險、資料時效與折溢價狀態，不提供買賣建議。',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final line in analysis.lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      line,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _AssetAllocationRow extends StatelessWidget {
  const _AssetAllocationRow({required this.row});

  final _AssetRowData row;

  @override
  Widget build(BuildContext context) {
    final value = row.maxPct == 0 ? 0.0 : (row.weightPct.abs() / row.maxPct);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(width: 112, child: Text(row.label)),
          Expanded(
            child: LinearProgressIndicator(
              value: value.clamp(0, 1).toDouble(),
              minHeight: 8,
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 76,
            child: Text(
              formatNullablePercent(row.weightPct),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
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
      return const Text('目前沒有可顯示的明細。');
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: columns.length * 118),
        child: DataTable(
          headingRowHeight: 40,
          dataRowMinHeight: 42,
          dataRowMaxHeight: 56,
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
                        child: Text(cell, overflow: TextOverflow.ellipsis),
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 128,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

LineChartBarData _trendLine({
  required Color color,
  required List<FlSpot> spots,
}) {
  return LineChartBarData(
    spots: spots,
    color: color,
    barWidth: 2.5,
    isCurved: false,
    dotData: FlDotData(show: spots.length <= 8),
    belowBarData: BarAreaData(show: false),
  );
}

List<FlSpot> _spots(
  List<EtfHoldingsHistoryPoint> points,
  double Function(EtfHoldingsHistoryPoint point) valueOf,
) {
  return [
    for (var index = 0; index < points.length; index += 1)
      FlSpot(index.toDouble(), valueOf(points[index])),
  ];
}

double _trendMaxY(List<EtfHoldingsHistoryPoint> points) {
  var maxValue = 0.0;
  for (final point in points) {
    for (final value in [
      point.txWeightPct,
      point.tsmcWeightPct,
      point.cashAndMarginPct,
    ]) {
      if (value > maxValue) {
        maxValue = value;
      }
    }
  }
  if (maxValue <= 0) {
    return 10;
  }
  return ((maxValue / 20).ceil() * 20).toDouble();
}

double _trendInterval(double maxY) {
  if (maxY <= 40) {
    return 10;
  }
  if (maxY <= 100) {
    return 20;
  }
  return 40;
}

String _monthDayLabel(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$month/$day';
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

double _premiumTrendMinY(List<FlSpot> spots) {
  var minValue = 0.0;
  var maxValue = 0.0;
  for (final spot in spots) {
    if (spot.y < minValue) {
      minValue = spot.y;
    }
    if (spot.y > maxValue) {
      maxValue = spot.y;
    }
  }
  final padding = _premiumPadding(minValue, maxValue);
  return minValue - padding;
}

double _premiumTrendMaxY(List<FlSpot> spots) {
  var minValue = 0.0;
  var maxValue = 0.0;
  for (final spot in spots) {
    if (spot.y < minValue) {
      minValue = spot.y;
    }
    if (spot.y > maxValue) {
      maxValue = spot.y;
    }
  }
  final padding = _premiumPadding(minValue, maxValue);
  return maxValue + padding;
}

double _premiumTrendInterval(double minY, double maxY) {
  final range = maxY - minY;
  if (range <= 1) {
    return 0.25;
  }
  if (range <= 2) {
    return 0.5;
  }
  return 1;
}

double _premiumPadding(double minValue, double maxValue) {
  final range = maxValue - minValue;
  if (range == 0) {
    return 0.5;
  }
  return range * 0.2;
}

String _hourMinuteLabel(DateTime date) {
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

class _ErrorLabState extends StatelessWidget {
  const _ErrorLabState({
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
        EmptyState(
          icon: Icons.error_outline,
          title: '00631L 資料載入失敗',
          message: '即時資料暫不可用：$error',
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
            label: const Text('重新整理'),
          ),
        ),
      ],
    );
  }
}

class _AssetRowData {
  const _AssetRowData({
    required this.label,
    required this.amount,
    required this.weightPct,
    required this.maxPct,
  });

  final String label;
  final double amount;
  final double weightPct;
  final double maxPct;
}

String _price(num? value) {
  if (value == null) {
    return 'unavailable';
  }
  return value.toStringAsFixed(2);
}

String _plainNumber(num? value) {
  if (value == null) {
    return 'unavailable';
  }
  return formatNumber(value, decimals: 2);
}

Color _premiumDiscountColor(
  ColorScheme colorScheme,
  PremiumDiscountLevel level,
) {
  switch (level) {
    case PremiumDiscountLevel.normal:
      return colorScheme.primary;
    case PremiumDiscountLevel.watch:
      return colorScheme.secondary;
    case PremiumDiscountLevel.elevated:
      return colorScheme.tertiary;
    case PremiumDiscountLevel.extreme:
      return colorScheme.error;
    case PremiumDiscountLevel.unavailable:
    case PremiumDiscountLevel.stale:
      return colorScheme.onSurfaceVariant;
  }
}

IconData _premiumDiscountIcon(PremiumDiscountLevel level) {
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

Color _holdingNoticeColor(
  ColorScheme colorScheme,
  HoldingChangeNoticeLevel level,
) {
  switch (level) {
    case HoldingChangeNoticeLevel.normal:
      return colorScheme.primary;
    case HoldingChangeNoticeLevel.watch:
      return colorScheme.secondary;
    case HoldingChangeNoticeLevel.elevated:
      return colorScheme.tertiary;
    case HoldingChangeNoticeLevel.stale:
    case HoldingChangeNoticeLevel.unavailable:
      return colorScheme.onSurfaceVariant;
  }
}

IconData _holdingNoticeIcon(HoldingChangeNoticeLevel level) {
  switch (level) {
    case HoldingChangeNoticeLevel.normal:
      return Icons.check_circle_outline;
    case HoldingChangeNoticeLevel.watch:
      return Icons.manage_search_outlined;
    case HoldingChangeNoticeLevel.elevated:
      return Icons.priority_high_outlined;
    case HoldingChangeNoticeLevel.stale:
      return Icons.schedule_outlined;
    case HoldingChangeNoticeLevel.unavailable:
      return Icons.history_toggle_off_outlined;
  }
}

Color _statusSummaryColor(
  ColorScheme colorScheme,
  EtfStatusSummaryLevel level,
) {
  switch (level) {
    case EtfStatusSummaryLevel.normal:
      return colorScheme.primary;
    case EtfStatusSummaryLevel.watch:
      return colorScheme.secondary;
    case EtfStatusSummaryLevel.elevated:
      return colorScheme.tertiary;
    case EtfStatusSummaryLevel.unavailable:
    case EtfStatusSummaryLevel.stale:
      return colorScheme.onSurfaceVariant;
    case EtfStatusSummaryLevel.error:
      return colorScheme.error;
  }
}

IconData _statusSummaryIcon(EtfStatusSummaryLevel level) {
  switch (level) {
    case EtfStatusSummaryLevel.normal:
      return Icons.check_circle_outline;
    case EtfStatusSummaryLevel.watch:
      return Icons.manage_search_outlined;
    case EtfStatusSummaryLevel.elevated:
      return Icons.priority_high_outlined;
    case EtfStatusSummaryLevel.unavailable:
      return Icons.cloud_off_outlined;
    case EtfStatusSummaryLevel.stale:
      return Icons.schedule_outlined;
    case EtfStatusSummaryLevel.error:
      return Icons.error_outline;
  }
}
