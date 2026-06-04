import '../models/screener_preset.dart';

abstract class ScreenerPresetRepository {
  List<ScreenerPreset> fetchPresets();

  void savePreset(ScreenerPreset preset);

  void deletePreset(String id);
}
