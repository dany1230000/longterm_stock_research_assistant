import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
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
    final strategies = ref.watch(strategyResultsProvider);
    final selected = ref.watch(selectedStrategyProvider);

    return SafeArea(
      child: strategies.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('策略資料載入失敗：$error')),
        data: (strategyList) => selected.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(child: Text('策略資料載入失敗：$error')),
          data: (backtest) => _BacktestContent(
            result: backtest,
            strategies: strategyList,
            onStrategyChanged: (id) {
              ref.read(selectedStrategyIdProvider.notifier).state = id;
            },
          ),
        ),
      ),
    );
  }
}

class _BacktestContent extends StatelessWidget {
  const _BacktestContent({
    required this.result,
    required this.strategies,
    required this.onStrategyChanged,
  });

  final BacktestResult result;
  final List<BacktestResult> strategies;
  final ValueChanged<String> onStrategyChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Text(
          '策略研究',
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
          title: '策略切換',
          subtitle: '切換不同 mock 策略時，統計、圖表與事件會同步更新。',
          child: DropdownButtonFormField<String>(
            initialValue: result.id,
            decoration: const InputDecoration(labelText: '策略名稱'),
            items: strategies.map((strategy) {
              return DropdownMenuItem(
                value: strategy.id,
                child: Text(strategy.strategyName),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                onStrategyChanged(value);
              }
            },
          ),
        ),
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
          title: '權益曲線 mock chart',
          subtitle: '用於展示策略淨值變化，不代表真實交易結果。',
          child: _MockLineChart(
            values: result.equityCurve,
            color: const Color(0xFF1D4E89),
            suffix: '',
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: '回撤 mock chart',
          subtitle: '用於觀察歷史統計中的低谷幅度。',
          child: _MockLineChart(
            values: result.drawdownCurve,
            color: const Color(0xFFB42318),
            suffix: '%',
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
        const SizedBox(height: 16),
        SectionCard(
          title: '策略事件列表',
          subtitle: '以 mock 事件輔助理解不同期間的策略狀態。',
          child: Column(
            children: result.events.map((event) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RiskChip(label: formatDate(event.date)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            event.description,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                      height: 1.45,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _MockLineChart extends StatelessWidget {
  const _MockLineChart({
    required this.values,
    required this.color,
    required this.suffix,
  });

  final List<double> values;
  final Color color;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final spread = math.max(maxValue - minValue, 1);

    return SizedBox(
      height: 190,
      child: LineChart(
        LineChartData(
          minY: minValue - spread * 0.12,
          maxY: maxValue + spread * 0.12,
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toStringAsFixed(0)}$suffix',
                    style: Theme.of(context).textTheme.labelSmall,
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var i = 0; i < values.length; i++)
                  FlSpot(i.toDouble(), values[i]),
              ],
              isCurved: true,
              barWidth: 3,
              color: color,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: color.withAlpha(24),
              ),
            ),
          ],
        ),
      ),
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
