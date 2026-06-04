import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:longterm_stock_research_assistant/app.dart';

void main() {
  testWidgets('shows dashboard and switches primary tabs', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: LongTermStockResearchApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('中長線股票研究助理'), findsOneWidget);

    await tester.tap(find.text('篩選'));
    await tester.pumpAndSettle();
    expect(find.text('條件篩選'), findsOneWidget);

    await tester.tap(find.text('回測'));
    await tester.pumpAndSettle();
    expect(find.text('策略回測'), findsOneWidget);
    expect(find.text('回測結果僅代表歷史統計，不保證未來績效。'), findsOneWidget);

    await tester.tap(find.text('日記'));
    await tester.pumpAndSettle();
    expect(find.text('研究日記'), findsOneWidget);

    await tester.tap(find.text('設定'));
    await tester.pumpAndSettle();
    expect(find.text('資料來源說明'), findsOneWidget);
  });

  testWidgets('opens stock detail from dashboard', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: LongTermStockResearchApp()),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2330 台積電').first);
    await tester.pumpAndSettle();

    expect(find.text('股票基本資訊'), findsOneWidget);
    expect(find.text('中長線體質分數'), findsOneWidget);
    expect(find.text('總覽'), findsOneWidget);
    expect(find.text('財務'), findsOneWidget);
    expect(find.text('估值'), findsOneWidget);
    expect(find.text('風險'), findsOneWidget);
    expect(find.text('筆記'), findsOneWidget);
  });
}
