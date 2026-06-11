import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PWA metadata is dedicated to 00631L and starts at root', () {
    final manifest = jsonDecode(File('web/manifest.json').readAsStringSync())
        as Map<String, dynamic>;
    final index = File('web/index.html').readAsStringSync();

    expect(manifest['name'], '00631L 正二研究室');
    expect(manifest['short_name'], '00631L');
    expect(manifest['start_url'], './');
    expect(manifest['scope'], './');
    expect(manifest['description'], contains('00631L 正二研究室'));
    expect(manifest['description'], contains('PWA'));

    expect(index, contains('<title>00631L 正二研究室</title>'));
    expect(index, contains('name="application-name" content="00631L 正二研究室"'));
    expect(index,
        contains('name="apple-mobile-web-app-title" content="00631L 正二研究室"'));
    expect(index, isNot(contains('LongTerm Stock Research Assistant')));
  });
}
