import 'screener_condition.dart';

class ScreenerPreset {
  const ScreenerPreset({
    required this.id,
    required this.name,
    required this.condition,
    required this.createdAt,
  });

  final String id;
  final String name;
  final ScreenerCondition condition;
  final DateTime createdAt;

  factory ScreenerPreset.fromJson(Map<String, Object?> json) {
    return ScreenerPreset(
      id: json['id'] as String,
      name: json['name'] as String,
      condition: ScreenerCondition.fromJson(
        Map<String, Object?>.from(json['condition'] as Map),
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'name': name,
      'condition': condition.toJson(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
