import 'package:flutter/material.dart';

import '../../shared/widgets/section_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Text(
            '設定',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            '確認產品定位、資料限制與未來功能規劃。',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          const SectionCard(
            title: '免責聲明',
            child: Text(
              '本 App 提供之資訊僅供研究與教育用途，不構成任何投資建議、買賣建議或收益保證。使用者應自行判斷並承擔投資風險。',
            ),
          ),
          const SizedBox(height: 14),
          const SectionCard(
            title: '資料來源說明',
            child: Text(
              '目前為模擬資料，尚未串接真實台股行情、財報、營收、籌碼或法人資料來源。',
            ),
          ),
          const SizedBox(height: 14),
          const SectionCard(
            title: '資料授權提醒',
            child: Text(
              '未來接入真實資料前，需確認行情、財報、營收、ETF 與指數資料的授權條款、展示範圍、更新頻率與商業使用限制。',
            ),
          ),
          const SizedBox(height: 14),
          const SectionCard(
            title: '版本資訊',
            child: Text('LongTerm Stock Research Assistant 0.2.0 Web MVP'),
          ),
          const SizedBox(height: 14),
          const SectionCard(
            title: '未來功能 placeholder',
            subtitle: '以下為產品方向占位，尚未實作。',
            child: Column(
              children: [
                _FutureItem(icon: Icons.dataset_outlined, label: '真實台股資料'),
                _FutureItem(icon: Icons.notifications_outlined, label: '研究提醒'),
                _FutureItem(
                    icon: Icons.compare_arrows_outlined, label: 'ETF 比較'),
                _FutureItem(
                    icon: Icons.account_balance_wallet_outlined,
                    label: '投資組合風險分析'),
                _FutureItem(icon: Icons.auto_awesome_outlined, label: 'AI 摘要'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FutureItem extends StatelessWidget {
  const _FutureItem({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            '規劃中',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
