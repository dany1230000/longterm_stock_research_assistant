import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/journal_entry.dart';
import '../../repositories/repository_providers.dart';
import '../../shared/utils/formatters.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/risk_chip.dart';
import '../../shared/widgets/section_card.dart';

class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  final _symbolController = TextEditingController();
  final _nameController = TextEditingController();
  final _reasonController = TextEditingController();
  final _focusController = TextEditingController();
  final _riskController = TextEditingController();
  final _reviewController = TextEditingController();
  EmotionTag _emotionTag = EmotionTag.calm;
  DateTime _researchDate = DateTime.now();

  @override
  void dispose() {
    _symbolController.dispose();
    _nameController.dispose();
    _reasonController.dispose();
    _focusController.dispose();
    _riskController.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(journalControllerProvider);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Text(
            '研究日記',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            '記錄研究理由、觀察重點、風險假設與後續檢討，協助建立可回顧的研究流程。',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: '新增研究紀錄',
            subtitle: '第一版資料暫存於記憶體，重新啟動後會回到空狀態。',
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _symbolController,
                        decoration: const InputDecoration(labelText: '股票代號'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: '股票名稱'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: _pickResearchDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: '研究日期',
                      suffixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    child: Text(formatDate(_researchDate)),
                  ),
                ),
                const SizedBox(height: 12),
                _JournalField(
                  label: '研究理由',
                  hintText: '例如：產業變化、財報趨勢、估值分位或風險檢核。',
                  controller: _reasonController,
                ),
                const SizedBox(height: 12),
                _JournalField(
                  label: '預期觀察重點',
                  hintText: '例如：營收 YoY、ROE、毛利率、現金流或 200 日均線。',
                  controller: _focusController,
                ),
                const SizedBox(height: 12),
                _JournalField(
                  label: '風險假設',
                  hintText: '例如：估值分位偏高、需求放緩、成本上升或景氣循環。',
                  controller: _riskController,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<EmotionTag>(
                  initialValue: _emotionTag,
                  decoration: const InputDecoration(labelText: '情緒標籤'),
                  items: EmotionTag.values.map((tag) {
                    return DropdownMenuItem(
                      value: tag,
                      child: Text(tag.label),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _emotionTag = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                _JournalField(
                  label: '後續檢討欄位',
                  hintText: '未來回顧時補充：資料是否符合原本假設，哪些條件需要修正。',
                  controller: _reviewController,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _addEntry,
                    icon: const Icon(Icons.note_add_outlined),
                    label: const Text('新增紀錄'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            '研究紀錄',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 10),
          if (entries.isEmpty)
            const EmptyState(
              icon: Icons.edit_note_outlined,
              title: '尚未建立研究紀錄',
              message: '可以先輸入一檔股票、研究理由與風險假設，建立第一筆可回顧的研究筆記。',
            )
          else
            ...entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _JournalEntryCard(entry: entry),
              ),
            ),
        ],
      ),
    );
  }

  void _addEntry() {
    final symbol = _symbolController.text.trim();
    final stockName = _nameController.text.trim();
    if (symbol.isEmpty || stockName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請填寫股票代號與股票名稱')),
      );
      return;
    }

    final entry = JournalEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      symbol: symbol,
      stockName: stockName,
      researchDate: _researchDate,
      researchReason: _reasonController.text.trim(),
      observationFocus: _focusController.text.trim(),
      riskAssumption: _riskController.text.trim(),
      emotionTag: _emotionTag,
      reviewNote: _reviewController.text.trim(),
    );

    ref.read(journalControllerProvider.notifier).addEntry(entry);
    _symbolController.clear();
    _nameController.clear();
    _reasonController.clear();
    _focusController.clear();
    _riskController.clear();
    _reviewController.clear();
    setState(() {
      _emotionTag = EmotionTag.calm;
      _researchDate = DateTime.now();
    });
  }

  Future<void> _pickResearchDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _researchDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _researchDate = picked);
    }
  }
}

class _JournalField extends StatelessWidget {
  const _JournalField({
    required this.label,
    required this.hintText,
    required this.controller,
  });

  final String label;
  final String hintText;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: 2,
      maxLines: 4,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
      ),
    );
  }
}

class _JournalEntryCard extends StatelessWidget {
  const _JournalEntryCard({required this.entry});

  final JournalEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SectionCard(
      title: '${entry.symbol} ${entry.stockName}',
      subtitle: '研究日期：${formatDate(entry.researchDate)}',
      trailing: RiskChip(label: entry.emotionTag.label),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _EntryText(label: '研究理由', value: entry.researchReason),
          _EntryText(label: '預期觀察重點', value: entry.observationFocus),
          _EntryText(label: '風險假設', value: entry.riskAssumption),
          _EntryText(label: '後續檢討', value: entry.reviewNote),
          Text(
            '此紀錄僅作研究流程回顧，不代表任何方向性結論。',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _EntryText extends StatelessWidget {
  const _EntryText({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.45),
          children: [
            TextSpan(
              text: '$label：',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
