// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

const _key = '00631l_position_input';

Future<String?> load00631LPosition() async {
  return html.window.localStorage[_key];
}

Future<void> save00631LPosition(String json) async {
  html.window.localStorage[_key] = json;
}

Future<void> clear00631LPosition() async {
  html.window.localStorage.remove(_key);
}
