String formatNumber(num value, {int decimals = 1}) {
  return value.toStringAsFixed(decimals);
}

String formatPercent(num value, {int decimals = 1}) {
  return '${value.toStringAsFixed(decimals)}%';
}

String formatNullablePercent(num? value, {int decimals = 2}) {
  if (value == null) {
    return 'unavailable';
  }
  return '${value.toStringAsFixed(decimals)}%';
}

String formatSignedPercent(num value, {int decimals = 1}) {
  final prefix = value > 0 ? '+' : '';
  return '$prefix${value.toStringAsFixed(decimals)}%';
}

String formatSignedNullablePercent(num? value, {int decimals = 2}) {
  if (value == null) {
    return 'unavailable';
  }
  final prefix = value > 0 ? '+' : '';
  return '$prefix${value.toStringAsFixed(decimals)}%';
}

String formatCurrency(num value) {
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(2)} 兆';
  }
  return '${value.toStringAsFixed(0)} 億';
}

String formatNtdAmount(num? value, {int decimals = 0}) {
  if (value == null) {
    return 'unavailable';
  }

  final fixed = value.toStringAsFixed(decimals);
  final parts = fixed.split('.');
  final whole = _withThousands(parts.first);
  if (decimals == 0 || parts.length == 1) {
    return 'NTD $whole';
  }
  return 'NTD $whole.${parts.last}';
}

String formatInteger(num? value) {
  if (value == null) {
    return 'unavailable';
  }
  return _withThousands(value.round().toString());
}

String formatDate(DateTime date) {
  return '${date.year}-${_two(date.month)}-${_two(date.day)}';
}

String formatTaiwanDate(DateTime date) {
  return '${date.year}/${_two(date.month)}/${_two(date.day)}';
}

String formatDateTime(DateTime date) {
  return '${formatDate(date)} ${_two(date.hour)}:${_two(date.minute)}';
}

String formatTimeSeconds(DateTime date) {
  return '${_two(date.hour)}:${_two(date.minute)}:${_two(date.second)}';
}

String formatTaiwanDateTimeSeconds(DateTime date) {
  return '${formatTaiwanDate(date)} ${formatTimeSeconds(date)}';
}

String _two(int value) => value.toString().padLeft(2, '0');

String _withThousands(String input) {
  final negative = input.startsWith('-');
  final digits = negative ? input.substring(1) : input;
  final buffer = StringBuffer();

  for (var i = 0; i < digits.length; i += 1) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(digits[i]);
  }

  return negative ? '-$buffer' : buffer.toString();
}
