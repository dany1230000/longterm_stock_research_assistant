import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/portfolio.dart';
import '../../models/portfolio_risk.dart';
import '../../repositories/repository_providers.dart';
import '../../shared/utils/formatters.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/metric_tile.dart';
import '../../shared/widgets/risk_chip.dart';
import '../../shared/widgets/section_card.dart';

class PortfolioRiskScreen extends ConsumerWidget {
  const PortfolioRiskScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final riskValue = ref.watch(portfolioRiskProvider);

    return SafeArea(
      child: riskValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: EmptyState(
            icon: Icons.error_outline,
            title: '投資組合風險資料載入失敗',
            message: '$error',
          ),
        ),
        data: (risk) => _PortfolioRiskContent(risk: risk),
      ),
    );
  }
}

class _PortfolioRiskContent extends StatelessWidget {
  const _PortfolioRiskContent({required this.risk});

  final PortfolioRisk risk;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Text(
          '投資組合',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          '使用 mock portfolio 做持股總覽、集中度、曝險與情境模擬，僅供研究參考。',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
        ),
        const SizedBox(height: 16),
        const SectionCard(
          title: 'Demo / 模擬資料提醒',
          child: Text(
            '本頁目前使用模擬資料，僅供研究與教育用途，不構成投資建議、買賣建議或收益保證。',
          ),
        ),
        const SizedBox(height: 16),
        _OverviewSection(risk: risk),
        const SizedBox(height: 16),
        SectionCard(
          title: risk.portfolio.name,
          subtitle: '更新 ${formatDateTime(risk.portfolio.updatedAt)} · 模擬資料',
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
                  MetricTile(
                    label: '單一持股集中度',
                    value: formatPercent(risk.largestHoldingWeight),
                    caption: '最大權重',
                  ),
                  MetricTile(
                    label: '高估值曝險',
                    value: formatPercent(risk.highValuationExposure),
                    caption: 'mock',
                  ),
                  MetricTile(
                    label: '高波動曝險',
                    value: formatPercent(risk.highVolatilityExposure),
                    caption: 'mock',
                  ),
                  MetricTile(
                    label: 'ETF / 個股比例',
                    value:
                        '${formatPercent(risk.etfWeight)} / ${formatPercent(risk.stockWeight)}',
                    caption: '權重',
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        _HoldingsSection(holdings: risk.portfolio.holdings),
        const SizedBox(height: 16),
        _ConcentrationSection(risk: risk),
        const SizedBox(height: 16),
        _AlertSection(alerts: risk.alerts),
        const SizedBox(height: 16),
        _ScenarioSection(scenarios: risk.scenarios),
      ],
    );
  }
}

class _OverviewSection extends StatelessWidget {
  const _OverviewSection({required this.risk});

  final PortfolioRisk risk;

  @override
  Widget build(BuildContext context) {
    final holdings = risk.portfolio.holdings;
    final totalWeight =
        holdings.fold<double>(0, (sum, holding) => sum + holding.weight);

    return SectionCard(
      title: '持股總覽',
      subtitle: '以下權重與曝險皆為 mock data。',
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
              MetricTile(
                label: '持股數',
                value: '${holdings.length}',
                caption: 'mock portfolio',
              ),
              MetricTile(
                label: '總權重',
                value: formatPercent(totalWeight),
                caption: '檢查用',
              ),
              MetricTile(
                label: 'ETF 權重',
                value: formatPercent(risk.etfWeight),
                caption: 'mock',
              ),
              MetricTile(
                label: '個股權重',
                value: formatPercent(risk.stockWeight),
                caption: 'mock',
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HoldingsSection extends StatelessWidget {
  const _HoldingsSection({required this.holdings});

  final List<PortfolioHolding> holdings;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: '持股清單',
      subtitle: '權重與曝險皆為模擬資料。',
      child: Column(
        children: holdings.map((holding) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${holding.symbol} ${holding.name}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${holding.assetType.label} · ${holding.industry}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                RiskChip(label: formatPercent(holding.weight)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ConcentrationSection extends StatelessWidget {
  const _ConcentrationSection({required this.risk});

  final PortfolioRisk risk;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: '產業集中度',
      subtitle: '用於觀察風險集中與需要觀察的曝險來源。',
      child: Column(
        children: risk.industryConcentration.entries.map((entry) {
          return _RiskBar(label: entry.key, value: entry.value);
        }).toList(),
      ),
    );
  }
}

class _AlertSection extends StatelessWidget {
  const _AlertSection({required this.alerts});

  final List<String> alerts;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: '風險提醒',
      subtitle: '以下項目作為研究參考，不代表方向性結論。',
      child: alerts.isEmpty
          ? const Text('目前沒有明顯集中度提醒。')
          : Column(
              children: alerts.map((alert) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          alert,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(height: 1.5),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}

class _ScenarioSection extends StatelessWidget {
  const _ScenarioSection({required this.scenarios});

  final List<PortfolioScenario> scenarios;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: '情境模擬',
      subtitle: 'mock 情境分析僅用於觀察風險敏感度。',
      child: Column(
        children: scenarios.map((scenario) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RiskChip(label: formatSignedPercent(scenario.impactPercent)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        scenario.name,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        scenario.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
    );
  }
}

class _RiskBar extends StatelessWidget {
  const _RiskBar({
    required this.label,
    required this.value,
  });

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(width: 112, child: Text(label)),
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
