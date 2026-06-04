import 'strategy_preset.dart';

class BacktestResult {
  const BacktestResult({
    required this.id,
    required this.strategyName,
    required this.conditionSummary,
    required this.startDate,
    required this.endDate,
    required this.annualizedReturn,
    required this.maxDrawdown,
    required this.winRate,
    required this.averageHoldingDays,
    required this.benchmarkComparison,
    required this.annualReturns,
    required this.equityCurve,
    required this.drawdownCurve,
    required this.events,
  });

  final String id;
  final String strategyName;
  final String conditionSummary;
  final DateTime startDate;
  final DateTime endDate;
  final double annualizedReturn;
  final double maxDrawdown;
  final double winRate;
  final int averageHoldingDays;
  final String benchmarkComparison;
  final Map<int, double> annualReturns;
  final List<double> equityCurve;
  final List<double> drawdownCurve;
  final List<StrategyEvent> events;

  factory BacktestResult.fromJson(Map<String, Object?> json) {
    return BacktestResult(
      id: json['id'] as String,
      strategyName: json['strategyName'] as String,
      conditionSummary: json['conditionSummary'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      annualizedReturn: (json['annualizedReturn'] as num).toDouble(),
      maxDrawdown: (json['maxDrawdown'] as num).toDouble(),
      winRate: (json['winRate'] as num).toDouble(),
      averageHoldingDays: json['averageHoldingDays'] as int,
      benchmarkComparison: json['benchmarkComparison'] as String,
      annualReturns:
          (json['annualReturns'] as Map<String, Object?>).map((key, value) {
        return MapEntry(int.parse(key), (value as num).toDouble());
      }),
      equityCurve: (json['equityCurve'] as List)
          .map((value) => (value as num).toDouble())
          .toList(),
      drawdownCurve: (json['drawdownCurve'] as List)
          .map((value) => (value as num).toDouble())
          .toList(),
      events: (json['events'] as List)
          .map(
            (event) => StrategyEvent.fromJson(
              Map<String, Object?>.from(event as Map),
            ),
          )
          .toList(),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'strategyName': strategyName,
      'conditionSummary': conditionSummary,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'annualizedReturn': annualizedReturn,
      'maxDrawdown': maxDrawdown,
      'winRate': winRate,
      'averageHoldingDays': averageHoldingDays,
      'benchmarkComparison': benchmarkComparison,
      'annualReturns': annualReturns.map(
        (key, value) => MapEntry('$key', value),
      ),
      'equityCurve': equityCurve,
      'drawdownCurve': drawdownCurve,
      'events': events.map((event) => event.toJson()).toList(),
    };
  }
}
