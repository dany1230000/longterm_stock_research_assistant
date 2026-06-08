import 'proxy_http_client_base.dart';

ProxyHttpClient createProxyHttpClient() => _UnsupportedProxyHttpClient();

class _UnsupportedProxyHttpClient implements ProxyHttpClient {
  @override
  Future<String> getString(
    Uri uri, {
    Duration timeout = const Duration(seconds: 8),
  }) {
    throw UnsupportedError(
        'No proxy HTTP client is available on this platform');
  }
}
