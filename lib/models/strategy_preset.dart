class StrategyEvent {
  const StrategyEvent({
    required this.date,
    required this.title,
    required this.description,
  });

  final DateTime date;
  final String title;
  final String description;

  factory StrategyEvent.fromJson(Map<String, Object?> json) {
    return StrategyEvent(
      date: DateTime.parse(json['date'] as String),
      title: json['title'] as String,
      description: json['description'] as String,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'date': date.toIso8601String(),
      'title': title,
      'description': description,
    };
  }
}

class StrategyPreset {
  const StrategyPreset({
    required this.id,
    required this.name,
    required this.description,
    required this.conditionSummary,
  });

  final String id;
  final String name;
  final String description;
  final String conditionSummary;

  factory StrategyPreset.fromJson(Map<String, Object?> json) {
    return StrategyPreset(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      conditionSummary: json['conditionSummary'] as String,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'conditionSummary': conditionSummary,
    };
  }
}
