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
  final _topicController = TextEditingController();
  final _reasonController = TextEditingController();
  final _focusController = TextEditingController();
  final _riskController = TextEditingController();
  final _reviewController = TextEditingController();
  EmotionTag _emotionTag = EmotionTag.calm;
  DateTime _researchDate = DateTime.now();
  String _symbolFilter = '全部';
  EmotionTag? _emotionFilter;
  bool _newestFirst = true;

  @override
  void dispose() {
    _symbolController.dispose();
    _nameController.dispose();
    _topicController.dispose();
    _reasonController.dispose();
    _focusController.dispose();
    _riskController.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(journalControllerProvider);
    final filteredEntries = _filteredEntries(entries);
    final stockOptions = [
      '全部',
      ...entries.map((entry) => entry.symbol).toSet().toList()..sort(),
    ];

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Text(
            '研究筆記',
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
          _DisciplineSummary(entries: entries),
          const SizedBox(height: 16),
          SectionCard(
            title: '新增觀察紀錄',
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
                TextField(
                  controller: _topicController,
                  decoration: const InputDecoration(labelText: '研究主題'),
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
            '觀察紀錄',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 10),
          _JournalFilters(
            symbols: stockOptions,
            symbolFilter: _symbolFilter,
            emotionFilter: _emotionFilter,
            newestFirst: _newestFirst,
            onSymbolChanged: (value) {
              setState(() => _symbolFilter = value);
            },
            onEmotionChanged: (value) {
              setState(() => _emotionFilter = value);
            },
            onSortChanged: (value) {
              setState(() => _newestFirst = value);
            },
          ),
          const SizedBox(height: 12),
          if (entries.isEmpty)
            const EmptyState(
              icon: Icons.edit_note_outlined,
              title: '尚未建立研究紀錄',
              message: '可以先輸入一檔股票、研究理由與風險假設，建立第一筆可回顧的研究筆記。',
            )
          else if (filteredEntries.isEmpty)
            const EmptyState(
              icon: Icons.search_off_outlined,
              title: '目前沒有符合篩選的紀錄',
              message: '可以調整股票或情緒標籤篩選條件。',
            )
          else
            ...filteredEntries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _JournalEntryCard(
                  entry: entry,
                  onEdit: () => _showEditDialog(entry),
                  onDelete: () => _deleteEntry(entry.id),
                ),
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
      topic: _topicController.text.trim().isEmpty
          ? '一般研究'
          : _topicController.text.trim(),
      researchReason: _reasonController.text.trim(),
      observationFocus: _focusController.text.trim(),
      riskAssumption: _riskController.text.trim(),
      emotionTag: _emotionTag,
      reviewNote: _reviewController.text.trim(),
    );

    ref.read(journalControllerProvider.notifier).addEntry(entry);
    _symbolController.clear();
    _nameController.clear();
    _topicController.clear();
    _reasonController.clear();
    _focusController.clear();
    _riskController.clear();
    _reviewController.clear();
    setState(() {
      _emotionTag = EmotionTag.calm;
      _researchDate = DateTime.now();
    });
  }

  List<JournalEntry> _filteredEntries(List<JournalEntry> entries) {
    final filtered = entries.where((entry) {
      final symbolMatched =
          _symbolFilter == '全部' || entry.symbol == _symbolFilter;
      final emotionMatched =
          _emotionFilter == null || entry.emotionTag == _emotionFilter;
      return symbolMatched && emotionMatched;
    }).toList();
    filtered.sort((a, b) {
      final result = a.researchDate.compareTo(b.researchDate);
      return _newestFirst ? -result : result;
    });
    return filtered;
  }

  void _deleteEntry(String id) {
    ref.read(journalControllerProvider.notifier).deleteEntry(id);
  }

  Future<void> _showEditDialog(JournalEntry entry) async {
    final topicController = TextEditingController(text: entry.topic);
    final reasonController = TextEditingController(text: entry.researchReason);
    final focusController = TextEditingController(text: entry.observationFocus);
    final riskController = TextEditingController(text: entry.riskAssumption);
    final reviewController = TextEditingController(text: entry.reviewNote);
    var emotionTag = entry.emotionTag;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('編輯 ${entry.symbol} ${entry.stockName}'),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: topicController,
                        decoration: const InputDecoration(labelText: '研究主題'),
                      ),
                      const SizedBox(height: 12),
                      _JournalField(
                        label: '研究理由',
                        hintText: '更新研究理由。',
                        controller: reasonController,
                      ),
                      const SizedBox(height: 12),
                      _JournalField(
                        label: '觀察重點',
                        hintText: '更新觀察重點。',
                        controller: focusController,
                      ),
                      const SizedBox(height: 12),
                      _JournalField(
                        label: '風險假設',
                        hintText: '更新風險假設。',
                        controller: riskController,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<EmotionTag>(
                        initialValue: emotionTag,
                        decoration: const InputDecoration(labelText: '情緒標籤'),
                        items: EmotionTag.values.map((tag) {
                          return DropdownMenuItem(
                            value: tag,
                            child: Text(tag.label),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => emotionTag = value);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      _JournalField(
                        label: '後續檢討',
                        hintText: '更新後續檢討。',
                        controller: reviewController,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () {
                    final updated = entry.copyWith(
                      topic: topicController.text.trim().isEmpty
                          ? '一般研究'
                          : topicController.text.trim(),
                      researchReason: reasonController.text.trim(),
                      observationFocus: focusController.text.trim(),
                      riskAssumption: riskController.text.trim(),
                      emotionTag: emotionTag,
                      reviewNote: reviewController.text.trim(),
                    );
                    ref
                        .read(journalControllerProvider.notifier)
                        .updateEntry(updated);
                    Navigator.of(context).pop();
                  },
                  child: const Text('儲存'),
                ),
              ],
            );
          },
        );
      },
    );

    topicController.dispose();
    reasonController.dispose();
    focusController.dispose();
    riskController.dispose();
    reviewController.dispose();
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

class _DisciplineSummary extends StatelessWidget {
  const _DisciplineSummary({required this.entries});

  final List<JournalEntry> entries;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthlyCount = entries
        .where((entry) =>
            entry.researchDate.year == now.year &&
            entry.researchDate.month == now.month)
        .length;
    final tagCounts = <EmotionTag, int>{};
    for (final entry in entries) {
      tagCounts.update(entry.emotionTag, (value) => value + 1,
          ifAbsent: () => 1);
    }
    final mostCommonTag = tagCounts.entries.isEmpty
        ? '尚無'
        : (tagCounts.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value)))
            .first
            .key
            .label;
    final pendingReviewCount =
        entries.where((entry) => entry.reviewNote.trim().isEmpty).length;

    return SectionCard(
      title: '研究紀律摘要',
      subtitle: '以 local memory 內的研究紀錄整理。',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 720;
          return GridView.count(
            crossAxisCount: isWide ? 3 : 1,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: isWide ? 1.9 : 3.2,
            children: [
              _SummaryTile(label: '本月紀錄數', value: '$monthlyCount'),
              _SummaryTile(label: '最常出現情緒標籤', value: mostCommonTag),
              _SummaryTile(label: '尚未檢討紀錄數', value: '$pendingReviewCount'),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE1E7EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _JournalFilters extends StatelessWidget {
  const _JournalFilters({
    required this.symbols,
    required this.symbolFilter,
    required this.emotionFilter,
    required this.newestFirst,
    required this.onSymbolChanged,
    required this.onEmotionChanged,
    required this.onSortChanged,
  });

  final List<String> symbols;
  final String symbolFilter;
  final EmotionTag? emotionFilter;
  final bool newestFirst;
  final ValueChanged<String> onSymbolChanged;
  final ValueChanged<EmotionTag?> onEmotionChanged;
  final ValueChanged<bool> onSortChanged;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: '紀錄篩選',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 720;
          final fields = [
            DropdownButtonFormField<String>(
              initialValue:
                  symbols.contains(symbolFilter) ? symbolFilter : '全部',
              decoration: const InputDecoration(labelText: '依股票篩選'),
              items: symbols.map((symbol) {
                return DropdownMenuItem(value: symbol, child: Text(symbol));
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  onSymbolChanged(value);
                }
              },
            ),
            DropdownButtonFormField<EmotionTag?>(
              initialValue: emotionFilter,
              decoration: const InputDecoration(labelText: '依情緒標籤篩選'),
              items: [
                const DropdownMenuItem(value: null, child: Text('全部')),
                ...EmotionTag.values.map((tag) {
                  return DropdownMenuItem(value: tag, child: Text(tag.label));
                }),
              ],
              onChanged: onEmotionChanged,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('日期由新到舊'),
              value: newestFirst,
              onChanged: onSortChanged,
            ),
          ];

          if (isWide) {
            return Row(
              children: [
                Expanded(child: fields[0]),
                const SizedBox(width: 12),
                Expanded(child: fields[1]),
                const SizedBox(width: 12),
                Expanded(child: fields[2]),
              ],
            );
          }

          return Column(
            children: [
              fields[0],
              const SizedBox(height: 12),
              fields[1],
              fields[2],
            ],
          );
        },
      ),
    );
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
  const _JournalEntryCard({
    required this.entry,
    required this.onEdit,
    required this.onDelete,
  });

  final JournalEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SectionCard(
      title: '${entry.symbol} ${entry.stockName}',
      subtitle: '研究日期：${formatDate(entry.researchDate)} · ${entry.topic}',
      trailing: Wrap(
        spacing: 6,
        children: [
          RiskChip(label: entry.emotionTag.label),
          IconButton(
            tooltip: '編輯',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: '刪除',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
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
