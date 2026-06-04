enum EmotionTag {
  calm,
  fomo,
  panic,
  greed,
  discipline,
}

extension EmotionTagLabel on EmotionTag {
  String get label {
    switch (this) {
      case EmotionTag.calm:
        return '冷靜';
      case EmotionTag.fomo:
        return 'FOMO';
      case EmotionTag.panic:
        return '恐慌';
      case EmotionTag.greed:
        return '貪婪';
      case EmotionTag.discipline:
        return '紀律';
    }
  }
}

class JournalEntry {
  const JournalEntry({
    required this.id,
    required this.symbol,
    required this.stockName,
    required this.researchDate,
    required this.researchReason,
    required this.observationFocus,
    required this.riskAssumption,
    required this.emotionTag,
    required this.reviewNote,
  });

  final String id;
  final String symbol;
  final String stockName;
  final DateTime researchDate;
  final String researchReason;
  final String observationFocus;
  final String riskAssumption;
  final EmotionTag emotionTag;
  final String reviewNote;
}
