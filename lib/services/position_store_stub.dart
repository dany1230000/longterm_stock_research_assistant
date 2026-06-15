final _positions = <String, String>{};

String _normalizeSymbol(String symbol) {
  final normalized = symbol.trim().toUpperCase();
  return normalized.isEmpty ? '00631L' : normalized;
}

Future<String?> load00631LPosition() async {
  return loadPosition('00631L');
}

Future<void> save00631LPosition(String json) async {
  return savePosition('00631L', json);
}

Future<void> clear00631LPosition() async {
  return clearPosition('00631L');
}

Future<String?> loadPosition(String symbol) async {
  return _positions[_normalizeSymbol(symbol)];
}

Future<void> savePosition(String symbol, String json) async {
  _positions[_normalizeSymbol(symbol)] = json;
}

Future<void> clearPosition(String symbol) async {
  _positions.remove(_normalizeSymbol(symbol));
}
