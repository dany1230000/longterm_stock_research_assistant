import 'package:flutter/material.dart';

import '../../shared/widgets/risk_chip.dart';
import '../../shared/widgets/section_card.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Text(
            '提醒中心',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            '以下為 mock 事件與風險提醒，用於展示研究工作流。所有內容僅作研究參考。',
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
          const _AlertGroup(
            title: '營收轉強提醒',
            alerts: [
              _MockAlert(
                label: '需要關注',
                title: '2308 台達電營收 YoY 改善',
                description: '近 12 個月模擬營收 YoY 呈改善，可作為研究參考。',
              ),
              _MockAlert(
                label: '研究參考',
                title: '2454 聯發科月營收動能維持',
                description: '模擬資料顯示營收年增率維持正向，需搭配毛利率檢視。',
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _AlertGroup(
            title: '估值偏高提醒',
            alerts: [
              _MockAlert(
                label: '風險提醒',
                title: '2330 台積電 PE / PB 分位偏高',
                description: '估值位於歷史樣本中上緣，後續需觀察獲利與產業需求。',
              ),
              _MockAlert(
                label: '需要關注',
                title: '2412 中華電估值分位偏高',
                description: '穩定現金流仍需與成長幅度及資本支出一起檢視。',
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _AlertGroup(
            title: '風險升高提醒',
            alerts: [
              _MockAlert(
                label: '風險提醒',
                title: '1301 台塑營收動能偏弱',
                description: '模擬資料顯示營收 YoY 仍為負值，需觀察景氣循環與產品利差。',
              ),
              _MockAlert(
                label: '需要關注',
                title: '2881 富邦金近月營收成長放緩',
                description: '金融股研究可同步觀察利率、資產品質與股利政策。',
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _AlertGroup(
            title: 'ETF 風險提醒',
            alerts: [
              _MockAlert(
                label: '風險提醒',
                title: '00631L 槓桿型 ETF 波動較高',
                description: '槓桿型 ETF 長期表現可能受波動拖累影響，僅供研究參考。',
              ),
              _MockAlert(
                label: '研究參考',
                title: '0050 與 006208 持股重疊率偏高',
                description: '研究 ETF 配置時可留意曝險重複程度。',
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _AlertGroup(
            title: '投資組合集中度提醒',
            alerts: [
              _MockAlert(
                label: '風險提醒',
                title: '半導體曝險集中',
                description: 'mock portfolio 對半導體情境較敏感，可作為風險集中研究參考。',
              ),
              _MockAlert(
                label: '需要關注',
                title: '單一持股權重較高',
                description: '最大權重持股對組合波動的影響需要持續觀察。',
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _AlertGroup(
            title: '財報 / 除權息 / 法說會 mock 事件提醒',
            alerts: [
              _MockAlert(
                label: '事件提醒',
                title: '2330 財報觀察週',
                description: '可追蹤 EPS、毛利率與資本支出變化。',
              ),
              _MockAlert(
                label: '事件提醒',
                title: '00878 配息資訊觀察',
                description: 'ETF 研究可搭配成分股、配息來源與費用率檢視。',
              ),
              _MockAlert(
                label: '事件提醒',
                title: '2308 法說會 mock event',
                description: '可整理管理層對產業需求與毛利率的說明。',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AlertGroup extends StatelessWidget {
  const _AlertGroup({
    required this.title,
    required this.alerts,
  });

  final String title;
  final List<_MockAlert> alerts;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: title,
      child: Column(
        children: alerts.map((alert) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RiskChip(label: alert.label),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        alert.description,
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

class _MockAlert {
  const _MockAlert({
    required this.label,
    required this.title,
    required this.description,
  });

  final String label;
  final String title;
  final String description;
}
