import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/journal_entry.dart';
import '../../models/risk_alert.dart';
import '../../models/stock.dart';
import '../../repositories/repository_providers.dart';
import '../../shared/utils/formatters.dart';
import '../../shared/widgets/metric_tile.dart';
import '../../shared/widgets/risk_chip.dart';
import '../../shared/widgets/section_card.dart';
import '../../shared/widgets/stock_list_tile.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watchlist = ref.watch(watchlistProvider);
    final journalEntries = ref.watch(journalControllerProvider);

    return SafeArea(
      child: watchlist.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('資料載入失敗：$error')),
        data: (stocks) => _DashboardContent(
          stocks: stocks,
          journalEntries: journalEntries,
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.stocks,
    required this.journalEntries,
  });

  final List<Stock> stocks;
  final List<JournalEntry> journalEntries;

  @override
  Widget build(BuildContext context) {
    final riskCount =
        stocks.fold<int>(0, (sum, stock) => sum + stock.riskAlerts.length);
    final latestUpdate = stocks
        .map((stock) => stock.lastUpdated)
        .reduce((value, element) => value.isAfter(element) ? value : element);
    final highRiskCount = stocks
        .where((stock) => stock.riskAlerts
            .any((alert) => alert.severity == RiskSeverity.high))
        .length;
    final attentionList = stocks
        .where((stock) =>
            stock.riskAlerts.any((alert) => alert.severity != RiskSeverity.low))
        .toList()
      ..sort((a, b) => b.riskAlerts.length.compareTo(a.riskAlerts.length));
    final highValuationList = stocks
        .where((stock) =>
            stock.valuation.rangeLabel.contains('偏高') ||
            stock.valuation.pePercentile5y >= 70 ||
            stock.valuation.pbPercentile5y >= 70)
        .toList()
      ..sort((a, b) =>
          b.valuation.pePercentile5y.compareTo(a.valuation.pePercentile5y));
    final revenueStrengthList = stocks
        .where((stock) =>
            stock.metric.revenueYoy >= 7 &&
            stock.financialTrend.revenueYoyLast12Months.last >
                stock.financialTrend.revenueYoyLast12Months.first)
        .toList()
      ..sort((a, b) => b.metric.revenueYoy.compareTo(a.metric.revenueYoy));
    final elevatedRiskList = stocks
        .where((stock) =>
            stock.riskAlerts
                .any((alert) => alert.severity == RiskSeverity.high) ||
            stock.metric.trendScore < 60 ||
            stock.metric.aboveMa200 == false)
        .toList()
      ..sort((a, b) => a.metric.trendScore.compareTo(b.metric.trendScore));
    final industryCounts = <String, int>{};
    for (final stock in stocks) {
      industryCounts.update(stock.industry, (value) => value + 1,
          ifAbsent: () => 1);
    }
    final recentEntries = journalEntries.take(3).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _HeroHeader(
          stockCount: stocks.length,
          latestUpdate: latestUpdate,
          highRiskCount: highRiskCount,
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 760;
            return GridView.count(
              crossAxisCount: isWide ? 4 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: isWide ? 1.45 : 1.08,
              children: [
                MetricTile(
                  label: '自選股總數',
                  value: '${stocks.length}',
                  caption: '模擬觀察名單',
                  icon: Icons.view_list_outlined,
                ),
                MetricTile(
                  label: '風險提醒',
                  value: '$riskCount',
                  caption: '含高風險 $highRiskCount 項',
                  icon: Icons.warning_amber_outlined,
                ),
                MetricTile(
                  label: '估值偏高',
                  value: '${highValuationList.length}',
                  caption: '依歷史分位整理',
                  icon: Icons.price_check_outlined,
                ),
                MetricTile(
                  label: '營收轉強',
                  value: '${revenueStrengthList.length}',
                  caption: '近月 YoY 改善',
                  icon: Icons.trending_up_outlined,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: '今日研究摘要',
          subtitle: '以下整理以本地模擬資料產生，作為研究工作流展示。',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SummaryLine(
                icon: Icons.fact_check_outlined,
                text:
                    '目前觀察 ${stocks.length} 檔台股樣本，最高體質分數為 ${stocks.map((stock) => stock.metric.qualityScore).reduce((a, b) => a > b ? a : b)}。',
              ),
              const SizedBox(height: 10),
              const _SummaryLine(
                icon: Icons.error_outline,
                text: '需要注意的觀察清單以中高風險提醒、估值分位與營收趨勢排序。',
              ),
              const SizedBox(height: 10),
              _SummaryLine(
                icon: Icons.schedule_outlined,
                text: '最近更新時間：${formatDateTime(latestUpdate)}，資料來源仍為模擬資料。',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _QuickActionsSection(),
        const SizedBox(height: 16),
        _ResearchListSection(
          title: '需要注意的觀察清單',
          subtitle: '含中高風險提醒或需要補充檢核的樣本。',
          stocks: attentionList.take(4).toList(),
          emptyText: '目前沒有中高風險提醒。',
          onTap: (stock) => context.push('/stocks/${stock.symbol}'),
        ),
        const SizedBox(height: 16),
        _ResearchListSection(
          title: '估值偏高觀察清單',
          subtitle: '依 PE / PB 歷史分位與估值狀態彙整。',
          stocks: highValuationList.take(4).toList(),
          emptyText: '目前沒有估值偏高樣本。',
          onTap: (stock) => context.push('/stocks/${stock.symbol}'),
        ),
        const SizedBox(height: 16),
        _ResearchListSection(
          title: '營收轉強觀察清單',
          subtitle: '近 12 個月營收 YoY 呈改善或維持成長的樣本。',
          stocks: revenueStrengthList.take(4).toList(),
          emptyText: '目前沒有營收轉強樣本。',
          onTap: (stock) => context.push('/stocks/${stock.symbol}'),
        ),
        const SizedBox(height: 16),
        _ResearchListSection(
          title: '風險升高觀察清單',
          subtitle: '含高風險提醒、趨勢條件偏弱或長期均線條件未符合的樣本。',
          stocks: elevatedRiskList.take(4).toList(),
          emptyText: '目前沒有風險升高樣本。',
          onTap: (stock) => context.push('/stocks/${stock.symbol}'),
        ),
        const SizedBox(height: 16),
        _IndustrySummarySection(industryCounts: industryCounts),
        const SizedBox(height: 16),
        _RecentJournalSection(entries: recentEntries),
        const SizedBox(height: 18),
        Text(
          '自選股列表',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 10),
        ...stocks.map(
          (stock) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: StockListTile(
              stock: stock,
              onTap: () => context.push('/stocks/${stock.symbol}'),
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickActionsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: '快速入口',
      subtitle: '用不同研究工具建立自己的研究流程。',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 760;
          final actions = [
            const _QuickAction(
              icon: Icons.filter_alt_outlined,
              label: '開始條件篩選',
              route: '/screener',
            ),
            const _QuickAction(
              icon: Icons.query_stats_outlined,
              label: '查看策略研究',
              route: '/backtest',
            ),
            const _QuickAction(
              icon: Icons.compare_arrows_outlined,
              label: '查看 ETF 比較',
              route: '/etfs',
            ),
            const _QuickAction(
              icon: Icons.science_outlined,
              label: '00631L 正二研究室',
              route: '/00631l-lab',
            ),
            const _QuickAction(
              icon: Icons.account_balance_wallet_outlined,
              label: '查看投資組合',
              route: '/portfolio',
            ),
            const _QuickAction(
              icon: Icons.notifications_active_outlined,
              label: '提醒中心',
              route: '/alerts',
            ),
          ];

          return GridView.count(
            crossAxisCount: isWide ? 6 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: isWide ? 1.5 : 1.45,
            children: actions,
          );
        },
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.route,
  });

  final IconData icon;
  final String label;
  final String route;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return OutlinedButton(
      onPressed: () => context.push(route),
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.all(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _IndustrySummarySection extends StatelessWidget {
  const _IndustrySummarySection({required this.industryCounts});

  final Map<String, int> industryCounts;

  @override
  Widget build(BuildContext context) {
    final total =
        industryCounts.values.fold<int>(0, (sum, value) => sum + value);
    final entries = industryCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SectionCard(
      title: '產業分布摘要',
      subtitle: '用於觀察研究樣本是否集中在少數產業。',
      child: Column(
        children: entries.map((entry) {
          final ratio = total == 0 ? 0.0 : entry.value / total;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                SizedBox(width: 132, child: Text(entry.key)),
                Expanded(
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 8,
                  ),
                ),
                const SizedBox(width: 10),
                Text('${entry.value} 檔'),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _RecentJournalSection extends StatelessWidget {
  const _RecentJournalSection({required this.entries});

  final List<JournalEntry> entries;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: '最近研究日記',
      subtitle: '研究日記目前暫存在本機 memory。',
      child: entries.isEmpty
          ? const Text('目前尚未建立研究日記，可從快速入口新增。')
          : Column(
              children: entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${entry.symbol} ${entry.stockName}',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${formatDate(entry.researchDate)} · ${entry.topic}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      RiskChip(label: entry.emotionTag.label),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.stockCount,
    required this.latestUpdate,
    required this.highRiskCount,
  });

  final int stockCount;
  final DateTime latestUpdate;
  final int highRiskCount;

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
          Text(
            '中長線股票研究助理',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '用財報、估值、趨勢與風險提醒整理研究參考，不提供方向性結論。',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              RiskChip(label: '$stockCount 檔觀察樣本'),
              RiskChip(label: '高風險提醒 $highRiskCount 項'),
              RiskChip(label: '更新 ${formatDateTime(latestUpdate)}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ),
      ],
    );
  }
}

class _ResearchListSection extends StatelessWidget {
  const _ResearchListSection({
    required this.title,
    required this.subtitle,
    required this.stocks,
    required this.emptyText,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final List<Stock> stocks;
  final String emptyText;
  final ValueChanged<Stock> onTap;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: title,
      subtitle: subtitle,
      child: stocks.isEmpty
          ? Text(emptyText)
          : Column(
              children: stocks.map((stock) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _CompactStockRow(
                    stock: stock,
                    onTap: () => onTap(stock),
                  ),
                );
              }).toList(),
            ),
    );
  }
}

class _CompactStockRow extends StatelessWidget {
  const _CompactStockRow({
    required this.stock,
    required this.onTap,
  });

  final Stock stock;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE1E7EF)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${stock.symbol} ${stock.name}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${stock.industry} · ${stock.valuation.rangeLabel} · YoY ${formatPercent(stock.metric.revenueYoy)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '${stock.metric.qualityScore}',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
