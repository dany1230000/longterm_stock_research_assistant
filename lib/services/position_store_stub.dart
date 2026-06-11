String? _position;

Future<String?> load00631LPosition() async {
  return _position;
}

Future<void> save00631LPosition(String json) async {
  _position = json;
}

Future<void> clear00631LPosition() async {
  _position = null;
}
