String formatNumber(num value, {int decimals = 1}) {
  return value.toStringAsFixed(decimals);
}

String formatPercent(num value, {int decimals = 1}) {
  return '${value.toStringAsFixed(decimals)}%';
}

String formatSignedPercent(num value, {int decimals = 1}) {
  final prefix = value > 0 ? '+' : '';
  return '$prefix${value.toStringAsFixed(decimals)}%';
}

String formatCurrency(num value) {
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(2)} 兆';
  }
  return '${value.toStringAsFixed(0)} 億';
}

String formatDate(DateTime date) {
  return '${date.year}-${_two(date.month)}-${_two(date.day)}';
}

String formatDateTime(DateTime date) {
  return '${formatDate(date)} ${_two(date.hour)}:${_two(date.minute)}';
}

String _two(int value) => value.toString().padLeft(2, '0');
