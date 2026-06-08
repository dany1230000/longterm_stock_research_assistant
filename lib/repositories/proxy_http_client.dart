import 'proxy_http_client_base.dart';
import 'proxy_http_client_stub.dart'
    if (dart.library.io) 'proxy_http_client_io.dart'
    if (dart.library.html) 'proxy_http_client_web.dart' as implementation;

export 'proxy_http_client_base.dart';

ProxyHttpClient createProxyHttpClient() {
  return implementation.createProxyHttpClient();
}
