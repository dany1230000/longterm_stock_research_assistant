import 'theme_preference_store_stub.dart'
    if (dart.library.html) 'theme_preference_store_web.dart';

class ThemePreferenceStore {
  static Future<String?> load() {
    return loadThemePreference();
  }

  static Future<void> save(String value) {
    return saveThemePreference(value);
  }
}
