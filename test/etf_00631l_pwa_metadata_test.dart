import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PWA metadata is dedicated to 00631L and starts at root', () {
    final manifest = jsonDecode(File('web/manifest.json').readAsStringSync())
        as Map<String, dynamic>;
    final index = File('web/index.html').readAsStringSync();

    expect(manifest['name'], 'ETF 研究室 · 00631L 正二研究室');
    expect(manifest['short_name'], 'ETF研究室');
    expect(manifest['start_url'], './');
    expect(manifest['scope'], './');
    expect(manifest['description'], contains('00631L 正二研究室'));
    expect(manifest['description'], contains('PWA'));

    expect(index, contains('<title>ETF 研究室 · 00631L 正二研究室</title>'));
    expect(index, contains('id="app-loading"'));
    expect(index, contains('flutter-first-frame'));
    expect(index, contains('static public data'));
    expect(index,
        contains('name="application-name" content="ETF 研究室 · 00631L 正二研究室"'));
    expect(
        index, contains('name="apple-mobile-web-app-title" content="ETF研究室"'));
    expect(index, isNot(contains('LongTerm Stock Research Assistant')));
  });
}
