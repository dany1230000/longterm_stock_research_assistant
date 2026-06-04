import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/risk_alert.dart';
import '../../models/stock.dart';
import '../../repositories/repository_providers.dart';
import '../../services/research_summary_service.dart';
import '../../shared/utils/formatters.dart';
import '../../shared/widgets/metric_tile.dart';
import '../../shared/widgets/risk_chip.dart';
import '../../shared/widgets/score_bar.dart';
import '../../shared/widgets/section_card.dart';

enum _DetailSection {
  overview('總覽'),
  financial('財務'),
  valuation('估值'),
  revenue('營收'),
  observation('籌碼 / 觀察資料'),
  risk('風險'),
  notes('研究筆記');

  const _DetailSection(this.label);

  final String label;
}

class StockDetailScreen extends ConsumerWidget {
  const StockDetailScreen({required this.symbol, super.key});

  final String symbol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stockValue = ref.watch(stockDetailProvider(symbol));

    return SafeArea(
      child: stockValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('找不到資料：$error')),
        data: (stock) => _StockDetailContent(stock: stock),
      ),
    );
  }
}

class _StockDetailContent extends StatefulWidget {
  const _StockDetailContent({required this.stock});

  final Stock stock;

  @override
  State<_StockDetailContent> createState() => _StockDetailContentState();
}

class _StockDetailContentState extends State<_StockDetailContent> {
  _DetailSection _selectedSection = _DetailSection.overview;

  @override
  Widget build(BuildContext context) {
    final stock = widget.stock;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _Header(stock: stock),
        const SizedBox(height: 12),
        const _DisclaimerCard(),
        const SizedBox(height: 12),
        _SectionSelector(
          selectedSection: _selectedSection,
          onChanged: (section) {
            setState(() => _selectedSection = section);
          },
        ),
        const SizedBox(height: 14),
        _buildSection(stock),
      ],
    );
  }

  Widget _buildSection(Stock stock) {
    switch (_selectedSection) {
      case _DetailSection.overview:
        return _OverviewSection(stock: stock);
      case _DetailSection.financial:
        return _FinancialSection(stock: stock);
      case _DetailSection.valuation:
        return _ValuationSection(stock: stock);
      case _DetailSection.revenue:
        return _RevenueSection(stock: stock);
      case _DetailSection.observation:
        return _ObservationSection(stock: stock);
      case _DetailSection.risk:
        return _RiskSection(stock: stock);
      case _DetailSection.notes:
        return _NotesSection(stock: stock);
    }
  }
}

class _SectionSelector extends StatelessWidget {
  const _SectionSelector({
    required this.selectedSection,
    required this.onChanged,
  });

  final _DetailSection selectedSection;
  final ValueChanged<_DetailSection> onChanged;

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 760;

    if (isCompact) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _DetailSection.values.map((section) {
          return ChoiceChip(
            label: Text(section.label),
            selected: selectedSection == section,
            onSelected: (_) => onChanged(section),
          );
        }).toList(),
      );
    }

    return SegmentedButton<_DetailSection>(
      segments: _DetailSection.values
          .map(
            (section) => ButtonSegment(
              value: section,
              label: Text(section.label),
            ),
          )
          .toList(),
      selected: {selectedSection},
      onSelectionChanged: (selection) {
        onChanged(selection.first);
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.stock});

  final Stock stock;

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
                '${stock.symbol} ${stock.name}',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${stock.industry} · 模擬資料更新 ${formatDateTime(stock.lastUpdated)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        CircleAvatar(
          radius: 28,
          backgroundColor: theme.colorScheme.primary.withAlpha(31),
          child: Text(
            '${stock.metric.qualityScore}',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _DisclaimerCard extends StatelessWidget {
  const _DisclaimerCard();

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
          Icon(Icons.info_outline, color: theme.colorScheme.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '本頁資訊僅供研究與教育用途，不構成任何投資建議、買賣建議或收益保證。',
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewSection extends StatelessWidget {
  const _OverviewSection({required this.stock});

  final Stock stock;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SectionCard(
          title: '股票基本資訊',
          subtitle: stock.pricePositionDescription,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MetricGrid(
                children: [
                  MetricTile(label: '股票代號', value: stock.symbol),
                  MetricTile(label: '股票名稱', value: stock.name),
                  MetricTile(label: '產業', value: stock.industry),
                  MetricTile(
                      label: '市值', value: formatCurrency(stock.marketCap)),
                  MetricTile(
                    label: '市值級距',
                    value: _marketCapRange(stock.marketCap),
                  ),
                  MetricTile(
                      label: '最新價格', value: formatNumber(stock.latestClose)),
                  MetricTile(
                      label: '52 週高點', value: formatNumber(stock.high52Week)),
                  MetricTile(
                      label: '52 週低點', value: formatNumber(stock.low52Week)),
                  MetricTile(
                    label: '近一年表現',
                    value: formatSignedPercent(stock.metric.lastYearReturn),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    stock.tags.map((tag) => RiskChip(label: tag)).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SectionCard(
          title: '中長線體質分數',
          subtitle: '此分數代表目前資料條件下的研究參考，不代表未來報酬。',
          child: Column(
            children: [
              ScoreBar(label: '成長分數', score: stock.metric.growthScore),
              const SizedBox(height: 14),
              ScoreBar(label: '獲利分數', score: stock.metric.profitabilityScore),
              const SizedBox(height: 14),
              ScoreBar(label: '安全分數', score: stock.metric.safetyScore),
              const SizedBox(height: 14),
              ScoreBar(label: '估值分數', score: stock.metric.valuationScore),
              const SizedBox(height: 14),
              ScoreBar(label: '趨勢分數', score: stock.metric.trendScore),
            ],
          ),
        ),
      ],
    );
  }
}

String _marketCapRange(double marketCap) {
  if (marketCap >= 10000) {
    return '超大型';
  }
  if (marketCap >= 1000) {
    return '大型';
  }
  if (marketCap >= 500) {
    return '中大型';
  }
  return '中小型';
}

class _FinancialSection extends StatelessWidget {
  const _FinancialSection({required this.stock});

  final Stock stock;

  @override
  Widget build(BuildContext context) {
    final trend = stock.financialTrend;

    return SectionCard(
      title: '財務趨勢',
      subtitle: '以下為模擬資料，用於展示近季與近月趨勢視覺化。',
      child: Column(
        children: [
          _TrendChart(
            title: '近 8 季 EPS',
            values: trend.epsLast8Quarters,
            lineColor: const Color(0xFF1D4E89),
          ),
          const SizedBox(height: 14),
          _TrendChart(
            title: '近 8 季 ROE',
            values: trend.roeLast8Quarters,
            lineColor: const Color(0xFF2A9D8F),
            suffix: '%',
          ),
          const SizedBox(height: 14),
          _TrendChart(
            title: '近 8 季毛利率',
            values: trend.grossMarginLast8Quarters,
            lineColor: const Color(0xFF7952B3),
            suffix: '%',
          ),
          const SizedBox(height: 14),
          _TrendChart(
            title: '近 12 個月營收 YoY',
            values: trend.revenueYoyLast12Months,
            lineColor: const Color(0xFFE9A23B),
            suffix: '%',
          ),
        ],
      ),
    );
  }
}

class _ValuationSection extends StatelessWidget {
  const _ValuationSection({required this.stock});

  final Stock stock;

  @override
  Widget build(BuildContext context) {
    final valuation = stock.valuation;

    return SectionCard(
      title: '估值區間',
      subtitle: '目前估值位於歷史${valuation.rangeLabel}區間，僅作相對位置研究參考。',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MetricGrid(
            children: [
              MetricTile(label: '本益比 PE', value: formatNumber(valuation.pe)),
              MetricTile(label: '股價淨值比 PB', value: formatNumber(valuation.pb)),
              MetricTile(
                label: '殖利率',
                value: formatPercent(valuation.dividendYield),
              ),
              MetricTile(
                label: '近五年 PE 分位數',
                value: '${valuation.pePercentile5y}',
                caption: '百分位',
              ),
              MetricTile(
                label: '近五年 PB 分位數',
                value: '${valuation.pbPercentile5y}',
                caption: '百分位',
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '解讀方式：分位數越高代表目前估值在歷史樣本中越接近上緣，仍需搭配成長、獲利與產業循環檢視。',
            style:
                Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _RevenueSection extends StatelessWidget {
  const _RevenueSection({required this.stock});

  final Stock stock;

  @override
  Widget build(BuildContext context) {
    final revenueValues = stock.financialTrend.revenueYoyLast12Months;
    final first = revenueValues.first;
    final last = revenueValues.last;
    final direction = last >= first ? '近月營收 YoY 較期初改善' : '近月營收 YoY 較期初轉弱';

    return Column(
      children: [
        SectionCard(
          title: '營收趨勢',
          subtitle: '以下為近 12 個月營收 YoY 模擬資料，僅供研究流程展示。',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TrendChart(
                title: '近 12 個月營收 YoY',
                values: revenueValues,
                lineColor: const Color(0xFFE9A23B),
                suffix: '%',
              ),
              const SizedBox(height: 14),
              _MetricGrid(
                children: [
                  MetricTile(
                    label: '期初 YoY',
                    value: formatPercent(first),
                  ),
                  MetricTile(
                    label: '最新 YoY',
                    value: formatPercent(last),
                  ),
                  MetricTile(
                    label: '變化',
                    value: formatSignedPercent(last - first),
                  ),
                  MetricTile(
                    label: '狀態',
                    value: stock.tags.contains('營收轉弱') ? '需觀察' : '維持追蹤',
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                '$direction。此判讀只描述模擬資料變化，不代表未來營收表現。',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(height: 1.5),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ObservationSection extends StatelessWidget {
  const _ObservationSection({required this.stock});

  final Stock stock;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SectionCard(
          title: '籌碼 / 觀察資料',
          subtitle: '第一版尚未串接籌碼資料，以下為模擬觀察欄位與趨勢條件。',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MetricGrid(
                children: [
                  MetricTile(
                    label: '長期均線',
                    value: stock.metric.aboveMa200 ? '站上' : '未站上',
                    caption: 'mock 200 日均線',
                  ),
                  MetricTile(
                    label: '趨勢分數',
                    value: '${stock.metric.trendScore}',
                    caption: '0 - 100',
                  ),
                  MetricTile(
                    label: '近一年表現',
                    value: formatSignedPercent(stock.metric.lastYearReturn),
                  ),
                  MetricTile(
                    label: '價格位置',
                    value: stock.latestClose >=
                            stock.low52Week +
                                (stock.high52Week - stock.low52Week) * 0.7
                        ? '區間偏高'
                        : '區間中低',
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                stock.pricePositionDescription,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(height: 1.5),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    stock.tags.map((tag) => RiskChip(label: tag)).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RiskSection extends StatelessWidget {
  const _RiskSection({required this.stock});

  final Stock stock;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: '風險提醒',
      subtitle: '以下項目用於研究流程檢核，非方向性結論。',
      child: Column(
        children: stock.riskAlerts
            .map(
              (alert) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _RiskAlertTile(alert: alert),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _NotesSection extends StatelessWidget {
  const _NotesSection({required this.stock});

  final Stock stock;

  @override
  Widget build(BuildContext context) {
    const summaryService = ResearchSummaryService();

    return Column(
      children: [
        SectionCard(
          title: 'AI 白話摘要',
          subtitle: '第一版使用模擬摘要，未串接 AI API。',
          child: Text(
            summaryService.buildPlainLanguageSummary(stock),
            style:
                Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6),
          ),
        ),
        const SizedBox(height: 14),
        const SectionCard(
          title: '研究筆記提示',
          subtitle: '可在研究日記頁新增正式紀錄；本區提供個股頁的筆記框架。',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _NotePrompt(text: '本次研究理由：產業位置、財報趨勢或估值分位。'),
              SizedBox(height: 10),
              _NotePrompt(text: '後續觀察重點：營收 YoY、毛利率、現金流或趨勢條件。'),
              SizedBox(height: 10),
              _NotePrompt(text: '風險假設：估值分位、景氣循環、產品週期或資產品質。'),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 760;
        return GridView.count(
          crossAxisCount: isWide ? 4 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: isWide ? 1.35 : 1.04,
          children: children,
        );
      },
    );
  }
}

class _TrendChart extends StatelessWidget {
  const _TrendChart({
    required this.title,
    required this.values,
    required this.lineColor,
    this.suffix = '',
  });

  final String title;
  final List<double> values;
  final Color lineColor;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final spread = math.max(maxValue - minValue, 1);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE1E7EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 170,
            child: LineChart(
              LineChartData(
                minY: minValue - spread * 0.12,
                maxY: maxValue + spread * 0.12,
                gridData: const FlGridData(
                  show: true,
                  drawVerticalLine: false,
                ),
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
                    color: lineColor,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: lineColor.withAlpha(26),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RiskAlertTile extends StatelessWidget {
  const _RiskAlertTile({required this.alert});

  final RiskAlert alert;

  @override
  Widget build(BuildContext context) {
    final color = switch (alert.severity) {
      RiskSeverity.low => const Color(0xFF64748B),
      RiskSeverity.medium => const Color(0xFFE9A23B),
      RiskSeverity.high => const Color(0xFFB42318),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE1E7EF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        alert.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    RiskChip(label: alert.severity.label, color: color),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  alert.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.45,
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

class _NotePrompt extends StatelessWidget {
  const _NotePrompt({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.edit_note_outlined, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style:
                Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ),
      ],
    );
  }
}
