import 'etf.dart';

class EtfComparison {
  const EtfComparison({
    required this.left,
    required this.right,
    required this.overlapRate,
    required this.overlapDescription,
  });

  final Etf left;
  final Etf right;
  final double overlapRate;
  final String overlapDescription;

  factory EtfComparison.fromJson(Map<String, Object?> json) {
    return EtfComparison(
      left: Etf.fromJson(Map<String, Object?>.from(json['left'] as Map)),
      right: Etf.fromJson(Map<String, Object?>.from(json['right'] as Map)),
      overlapRate: (json['overlapRate'] as num).toDouble(),
      overlapDescription: json['overlapDescription'] as String,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'left': left.toJson(),
      'right': right.toJson(),
      'overlapRate': overlapRate,
      'overlapDescription': overlapDescription,
    };
  }
}
