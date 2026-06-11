import 'position_store_stub.dart'
    if (dart.library.html) 'position_store_web.dart';

class PositionStore {
  static Future<String?> load00631L() {
    return load00631LPosition();
  }

  static Future<void> save00631L(String json) {
    return save00631LPosition(json);
  }

  static Future<void> clear00631L() {
    return clear00631LPosition();
  }
}
