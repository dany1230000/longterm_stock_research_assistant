import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/etf.dart';
import '../../repositories/repository_providers.dart';
import '../../shared/utils/formatters.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/metric_tile.dart';
import '../../shared/widgets/risk_chip.dart';
import '../../shared/widgets/section_card.dart';

class EtfCompareScreen extends ConsumerWidget {
  const EtfCompareScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final etfsValue = ref.watch(etfListProvider);
    final comparisonValue = ref.watch(etfComparisonProvider);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Text(
            'ETF 比較',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            '使用模擬 ETF 資料比較費用率、波動、持股與曝險重疊，僅供研究參考。',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
          ),
          const SizedBox(height: 16),
          etfsValue.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => EmptyState(
              icon: Icons.error_outline,
              title: 'ETF 模擬資料載入失敗',
              message: '$error',
            ),
            data: (etfs) => _EtfSelector(etfs: etfs),
          ),
          const SizedBox(height: 16),
          comparisonValue.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => EmptyState(
              icon: Icons.error_outline,
              title: 'ETF 比較資料載入失敗',
              message: '$error',
            ),
            data: (comparison) {
              return Column(
                children: [
                  _LeveragedWarning(
                    etfs: [comparison.left, comparison.right],
                  ),
                  _ComparisonSummary(etfs: [comparison.left, comparison.right]),
                  const SizedBox(height: 16),
                  SectionCard(
                    title: '比較表',
                    subtitle: comparison.overlapDescription,
                    child: Column(
                      children: [
                        _CompareRow(
                          label: '類型',
                          left: comparison.left.type,
                          right: comparison.right.type,
                        ),
                        _CompareRow(
                          label: '費用率',
                          left: formatPercent(comparison.left.expenseRatio),
                          right: formatPercent(comparison.right.expenseRatio),
                        ),
                        _CompareRow(
                          label: '配息頻率',
                          left: comparison.left.distributionFrequency,
                          right: comparison.right.distributionFrequency,
                        ),
                        _CompareRow(
                          label: '近一年表現',
                          left: formatSignedPercent(
                            comparison.left.lastYearReturn,
                          ),
                          right: formatSignedPercent(
                            comparison.right.lastYearReturn,
                          ),
                        ),
                        _CompareRow(
                          label: '近三年年化 mock',
                          left: formatPercent(
                            comparison.left.threeYearAnnualizedReturn,
                          ),
                          right: formatPercent(
                            comparison.right.threeYearAnnualizedReturn,
                          ),
                        ),
                        _CompareRow(
                          label: '波動度 mock',
                          left: formatPercent(comparison.left.volatility),
                          right: formatPercent(comparison.right.volatility),
                        ),
                        _CompareRow(
                          label: '最大回撤 mock',
                          left:
                              formatSignedPercent(comparison.left.maxDrawdown),
                          right:
                              formatSignedPercent(comparison.right.maxDrawdown),
                        ),
                        _CompareRow(
                          label: '重疊率 mock',
                          left: formatPercent(comparison.overlapRate),
                          right: formatPercent(comparison.overlapRate),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _HoldingsSection(etfs: [comparison.left, comparison.right]),
                  const SizedBox(height: 16),
                  _ExposureSection(etfs: [comparison.left, comparison.right]),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _EtfSelector extends ConsumerWidget {
  const _EtfSelector({required this.etfs});

  final List<Etf> etfs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pair = ref.watch(selectedEtfPairProvider);

    return SectionCard(
      title: '選擇兩檔 ETF',
      subtitle: '第一版使用模擬資料，重點是展示比較流程。',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 720;
          final selectors = [
            _EtfDropdown(
              label: 'ETF A',
              value: pair.$1,
              etfs: etfs,
              onChanged: (value) {
                ref.read(selectedEtfPairProvider.notifier).state =
                    (value, pair.$2);
              },
            ),
            _EtfDropdown(
              label: 'ETF B',
              value: pair.$2,
              etfs: etfs,
              onChanged: (value) {
                ref.read(selectedEtfPairProvider.notifier).state =
                    (pair.$1, value);
              },
            ),
          ];

          if (isWide) {
            return Row(
              children: [
                Expanded(child: selectors[0]),
                const SizedBox(width: 12),
                Expanded(child: selectors[1]),
              ],
            );
          }

          return Column(
            children: [
              selectors[0],
              const SizedBox(height: 12),
              selectors[1],
            ],
          );
        },
      ),
    );
  }
}

class _EtfDropdown extends StatelessWidget {
  const _EtfDropdown({
    required this.label,
    required this.value,
    required this.etfs,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<Etf> etfs;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: etfs.map((etf) {
        return DropdownMenuItem(
          value: etf.symbol,
          child: Text('${etf.symbol} ${etf.name}'),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }
}

class _LeveragedWarning extends StatelessWidget {
  const _LeveragedWarning({required this.etfs});

  final List<Etf> etfs;

  @override
  Widget build(BuildContext context) {
    if (!etfs.any((etf) => etf.isLeveraged)) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SectionCard(
        title: '槓桿型 ETF 風險提醒',
        child: Text(
          '槓桿型 ETF 風險較高，長期表現可能受波動拖累影響。本頁僅供研究參考。',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
        ),
      ),
    );
  }
}

class _ComparisonSummary extends StatelessWidget {
  const _ComparisonSummary({required this.etfs});

  final List<Etf> etfs;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'ETF 概覽',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 720;
          return GridView.count(
            crossAxisCount: isWide ? 4 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: isWide ? 1.25 : 1.0,
            children: [
              for (final etf in etfs) ...[
                MetricTile(
                  label: '${etf.symbol} 費用率',
                  value: formatPercent(etf.expenseRatio),
                  caption: etf.type,
                ),
                MetricTile(
                  label: '${etf.symbol} 波動度',
                  value: formatPercent(etf.volatility),
                  caption: 'mock',
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _CompareRow extends StatelessWidget {
  const _CompareRow({
    required this.label,
    required this.left,
    required this.right,
  });

  final String label;
  final String left;
  final String right;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 104,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(child: Text(left)),
          const SizedBox(width: 10),
          Expanded(child: Text(right)),
        ],
      ),
    );
  }
}

class _HoldingsSection extends StatelessWidget {
  const _HoldingsSection({required this.etfs});

  final List<Etf> etfs;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: '前五大持股 mock',
      child: Column(
        children: etfs.map((etf) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RiskChip(label: '${etf.symbol} ${etf.name}'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: etf.topHoldings.map((holding) {
                    return RiskChip(
                      label: '${holding.name} ${formatPercent(holding.weight)}',
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ExposureSection extends StatelessWidget {
  const _ExposureSection({required this.etfs});

  final List<Etf> etfs;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: '產業曝險 mock',
      subtitle: '用於比較兩檔 ETF 的主要曝險來源。',
      child: Column(
        children: etfs.map((etf) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${etf.symbol} ${etf.name}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                ...etf.industryExposure.entries.map((entry) {
                  return _ExposureBar(label: entry.key, value: entry.value);
                }),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ExposureBar extends StatelessWidget {
  const _ExposureBar({
    required this.label,
    required this.value,
  });

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(width: 84, child: Text(label)),
          Expanded(
            child: LinearProgressIndicator(
              value: value.clamp(0, 100) / 100,
              minHeight: 8,
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 52,
            child: Text(
              formatPercent(value),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
