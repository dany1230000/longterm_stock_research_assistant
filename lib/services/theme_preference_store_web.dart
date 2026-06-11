// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

const _key = '00631l_theme_mode';

Future<String?> loadThemePreference() async {
  return html.window.localStorage[_key];
}

Future<void> saveThemePreference(String value) async {
  html.window.localStorage[_key] = value;
}
