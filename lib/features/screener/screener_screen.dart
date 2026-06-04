import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/screener_condition.dart';
import '../../models/stock.dart';
import '../../repositories/repository_providers.dart';
import '../../shared/utils/formatters.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/risk_chip.dart';
import '../../shared/widgets/section_card.dart';

class ScreenerScreen extends ConsumerStatefulWidget {
  const ScreenerScreen({super.key});

  @override
  ConsumerState<ScreenerScreen> createState() => _ScreenerScreenState();
}

class _ScreenerScreenState extends ConsumerState<ScreenerScreen> {
  ScreenerCondition _draftCondition = const ScreenerCondition();
  ScreenerCondition _submittedCondition = const ScreenerCondition();

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(screenerResultsProvider(_submittedCondition));

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Text(
            '條件篩選',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            '用模擬資料建立條件篩選結果，整理可後續研究的觀察清單。',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: '條件設定',
            subtitle: '調整門檻後按下套用，結果會依體質分數排序。',
            child: Column(
              children: [
                _ConditionSlider(
                  label: 'ROE 大於',
                  value: _draftCondition.minRoe,
                  min: 0,
                  max: 30,
                  divisions: 30,
                  suffix: '%',
                  onChanged: (value) {
                    setState(() {
                      _draftCondition = _draftCondition.copyWith(minRoe: value);
                    });
                  },
                ),
                _ConditionSlider(
                  label: '近 12 個月營收 YoY 大於',
                  value: _draftCondition.minRevenueYoy,
                  min: -10,
                  max: 25,
                  divisions: 35,
                  suffix: '%',
                  onChanged: (value) {
                    setState(() {
                      _draftCondition =
                          _draftCondition.copyWith(minRevenueYoy: value);
                    });
                  },
                ),
                _ConditionSlider(
                  label: 'PE 小於',
                  value: _draftCondition.maxPe,
                  min: 8,
                  max: 45,
                  divisions: 37,
                  onChanged: (value) {
                    setState(() {
                      _draftCondition = _draftCondition.copyWith(maxPe: value);
                    });
                  },
                ),
                _ConditionSlider(
                  label: '殖利率大於',
                  value: _draftCondition.minDividendYield,
                  min: 0,
                  max: 6,
                  divisions: 24,
                  suffix: '%',
                  onChanged: (value) {
                    setState(() {
                      _draftCondition =
                          _draftCondition.copyWith(minDividendYield: value);
                    });
                  },
                ),
                _ConditionSlider(
                  label: '體質分數大於',
                  value: _draftCondition.minQualityScore,
                  min: 40,
                  max: 95,
                  divisions: 55,
                  onChanged: (value) {
                    setState(() {
                      _draftCondition =
                          _draftCondition.copyWith(minQualityScore: value);
                    });
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('要求站上 200 日均線'),
                  subtitle: const Text('以模擬趨勢條件作為研究篩選輔助。'),
                  value: _draftCondition.requireAboveMa200,
                  onChanged: (value) {
                    setState(() {
                      _draftCondition =
                          _draftCondition.copyWith(requireAboveMa200: value);
                    });
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _resetCondition,
                        icon: const Icon(Icons.restart_alt),
                        label: const Text('重設條件'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _applyCondition,
                        icon: const Icon(Icons.manage_search),
                        label: const Text('套用條件'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: '目前套用的條件摘要',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _conditionChips(_submittedCondition)
                  .map((label) => RiskChip(label: label))
                  .toList(),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            '符合條件的研究清單',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 10),
          results.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Text('篩選資料載入失敗：$error'),
            data: (stocks) {
              if (stocks.isEmpty) {
                return const EmptyState(
                  icon: Icons.filter_alt_off_outlined,
                  title: '目前沒有符合條件的樣本',
                  message: '可以放寬 ROE、PE、體質分數或趨勢條件，再重新產生研究清單。',
                );
              }
              return Column(
                children: stocks.map((stock) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ScreenerResultCard(
                      stock: stock,
                      onTap: () => context.push('/stocks/${stock.symbol}'),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  void _applyCondition() {
    setState(() => _submittedCondition = _draftCondition);
  }

  void _resetCondition() {
    setState(() {
      _draftCondition = const ScreenerCondition();
      _submittedCondition = const ScreenerCondition();
    });
  }

  List<String> _conditionChips(ScreenerCondition condition) {
    return [
      'ROE > ${formatNumber(condition.minRoe)}%',
      '營收 YoY > ${formatNumber(condition.minRevenueYoy)}%',
      'PE < ${formatNumber(condition.maxPe)}',
      '殖利率 > ${formatNumber(condition.minDividendYield)}%',
      '體質 > ${formatNumber(condition.minQualityScore, decimals: 0)}',
      condition.requireAboveMa200 ? '站上 200 日均線' : '不限制 200 日均線',
    ];
  }
}

class _ConditionSlider extends StatelessWidget {
  const _ConditionSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.divisions,
    this.suffix = '',
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final String suffix;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${formatNumber(value)}$suffix',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            label: '${formatNumber(value)}$suffix',
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _ScreenerResultCard extends StatelessWidget {
  const _ScreenerResultCard({
    required this.stock,
    required this.onTap,
  });

  final Stock stock;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                          '${stock.symbol} ${stock.name}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          stock.industry,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  RiskChip(label: '體質 ${stock.metric.qualityScore}'),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  RiskChip(label: 'ROE ${formatPercent(stock.metric.roe)}'),
                  RiskChip(
                    label: '營收 YoY ${formatPercent(stock.metric.revenueYoy)}',
                  ),
                  RiskChip(label: 'PE ${formatNumber(stock.valuation.pe)}'),
                  RiskChip(
                    label:
                        '殖利率 ${formatPercent(stock.valuation.dividendYield)}',
                  ),
                  RiskChip(
                    label: stock.metric.aboveMa200 ? '200 日均線之上' : '200 日均線之下',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '研究說明：此結果僅代表符合目前條件，不代表未來表現。',
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
