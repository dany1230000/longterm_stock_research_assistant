import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:longterm_stock_research_assistant/features/leveraged_etf_lab/leveraged_etf_00631l_screen.dart';
import 'package:longterm_stock_research_assistant/models/leveraged_etf_lab.dart';
import 'package:longterm_stock_research_assistant/repositories/cached_00631l_repository.dart';
import 'package:longterm_stock_research_assistant/repositories/mock_00631l_repository.dart';
import 'package:longterm_stock_research_assistant/repositories/official_00631l_repository.dart';
import 'package:longterm_stock_research_assistant/repositories/repository_providers.dart';

void main() {
  testWidgets('00631L lab renders summary cards', (tester) async {
    await _pumpLab(tester, Mock00631LRepository());

    expect(find.text('00631L 正二研究室'), findsOneWidget);
    expect(find.text('00631L 市價'), findsOneWidget);
    expect(find.text('預估淨值'), findsOneWidget);
    expect(find.text('折溢價 %'), findsOneWidget);
    expect(find.text('官方內容物日期'), findsOneWidget);
    expect(find.text('資料狀態'), findsOneWidget);
    expect(find.text('mock'), findsWidgets);
  });

  testWidgets('00631L lab shows fallback error state', (tester) async {
    await _pumpLab(tester, _Error00631LRepository());

    expect(find.text('00631L 資料載入失敗'), findsOneWidget);
    expect(find.textContaining('即時資料暫不可用'), findsOneWidget);
    expect(find.text('重新整理'), findsOneWidget);
  });

  testWidgets('00631L lab renders mock fallback when live proxy is down',
      (tester) async {
    await _pumpLab(
      tester,
      Cached00631LRepository(
        primary: _Error00631LRepository(),
        fallback: Mock00631LRepository(),
      ),
    );

    expect(find.text('mock'), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('00631L lab shows mock stock and futures tables', (tester) async {
    await _pumpLab(tester, Mock00631LRepository());

    await _scrollUntilTextVisible(tester, '股票明細表');
    expect(find.text('股票明細表'), findsOneWidget);
    expect(find.text('台積電'), findsOneWidget);
    expect(find.text('37.44%'), findsWidgets);

    await _scrollUntilTextVisible(tester, '期貨明細表');
    expect(find.text('期貨明細表'), findsOneWidget);
    expect(find.text('TX'), findsWidgets);
    expect(find.text('臺股期貨'), findsOneWidget);
    expect(find.text('202606'), findsWidgets);
  });

  testWidgets('00631L lab shows intraday NAV values and source contract',
      (tester) async {
    await _pumpLab(tester, Mock00631LRepository());

    expect(find.text('36.56'), findsWidgets);
    expect(find.text('+0.44%'), findsWidgets);
    expect(find.text('twse_a_k_json'), findsWidgets);
  });

  testWidgets('00631L lab labels unavailable intraday NAV', (tester) async {
    await _pumpLab(tester, _NoIntraday00631LRepository());

    expect(find.text('intraday unavailable'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}

Future<void> _pumpLab(
  WidgetTester tester,
  Official00631LRepository repository,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        official00631LRepositoryProvider.overrideWithValue(repository),
      ],
      child: const MaterialApp(
        home: Scaffold(body: LeveragedEtf00631LScreen()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _scrollUntilTextVisible(WidgetTester tester, String text) async {
  final listView = find.byType(ListView);
  for (var i = 0; i < 12 && find.text(text).evaluate().isEmpty; i += 1) {
    await tester.drag(listView, const Offset(0, -320));
    await tester.pumpAndSettle();
  }
}

class _Error00631LRepository extends Official00631LRepository {
  @override
  Future<LeveragedEtfProfile> fetchProfile() {
    throw const RepositoryFetchException('fixture failure');
  }

  @override
  Future<EtfDailyHoldingSnapshot> fetchDailySnapshot() {
    throw const RepositoryFetchException('fixture failure');
  }

  @override
  Future<EtfIntradayNav?> fetchIntradayNav() {
    throw const RepositoryFetchException('fixture failure');
  }

  @override
  Future<FuturesQuote> fetchFuturesQuote() {
    throw const RepositoryFetchException('fixture failure');
  }

  @override
  Future<Etf00631LLabData> fetchLabData() {
    throw const RepositoryFetchException('fixture failure');
  }
}

class _NoIntraday00631LRepository extends Mock00631LRepository {
  @override
  Future<EtfIntradayNav?> fetchIntradayNav() async {
    return null;
  }
}
