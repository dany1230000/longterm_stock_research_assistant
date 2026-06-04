import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/risk_alert.dart';
import '../../models/screener_condition.dart';
import '../../models/screener_preset.dart';
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
    final industries =
        ref.watch(industryOptionsProvider).valueOrNull ?? const ['全部'];
    final presets = ref.watch(screenerPresetControllerProvider);

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
            subtitle: '調整門檻後按下套用，結果會依指定排序產生研究清單。',
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
                  label: 'PB 小於',
                  value: _draftCondition.maxPb,
                  min: 0.8,
                  max: 10,
                  divisions: 46,
                  onChanged: (value) {
                    setState(() {
                      _draftCondition = _draftCondition.copyWith(maxPb: value);
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
                _ConditionSlider(
                  label: '成長分數大於',
                  value: _draftCondition.minGrowthScore,
                  min: 30,
                  max: 95,
                  divisions: 65,
                  onChanged: (value) {
                    setState(() {
                      _draftCondition =
                          _draftCondition.copyWith(minGrowthScore: value);
                    });
                  },
                ),
                _ConditionSlider(
                  label: '估值分數大於',
                  value: _draftCondition.minValuationScore,
                  min: 30,
                  max: 95,
                  divisions: 65,
                  onChanged: (value) {
                    setState(() {
                      _draftCondition =
                          _draftCondition.copyWith(minValuationScore: value);
                    });
                  },
                ),
                DropdownButtonFormField<RiskSeverity>(
                  initialValue: _draftCondition.maxRiskSeverity,
                  decoration: const InputDecoration(labelText: '風險程度低於'),
                  items: RiskSeverity.values.map((severity) {
                    return DropdownMenuItem(
                      value: severity,
                      child: Text('最高 ${severity.label} 風險'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _draftCondition =
                            _draftCondition.copyWith(maxRiskSeverity: value);
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: industries.contains(_draftCondition.industry)
                      ? _draftCondition.industry
                      : '全部',
                  decoration: const InputDecoration(labelText: '產業篩選'),
                  items: industries.map((industry) {
                    return DropdownMenuItem(
                      value: industry,
                      child: Text(industry),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _draftCondition =
                            _draftCondition.copyWith(industry: value);
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<ScreenerSortOption>(
                  initialValue: _draftCondition.sortOption,
                  decoration: const InputDecoration(labelText: '結果排序'),
                  items: ScreenerSortOption.values.map((option) {
                    return DropdownMenuItem(
                      value: option,
                      child: Text(option.label),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _draftCondition =
                            _draftCondition.copyWith(sortOption: value);
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
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
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _savePreset,
                    icon: const Icon(Icons.bookmark_add_outlined),
                    label: const Text('儲存目前條件 preset'),
                  ),
                ),
              ],
            ),
          ),
          if (presets.isNotEmpty) ...[
            const SizedBox(height: 16),
            SectionCard(
              title: '已儲存條件 preset',
              subtitle: '暫存於 local memory，重新啟動後會回到預設狀態。',
              child: Column(
                children: presets.map((preset) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _PresetRow(
                      preset: preset,
                      onLoad: () => _loadPreset(preset),
                      onDelete: () => _deletePreset(preset.id),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
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
                crossAxisAlignment: CrossAxisAlignment.start,
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

  void _savePreset() {
    final preset = ScreenerPreset(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: '研究條件 ${ref.read(screenerPresetControllerProvider).length + 1}',
      condition: _draftCondition,
      createdAt: DateTime.now(),
    );
    ref.read(screenerPresetControllerProvider.notifier).savePreset(preset);
  }

  void _loadPreset(ScreenerPreset preset) {
    setState(() {
      _draftCondition = preset.condition;
      _submittedCondition = preset.condition;
    });
  }

  void _deletePreset(String id) {
    ref.read(screenerPresetControllerProvider.notifier).deletePreset(id);
  }

  List<String> _conditionChips(ScreenerCondition condition) {
    return [
      'ROE > ${formatNumber(condition.minRoe)}%',
      '營收 YoY > ${formatNumber(condition.minRevenueYoy)}%',
      'PE < ${formatNumber(condition.maxPe)}',
      'PB < ${formatNumber(condition.maxPb)}',
      '殖利率 > ${formatNumber(condition.minDividendYield)}%',
      '體質 > ${formatNumber(condition.minQualityScore, decimals: 0)}',
      '成長 > ${formatNumber(condition.minGrowthScore, decimals: 0)}',
      '估值 > ${formatNumber(condition.minValuationScore, decimals: 0)}',
      '最高 ${condition.maxRiskSeverity.label} 風險',
      '產業 ${condition.industry}',
      '排序 ${condition.sortOption.label}',
      condition.requireAboveMa200 ? '站上 200 日均線' : '不限制 200 日均線',
    ];
  }
}

class _PresetRow extends StatelessWidget {
  const _PresetRow({
    required this.preset,
    required this.onLoad,
    required this.onDelete,
  });

  final ScreenerPreset preset;
  final VoidCallback onLoad;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                preset.name,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'ROE > ${formatNumber(preset.condition.minRoe)}% · PE < ${formatNumber(preset.condition.maxPe)} · ${preset.condition.sortOption.label}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: '載入',
          onPressed: onLoad,
          icon: const Icon(Icons.file_open_outlined),
        ),
        IconButton(
          tooltip: '刪除',
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline),
        ),
      ],
    );
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
                  RiskChip(label: 'PB ${formatNumber(stock.valuation.pb)}'),
                  RiskChip(
                    label:
                        '殖利率 ${formatPercent(stock.valuation.dividendYield)}',
                  ),
                  RiskChip(label: '成長 ${stock.metric.growthScore}'),
                  RiskChip(label: '估值 ${stock.metric.valuationScore}'),
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
