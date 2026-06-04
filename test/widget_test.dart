import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:longterm_stock_research_assistant/app.dart';
import 'package:longterm_stock_research_assistant/router.dart';

void main() {
  testWidgets('shows dashboard and switches primary tabs', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: LongTermStockResearchApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('中長線股票研究助理'), findsOneWidget);

    await tester.tap(find.text('條件篩選'));
    await tester.pumpAndSettle();
    expect(find.text('條件篩選'), findsWidgets);

    await tester.tap(find.text('策略研究'));
    await tester.pumpAndSettle();
    expect(find.text('策略研究'), findsWidgets);
    expect(find.text('回測結果僅代表歷史統計，不保證未來績效。'), findsOneWidget);

    await tester.tap(find.text('投資組合'));
    await tester.pumpAndSettle();
    expect(find.text('投資組合'), findsWidgets);
    expect(find.text('持股總覽'), findsOneWidget);

    await tester.tap(find.text('設定'));
    await tester.pumpAndSettle();
    expect(find.text('資料來源說明'), findsOneWidget);
  });

  testWidgets('opens stock detail route', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerConfig: createAppRouter(initialLocation: '/stocks/2330'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('股票基本資訊'), findsOneWidget);
    expect(find.text('總覽'), findsOneWidget);
    expect(find.text('財務'), findsOneWidget);
    expect(find.text('估值'), findsOneWidget);
    expect(find.text('營收'), findsOneWidget);
    expect(find.text('籌碼 / 觀察資料'), findsOneWidget);
    expect(find.text('風險'), findsOneWidget);
    expect(find.text('研究筆記'), findsOneWidget);
  });

  testWidgets('primary and secondary routes render', (tester) async {
    final routes = <String, String>{
      '/dashboard': '中長線股票研究助理',
      '/stocks/2330': '股票基本資訊',
      '/screener': '條件設定',
      '/backtest': '策略研究',
      '/journal': '研究筆記',
      '/settings': '資料來源說明',
      '/etfs': 'ETF 比較',
      '/portfolio': '投資組合',
      '/alerts': '提醒中心',
    };

    for (final entry in routes.entries) {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: createAppRouter(initialLocation: entry.key),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(entry.value), findsWidgets);
    }
  });
}
