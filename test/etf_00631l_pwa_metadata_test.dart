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
    expect(index, contains('class="loading-shell"'));
    expect(index, contains('class="loading-nav"'));
    expect(index, contains('00631L 正二研究室'));
    expect(index, contains('ETF 研究室'));
    expect(index, contains('資料載入中'));
    expect(index, contains('盤中 NAV'));
    expect(index, contains('官方內容物'));
    expect(index, contains('歷史回測'));
    expect(index, contains('AI 分析'));
    expect(index, contains('flutter-first-frame'));
    expect(index, contains('公開靜態資料'));
    expect(index,
        contains('name="application-name" content="ETF 研究室 · 00631L 正二研究室"'));
    expect(
        index, contains('name="apple-mobile-web-app-title" content="ETF研究室"'));
    expect(index, isNot(contains('LongTerm Stock Research Assistant')));
    expect(index, isNot(contains('ETF Research Room')));
    expect(index, isNot(contains('loading data')));
    expect(index, isNot(contains('static public data')));
    expect(index, isNot(contains('LIVE')));
    expect(index, isNot(contains('DAY')));
    expect(index, isNot(contains('HIS')));
  });

  test('Pages build defaults to the public Render backend with static fallback',
      () {
    final workflow =
        File('.github/workflows/deploy_web.yml').readAsStringSync();
    final script =
        File('scripts/00631l_build_pages_static.cmd').readAsStringSync();

    expect(
      workflow,
      contains('https://longterm-stock-research-assistant.onrender.com'),
    );
    expect(workflow, contains('USE_00631L_LIVE_PROXY=true'));
    expect(workflow, contains('USE_00631L_STATIC_DATA=true'));

    expect(
      script,
      contains('https://longterm-stock-research-assistant.onrender.com'),
    );
    expect(script, contains('--dart-define=USE_00631L_LIVE_PROXY=true'));
    expect(script, contains('--dart-define=USE_00631L_STATIC_DATA=true'));
  });
}
