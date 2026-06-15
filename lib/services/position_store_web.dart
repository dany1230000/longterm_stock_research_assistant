// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

const _key = '00631l_position_input';

String _symbolKey(String symbol) {
  final normalized = symbol.trim().toUpperCase();
  return normalized.isEmpty ? _key : 'etf_position_input_$normalized';
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
  final key = _symbolKey(symbol);
  return html.window.localStorage[key] ??
      (symbol.trim().toUpperCase() == '00631L'
          ? html.window.localStorage[_key]
          : null);
}

Future<void> savePosition(String symbol, String json) async {
  html.window.localStorage[_symbolKey(symbol)] = json;
}

Future<void> clearPosition(String symbol) async {
  html.window.localStorage.remove(_symbolKey(symbol));
}
