String? _themePreference;

Future<String?> loadThemePreference() async {
  return _themePreference;
}

Future<void> saveThemePreference(String value) async {
  _themePreference = value;
}
