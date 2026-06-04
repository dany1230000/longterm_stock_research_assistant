enum RiskSeverity {
  low,
  medium,
  high,
}

extension RiskSeverityLabel on RiskSeverity {
  String get label {
    switch (this) {
      case RiskSeverity.low:
        return '低';
      case RiskSeverity.medium:
        return '中';
      case RiskSeverity.high:
        return '高';
    }
  }
}

class RiskAlert {
  const RiskAlert({
    required this.title,
    required this.severity,
    required this.description,
  });

  final String title;
  final RiskSeverity severity;
  final String description;
}
