// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html';

import 'proxy_http_client_base.dart';

ProxyHttpClient createProxyHttpClient() => _WebProxyHttpClient();

class _WebProxyHttpClient implements ProxyHttpClient {
  @override
  Future<String> getString(
    Uri uri, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final request = await HttpRequest.request(
      uri.toString(),
      method: 'GET',
      requestHeaders: const {'Accept': 'application/json'},
    ).timeout(timeout);
    final status = request.status ?? 0;
    if (status < 200 || status >= 300) {
      throw StateError('Proxy returned HTTP $status');
    }
    return request.responseText ?? '';
  }
}
