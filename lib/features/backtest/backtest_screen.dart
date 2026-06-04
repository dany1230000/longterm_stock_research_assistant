import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/backtest_result.dart';
import '../../repositories/repository_providers.dart';
import '../../shared/utils/formatters.dart';
import '../../shared/widgets/metric_tile.dart';
import '../../shared/widgets/risk_chip.dart';
import '../../shared/widgets/section_card.dart';

class BacktestScreen extends ConsumerWidget {
  const BacktestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(backtestResultProvider);

    return SafeArea(
      child: result.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('回測資料載入失敗：$error')),
        data: (backtest) => _BacktestContent(result: backtest),
      ),
    );
  }
}

class _BacktestContent extends StatelessWidget {
  const _BacktestContent({required this.result});

  final BacktestResult result;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Text(
          '策略回測',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          '以模擬歷史資料呈現策略研究流程，協助理解條件組合的歷史統計特性。',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
        ),
        const SizedBox(height: 14),
        const _BacktestWarning(),
        const SizedBox(height: 16),
        SectionCard(
          title: result.strategyName,
          subtitle:
              '回測期間：${formatDate(result.startDate)} 到 ${formatDate(result.endDate)}',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '策略條件摘要',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: result.conditionSummary
                    .split('、')
                    .map((condition) => RiskChip(label: condition))
                    .toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: '歷史統計指標',
          subtitle: '以下數值為模擬結果，用於檢視策略研究框架。',
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 760;
              return GridView.count(
                crossAxisCount: isWide ? 4 : 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: isWide ? 1.35 : 1.04,
                children: [
                  MetricTile(
                    label: '年化報酬',
                    value: formatPercent(result.annualizedReturn),
                    caption: '歷史統計',
                  ),
                  MetricTile(
                    label: '最大回撤',
                    value: formatPercent(result.maxDrawdown),
                    caption: '歷史低谷幅度',
                  ),
                  MetricTile(
                    label: '勝率',
                    value: formatPercent(result.winRate),
                    caption: '樣本交易統計',
                  ),
                  MetricTile(
                    label: '平均持有天數',
                    value: '${result.averageHoldingDays}',
                    caption: '天',
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: '與 0050 比較',
          subtitle: '此比較僅用於歷史樣本定位。',
          child: Text(
            result.benchmarkComparison,
            style:
                Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: '年度報酬表',
          subtitle: '年度差異可協助觀察策略在不同市場環境下的穩定度。',
          child: Column(
            children: result.annualReturns.entries.map((entry) {
              return _AnnualReturnRow(year: entry.key, value: entry.value);
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _BacktestWarning extends StatelessWidget {
  const _BacktestWarning();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF3D08A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_outlined, color: theme.colorScheme.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '回測結果僅代表歷史統計，不保證未來績效。',
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnnualReturnRow extends StatelessWidget {
  const _AnnualReturnRow({
    required this.year,
    required this.value,
  });

  final int year;
  final double value;

  @override
  Widget build(BuildContext context) {
    final color = value >= 0
        ? const Color(0xFF15803D)
        : Theme.of(context).colorScheme.error;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              '$year',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 10,
                value: value.abs().clamp(0, 30) / 30,
                backgroundColor: const Color(0xFFE8EEF5),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 76,
            child: Text(
              formatSignedPercent(value),
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
