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
    this.topic = '一般研究',
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
  final String topic;
  final String researchReason;
  final String observationFocus;
  final String riskAssumption;
  final EmotionTag emotionTag;
  final String reviewNote;

  JournalEntry copyWith({
    String? id,
    String? symbol,
    String? stockName,
    DateTime? researchDate,
    String? topic,
    String? researchReason,
    String? observationFocus,
    String? riskAssumption,
    EmotionTag? emotionTag,
    String? reviewNote,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      symbol: symbol ?? this.symbol,
      stockName: stockName ?? this.stockName,
      researchDate: researchDate ?? this.researchDate,
      topic: topic ?? this.topic,
      researchReason: researchReason ?? this.researchReason,
      observationFocus: observationFocus ?? this.observationFocus,
      riskAssumption: riskAssumption ?? this.riskAssumption,
      emotionTag: emotionTag ?? this.emotionTag,
      reviewNote: reviewNote ?? this.reviewNote,
    );
  }

  factory JournalEntry.fromJson(Map<String, Object?> json) {
    return JournalEntry(
      id: json['id'] as String,
      symbol: json['symbol'] as String,
      stockName: json['stockName'] as String,
      researchDate: DateTime.parse(json['researchDate'] as String),
      topic: json['topic'] as String? ?? '一般研究',
      researchReason: json['researchReason'] as String? ?? '',
      observationFocus: json['observationFocus'] as String? ?? '',
      riskAssumption: json['riskAssumption'] as String? ?? '',
      emotionTag: EmotionTag.values.firstWhere(
        (tag) => tag.name == json['emotionTag'],
        orElse: () => EmotionTag.calm,
      ),
      reviewNote: json['reviewNote'] as String? ?? '',
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'symbol': symbol,
      'stockName': stockName,
      'researchDate': researchDate.toIso8601String(),
      'topic': topic,
      'researchReason': researchReason,
      'observationFocus': observationFocus,
      'riskAssumption': riskAssumption,
      'emotionTag': emotionTag.name,
      'reviewNote': reviewNote,
    };
  }
}
