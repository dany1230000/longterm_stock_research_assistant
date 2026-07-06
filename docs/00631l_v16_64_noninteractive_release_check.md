# 00631L v16.64 Noninteractive Release Check

This maintenance pass reduces the chance that validation opens a visible
Windows shell window.

- `release_check_00631l.py` resolves the Flutter SDK and calls the bundled
  `dart.exe` directly for `dart format`.
- `release_check_00631l.py` runs `flutter analyze`, `flutter test`, and
  `flutter build web` through `dart.exe` plus `flutter_tools.snapshot`, avoiding
  the high-frequency `cmd /c flutter.bat` wrapper.
- A backend unit test guards these core tool steps so they are not moved back
  behind a `cmd /c` wrapper.

Some legacy Windows helper scripts are still executed through their existing
`.cmd` wrappers. They should be migrated gradually when a Python entry point is
available for each helper.
