import '../models/screener_preset.dart';
import 'screener_preset_repository.dart';

class InMemoryScreenerPresetRepository implements ScreenerPresetRepository {
  final List<ScreenerPreset> _presets = [];

  @override
  List<ScreenerPreset> fetchPresets() {
    return List.unmodifiable(_presets);
  }

  @override
  void savePreset(ScreenerPreset preset) {
    final index = _presets.indexWhere((item) => item.id == preset.id);
    if (index == -1) {
      _presets.insert(0, preset);
    } else {
      _presets[index] = preset;
    }
  }

  @override
  void deletePreset(String id) {
    _presets.removeWhere((preset) => preset.id == id);
  }
}
