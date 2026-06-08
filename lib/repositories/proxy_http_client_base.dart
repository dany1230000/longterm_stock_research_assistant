abstract class ProxyHttpClient {
  Future<String> getString(
    Uri uri, {
    Duration timeout = const Duration(seconds: 8),
  });
}
