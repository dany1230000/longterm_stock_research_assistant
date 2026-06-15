import 'position_store_stub.dart'
    if (dart.library.html) 'position_store_web.dart' as position_storage;

class PositionStore {
  static Future<String?> load00631L() {
    return position_storage.load00631LPosition();
  }

  static Future<void> save00631L(String json) {
    return position_storage.save00631LPosition(json);
  }

  static Future<void> clear00631L() {
    return position_storage.clear00631LPosition();
  }

  static Future<String?> loadPosition(String symbol) {
    return position_storage.loadPosition(symbol);
  }

  static Future<void> savePosition(String symbol, String json) {
    return position_storage.savePosition(symbol, json);
  }

  static Future<void> clearPosition(String symbol) {
    return position_storage.clearPosition(symbol);
  }
}
