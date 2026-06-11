import 'package:flutter/material.dart';

import 'theme_preference_store.dart';

final appThemeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);

Future<void> setAppThemeMode(ThemeMode mode) async {
  appThemeModeNotifier.value = mode;
  await ThemePreferenceStore.save(mode.name);
}

Future<void> loadSavedThemeMode() async {
  final value = await ThemePreferenceStore.load();
  if (value == null) {
    return;
  }
  appThemeModeNotifier.value = ThemeMode.values.firstWhere(
    (mode) => mode.name == value,
    orElse: () => ThemeMode.light,
  );
}
