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
        _ProfileSection(profile: data.profile),
        const SizedBox(height: 16),
        _AssetAllocationSection(snapshot: data.snapshot),
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
        return GridView.count(
          crossAxisCount: isWide ? 5 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: isWide ? 1.35 : 1.05,
          children: cards,
        );
      },
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
