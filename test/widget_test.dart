import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:longterm_stock_research_assistant/app.dart';
import 'package:longterm_stock_research_assistant/router.dart';

void main() {
  testWidgets('root opens standalone 00631L app', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: LongTermStockResearchApp()),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('ETF 研究室'), findsWidgets);
    expect(find.textContaining('00631L 正二研究室'), findsWidgets);
    expect(find.text('總覽'), findsWidgets);
    expect(find.text('歷回'), findsWidgets);
    expect(find.text('持倉'), findsWidgets);
    expect(find.text('AI'), findsWidgets);
    expect(find.text('帳戶'), findsWidgets);
    expect(
      find.byKey(const ValueKey('00631l-section-etf')),
      findsNothing,
    );
    expect(find.text('研究工作台'), findsNothing);
    expect(find.text('中長線股票研究助理'), findsNothing);
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
      '/': '00631L 正二研究室',
      '/dashboard': '中長線股票研究助理',
      '/stocks/2330': '股票基本資訊',
      '/screener': '條件設定',
      '/backtest': '策略研究',
      '/journal': '研究筆記',
      '/settings': '資料來源說明',
      '/etfs': 'ETF 比較',
      '/00631l-lab': '00631L 正二研究室',
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
      expect(find.textContaining(entry.value), findsWidgets);
    }
  });

  testWidgets('legacy lab route and internal dashboard entry remain reachable',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerConfig: createAppRouter(initialLocation: '/dashboard'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('中長線股票研究助理'), findsOneWidget);
    expect(find.text('00631L 正二研究室'), findsOneWidget);
    expect(find.textContaining('00631L 專用研究室'), findsOneWidget);
    expect(find.textContaining('/00631l-lab'), findsOneWidget);
    expect(find.text('進入 00631L 正二研究室'), findsOneWidget);

    await tester.tap(find.text('進入 00631L 正二研究室'));
    await tester.pumpAndSettle();

    expect(find.textContaining('00631L 正二研究室'), findsWidgets);
    expect(find.textContaining('行情'), findsWidgets);
    expect(find.textContaining('撣'), findsNothing);
    expect(find.text('更多資料'), findsOneWidget);
  });
}
